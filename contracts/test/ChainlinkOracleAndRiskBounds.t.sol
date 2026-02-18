// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {TestBase} from "./utils/TestBase.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {MockChainlinkAggregatorV3} from "../src/mocks/MockChainlinkAggregatorV3.sol";
import {TokenRegistry} from "../src/hub/TokenRegistry.sol";
import {KinkInterestRateModel} from "../src/hub/KinkInterestRateModel.sol";
import {HubMoneyMarket} from "../src/hub/HubMoneyMarket.sol";
import {HubRiskManager} from "../src/hub/HubRiskManager.sol";
import {ChainlinkPriceOracle} from "../src/hub/ChainlinkPriceOracle.sol";
import {IPriceOracle} from "../src/interfaces/IPriceOracle.sol";

contract ChainlinkOracleAndRiskBoundsTest is TestBase {
    MockERC20 internal asset;
    MockChainlinkAggregatorV3 internal feed8;
    ChainlinkPriceOracle internal chainlinkOracle;
    HubRiskManager internal riskManager;

    function setUp() external {
        vm.warp(1_000_000);

        asset = new MockERC20("Asset", "AST", 18);
        feed8 = new MockChainlinkAggregatorV3(8);
        feed8.setRoundData(1, 2_000e8, block.timestamp, block.timestamp, 1);

        chainlinkOracle = new ChainlinkPriceOracle(address(this));
        chainlinkOracle.setFeed(address(asset), address(feed8), 1 hours, 0, 0);

        TokenRegistry registry = new TokenRegistry(address(this));
        KinkInterestRateModel rateModel = new KinkInterestRateModel(
            address(this),
            3_170_979_198_000_000_000,
            6_341_958_396_000_000_000,
            19_025_875_190_000_000_000,
            800_000_000_000_000_000_000_000_000,
            100_000_000_000_000_000_000_000_000
        );
        HubMoneyMarket moneyMarket = new HubMoneyMarket(address(this), registry, rateModel);
        riskManager = new HubRiskManager(address(this), registry, moneyMarket, IPriceOracle(address(chainlinkOracle)));
    }

    function testChainlinkOracle_readsConfiguredFeed() external view {
        assertEq(chainlinkOracle.getPrice(address(asset)), 2_000e8, "chainlink oracle should return feed price");
    }

    function testChainlinkOracle_rejectsStalePrice() external {
        uint256 staleTimestamp = block.timestamp - 2 hours;
        feed8.setRoundData(2, 2_000e8, staleTimestamp, staleTimestamp, 2);

        vm.expectRevert(
            abi.encodeWithSelector(
                ChainlinkPriceOracle.StaleFeedPrice.selector, address(asset), staleTimestamp, uint32(1 hours)
            )
        );
        chainlinkOracle.getPrice(address(asset));
    }

    function testChainlinkOracle_rejectsNonPositivePrice() external {
        feed8.setRoundData(2, 0, block.timestamp, block.timestamp, 2);

        vm.expectRevert(abi.encodeWithSelector(ChainlinkPriceOracle.InvalidFeedAnswer.selector, address(asset), int256(0)));
        chainlinkOracle.getPrice(address(asset));
    }

    function testChainlinkOracle_normalizesDecimalsToE8() external {
        MockERC20 asset18 = new MockERC20("Asset18", "A18", 18);
        MockChainlinkAggregatorV3 feed18 = new MockChainlinkAggregatorV3(18);
        feed18.setRoundData(1, 2_000e18, block.timestamp, block.timestamp, 1);

        chainlinkOracle.setFeed(address(asset18), address(feed18), 1 hours, 0, 0);
        assertEq(chainlinkOracle.getPrice(address(asset18)), 2_000e8, "18-decimal feed should normalize to e8");
    }

    function testRiskManager_enforcesOracleBounds() external {
        riskManager.setOracleBounds(2_100e8, 2_500e8);

        vm.expectRevert(abi.encodeWithSelector(HubRiskManager.InvalidOraclePrice.selector, address(asset), 2_000e8));
        riskManager.getAssetPriceE8(address(asset));
    }

    function testRiskManager_rejectsInvalidOracleBounds() external {
        vm.expectRevert(abi.encodeWithSelector(HubRiskManager.InvalidOracleBounds.selector, 0, 1e8));
        riskManager.setOracleBounds(0, 1e8);
    }
}
