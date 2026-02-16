// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IHubSettlement {
    function isIntentSettled(bytes32 intentId) external view returns (bool);
}
