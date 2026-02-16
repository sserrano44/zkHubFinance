// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IHubMoneyMarket {
    function getUserSupply(address user, address asset) external view returns (uint256);
    function getUserDebt(address user, address asset) external view returns (uint256);
    function totalSupplyAssets(address asset) external view returns (uint256);
    function totalDebtAssets(address asset) external view returns (uint256);
    function availableLiquidity(address asset) external view returns (uint256);
}
