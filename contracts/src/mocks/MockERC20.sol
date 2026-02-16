// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import {ERC20} from "@openzeppelin/token/ERC20/ERC20.sol";
import {Ownable} from "@openzeppelin/access/Ownable.sol";

contract MockERC20 is ERC20, Ownable {
    uint8 private immutable _decimals;

    mapping(address => bool) public minters;

    error NotMinter(address caller);

    event MinterSet(address indexed minter, bool allowed);

    constructor(string memory name_, string memory symbol_, uint8 decimals_) ERC20(name_, symbol_) Ownable(msg.sender) {
        _decimals = decimals_;
        minters[msg.sender] = true;
    }

    function decimals() public view override returns (uint8) {
        return _decimals;
    }

    function setMinter(address minter, bool allowed) external onlyOwner {
        minters[minter] = allowed;
        emit MinterSet(minter, allowed);
    }

    function mint(address to, uint256 amount) external {
        if (!minters[msg.sender]) revert NotMinter(msg.sender);
        _mint(to, amount);
    }

    function burn(address from, uint256 amount) external {
        if (!minters[msg.sender]) revert NotMinter(msg.sender);
        _burn(from, amount);
    }
}
