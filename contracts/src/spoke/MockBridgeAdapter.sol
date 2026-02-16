// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {Ownable} from "@openzeppelin/access/Ownable.sol";
import {IERC20} from "@openzeppelin/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/token/ERC20/utils/SafeERC20.sol";
import {IBridgeAdapter} from "../interfaces/IBridgeAdapter.sol";

contract MockBridgeAdapter is Ownable, IBridgeAdapter {
    using SafeERC20 for IERC20;

    event BridgeTeleportInitiated(
        address indexed token,
        uint256 amount,
        address indexed hubRecipient,
        bytes extraData,
        address indexed caller
    );

    constructor(address owner_) Ownable(owner_) {}

    function bridgeToHub(address token, uint256 amount, address hubRecipient, bytes calldata extraData) external {
        IERC20(token).safeTransferFrom(msg.sender, address(this), amount);
        emit BridgeTeleportInitiated(token, amount, hubRecipient, extraData, msg.sender);
    }

    function releaseEscrow(address token, address to, uint256 amount) external onlyOwner {
        IERC20(token).safeTransfer(to, amount);
    }
}
