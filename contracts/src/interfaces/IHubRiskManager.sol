// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IHubRiskManager {
    function canUserSupply(address asset, uint256 amount) external view returns (bool);
    function canLockBorrow(address user, address asset, uint256 amount) external view returns (bool);
    function canLockWithdraw(address user, address asset, uint256 amount) external view returns (bool);
    function canUserBorrow(address user, address asset, uint256 amount) external view returns (bool);
    function canUserWithdraw(address user, address asset, uint256 amount) external view returns (bool);
    function isLiquidatable(address user) external view returns (bool);
    function getAssetPriceE8(address asset) external view returns (uint256);
    function getLiquidationBonusBps(address asset) external view returns (uint256);
}
