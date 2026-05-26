// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract MockSwapRouter {
    uint256 public amountOut = 5e18;

    address public tokenIn;
    address public tokenOut;
    address public recipient;
    uint256 public amountIn;

    function exactInputSingle(ISwapRouter.ExactInputSingleParams calldata params) external payable returns (uint256) {
        tokenIn = params.tokenIn;
        tokenOut = params.tokenOut;
        recipient = params.recipient;
        amountIn = params.amountIn;

        return amountOut;
    }
}
