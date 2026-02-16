// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {Pausable} from "@openzeppelin/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/security/ReentrancyGuard.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Constants} from "../libraries/Constants.sol";
import {IntentHasher} from "../libraries/IntentHasher.sol";
import {IBridgeAdapter} from "../interfaces/IBridgeAdapter.sol";

contract SpokePortal is Ownable, Pausable, ReentrancyGuard {
    using SafeERC20 for IERC20;

    struct Deposit {
        uint8 intentType;
        address user;
        address token;
        uint256 amount;
        uint256 timestamp;
    }

    uint256 public immutable hubChainId;

    IBridgeAdapter public bridgeAdapter;
    address public hubRecipient;

    uint256 public nextDepositId;

    mapping(uint256 => Deposit) public deposits;
    mapping(bytes32 => bool) public filledIntent;

    event BridgeAdapterSet(address indexed adapter);
    event HubRecipientSet(address indexed hubRecipient);

    event SupplyInitiated(
        uint256 indexed depositId,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 hubChainId,
        uint256 timestamp
    );

    event RepayInitiated(
        uint256 indexed depositId,
        address indexed user,
        address indexed token,
        uint256 amount,
        uint256 hubChainId,
        uint256 timestamp
    );

    event BorrowFilled(
        bytes32 indexed intentId,
        address indexed user,
        address indexed token,
        uint256 amountToUser,
        address relayer,
        uint256 fee,
        uint256 timestamp
    );

    event WithdrawFilled(
        bytes32 indexed intentId,
        address indexed user,
        address indexed token,
        uint256 amountToUser,
        address relayer,
        uint256 fee,
        uint256 timestamp
    );

    error InvalidAmount();
    error UnsupportedIntentType(uint8 intentType);
    error IntentAlreadyFilled(bytes32 intentId);
    error InvalidFee(uint256 fee, uint256 maxFee);
    error InvalidOutputChain(uint256 outputChainId, uint256 chainId);
    error AdapterNotSet();
    error HubRecipientNotSet();

    constructor(address owner_, uint256 hubChainId_) Ownable(owner_) {
        hubChainId = hubChainId_;
    }

    function setBridgeAdapter(address bridgeAdapter_) external onlyOwner {
        bridgeAdapter = IBridgeAdapter(bridgeAdapter_);
        emit BridgeAdapterSet(bridgeAdapter_);
    }

    function setHubRecipient(address hubRecipient_) external onlyOwner {
        hubRecipient = hubRecipient_;
        emit HubRecipientSet(hubRecipient_);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function initiateSupply(address token, uint256 amount, address user)
        external
        nonReentrant
        whenNotPaused
        returns (uint256 depositId)
    {
        depositId = _initiateInbound(Constants.INTENT_SUPPLY, token, amount, user);
        emit SupplyInitiated(depositId, user, token, amount, hubChainId, block.timestamp);
    }

    function initiateRepay(address token, uint256 amount, address user)
        external
        nonReentrant
        whenNotPaused
        returns (uint256 depositId)
    {
        depositId = _initiateInbound(Constants.INTENT_REPAY, token, amount, user);
        emit RepayInitiated(depositId, user, token, amount, hubChainId, block.timestamp);
    }

    function fillBorrow(DataTypes.Intent calldata intent, uint256 relayerFee, bytes calldata)
        external
        nonReentrant
        whenNotPaused
        returns (bytes32 intentId)
    {
        if (intent.intentType != Constants.INTENT_BORROW) revert UnsupportedIntentType(intent.intentType);
        intentId = _fillOutbound(intent, relayerFee);
        emit BorrowFilled(
            intentId,
            intent.user,
            intent.outputToken,
            intent.amount - relayerFee,
            msg.sender,
            relayerFee,
            block.timestamp
        );
    }

    function fillWithdraw(DataTypes.Intent calldata intent, uint256 relayerFee, bytes calldata)
        external
        nonReentrant
        whenNotPaused
        returns (bytes32 intentId)
    {
        if (intent.intentType != Constants.INTENT_WITHDRAW) revert UnsupportedIntentType(intent.intentType);
        intentId = _fillOutbound(intent, relayerFee);
        emit WithdrawFilled(
            intentId,
            intent.user,
            intent.outputToken,
            intent.amount - relayerFee,
            msg.sender,
            relayerFee,
            block.timestamp
        );
    }

    function _initiateInbound(uint8 intentType, address token, uint256 amount, address user)
        internal
        returns (uint256 depositId)
    {
        // Spoke only escrows and forwards to bridge adapter; accounting stays on hub.
        if (amount == 0) revert InvalidAmount();
        if (address(bridgeAdapter) == address(0)) revert AdapterNotSet();
        if (hubRecipient == address(0)) revert HubRecipientNotSet();

        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);

        depositId = ++nextDepositId;
        deposits[depositId] = Deposit({
            intentType: intentType,
            user: user,
            token: token,
            amount: amount,
            timestamp: block.timestamp
        });

        IERC20(token).safeApprove(address(bridgeAdapter), 0);
        IERC20(token).safeApprove(address(bridgeAdapter), amount);

        bridgeAdapter.bridgeToHub(
            token,
            amount,
            hubRecipient,
            abi.encode(depositId, intentType, user, token, amount, block.chainid, hubChainId)
        );
    }

    function _fillOutbound(DataTypes.Intent calldata intent, uint256 relayerFee) internal returns (bytes32 intentId) {
        // Fills are single-use by intentId; settlement on hub is the source of accounting truth.
        if (intent.outputChainId != block.chainid) {
            revert InvalidOutputChain(intent.outputChainId, block.chainid);
        }
        if (intent.amount == 0 || relayerFee > intent.maxRelayerFee || relayerFee >= intent.amount) {
            revert InvalidFee(relayerFee, intent.maxRelayerFee);
        }

        intentId = IntentHasher.rawIntentId(intent);
        if (filledIntent[intentId]) revert IntentAlreadyFilled(intentId);

        filledIntent[intentId] = true;
        IERC20(intent.outputToken).safeTransferFrom(msg.sender, intent.recipient, intent.amount - relayerFee);
    }
}
