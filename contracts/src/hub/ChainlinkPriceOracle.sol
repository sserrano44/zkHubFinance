// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {IPriceOracle} from "../interfaces/IPriceOracle.sol";
import {IChainlinkAggregatorV3} from "../interfaces/IChainlinkAggregatorV3.sol";

contract ChainlinkPriceOracle is Ownable, IPriceOracle {
    struct FeedConfig {
        address feed;
        uint32 heartbeat;
        uint8 feedDecimals;
        uint256 minPriceE8;
        uint256 maxPriceE8;
        bool enabled;
    }

    mapping(address asset => FeedConfig) public feedConfigByAsset;

    event FeedConfigured(
        address indexed asset,
        address indexed feed,
        uint8 feedDecimals,
        uint32 heartbeat,
        uint256 minPriceE8,
        uint256 maxPriceE8
    );
    event FeedDisabled(address indexed asset);

    error FeedNotConfigured(address asset);
    error InvalidFeed(address feed);
    error InvalidHeartbeat(uint32 heartbeat);
    error InvalidFeedDecimals(uint8 feedDecimals);
    error InvalidPriceBounds(uint256 minPriceE8, uint256 maxPriceE8);
    error InvalidFeedRound(address asset, uint80 roundId, uint80 answeredInRound);
    error InvalidFeedAnswer(address asset, int256 answer);
    error InvalidFeedTimestamp(address asset, uint256 updatedAt);
    error StaleFeedPrice(address asset, uint256 updatedAt, uint32 heartbeat);
    error FeedPriceOutOfBounds(address asset, uint256 priceE8, uint256 minPriceE8, uint256 maxPriceE8);

    constructor(address owner_) Ownable(owner_) {}

    function setFeed(address asset, address feed, uint32 heartbeat, uint256 minPriceE8, uint256 maxPriceE8)
        external
        onlyOwner
    {
        if (feed == address(0)) revert InvalidFeed(feed);
        if (heartbeat == 0) revert InvalidHeartbeat(heartbeat);
        if (maxPriceE8 != 0 && maxPriceE8 < minPriceE8) revert InvalidPriceBounds(minPriceE8, maxPriceE8);

        uint8 feedDecimals = IChainlinkAggregatorV3(feed).decimals();
        if (feedDecimals > 18) revert InvalidFeedDecimals(feedDecimals);

        feedConfigByAsset[asset] = FeedConfig({
            feed: feed,
            heartbeat: heartbeat,
            feedDecimals: feedDecimals,
            minPriceE8: minPriceE8,
            maxPriceE8: maxPriceE8,
            enabled: true
        });

        emit FeedConfigured(asset, feed, feedDecimals, heartbeat, minPriceE8, maxPriceE8);
    }

    function disableFeed(address asset) external onlyOwner {
        delete feedConfigByAsset[asset];
        emit FeedDisabled(asset);
    }

    function getPrice(address asset) external view returns (uint256) {
        return _readPriceE8(asset);
    }

    function _readPriceE8(address asset) internal view returns (uint256 priceE8) {
        FeedConfig memory config = feedConfigByAsset[asset];
        if (!config.enabled) revert FeedNotConfigured(asset);

        (uint80 roundId, int256 answer,, uint256 updatedAt, uint80 answeredInRound) =
            IChainlinkAggregatorV3(config.feed).latestRoundData();

        if (answeredInRound < roundId) revert InvalidFeedRound(asset, roundId, answeredInRound);
        if (answer <= 0) revert InvalidFeedAnswer(asset, answer);
        if (updatedAt == 0 || updatedAt > block.timestamp) revert InvalidFeedTimestamp(asset, updatedAt);
        if (block.timestamp - updatedAt > config.heartbeat) {
            revert StaleFeedPrice(asset, updatedAt, config.heartbeat);
        }

        // casting to uint256 is safe because answer > 0 is checked above.
        // forge-lint: disable-next-line(unsafe-typecast)
        priceE8 = _normalizeToE8(uint256(answer), config.feedDecimals);

        if (config.minPriceE8 != 0 && priceE8 < config.minPriceE8) {
            revert FeedPriceOutOfBounds(asset, priceE8, config.minPriceE8, config.maxPriceE8);
        }
        if (config.maxPriceE8 != 0 && priceE8 > config.maxPriceE8) {
            revert FeedPriceOutOfBounds(asset, priceE8, config.minPriceE8, config.maxPriceE8);
        }
    }

    function _normalizeToE8(uint256 value, uint8 decimals) internal pure returns (uint256) {
        if (decimals == 8) return value;
        if (decimals > 8) return value / (10 ** (decimals - 8));
        return value * (10 ** (8 - decimals));
    }
}
