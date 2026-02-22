// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {IDepositProofVerifier} from "./IDepositProofVerifier.sol";

interface IAcrossDepositProofBackend {
    struct CanonicalSourceProof {
        uint256 sourceBlockNumber;
        bytes32 sourceBlockHash;
        bytes32 receiptsRoot;
        address sourceSpokePool;
        bytes finalityProof;
        bytes inclusionProof;
    }

    function verifyCanonicalDeposit(
        IDepositProofVerifier.DepositWitness calldata witness,
        CanonicalSourceProof calldata proof,
        address destinationReceiver,
        uint256 destinationChainId
    ) external view returns (bool);
}
