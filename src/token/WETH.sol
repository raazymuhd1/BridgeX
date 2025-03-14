// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract WETH is ERC20 {


    constructor() ERC20("Wrapped ETH", "WETH") {

    }

    function mintToken(address to, uint256 amount) external returns(bool) {
        _mint(to, amount);
        return true;
    }

    function burnToken(address to, uint256 amount) external {}
}