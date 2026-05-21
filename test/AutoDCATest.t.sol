// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import {Test} from "forge-std/Test.sol";
import {AutoDCA} from "../src/AutoDCA.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract TestAutoDCA is Test {
    AutoDCA autoDca;
    address user = makeAddr("user");

    function setUp() external {
        autoDca = new AutoDCA(makeAddr("usdc"));
    }

    function testMinimumDepositIsFifty() public view {
        assertEq(autoDca.MINIMUM_DEPOSIT(), 50e6);
    }

    function testDepositSuccess() public {
        uint256 amount = 70e6;
        
        vm.mockCall(
            autoDca.I_USDC(),
            abi.encodeCall(IERC20.transferFrom, (user, address(autoDca), amount)),
            abi.encode(true)
        );
        
        vm.prank(user);
        autoDca.deposit(amount);

        assertEq(autoDca.userBalances(user), amount);
    }

    function testDepositRevertsIfAmountBelowMinimum() public {
        vm.prank(user);
        vm.expectRevert(AutoDCA.AutoDCA__AmountBelowMinimum.selector);
        autoDca.deposit(40e6);
    }
}
