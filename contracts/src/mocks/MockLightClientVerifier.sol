// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ILightClientVerifier} from "../interfaces/ILightClientVerifier.sol";

/// @notice Local-only light client verifier mock.
/// @dev Validates that proof payload binds exact chain/block tuple.
contract MockLightClientVerifier is ILightClientVerifier {
    struct FinalityProofData {
        uint256 sourceChainId;
        uint256 sourceBlockNumber;
        bytes32 sourceBlockHash;
    }

    function verifyFinalizedBlock(
        uint256 sourceChainId,
        uint256 sourceBlockNumber,
        bytes32 sourceBlockHash,
        bytes calldata proof
    ) external view override returns (bool) {
        if (sourceChainId == 0 || sourceBlockNumber == 0 || sourceBlockHash == bytes32(0)) return false;

        try this.decodeFinalityProof(proof) returns (FinalityProofData memory decoded) {
            return (
                decoded.sourceChainId == sourceChainId && decoded.sourceBlockNumber == sourceBlockNumber
                    && decoded.sourceBlockHash == sourceBlockHash
            );
        } catch {
            return false;
        }
    }

    function decodeFinalityProof(bytes calldata proof) external pure returns (FinalityProofData memory decoded) {
        decoded = abi.decode(proof, (FinalityProofData));
    }
}
