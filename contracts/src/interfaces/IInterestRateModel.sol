// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IInterestRateModel {
    function getBorrowRate(address asset, uint256 utilizationRay) external view returns (uint256);
    function getSupplyRate(address asset, uint256 utilizationRay) external view returns (uint256);
}
