// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

/// @title MockSyncoPriceOracle
/// @notice Oracle simulasi harga SYNCO terhadap USDC untuk pengujian lokal.
/// @dev Bukan oracle produksi dan tidak boleh digunakan di mainnet.
contract MockSyncoPriceOracle {
    uint256 public constant PRICE_DECIMALS = 8;

    address public immutable administrator;

    // Harga SYNCO dalam USDC, dengan 8 angka desimal.
    // Contoh: 0.01 USDC = 1_000_000.
    uint256 public syncoPriceUsdc;

    uint256 public updatedAt;

    error Unauthorized();
    error InvalidPrice();

    event PriceUpdated(
        uint256 oldPrice,
        uint256 newPrice,
        uint256 timestamp
    );

    constructor(address initialAdministrator, uint256 initialPrice) {
        if (initialAdministrator == address(0)) revert Unauthorized();
        if (initialPrice == 0) revert InvalidPrice();

        administrator = initialAdministrator;
        syncoPriceUsdc = initialPrice;
        updatedAt = block.timestamp;
    }

    function setPrice(uint256 newPrice) external {
        if (msg.sender != administrator) revert Unauthorized();
        if (newPrice == 0) revert InvalidPrice();

        uint256 oldPrice = syncoPriceUsdc;

        syncoPriceUsdc = newPrice;
        updatedAt = block.timestamp;

        emit PriceUpdated(oldPrice, newPrice, block.timestamp);
    }

    function getPrice()
        external
        view
        returns (uint256 price, uint256 timestamp)
    {
        return (syncoPriceUsdc, updatedAt);
    }
}
