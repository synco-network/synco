// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {MockSyncoPriceOracle} from "../../src/oracle/MockSyncoPriceOracle.sol";
import {SyncoGasCalculator} from "../../src/fees/SyncoGasCalculator.sol";

contract SyncoGasCalculatorTest is Test {
    MockSyncoPriceOracle internal oracle;
    SyncoGasCalculator internal calculator;

    address internal admin = address(0x1234);

    function setUp() public {
        oracle = new MockSyncoPriceOracle(admin, 1_000_000);
        calculator = new SyncoGasCalculator(address(oracle), 300);
    }

    function testFeeAtOneCent() public view {
        // Harga 1 SYNCO = 0.01 USDC.
        assertEq(calculator.calculateTransferFee(), 0.01 ether);
    }

    function testFeeAtOneDollar() public {
        // Harga 1 SYNCO = 1 USDC.
        vm.prank(admin);
        oracle.setPrice(100_000_000);

        assertEq(calculator.calculateTransferFee(), 0.0001 ether);
    }

    function testFeeAtOneTenthCent() public {
        // Harga 1 SYNCO = 0.001 USDC.
        vm.prank(admin);
        oracle.setPrice(100_000);

        assertEq(calculator.calculateTransferFee(), 0.1 ether);
    }

    function testFeeRoundsUp() public {
        // Harga 1 SYNCO = 0.03 USDC.
        vm.prank(admin);
        oracle.setPrice(3_000_000);

        uint256 fee = calculator.calculateTransferFee();

        assertGe(fee * 3_000_000, 10_000 * 1e18);
    }

    function testRejectsStalePrice() public {
        vm.warp(block.timestamp + 301);

        vm.expectRevert(
            SyncoGasCalculator.StaleOraclePrice.selector
        );

        calculator.calculateTransferFee();
    }

    function testRejectsFutureTimestamp() public {
        vm.warp(1000);

        vm.prank(admin);
        oracle.setPrice(2_000_000);

        vm.warp(999);

        vm.expectRevert(
            SyncoGasCalculator.InvalidOracleTimestamp.selector
        );

        calculator.calculateTransferFee();
    }

    function testRejectsZeroOraclePrice() public {
        // Oracle normal tidak mengizinkan harga nol.
        // Tes ini memeriksa validasi kalkulator dengan mock khusus.
        ZeroPriceOracle zeroOracle = new ZeroPriceOracle();

        SyncoGasCalculator zeroCalculator =
            new SyncoGasCalculator(address(zeroOracle), 300);

        vm.expectRevert(
            SyncoGasCalculator.InvalidOraclePrice.selector
        );

        zeroCalculator.calculateTransferFee();
    }

    function testRejectsZeroMaxAge() public {
        vm.expectRevert(
            SyncoGasCalculator.InvalidMaxPriceAge.selector
        );

        new SyncoGasCalculator(address(oracle), 0);
    }

    function testRejectsZeroOracleAddress() public {
        vm.expectRevert(
            SyncoGasCalculator.InvalidOracleAddress.selector
        );

        new SyncoGasCalculator(address(0), 300);
    }
}

contract ZeroPriceOracle {
    function getPrice()
        external
        view
        returns (uint256 price, uint256 timestamp)
    {
        return (0, block.timestamp);
    }
}
