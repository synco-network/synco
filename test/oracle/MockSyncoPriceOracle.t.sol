// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {MockSyncoPriceOracle} from "../../src/oracle/MockSyncoPriceOracle.sol";

contract MockSyncoPriceOracleTest is Test {
    MockSyncoPriceOracle internal oracle;

    address internal admin = address(0x1234);
    address internal attacker = address(0x5678);

    uint256 internal constant INITIAL_PRICE = 1_000_000;
    // 1_000_000 dengan 8 desimal = 0.01 USDC per SYNCO.

    function setUp() public {
        oracle = new MockSyncoPriceOracle(admin, INITIAL_PRICE);
    }

    function testInitialPriceIsCorrect() public view {
        (uint256 price,) = oracle.getPrice();
        assertEq(price, INITIAL_PRICE);
    }

    function testAdministratorCanUpdatePrice() public {
        vm.prank(admin);
        oracle.setPrice(2_000_000);

        (uint256 price,) = oracle.getPrice();
        assertEq(price, 2_000_000);
    }

    function testNonAdministratorCannotUpdatePrice() public {
        vm.prank(attacker);

        vm.expectRevert(
            MockSyncoPriceOracle.Unauthorized.selector
        );

        oracle.setPrice(2_000_000);
    }

    function testZeroPriceIsRejected() public {
        vm.prank(admin);

        vm.expectRevert(
            MockSyncoPriceOracle.InvalidPrice.selector
        );

        oracle.setPrice(0);
    }

    function testZeroInitialPriceIsRejected() public {
        vm.expectRevert(
            MockSyncoPriceOracle.InvalidPrice.selector
        );

        new MockSyncoPriceOracle(admin, 0);
    }
}
