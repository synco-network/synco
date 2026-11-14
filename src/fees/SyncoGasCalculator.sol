// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

interface ISyncoPriceOracle {
    function getPrice()
        external
        view
        returns (uint256 price, uint256 timestamp);
}

/// @title SyncoGasCalculator
/// @notice Menghitung biaya transfer sederhana dalam SYNCO.
/// @dev Simulasi awal dengan asumsi 1 USDC = 1 USD.
contract SyncoGasCalculator {
    uint256 public constant PRICE_SCALE = 1e8;
    uint256 public constant SYNCO_SCALE = 1e18;

    // Target 0.0001 USDC dengan 8 angka desimal.
    uint256 public constant TARGET_FEE_USDC = 10_000;

    ISyncoPriceOracle public immutable oracle;
    uint256 public immutable maxPriceAge;

    error InvalidOracleAddress();
    error InvalidMaxPriceAge();
    error InvalidOraclePrice();
    error InvalidOracleTimestamp();
    error StaleOraclePrice();

    constructor(address oracleAddress, uint256 maxAge) {
        if (oracleAddress == address(0)) {
            revert InvalidOracleAddress();
        }

        if (maxAge == 0) {
            revert InvalidMaxPriceAge();
        }

        oracle = ISyncoPriceOracle(oracleAddress);
        maxPriceAge = maxAge;
    }

    /// @notice Menghitung biaya transfer sederhana dalam wei SYNCO.
    /// @return fee Jumlah SYNCO dalam satuan terkecil (18 desimal).
    function calculateTransferFee()
        external
        view
        returns (uint256 fee)
    {
        (uint256 price, uint256 timestamp) = oracle.getPrice();

        if (price == 0) revert InvalidOraclePrice();

        if (timestamp > block.timestamp) {
            revert InvalidOracleTimestamp();
        }

        if (block.timestamp - timestamp > maxPriceAge) {
            revert StaleOraclePrice();
        }

        // Pembulatan ke atas agar biaya tidak menjadi kurang
        // dari target akibat pembagian bilangan bulat.
        uint256 numerator = TARGET_FEE_USDC * SYNCO_SCALE;

        fee = (numerator + price - 1) / price;
    }
}
