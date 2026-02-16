// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {Pausable} from "@openzeppelin/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IBridgeAdapter} from "../interfaces/IBridgeAdapter.sol";

interface ICanonicalTokenBridge {
    function bridgeERC20To(
        address localToken,
        address remoteToken,
        address to,
        uint256 amount,
        uint32 minGasLimit,
        bytes calldata extraData
    ) external;
}

/// @notice Canonical bridge adapter for spoke->hub ERC20 transfers.
/// @dev Intended for Base/Worldchain canonical routes. Supports per-token bridge routes and caller allowlisting.
contract CanonicalBridgeAdapter is Ownable, Pausable, ReentrancyGuard, IBridgeAdapter {
    using SafeERC20 for IERC20;

    struct Route {
        address bridge;
        address remoteToken;
        uint32 minGasLimit;
        bool enabled;
    }

    mapping(address => Route) public routes;
    mapping(address => bool) public allowedCaller;
    uint32 public defaultMinGasLimit = 200_000;

    event RouteSet(
        address indexed localToken,
        address indexed bridge,
        address indexed remoteToken,
        uint32 minGasLimit,
        bool enabled
    );
    event AllowedCallerSet(address indexed caller, bool allowed);
    event DefaultMinGasLimitSet(uint32 minGasLimit);
    event CanonicalBridgeInitiated(
        address indexed localToken,
        address indexed remoteToken,
        address indexed hubRecipient,
        address bridge,
        uint256 amount,
        uint32 minGasLimit,
        bytes extraData,
        address caller
    );

    error InvalidToken(address token);
    error InvalidBridge(address bridge);
    error InvalidRecipient(address recipient);
    error InvalidAmount();
    error InvalidMinGasLimit();
    error UnauthorizedCaller(address caller);
    error RouteNotEnabled(address localToken);

    constructor(address owner_) Ownable(owner_) {}

    function setAllowedCaller(address caller, bool allowed) external onlyOwner {
        if (caller == address(0)) revert UnauthorizedCaller(caller);
        allowedCaller[caller] = allowed;
        emit AllowedCallerSet(caller, allowed);
    }

    function setDefaultMinGasLimit(uint32 minGasLimit) external onlyOwner {
        if (minGasLimit == 0) revert InvalidMinGasLimit();
        defaultMinGasLimit = minGasLimit;
        emit DefaultMinGasLimitSet(minGasLimit);
    }

    function setRoute(address localToken, address bridge, address remoteToken, uint32 minGasLimit, bool enabled)
        external
        onlyOwner
    {
        if (localToken == address(0)) revert InvalidToken(localToken);
        if (bridge == address(0)) revert InvalidBridge(bridge);
        if (remoteToken == address(0)) revert InvalidToken(remoteToken);

        routes[localToken] = Route({
            bridge: bridge,
            remoteToken: remoteToken,
            minGasLimit: minGasLimit,
            enabled: enabled
        });

        emit RouteSet(localToken, bridge, remoteToken, minGasLimit, enabled);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function bridgeToHub(address token, uint256 amount, address hubRecipient, bytes calldata extraData)
        external
        nonReentrant
        whenNotPaused
    {
        if (!allowedCaller[msg.sender]) revert UnauthorizedCaller(msg.sender);
        if (token == address(0)) revert InvalidToken(token);
        if (hubRecipient == address(0)) revert InvalidRecipient(hubRecipient);
        if (amount == 0) revert InvalidAmount();

        Route memory route = routes[token];
        if (!route.enabled || route.bridge == address(0) || route.remoteToken == address(0)) {
            revert RouteNotEnabled(token);
        }

        uint32 minGasLimit = route.minGasLimit == 0 ? defaultMinGasLimit : route.minGasLimit;

        // Pull escrowed tokens from portal (or another authorized caller), then hand off to canonical bridge.
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        IERC20(token).safeApprove(route.bridge, 0);
        IERC20(token).safeApprove(route.bridge, amount);

        ICanonicalTokenBridge(route.bridge).bridgeERC20To(
            token, route.remoteToken, hubRecipient, amount, minGasLimit, extraData
        );

        IERC20(token).safeApprove(route.bridge, 0);

        emit CanonicalBridgeInitiated(
            token,
            route.remoteToken,
            hubRecipient,
            route.bridge,
            amount,
            minGasLimit,
            extraData,
            msg.sender
        );
    }
}
