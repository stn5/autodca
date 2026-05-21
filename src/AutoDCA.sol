// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AutoDCA {
    using SafeERC20 for IERC20;

    error AutoDCA__AmountBelowMinimum();

    address public immutable I_USDC;
    uint256 public constant MINIMUM_DEPOSIT = 50e6;
    mapping(address => uint256) public userBalances;

    event Deposited(address indexed user, uint256 amount);

    constructor(address usdc) {
        I_USDC = usdc;
    }

    function deposit(uint256 amount) external {
        if (amount < MINIMUM_DEPOSIT) revert AutoDCA__AmountBelowMinimum();
        IERC20(I_USDC).safeTransferFrom(msg.sender, address(this), amount);
        userBalances[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }
}
