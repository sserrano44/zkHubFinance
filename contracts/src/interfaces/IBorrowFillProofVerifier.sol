// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBorrowFillProofVerifier {
    struct BorrowFillWitness {
        uint256 sourceChainId;
        bytes32 intentId;
        uint8 intentType;
        address user;
        address recipient;
        address spokeToken;
        address hubAsset;
        uint256 amount;
        uint256 fee;
        address relayer;
        bytes32 sourceTxHash;
        uint256 sourceLogIndex;
        bytes32 messageHash;
    }

    function verifyBorrowFillProof(bytes calldata proof, BorrowFillWitness calldata witness)
        external
        view
        returns (bool);
}
