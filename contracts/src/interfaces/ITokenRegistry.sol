// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {DataTypes} from "../libraries/DataTypes.sol";

interface ITokenRegistry {
    struct TokenConfig {
        address hubToken;
        address spokeToken;
        uint8 decimals;
        DataTypes.RiskParams risk;
        bytes32 bridgeAdapterId;
        bool enabled;
    }

    function getConfigByHub(address hubToken) external view returns (TokenConfig memory);
    function getHubTokenBySpoke(address spokeToken) external view returns (address);
    function getSupportedAssets() external view returns (address[] memory);
}
