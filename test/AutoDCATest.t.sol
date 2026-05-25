// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AutoDCA} from "../src/AutoDCA.sol";
import {MockUSDC} from "./mocks/MockUSDC.sol";

contract TestAutoDCA is Test {
    AutoDCA autoDca;
    MockUSDC usdc;
    address user = makeAddr("user");

    uint256 constant USER_STARTING_BALANCE = 500e6;
    uint256 constant DEPOSIT_AMOUNT = 70e6;

    function setUp() external {
        usdc = new MockUSDC();
        autoDca = new AutoDCA(address(usdc));
        usdc.mint(user, USER_STARTING_BALANCE);
    }

    function testConstructorIfAddressIsZero() public {
        vm.expectRevert(AutoDCA.AutoDCA__InvalidTokenAddress.selector);
        new AutoDCA(address(0));
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

        vm.startPrank(user);
        usdc.approve(address(autoDca), DEPOSIT_AMOUNT);
        autoDca.deposit(DEPOSIT_AMOUNT);
        autoDca.withdraw(withdrawAmount);
        vm.stopPrank();

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
        vm.startPrank(user);
        usdc.approve(address(autoDca), DEPOSIT_AMOUNT);
        autoDca.deposit(DEPOSIT_AMOUNT);

        vm.expectRevert(AutoDCA.AutoDCA__InsufficientBalance.selector);
        autoDca.withdraw(DEPOSIT_AMOUNT + 1);
        vm.stopPrank();
    }

    /* Tests for createOrder func */

    function testCreateOrderSuccess() public {
        address tokenToBuy = makeAddr("mockETH");
        uint256 usdcAmountPerSwap = 60e6;
        uint256 interval = 1 days;

        vm.prank(user);
        uint256 orderId = autoDca.createOrder(tokenToBuy, usdcAmountPerSwap, interval);
        (
            address orderUser,
            address ordertokenToBuy,
            uint256 orderUsdcAmountPerSwap,
            uint256 orderInterval,
            ,
            bool orderIsActive
        ) = autoDca.orders(orderId);

        assertEq(orderUser, user);
        assertEq(ordertokenToBuy, tokenToBuy);
        assertEq(orderUsdcAmountPerSwap, usdcAmountPerSwap);
        assertEq(orderInterval, interval);
        assertEq(orderIsActive, true);
    }

    function testCreateOrderRevertsIftokenToBuyIsZero() public {
        vm.prank(user);
        vm.expectRevert(AutoDCA.AutoDCA__InvalidTokenAddress.selector);
        autoDca.createOrder(address(0), 60e6, 1 days);
    }

    function testCreateOrderRevertsIfLowAmountPerSwap() public {
        vm.prank(user);
        vm.expectRevert(AutoDCA.AutoDCA__AmountBelowMinimum.selector);
        autoDca.createOrder(makeAddr("mockETH"), 20e6, 1 days);
    }

    function testCreateOrderRevertsIfIntervalBelowMinimum() public {
        vm.prank(user);
        vm.expectRevert(AutoDCA.AutoDCA__InvalidInterval.selector);
        autoDca.createOrder(makeAddr("mockETH"), 100e6, 1 hours);
    }

    /* Tests for updateOrder func */

    function testUpdateOrderSuccess() public {
        address tokenToBuy = makeAddr("mockETH");
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
        uint256 orderId = autoDca.createOrder(makeAddr("mockETH"), 100e6, 2 weeks);

        vm.prank(user2);
        vm.expectRevert(AutoDCA.AutoDCA__NotOrderOwner.selector);
        autoDca.updateOrder(orderId, 200e6, 10 days);
    }

    /* Tests for cancelOrder func */

    function testCancelOrderSuccess() public {
        address tokenToBuy = makeAddr("mockETH");

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
        uint256 orderId = autoDca.createOrder(makeAddr("mockETH"), 60e6, 1 days);

        vm.prank(user2);
        vm.expectRevert(AutoDCA.AutoDCA__NotOrderOwner.selector);
        autoDca.cancelOrder(orderId);
    }

    function testCancelOrderRevertsIfOrderAlreadyInactive() public {
        vm.startPrank(user);
        uint256 orderId = autoDca.createOrder(makeAddr("mockETH"), 60e6, 1 days);
        autoDca.cancelOrder(orderId);

        vm.expectRevert(AutoDCA.AutoDCA__OrderAlreadyInactive.selector);
        autoDca.cancelOrder(orderId);
        vm.stopPrank();
    }
}
