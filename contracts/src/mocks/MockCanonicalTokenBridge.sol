// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";

contract MockCanonicalTokenBridge {
    using SafeERC20 for IERC20;

    address public lastLocalToken;
    address public lastRemoteToken;
    address public lastRecipient;
    uint256 public lastAmount;
    uint32 public lastMinGasLimit;
    bytes32 public lastExtraDataHash;
    address public lastCaller;

    event BridgeCalled(
        address indexed localToken,
        address indexed remoteToken,
        address indexed recipient,
        uint256 amount,
        uint32 minGasLimit,
        bytes extraData,
        address caller
    );

    function bridgeERC20To(
        address localToken,
        address remoteToken,
        address to,
        uint256 amount,
        uint32 minGasLimit,
        bytes calldata extraData
    ) external {
        IERC20(localToken).safeTransferFrom(msg.sender, address(this), amount);

        lastLocalToken = localToken;
        lastRemoteToken = remoteToken;
        lastRecipient = to;
        lastAmount = amount;
        lastMinGasLimit = minGasLimit;
        lastExtraDataHash = keccak256(extraData);
        lastCaller = msg.sender;

        emit BridgeCalled(localToken, remoteToken, to, amount, minGasLimit, extraData, msg.sender);
    }
}
