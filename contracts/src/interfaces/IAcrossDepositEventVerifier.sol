// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IAcrossDepositEventVerifier {
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
    ) external view returns (bool);
}
