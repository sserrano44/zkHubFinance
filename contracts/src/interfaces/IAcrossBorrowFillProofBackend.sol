// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IBorrowFillProofVerifier} from "./IBorrowFillProofVerifier.sol";

interface IAcrossBorrowFillProofBackend {
    struct CanonicalSourceProof {
        uint256 sourceBlockNumber;
        bytes32 sourceBlockHash;
        bytes32 receiptsRoot;
        address sourceReceiver;
        bytes finalityProof;
        bytes inclusionProof;
    }

    function verifyCanonicalBorrowFill(
        IBorrowFillProofVerifier.BorrowFillWitness calldata witness,
        CanonicalSourceProof calldata proof,
        address destinationFinalizer,
        uint256 destinationChainId
    ) external view returns (bool);
}
