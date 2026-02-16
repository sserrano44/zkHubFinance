// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {DataTypes} from "../libraries/DataTypes.sol";

library IntentHasher {
    bytes32 internal constant INTENT_TYPEHASH =
        keccak256(
            "Intent(uint8 intentType,address user,uint256 inputChainId,uint256 outputChainId,address inputToken,address outputToken,uint256 amount,address recipient,uint256 maxRelayerFee,uint256 nonce,uint256 deadline)"
        );

    function hashIntentStruct(DataTypes.Intent memory intent) internal pure returns (bytes32) {
        return
            keccak256(
                abi.encode(
                    INTENT_TYPEHASH,
                    intent.intentType,
                    intent.user,
                    intent.inputChainId,
                    intent.outputChainId,
                    intent.inputToken,
                    intent.outputToken,
                    intent.amount,
                    intent.recipient,
                    intent.maxRelayerFee,
                    intent.nonce,
                    intent.deadline
                )
            );
    }

    function rawIntentId(DataTypes.Intent memory intent) internal pure returns (bytes32) {
        return keccak256(abi.encode(intent));
    }
}
