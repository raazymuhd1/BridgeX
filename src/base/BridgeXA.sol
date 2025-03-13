// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

abstract contract BridgeXA {

    error BridgeXA__NotAnAdmin(address admin);
    error BridgeXA__AmountExceededOrNotEnough(uint256 amount, uint256 userBalance);
    error BridgeXA__TransferFailed();

    IERC20 private s_token;
    address private s_admin;
    mapping(address user_ => uint256 balance_) private s_lockedTokens;
    mapping(bytes32 => bool) private s_processedTx;

    constructor(address initAdmin_) {
        s_admin = initAdmin_;
    }

    // -------------------------------------------- EVENTS -------------------------------------------

    event DepositLocked(uint256 indexed amount, address indexed user_, bytes32 indexed txHash);
    event DepositReleased(uint256 indexed amount, address indexed user_, bytes32 indexed txHash);


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

    function lockDeposit(uint256 tokenAmount, address token) internal EnoughAmount(msg.sender, token, tokenAmount) returns(uint256 amount, bytes32 hashTx) {
        bool success = IERC20(token).transferFrom(msg.sender, address(this), amount);
        if(!success) revert BridgeXA__TransferFailed();

        bytes32 txHash = keccak256(abi.encodePacked(msg.sender, amount, block.timestamp));
        amount = tokenAmount;
        hashTx = txHash;
        emit DepositLocked(tokenAmount, msg.sender, txHash);
    }

    /**
     * @dev this function will exxecuted by an off-chain node, not by user
     * @param token_ - token to release
     * @param to_ - the recipient address
     * @param amount_ - amount to release
     * @param txHash_ - tx hash to release
     */
    function releaseDeposit(address token_, address to_, uint256 amount_, bytes32 txHash_) internal OnlyAdmin returns(uint256, bytes32)  {
        if(s_lockedTokens[to_] < amount_) revert("Insufficient deposit history");
        if(s_processedTx[txHash_] == true) revert("tx has been processed");
        bool successTf = IERC20(token_).transfer(to_, amount_);
        if(!successTf) revert BridgeXA__TransferFailed();

        s_processedTx[txHash_] = true;
        s_lockedTokens[to_] -= amount_;
        emit DepositReleased(amount_, to_, txHash_);
        return (amount_, txHash_);
    }
}