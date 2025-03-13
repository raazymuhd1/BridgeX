// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import { IERC20 } from "../interfaces/IERC20.sol";

abstract contract BridgeXB {

    error BridgeXB__NotAnAdmin(address admin);
    error BridgeXB__AmountExceededOrNotEnough(uint256 amount, uint256 userBalance);
    error BridgeXB__TransferFailed();

    IERC20 private s_token;
    address private s_admin;
    mapping(address user_ => uint256 balance_) private s_mintedTokens;
    mapping(bytes32 => bool) private s_processedTx;

    constructor(address initAdmin_) {
        s_admin = initAdmin_;
    }

    // -------------------------------------------- EVENTS -------------------------------------------

    event TokenMinted(uint256 indexed amount, address indexed user_, bytes32 indexed txHash);
    event TokenBurned(uint256 indexed amount, address indexed user_, bytes32 indexed txHash);


    // -------------------------------------------- MODIFIERS -------------------------------------------

    modifier OnlyValidToken(address token) {
        if(token == address(0)) revert("Invalid token");
        _;
    }

    modifier OnlyAdmin {
        address admin_ = s_admin;
        if(msg.sender != admin_) revert BridgeXB__NotAnAdmin(msg.sender);
        _;
    }

    modifier InvalidRecipient(address recipient) {
        if(recipient == address(0)) revert("Invalid recipient");
        _;
    }

    modifier EnoughAmount(address user_, address token, uint256 amount_) {
        s_token = IERC20(token);
        uint userBalance = s_token.balanceOf(user_);
        if(amount_ >= userBalance || amount_ <= 0) revert BridgeXB__AmountExceededOrNotEnough(amount_, userBalance);
        _;
    }

    function mintToken(uint256 tokenAmount, address token, address to, bytes32 txHash) internal InvalidRecipient(to) OnlyAdmin OnlyValidToken(token) returns(uint256, bytes32) {
        if(s_processedTx[txHash] == true) revert("tx has been processed");
        if(tokenAmount <= 0) revert("token amount must be greater than zero");

        s_processedTx[txHash] = true;
        s_mintedTokens[to] += tokenAmount;

        bool minted = IERC20(token).mintToken(to, tokenAmount);
        if(!minted) revert("Mint Failed");
        emit TokenMinted(tokenAmount, msg.sender, txHash);
    }

    /**
     * @dev this function will exxecuted by an off-chain node, not by user
     * @param token_ - token to release
     * @param to_ - the recipient address
     * @param amount_ - amount to release
     * @param txHash_ - tx hash to release
     */
    function burnToken(address token_, address to_, uint256 amount_, bytes32 txHash_) internal returns(uint256, bytes32)  {
       
    }
}