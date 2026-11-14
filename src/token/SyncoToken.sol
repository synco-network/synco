// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract SyncoToken is ERC20 {
    uint256 public constant MAX_SUPPLY = 10_000_000 ether;

    error InvalidRecipient();

    constructor(address initialHolder) ERC20("SYNCO", "SYNCO") {
        if (initialHolder == address(0)) {
            revert InvalidRecipient();
        }

        _mint(initialHolder, MAX_SUPPLY);
    }
}
