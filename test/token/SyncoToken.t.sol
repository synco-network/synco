// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {SyncoToken} from "../../src/token/SyncoToken.sol";

contract SyncoTokenTest is Test {
    SyncoToken internal token;
    address internal holder = address(0x1234);
    address internal recipient = address(0x5678);

    function setUp() public {
        token = new SyncoToken(holder);
    }

    function testInitialSupplyIsTenMillion() public view {
        assertEq(token.totalSupply(), 10_000_000 ether);
    }

    function testEntireSupplyGoesToInitialHolder() public view {
        assertEq(token.balanceOf(holder), 10_000_000 ether);
    }

    function testTokenTransferWorks() public {
        vm.prank(holder);
        token.transfer(recipient, 100 ether);

        assertEq(token.balanceOf(recipient), 100 ether);
        assertEq(token.balanceOf(holder), 9_999_900 ether);
    }

    function testZeroAddressCannotBeInitialHolder() public {
        vm.expectRevert(SyncoToken.InvalidRecipient.selector);
        new SyncoToken(address(0));
    }
}
