// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract BridgeXA {

    error BridgeXA__NotAnAdmin(address admin);
    error BridgeXA__AmountExceededOrNotEnough(uint256 amount, uint256 userBalance);

    IERC20 private s_token;
    address private s_admin;
    mapping(bytes32 => bool) private processedTx;

    constructor(address initAdmin_) {
        s_admin = initAdmin_;
    }

    // -------------------------------------------- EVENTS -------------------------------------------

    event DepositLocked(uint256 indexed amount, address indexed user_, bytes32 indexed txHash);
    event DepositRelased(uint256 indexed amount, address indexed user_, bytes32 indexed txHash);


    // -------------------------------------------- MODIFIERS -------------------------------------------

    modifier OnlyAdmin {
        address admin_ = s_admin;
        if(msg.sender != admin_) revert BridgeXA__NotAnAdmin(msg.sender);
        _;
    }

    modifier EnoughAmount(address user_, address token, uint256 amount_) {
        s_token = IERC20(token);
        uint userBalance = s_token.balanceOf(user_);
        if(amount_ >= userBalance || amount_ <= 0) revert BridgeXA__AmountExceededOrNotEnough(amount_, userBalance);
        _;
    }

    function lockDeposit(uint256 tokenAmount, address token) internal EnoughAmount returns(uint256 amount, bytes32 hashTx) {
        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        if(!success) revert("Transfer Failed");

        bytes32 txHash = keccak256(abi.encodePacked(msg.sender, amount, block.timestamp));
        amount = tokenAmount;
        hashTx = txHash;
        emit DepositLocked(tokenAmount, msg.sender, txHash);
    }

    function releaseDeposit(address to_, uint256 amount_, bytes32 txHash) internal returns(uint256 amount, bytes txHash)  {

    }
}