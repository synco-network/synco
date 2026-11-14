// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/// @title SyncoAllocation
/// @notice Distribusi nyata alokasi awal SYNCO.
/// @dev Tidak mencetak token. Token harus disetor terlebih dahulu.
contract SyncoAllocation {
    uint256 public constant MAX_SUPPLY = 10_000_000 ether;

    uint256 public constant STAKING_ALLOCATION = 1_000_000 ether;
    uint256 public constant USERS_ALLOCATION = 8_500_000 ether;
    uint256 public constant DEVELOPER_ALLOCATION = 500_000 ether;

    IERC20 public immutable syncoToken;
    address public immutable administrator;

    mapping(bytes32 => address) public recipients;
    mapping(bytes32 => bool) public distributed;

    uint256 public totalDistributed;

    bytes32 public constant STAKING_VALIDATOR =
        keccak256("STAKING_VALIDATOR");

    bytes32 public constant USERS_ECOSYSTEM =
        keccak256("USERS_ECOSYSTEM");

    bytes32 public constant DEVELOPER =
        keccak256("DEVELOPER");

    error Unauthorized();
    error InvalidAddress();
    error InvalidCategory();
    error AlreadyDistributed();
    error TransferFailed();
    error InsufficientAllocationBalance();

    event RecipientConfigured(bytes32 indexed category, address indexed recipient);
    event AllocationDistributed(
        bytes32 indexed category,
        address indexed recipient,
        uint256 amount
    );

    modifier onlyAdministrator() {
        if (msg.sender != administrator) revert Unauthorized();
        _;
    }

    constructor(address tokenAddress, address initialAdministrator) {
        if (
            tokenAddress == address(0) ||
            initialAdministrator == address(0)
        ) revert InvalidAddress();

        syncoToken = IERC20(tokenAddress);
        administrator = initialAdministrator;
    }

    function configureRecipient(bytes32 category, address recipient)
        external
        onlyAdministrator
    {
        if (recipient == address(0)) revert InvalidAddress();
        if (!_validCategory(category)) revert InvalidCategory();
        if (distributed[category]) revert AlreadyDistributed();

        recipients[category] = recipient;

        emit RecipientConfigured(category, recipient);
    }

    function distribute(bytes32 category) external onlyAdministrator {
        if (!_validCategory(category)) revert InvalidCategory();
        if (distributed[category]) revert AlreadyDistributed();

        address recipient = recipients[category];
        if (recipient == address(0)) revert InvalidAddress();

        uint256 amount = _allocationAmount(category);

        if (totalDistributed + amount > MAX_SUPPLY) {
            revert InsufficientAllocationBalance();
        }

        if (syncoToken.balanceOf(address(this)) < amount) {
            revert InsufficientAllocationBalance();
        }

        distributed[category] = true;
        totalDistributed += amount;

        bool success = syncoToken.transfer(recipient, amount);
        if (!success) revert TransferFailed();

        emit AllocationDistributed(category, recipient, amount);
    }

    function _validCategory(bytes32 category) internal pure returns (bool) {
        return (
            category == STAKING_VALIDATOR ||
            category == USERS_ECOSYSTEM ||
            category == DEVELOPER
        );
    }

    function _allocationAmount(bytes32 category)
        internal
        pure
        returns (uint256)
    {
        if (category == STAKING_VALIDATOR) return STAKING_ALLOCATION;
        if (category == USERS_ECOSYSTEM) return USERS_ALLOCATION;
        if (category == DEVELOPER) return DEVELOPER_ALLOCATION;

        revert InvalidCategory();
    }
}
