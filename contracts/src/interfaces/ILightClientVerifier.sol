// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface ILightClientVerifier {
    function verifyFinalizedBlock(
        uint256 sourceChainId,
        uint256 sourceBlockNumber,
        bytes32 sourceBlockHash,
        bytes calldata proof
    ) external view returns (bool);
}
