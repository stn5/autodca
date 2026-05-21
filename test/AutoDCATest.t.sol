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
}
