// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {Pausable} from "@openzeppelin/security/Pausable.sol";
import {ReentrancyGuard} from "@openzeppelin/security/ReentrancyGuard.sol";
import {DataTypes} from "../libraries/DataTypes.sol";
import {Constants} from "../libraries/Constants.sol";
import {HubIntentInbox} from "./HubIntentInbox.sol";
import {ITokenRegistry} from "../interfaces/ITokenRegistry.sol";
import {IHubRiskManager} from "../interfaces/IHubRiskManager.sol";
import {IHubMoneyMarket} from "../interfaces/IHubMoneyMarket.sol";

contract HubLockManager is Ownable, Pausable, ReentrancyGuard {
    uint8 public constant LOCK_STATUS_NONE = 0;
    uint8 public constant LOCK_STATUS_ACTIVE = 1;
    uint8 public constant LOCK_STATUS_CONSUMED = 2;
    uint8 public constant LOCK_STATUS_CANCELLED = 3;

    HubIntentInbox public immutable intentInbox;
    ITokenRegistry public immutable tokenRegistry;
    IHubRiskManager public immutable riskManager;
    IHubMoneyMarket public immutable moneyMarket;

    address public settlement;
    uint256 public lockTtl = 30 minutes;

    mapping(bytes32 => DataTypes.Lock) public locks;

    mapping(address => mapping(address => uint256)) public reservedDebt;
    mapping(address => mapping(address => uint256)) public reservedWithdraw;
    mapping(address => uint256) public reservedLiquidity;

    event SettlementSet(address indexed settlement);
    event LockTtlSet(uint256 lockTtl);

    event BorrowLocked(bytes32 indexed intentId, address indexed user, address indexed asset, uint256 amount, address relayer);
    event WithdrawLocked(bytes32 indexed intentId, address indexed user, address indexed asset, uint256 amount, address relayer);
    event LockCancelled(bytes32 indexed intentId, address indexed user, address indexed relayer);
    event LockConsumed(bytes32 indexed intentId, address indexed user, address indexed relayer);

    error InvalidIntentType(uint8 intentType);
    error LockAlreadyExists(bytes32 intentId);
    error InsufficientHubLiquidity(address asset, uint256 requested, uint256 availableAfterReservations);
    error RiskCheckFailed(bytes32 intentId);
    error LockNotFound(bytes32 intentId);
    error LockNotActive(bytes32 intentId);
    error LockNotExpired(bytes32 intentId, uint256 expiry);
    error LockExpired(bytes32 intentId, uint256 expiry);
    error UnauthorizedSettlement(address caller);
    error LockMismatch(bytes32 intentId);
    error UnsupportedAsset(address token);
    error InvalidSettlement(address settlement);

    modifier onlySettlement() {
        if (msg.sender != settlement) revert UnauthorizedSettlement(msg.sender);
        _;
    }

    constructor(
        address owner_,
        HubIntentInbox intentInbox_,
        ITokenRegistry tokenRegistry_,
        IHubRiskManager riskManager_,
        IHubMoneyMarket moneyMarket_
    ) Ownable(owner_) {
        intentInbox = intentInbox_;
        tokenRegistry = tokenRegistry_;
        riskManager = riskManager_;
        moneyMarket = moneyMarket_;
    }

    function setSettlement(address settlement_) external onlyOwner {
        if (settlement_ == address(0)) revert InvalidSettlement(settlement_);
        settlement = settlement_;
        emit SettlementSet(settlement_);
    }

    function setLockTtl(uint256 lockTtl_) external onlyOwner {
        lockTtl = lockTtl_;
        emit LockTtlSet(lockTtl_);
    }

    function pause() external onlyOwner {
        _pause();
    }

    function unpause() external onlyOwner {
        _unpause();
    }

    function lock(DataTypes.Intent calldata intent, bytes calldata signature)
        external
        nonReentrant
        whenNotPaused
        returns (bytes32 intentId)
    {
        if (intent.intentType != Constants.INTENT_BORROW && intent.intentType != Constants.INTENT_WITHDRAW) {
            revert InvalidIntentType(intent.intentType);
        }

        intentId = intentInbox.consumeIntent(intent, signature);
        if (locks[intentId].status != LOCK_STATUS_NONE) {
            revert LockAlreadyExists(intentId);
        }

        address asset = _resolveHubAsset(intent.outputToken);

        uint256 availableAfterReservations = moneyMarket.availableLiquidity(asset) - reservedLiquidity[asset];
        if (availableAfterReservations < intent.amount) {
            revert InsufficientHubLiquidity(asset, intent.amount, availableAfterReservations);
        }

        bool canLock;
        if (intent.intentType == Constants.INTENT_BORROW) {
            canLock = riskManager.canLockBorrow(intent.user, asset, intent.amount);
        } else {
            canLock = riskManager.canLockWithdraw(intent.user, asset, intent.amount);
        }
        if (!canLock) revert RiskCheckFailed(intentId);

        uint256 expiry = block.timestamp + lockTtl;
        if (expiry > intent.deadline) {
            expiry = intent.deadline;
        }

        DataTypes.Lock memory lockData = DataTypes.Lock({
            intentId: intentId,
            user: intent.user,
            intentType: intent.intentType,
            asset: asset,
            amount: intent.amount,
            relayer: msg.sender,
            lockTimestamp: block.timestamp,
            expiry: expiry,
            status: LOCK_STATUS_ACTIVE
        });

        locks[intentId] = lockData;

        reservedLiquidity[asset] += intent.amount;
        if (intent.intentType == Constants.INTENT_BORROW) {
            reservedDebt[intent.user][asset] += intent.amount;
            emit BorrowLocked(intentId, intent.user, asset, intent.amount, msg.sender);
        } else {
            reservedWithdraw[intent.user][asset] += intent.amount;
            emit WithdrawLocked(intentId, intent.user, asset, intent.amount, msg.sender);
        }
    }

    function cancelExpiredLock(bytes32 intentId) external nonReentrant {
        DataTypes.Lock storage lockData = locks[intentId];
        if (lockData.status == LOCK_STATUS_NONE) revert LockNotFound(intentId);
        if (lockData.status != LOCK_STATUS_ACTIVE) revert LockNotActive(intentId);
        if (block.timestamp < lockData.expiry) revert LockNotExpired(intentId, lockData.expiry);

        _releaseReservation(lockData);
        lockData.status = LOCK_STATUS_CANCELLED;

        emit LockCancelled(intentId, lockData.user, lockData.relayer);
    }

    function consumeLock(
        bytes32 intentId,
        uint8 expectedIntentType,
        address expectedUser,
        address expectedAsset,
        uint256 expectedAmount,
        address expectedRelayer
    ) external onlySettlement returns (DataTypes.Lock memory lockData) {
        lockData = locks[intentId];
        if (lockData.status == LOCK_STATUS_NONE) revert LockNotFound(intentId);
        if (lockData.status != LOCK_STATUS_ACTIVE) revert LockNotActive(intentId);
        if (block.timestamp > lockData.expiry) revert LockExpired(intentId, lockData.expiry);

        if (
            lockData.intentType != expectedIntentType || lockData.user != expectedUser
                || lockData.asset != expectedAsset || lockData.amount != expectedAmount
                || lockData.relayer != expectedRelayer
        ) {
            revert LockMismatch(intentId);
        }

        _releaseReservation(lockData);
        locks[intentId].status = LOCK_STATUS_CONSUMED;

        emit LockConsumed(intentId, lockData.user, lockData.relayer);
    }

    function _releaseReservation(DataTypes.Lock memory lockData) internal {
        reservedLiquidity[lockData.asset] -= lockData.amount;
        if (lockData.intentType == Constants.INTENT_BORROW) {
            reservedDebt[lockData.user][lockData.asset] -= lockData.amount;
        } else {
            reservedWithdraw[lockData.user][lockData.asset] -= lockData.amount;
        }
    }

    function _resolveHubAsset(address outputToken) internal view returns (address asset) {
        asset = tokenRegistry.getHubTokenBySpoke(outputToken);
        if (asset == address(0)) {
            ITokenRegistry.TokenConfig memory directCfg = tokenRegistry.getConfigByHub(outputToken);
            if (directCfg.hubToken == outputToken) {
                asset = outputToken;
            }
        }
        if (asset == address(0)) revert UnsupportedAsset(outputToken);

        ITokenRegistry.TokenConfig memory cfg = tokenRegistry.getConfigByHub(asset);
        if (cfg.hubToken != asset || !cfg.enabled) revert UnsupportedAsset(outputToken);
    }
}
