// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

contract AutoDCA is AutomationCompatibleInterface {
    using SafeERC20 for IERC20;

    /* Errors */
    error AutoDCA__InvalidTokenAddress();
    error AutoDCA__AmountBelowMinimum();
    error AutoDCA__AmountMustBeGreaterThanZero();
    error AutoDCA__InsufficientBalance();
    error AutoDCA__InvalidInterval();
    error AutoDCA__NotOrderOwner();
    error AutoDCA__OrderAlreadyInactive();
    error AutoDCA__OrderAlreadyExist();

    struct Order {
        address user;
        address tokenToBuy;
        uint256 usdcAmountPerSwap;
        uint256 interval;
        uint256 lastExecuted;
        bool isActive;
    }

    address public immutable I_USDC;
    ISwapRouter public immutable I_SWAP_ROUTER;
    uint24 public constant POOL_FEE = 3000;
    uint256 public constant MINIMUM_DEPOSIT = 50e6;
    uint256 public constant MINIMUM_INTERVAL = 1 days;
    uint256 public nextOrderId = 1;
    mapping(address => uint256) public userBalances;
    mapping(uint256 => Order) public orders;
    mapping(address user => mapping(address tokenAddress => uint256 orderId)) public activeUserOrderIds;

    /* Events */
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event OrderCreated(
        uint256 indexed orderId,
        address indexed user,
        address indexed tokenToBuy,
        uint256 usdcAmountPerSwap,
        uint256 interval
    );
    event OrderExecuted(
        uint256 indexed orderId, 
        address indexed user, 
        address indexed tokenToBuy, 
        uint256 usdcAmountSpent,
        uint256 executedAt
    );
    event OrderUpdated(uint256 indexed orderId, uint256 usdcAmountPerSwap, uint256 interval);
    event OrderCancelled(uint256 indexed orderId);

    constructor(address usdc, address swapRouter) {
        if (usdc == address(0) || swapRouter == address(0)) revert AutoDCA__InvalidTokenAddress();
        I_USDC = usdc;
        I_SWAP_ROUTER = ISwapRouter(swapRouter);
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

    function createOrder(address tokenToBuy, uint256 usdcAmountPerSwap, uint256 interval) external returns (uint256) {
        if (tokenToBuy == address(0)) revert AutoDCA__InvalidTokenAddress();
        if (activeUserOrderIds[msg.sender][tokenToBuy] != 0) revert AutoDCA__OrderAlreadyExist();
        if (usdcAmountPerSwap < MINIMUM_DEPOSIT) revert AutoDCA__AmountBelowMinimum();
        if (interval < MINIMUM_INTERVAL) revert AutoDCA__InvalidInterval();

        uint256 orderId = nextOrderId;
        orders[orderId] = Order({
            user: msg.sender,
            tokenToBuy: tokenToBuy,
            usdcAmountPerSwap: usdcAmountPerSwap,
            interval: interval,
            lastExecuted: block.timestamp,
            isActive: true
        });

        activeUserOrderIds[msg.sender][tokenToBuy] = orderId;
        nextOrderId++;

        emit OrderCreated(orderId, msg.sender, tokenToBuy, usdcAmountPerSwap, interval);
        return orderId;
    }

    function updateOrder(uint256 orderId, uint256 usdcAmountPerSwap, uint256 interval) external {
        Order storage order = orders[orderId];
        if (order.user != msg.sender) revert AutoDCA__NotOrderOwner();
        if (!order.isActive) revert AutoDCA__OrderAlreadyInactive();
        if (usdcAmountPerSwap < MINIMUM_DEPOSIT) revert AutoDCA__AmountBelowMinimum();
        if (interval < MINIMUM_INTERVAL) revert AutoDCA__InvalidInterval();

        order.usdcAmountPerSwap = usdcAmountPerSwap;
        order.interval = interval;

        emit OrderUpdated(orderId, usdcAmountPerSwap, interval);
    }

    function cancelOrder(uint256 orderId) external {
        Order storage order = orders[orderId];
        if (order.user != msg.sender) revert AutoDCA__NotOrderOwner();
        if (!order.isActive) revert AutoDCA__OrderAlreadyInactive();

        order.isActive = false;
        activeUserOrderIds[msg.sender][order.tokenToBuy] = 0;

        emit OrderCancelled(orderId);
    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        for (uint256 orderId = 1; orderId < nextOrderId; orderId++) {
            Order memory order = orders[orderId];
            bool hasEnoughBalance = userBalances[order.user] >= order.usdcAmountPerSwap;
            bool timePassed = block.timestamp >= order.lastExecuted + order.interval;

            if (order.isActive && hasEnoughBalance && timePassed) {
                return (true, abi.encode(orderId));
            }
        }

        return (false, "");
    }

    function performUpkeep(bytes calldata performData) external override {
        uint256 orderId = abi.decode(performData, (uint256));
        Order storage order = orders[orderId];
        bool hasEnoughBalance = userBalances[order.user] >= order.usdcAmountPerSwap;
        bool timePassed = block.timestamp >= order.lastExecuted + order.interval;

        if (!order.isActive) revert AutoDCA__OrderAlreadyInactive();
        if (!hasEnoughBalance) revert AutoDCA__InsufficientBalance();
        if (!timePassed) revert AutoDCA__InvalidInterval();

        userBalances[order.user] -= order.usdcAmountPerSwap;
        order.lastExecuted = block.timestamp;

        // Uniswap v3 swap 

        emit OrderExecuted(orderId, order.user, order.tokenToBuy, order.usdcAmountPerSwap, block.timestamp);
    }
}
