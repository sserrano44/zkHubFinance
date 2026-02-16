// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

library DataTypes {
    struct Intent {
        uint8 intentType;
        address user;
        uint256 inputChainId;
        uint256 outputChainId;
        address inputToken;
        address outputToken;
        uint256 amount;
        address recipient;
        uint256 maxRelayerFee;
        uint256 nonce;
        uint256 deadline;
    }

    struct RiskParams {
        uint256 ltvBps;
        uint256 liquidationThresholdBps;
        uint256 liquidationBonusBps;
        uint256 supplyCap;
        uint256 borrowCap;
    }

    struct Lock {
        bytes32 intentId;
        address user;
        uint8 intentType;
        address asset;
        uint256 amount;
        address relayer;
        uint256 lockTimestamp;
        uint256 expiry;
        uint8 status;
    }

    struct SupplyCredit {
        uint256 depositId;
        address user;
        address hubAsset;
        uint256 amount;
    }

    struct RepayCredit {
        uint256 depositId;
        address user;
        address hubAsset;
        uint256 amount;
    }

    struct BorrowFinalize {
        bytes32 intentId;
        address user;
        address hubAsset;
        uint256 amount;
        uint256 fee;
        address relayer;
    }

    struct WithdrawFinalize {
        bytes32 intentId;
        address user;
        address hubAsset;
        uint256 amount;
        uint256 fee;
        address relayer;
    }

    struct SettlementBatch {
        uint256 batchId;
        uint256 hubChainId;
        uint256 spokeChainId;
        bytes32 actionsRoot;
        SupplyCredit[] supplyCredits;
        RepayCredit[] repayCredits;
        BorrowFinalize[] borrowFinalizations;
        WithdrawFinalize[] withdrawFinalizations;
    }
}
