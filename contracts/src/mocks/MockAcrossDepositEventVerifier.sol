// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IAcrossDepositEventVerifier} from "../interfaces/IAcrossDepositEventVerifier.sol";

/// @notice Local-only Across deposit event inclusion verifier mock.
/// @dev Validates that proof payload binds exact source event fields.
contract MockAcrossDepositEventVerifier is IAcrossDepositEventVerifier {
    struct InclusionProofData {
        uint256 sourceChainId;
        bytes32 sourceBlockHash;
        bytes32 receiptsRoot;
        bytes32 sourceTxHash;
        uint256 sourceLogIndex;
        address sourceSpokePool;
        address inputToken;
        address outputToken;
        uint256 outputAmount;
        uint256 destinationChainId;
        address recipient;
        bytes32 messageHash;
    }

    function verifyV3FundsDeposited(
        uint256 sourceChainId,
        bytes32 sourceBlockHash,
        bytes32 receiptsRoot,
        bytes32 sourceTxHash,
        uint256 sourceLogIndex,
        address sourceSpokePool,
        address expectedInputToken,
        bytes32 expectedMessageHash,
        address expectedRecipient,
        uint256 expectedDestinationChainId,
        address expectedOutputToken,
        uint256 expectedOutputAmount,
        bytes calldata proof
    ) external view override returns (bool) {
        if (sourceChainId == 0 || sourceBlockHash == bytes32(0) || sourceTxHash == bytes32(0) || sourceSpokePool == address(0))
        {
            return false;
        }

        try this.decodeInclusionProof(proof) returns (InclusionProofData memory decoded) {
            return (
                decoded.sourceChainId == sourceChainId && decoded.sourceBlockHash == sourceBlockHash
                    && decoded.receiptsRoot == receiptsRoot && decoded.sourceTxHash == sourceTxHash
                    && decoded.sourceLogIndex == sourceLogIndex && decoded.sourceSpokePool == sourceSpokePool
                    && decoded.inputToken == expectedInputToken && decoded.outputToken == expectedOutputToken
                    && decoded.outputAmount == expectedOutputAmount
                    && decoded.destinationChainId == expectedDestinationChainId && decoded.recipient == expectedRecipient
                    && decoded.messageHash == expectedMessageHash
            );
        } catch {
            return false;
        }
    }

    function decodeInclusionProof(bytes calldata proof) external pure returns (InclusionProofData memory decoded) {
        decoded = abi.decode(proof, (InclusionProofData));
    }
}
