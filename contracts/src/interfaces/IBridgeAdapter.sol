// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

interface IBridgeAdapter {
    function bridgeToHub(address token, uint256 amount, address hubRecipient, bytes calldata extraData) external;
}
