// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";

contract MockOracle is Ownable, IPriceOracle {
    mapping(address => uint256) public pricesE8;

    event PriceUpdated(address indexed asset, uint256 priceE8);

    error PriceNotSet(address asset);

    constructor(address admin) Ownable(admin) {}

    function setPrice(address asset, uint256 priceE8) external onlyOwner {
        pricesE8[asset] = priceE8;
        emit PriceUpdated(asset, priceE8);
    }

    function getPrice(address asset) external view returns (uint256) {
        uint256 price = pricesE8[asset];
        if (price == 0) revert PriceNotSet(asset);
        return price;
    }
}
