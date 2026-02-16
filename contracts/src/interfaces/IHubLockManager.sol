// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IHubLockManager {
    function reservedDebt(address user, address asset) external view returns (uint256);
    function reservedWithdraw(address user, address asset) external view returns (uint256);
}
