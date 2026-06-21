// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Ownable} from "@openzeppelin/contracts/access/Ownable.sol";
import {AggregatorV3Interface} from "@chainlink/contracts/src/v0.8/shared/interfaces/AggregatorV3Interface.sol";
import {AutomationCompatibleInterface} from "@chainlink/contracts/src/v0.8/automation/interfaces/AutomationCompatibleInterface.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {ReentrancyGuard} from "@openzeppelin/contracts/utils/ReentrancyGuard.sol";

contract AutoDCA is AutomationCompatibleInterface, Ownable, ReentrancyGuard {
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
    error AutoDCA__OrderNotReady();
    error AutoDCA__TokenNotAllowed();
    error AutoDCA__InvalidPriceFeed();
    error AutoDCA__StalePrice();
    error AutoDCA__InvalidHeartbeat();

    struct Order {
        address user;
        address tokenToBuy;
        uint256 usdcAmountPerSwap;
        uint256 interval;
        uint256 lastExecuted;
        bool isActive;
    }

    struct TokenConfig {
        bool isAllowed;
        address priceFeedAddress;
        uint8 tokenDecimals;
        uint256 priceFeedHeartbeat;
    }

    address public immutable I_USDC;
    ISwapRouter public immutable I_SWAP_ROUTER;
    uint24 public constant POOL_FEE = 3000;
    uint256 public constant MINIMUM_DEPOSIT = 10e6;
    uint256 public constant MINIMUM_INTERVAL = 1 days;
    uint256 public constant SWAP_DEADLINE = 5 minutes;
    uint256 public constant SLIPPAGE_BPS = 100; // 1%
    uint256 public constant BPS_PRECISION = 10_000;
    uint256 public constant USDC_PRECISION = 1e6;
    uint256 public nextOrderId = 1;
    uint256[] public activeOrderIds;
    address[] public allowedTokenList;
    mapping(address => uint256) public userBalances;
    mapping(uint256 => Order) public orders;
    mapping(uint256 orderId => uint256 index) private activeOrderIndex;
    mapping(address user => mapping(address tokenAddress => uint256 orderId)) public activeUserOrderIds;
    mapping(address token => TokenConfig config) public allowedTokens;    

    /* Events */
    event Deposited(address indexed user, uint256 amount);
    event Withdrawn(address indexed user, uint256 amount);
    event OrderCreated(
        uint256 indexed orderId,
        address indexed user,
        address indexed tokenToBuy,
        uint256 usdcAmountPerSwap,
        uint256 interval,
        uint256 createdAt
    );
    event OrderExecuted(
        uint256 indexed orderId,
        address indexed user,
        address indexed tokenToBuy,
        uint256 usdcAmountSpent,
        uint256 tokenAmountReceived,
        uint256 executedAt
    );
    event OrderUpdated(uint256 indexed orderId, uint256 usdcAmountPerSwap, uint256 interval);
    event OrderCancelled(uint256 indexed orderId);
    event TokenConfigured(address indexed token, address priceFeed, uint8 decimals, uint256 heartbeat, bool isAllowed);

    constructor(address usdc, address swapRouter) Ownable(msg.sender) {
        if (usdc == address(0) || swapRouter == address(0)) revert AutoDCA__InvalidTokenAddress();
        I_USDC = usdc;
        I_SWAP_ROUTER = ISwapRouter(swapRouter);
    }

    function deposit(uint256 amount) external nonReentrant {
        if (amount < MINIMUM_DEPOSIT) revert AutoDCA__AmountBelowMinimum();
        IERC20(I_USDC).safeTransferFrom(msg.sender, address(this), amount);
        userBalances[msg.sender] += amount;
        emit Deposited(msg.sender, amount);
    }

    function withdraw(uint256 amount) external nonReentrant {
        if (amount == 0) revert AutoDCA__AmountMustBeGreaterThanZero();
        if (userBalances[msg.sender] < amount) revert AutoDCA__InsufficientBalance();
        userBalances[msg.sender] -= amount;
        IERC20(I_USDC).safeTransfer(msg.sender, amount);
        emit Withdrawn(msg.sender, amount);
    }

    function createOrder(address tokenToBuy, uint256 usdcAmountPerSwap, uint256 interval) external returns (uint256) {
        if (tokenToBuy == address(0)) revert AutoDCA__InvalidTokenAddress();
        if (!allowedTokens[tokenToBuy].isAllowed) revert AutoDCA__TokenNotAllowed();
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
        _addToActiveSet(orderId);
        nextOrderId++;

        emit OrderCreated(orderId, msg.sender, tokenToBuy, usdcAmountPerSwap, interval, block.timestamp);
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
        _removeFromActiveSet(orderId);

        emit OrderCancelled(orderId);
    }

    function checkUpkeep(bytes calldata) external view override returns (bool upkeepNeeded, bytes memory performData) {
        for (uint256 i = 0; i < activeOrderIds.length; i++) {
            uint256 orderId = activeOrderIds[i];
            Order memory order = orders[orderId];
            bool hasEnoughBalance = userBalances[order.user] >= order.usdcAmountPerSwap;
            bool timePassed = block.timestamp >= order.lastExecuted + order.interval;

            if (order.isActive && hasEnoughBalance && timePassed) {
                return (true, abi.encode(orderId));
            }
        }

        return (false, "");
    }

    function performUpkeep(bytes calldata performData) external override nonReentrant {
        uint256 orderId = abi.decode(performData, (uint256));
        Order storage order = orders[orderId];
        bool hasEnoughBalance = userBalances[order.user] >= order.usdcAmountPerSwap;
        bool timePassed = block.timestamp >= order.lastExecuted + order.interval;

        if (!order.isActive) revert AutoDCA__OrderAlreadyInactive();
        if (!hasEnoughBalance) revert AutoDCA__InsufficientBalance();
        if (!timePassed) revert AutoDCA__OrderNotReady();

        uint256 amountIn = order.usdcAmountPerSwap;

        userBalances[order.user] -= amountIn;
        order.lastExecuted = block.timestamp;

        IERC20(I_USDC).forceApprove(address(I_SWAP_ROUTER), amountIn);

        uint256 amountOut = I_SWAP_ROUTER.exactInputSingle(
            ISwapRouter.ExactInputSingleParams({
                tokenIn: I_USDC,
                tokenOut: order.tokenToBuy,
                fee: POOL_FEE,
                recipient: order.user,
                deadline: block.timestamp + SWAP_DEADLINE,
                amountIn: amountIn,
                amountOutMinimum: _getMinAmountOut(order.tokenToBuy, amountIn),
                sqrtPriceLimitX96: 0
            })
        );

        IERC20(I_USDC).forceApprove(address(I_SWAP_ROUTER), 0);
        emit OrderExecuted(orderId, order.user, order.tokenToBuy, amountIn, amountOut, block.timestamp);
    }

    /* Token whitelist managed by ownr */

    function setAllowedToken(address token, address priceFeedAddress, uint8 tokenDecimals, uint256 heartbeat, bool isAllowed) external onlyOwner {
        if (token == address(0)) revert AutoDCA__InvalidTokenAddress();
        TokenConfig storage tokenConfig = allowedTokens[token];

        if (!isAllowed) {
            tokenConfig.isAllowed = false;
            emit TokenConfigured(token, tokenConfig.priceFeedAddress, tokenConfig.tokenDecimals, tokenConfig.priceFeedHeartbeat, false);
            return;
        }

        if (priceFeedAddress == address(0)) revert AutoDCA__InvalidPriceFeed();
        if (heartbeat == 0) revert AutoDCA__InvalidHeartbeat();

        if (!tokenConfig.isAllowed) {
            allowedTokenList.push(token);
        }

        tokenConfig.isAllowed = true;
        tokenConfig.priceFeedAddress = priceFeedAddress;
        tokenConfig.tokenDecimals = tokenDecimals;
        tokenConfig.priceFeedHeartbeat = heartbeat;

        emit TokenConfigured(token, priceFeedAddress, tokenDecimals, heartbeat, true);
    }

    function getAllowedTokens() external view returns (address[] memory) {
        return allowedTokenList;
    }

    function getActiveOrderIds() external view returns (uint256[] memory) {
        return activeOrderIds;
    }

    function getActiveOrderCount() external view returns (uint256) {
        return activeOrderIds.length;
    }

    function getOrder(uint256 orderId) external view returns (Order memory) {
        return orders[orderId];
    }

    function _addToActiveSet(uint256 orderId) private {
        activeOrderIndex[orderId] = activeOrderIds.length;
        activeOrderIds.push(orderId);
    }

    function _removeFromActiveSet(uint256 orderId) private {
        uint256 index = activeOrderIndex[orderId];
        uint256 lastIndex = activeOrderIds.length - 1;

        if (index != lastIndex) {
            uint256 lastOrderId = activeOrderIds[lastIndex];
            activeOrderIds[index] = lastOrderId;
            activeOrderIndex[lastOrderId] = index;
        }

        activeOrderIds.pop();
        delete activeOrderIndex[orderId];
    }

    function _getMinAmountOut(address tokenToBuy, uint256 usdcAmount) internal view returns (uint256) {
        TokenConfig memory tokenConfig = allowedTokens[tokenToBuy];
        AggregatorV3Interface priceFeed = AggregatorV3Interface(tokenConfig.priceFeedAddress);
        (, int256 price,, uint256 updatedAt,) = priceFeed.latestRoundData();

        if (price <= 0) revert AutoDCA__InvalidPriceFeed();
        if (updatedAt == 0 || block.timestamp - updatedAt > tokenConfig.priceFeedHeartbeat) revert AutoDCA__StalePrice();

        uint256 tokenPrecision = 10 ** tokenConfig.tokenDecimals;
        uint256 priceFeedPrecision = 10 ** priceFeed.decimals();
        uint256 expectedAmountOut = (usdcAmount * tokenPrecision * priceFeedPrecision) / (uint256(price) * USDC_PRECISION);

        return (expectedAmountOut * (BPS_PRECISION - SLIPPAGE_BPS)) / BPS_PRECISION;
    }
}
