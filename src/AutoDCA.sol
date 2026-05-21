// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

contract AutoDCA {
    using SafeERC20 for IERC20;

    /* Errors */
    error AutoDCA__InvalidTokenAddress();
    error AutoDCA__AmountBelowMinimum();
    error AutoDCA__AmountMustBeGreaterThanZero();
    error AutoDCA__InsufficientBalance();

    address public immutable I_USDC;
    uint256 public constant MINIMUM_DEPOSIT = 50e6;
    mapping(address => uint256) public userBalances;

    /* Events */
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);

    constructor(address usdc) {
        I_USDC = usdc;
    }

    function deposit(uint256 amount) external {
        if (amount < MINIMUM_DEPOSIT) revert AutoDCA__AmountBelowMinimum();
        IERC20(I_USDC).safeTransferFrom(msg.sender, address(this), amount);
        userBalances[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external {
        if (amount == 0) revert AutoDCA__AmountMustBeGreaterThanZero();
        if (userBalances[msg.sender] < amount) revert AutoDCA__InsufficientBalance();
        userBalances[msg.sender] -= amount;
        IERC20(I_USDC).safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }
}
