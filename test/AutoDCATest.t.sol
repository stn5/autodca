// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AutoDCA} from "../src/AutoDCA.sol";
import {MockUSDC} from "./mocks/MockUSDC.sol";
import {MockSwapRouter} from "./mocks/MockSwapRouter.sol";

contract TestAutoDCA is Test {
    AutoDCA autoDca;
    MockUSDC usdc;
    MockSwapRouter swapRouter;
    address user = makeAddr("user");
    address tokenToBuy = makeAddr("mockETH");

    uint256 constant USER_STARTING_BALANCE = 500e6;
    uint256 constant DEPOSIT_AMOUNT = 120e6;

    function setUp() external {
        usdc = new MockUSDC();
        swapRouter = new MockSwapRouter();
        autoDca = new AutoDCA(address(usdc), address(swapRouter));
        autoDca.setAllowedToken(tokenToBuy, true);
        usdc.mint(user, USER_STARTING_BALANCE);
    }

    function testConstructorRevertsIfUsdcAddressIsZero() public {
        vm.expectRevert(AutoDCA.AutoDCA__InvalidTokenAddress.selector);
        new AutoDCA(address(0), address(swapRouter));
    }

    function testConstructorRevertsIfSwapRouterAddressIsZero() public {
        vm.expectRevert(AutoDCA.AutoDCA__InvalidTokenAddress.selector);
        new AutoDCA(address(usdc), address(0));
    }

    /* Tests for deposit func */

    function testMinimumDepositIsFifty() public view {
        assertEq(autoDca.MINIMUM_DEPOSIT(), 50e6);
    }

    function testDepositSuccess() public {
        vm.startPrank(user);
        usdc.approve(address(autoDca), DEPOSIT_AMOUNT);
        autoDca.deposit(DEPOSIT_AMOUNT);
        vm.stopPrank();

        assertEq(autoDca.userBalances(user), DEPOSIT_AMOUNT);
        assertEq(usdc.balanceOf(user), USER_STARTING_BALANCE - DEPOSIT_AMOUNT);
        assertEq(usdc.balanceOf(address(autoDca)), DEPOSIT_AMOUNT);
    }

    function testDepositRevertsIfAmountBelowMinimum() public {
        uint256 amount = autoDca.MINIMUM_DEPOSIT() - 1;

        vm.prank(user);
        vm.expectRevert(AutoDCA.AutoDCA__AmountBelowMinimum.selector);
        autoDca.deposit(amount);
    }

    /* Tests for withdraw func */

    function testWithdrawSuccess() public {
        uint256 withdrawAmount = 30e6;

        _deposit(DEPOSIT_AMOUNT);
        vm.prank(user);
        autoDca.withdraw(withdrawAmount);

        assertEq(autoDca.userBalances(user), DEPOSIT_AMOUNT - withdrawAmount);
        assertEq(usdc.balanceOf(user), USER_STARTING_BALANCE - DEPOSIT_AMOUNT + withdrawAmount);
        assertEq(usdc.balanceOf(address(autoDca)), DEPOSIT_AMOUNT - withdrawAmount);
    }

    function testWithdrawRevertsIfAmountIsZero() public {
        vm.prank(user);
        vm.expectRevert(AutoDCA.AutoDCA__AmountMustBeGreaterThanZero.selector);
        autoDca.withdraw(0);
    }

    function testWithdrawRevertsIfInsufficientBalance() public {
        _deposit(DEPOSIT_AMOUNT);

        vm.prank(user);
        vm.expectRevert(AutoDCA.AutoDCA__InsufficientBalance.selector);
        autoDca.withdraw(DEPOSIT_AMOUNT + 1);
    }

    /* Tests for createOrder func */

    function testCreateOrderSuccess() public {
        uint256 usdcAmountPerSwap = 60e6;
        uint256 interval = 1 days;

        vm.prank(user);
        uint256 orderId = autoDca.createOrder(tokenToBuy, usdcAmountPerSwap, interval);
        (
            address orderUser,
            address ordertokenToBuy,
            uint256 orderUsdcAmountPerSwap,
            uint256 orderInterval,
            uint256 orderLastExecuted,
            bool orderIsActive
        ) = autoDca.orders(orderId);

        assertEq(orderUser, user);
        assertEq(ordertokenToBuy, tokenToBuy);
        assertEq(orderUsdcAmountPerSwap, usdcAmountPerSwap);
        assertEq(orderInterval, interval);
        assertEq(orderLastExecuted, block.timestamp);
        assertTrue(orderIsActive);
    }

    function testCreateOrderRevertsIftokenToBuyIsZero() public {
        vm.prank(user);
        vm.expectRevert(AutoDCA.AutoDCA__InvalidTokenAddress.selector);
        autoDca.createOrder(address(0), 60e6, 1 days);
    }

    function testCreateOrderRevertsIfLowAmountPerSwap() public {
        vm.prank(user);
        vm.expectRevert(AutoDCA.AutoDCA__AmountBelowMinimum.selector);
        autoDca.createOrder(tokenToBuy, 20e6, 1 days);
    }

    function testCreateOrderRevertsIfIntervalBelowMinimum() public {
        vm.prank(user);
        vm.expectRevert(AutoDCA.AutoDCA__InvalidInterval.selector);
        autoDca.createOrder(tokenToBuy, 100e6, 1 hours);
    }

    function testCreateOrderRevertsIfTokenIsNotAllowed() public {
        address notAllowedToken = makeAddr("mockBTC");

        vm.prank(user);
        vm.expectRevert(AutoDCA.AutoDCA__TokenNotAllowed.selector);
        autoDca.createOrder(notAllowedToken, 100e6, 1 days);
    }

    /* Tests for updateOrder func */

    function testUpdateOrderSuccess() public {
        uint256 updatedUsdcAmountToSwap = 200e6;
        uint256 updatedInterval = 10 days;

        vm.startPrank(user);
        uint256 orderId = autoDca.createOrder(tokenToBuy, 100e6, 2 weeks);
        autoDca.updateOrder(orderId, updatedUsdcAmountToSwap, updatedInterval);
        vm.stopPrank();

        (
            address orderUser,
            address orderTokenToBuy,
            uint256 orderUsdcAmountPerSwap,
            uint256 orderInterval,
            ,
            bool orderIsActive
        ) = autoDca.orders(orderId);

        assertEq(orderUser, user);
        assertEq(orderTokenToBuy, tokenToBuy);
        assertEq(orderUsdcAmountPerSwap, updatedUsdcAmountToSwap);
        assertEq(orderInterval, updatedInterval);
        assertTrue(orderIsActive);
    }

    function testUpdateOrderRevertsIfNotOwner() public {
        address user2 = makeAddr("user2");

        vm.prank(user);
        uint256 orderId = autoDca.createOrder(tokenToBuy, 100e6, 2 weeks);

        vm.prank(user2);
        vm.expectRevert(AutoDCA.AutoDCA__NotOrderOwner.selector);
        autoDca.updateOrder(orderId, 200e6, 10 days);
    }

    /* Tests for cancelOrder func */

    function testCancelOrderSuccess() public {
        vm.startPrank(user);
        uint256 orderId = autoDca.createOrder(tokenToBuy, 60e6, 1 days);
        autoDca.cancelOrder(orderId);
        vm.stopPrank();

        (,,,,, bool isActive) = autoDca.orders(orderId);
        assertFalse(isActive);
        assertEq(autoDca.activeUserOrderIds(user, tokenToBuy), 0);
    }

    function testCancelOrderRevertsIfNotOrderOwner() public {
        address user2 = makeAddr("user2");

        vm.prank(user);
        uint256 orderId = autoDca.createOrder(tokenToBuy, 60e6, 1 days);

        vm.prank(user2);
        vm.expectRevert(AutoDCA.AutoDCA__NotOrderOwner.selector);
        autoDca.cancelOrder(orderId);
    }

    function testCancelOrderRevertsIfOrderAlreadyInactive() public {
        vm.startPrank(user);
        uint256 orderId = autoDca.createOrder(tokenToBuy, 60e6, 1 days);
        autoDca.cancelOrder(orderId);

        vm.expectRevert(AutoDCA.AutoDCA__OrderAlreadyInactive.selector);
        autoDca.cancelOrder(orderId);
        vm.stopPrank();
    }

    /* Tests for checkUpkeep func */

    function testCheckUpkeepIfNoOrders() public view {
        (bool upkeepNeeded,) = autoDca.checkUpkeep("");
        assertFalse(upkeepNeeded);
    }

    function testCheckUpkeepIfUserHasNoBalance() public {
        vm.prank(user);
        autoDca.createOrder(tokenToBuy, 100e6, 7 days);

        (bool upkeepNeeded,) = autoDca.checkUpkeep("");
        assertFalse(upkeepNeeded);
    }

    function testCheckUpkeepIfIntervalNotPassed() public {
        _deposit(DEPOSIT_AMOUNT);
        vm.prank(user);
        autoDca.createOrder(tokenToBuy, 100e6, 7 days);

        (bool upkeepNeeded,) = autoDca.checkUpkeep("");
        assertFalse(upkeepNeeded);
    }

    function testCheckUpkeepIfOrderIsReady() public {
        _deposit(DEPOSIT_AMOUNT);
        vm.prank(user);
        uint256 orderId = autoDca.createOrder(tokenToBuy, 100e6, 7 days);

        vm.warp(block.timestamp + 10 days);

        (bool upkeepNeeded, bytes memory performData) = autoDca.checkUpkeep("");
        assertTrue(upkeepNeeded);
        assertEq(abi.decode(performData, (uint256)), orderId);
    }

    /* Tests for performUpkeep func */

    function testPerformUpkeepSuccess() public {
        _deposit(DEPOSIT_AMOUNT);
        vm.prank(user);
        uint256 orderId = autoDca.createOrder(tokenToBuy, 100e6, 7 days);

        vm.warp(block.timestamp + 10 days);

        autoDca.performUpkeep(abi.encode(orderId));
        assertEq(autoDca.userBalances(user), DEPOSIT_AMOUNT - 100e6);
        assertEq(swapRouter.tokenIn(), address(usdc));
        assertEq(swapRouter.tokenOut(), tokenToBuy);
        assertEq(swapRouter.recipient(), user);
        assertEq(swapRouter.amountIn(), 100e6);
    }

    function testPerformUpkeepRevertsIfInsufficientBalance() public {
        vm.prank(user);
        uint256 orderId = autoDca.createOrder(tokenToBuy, 100e6, 7 days);

        vm.warp(block.timestamp + 10 days);

        vm.expectRevert(AutoDCA.AutoDCA__InsufficientBalance.selector);
        autoDca.performUpkeep(abi.encode(orderId));
    }

    function testPerformUpkeepRevertsIfTimeNotPassed() public {
        _deposit(DEPOSIT_AMOUNT);
        vm.prank(user);
        uint256 orderId = autoDca.createOrder(tokenToBuy, 100e6, 7 days);

        vm.expectRevert(AutoDCA.AutoDCA__InvalidInterval.selector);
        autoDca.performUpkeep(abi.encode(orderId));
    }

    /* Deposit helper */

    function _deposit(uint256 amount) internal {
        vm.startPrank(user);
        usdc.approve(address(autoDca), amount);
        autoDca.deposit(amount);
        vm.stopPrank();
    }
}
