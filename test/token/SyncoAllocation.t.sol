// SPDX-License-Identifier: MIT
pragma solidity 0.8.28;

import {Test} from "forge-std/Test.sol";
import {SyncoToken} from "../../src/token/SyncoToken.sol";
import {SyncoAllocation} from "../../src/token/SyncoAllocation.sol";

contract UnauthorizedCaller {
    function tryDistribute(
        SyncoAllocation allocation,
        bytes32 category
    ) external returns (bool success) {
        (success,) = address(allocation).call(
            abi.encodeCall(SyncoAllocation.distribute, (category))
        );
    }
}

contract SyncoAllocationTest is Test {
    SyncoToken internal token;
    SyncoAllocation internal allocation;

    address internal stakingRecipient = address(0x1111);
    address internal usersRecipient = address(0x2222);
    address internal developerRecipient = address(0x3333);

    function setUp() public {
        token = new SyncoToken(address(this));

        allocation = new SyncoAllocation(
            address(token),
            address(this)
        );

        token.transfer(address(allocation), 10_000_000 ether);
    }

    function testAllocationAmounts() public view {
        assertEq(allocation.STAKING_ALLOCATION(), 1_000_000 ether);
        assertEq(allocation.USERS_ALLOCATION(), 8_500_000 ether);
        assertEq(allocation.DEVELOPER_ALLOCATION(), 500_000 ether);
    }

    function testDistributeStakingAllocation() public {
        allocation.configureRecipient(
            allocation.STAKING_VALIDATOR(),
            stakingRecipient
        );

        allocation.distribute(allocation.STAKING_VALIDATOR());

        assertEq(token.balanceOf(stakingRecipient), 1_000_000 ether);
        assertEq(allocation.totalDistributed(), 1_000_000 ether);
    }

    function testDistributeAllAllocations() public {
        allocation.configureRecipient(
            allocation.STAKING_VALIDATOR(),
            stakingRecipient
        );

        allocation.configureRecipient(
            allocation.USERS_ECOSYSTEM(),
            usersRecipient
        );

        allocation.configureRecipient(
            allocation.DEVELOPER(),
            developerRecipient
        );

        allocation.distribute(allocation.STAKING_VALIDATOR());
        allocation.distribute(allocation.USERS_ECOSYSTEM());
        allocation.distribute(allocation.DEVELOPER());

        assertEq(token.balanceOf(stakingRecipient), 1_000_000 ether);
        assertEq(token.balanceOf(usersRecipient), 8_500_000 ether);
        assertEq(token.balanceOf(developerRecipient), 500_000 ether);
        assertEq(allocation.totalDistributed(), 10_000_000 ether);
        assertEq(token.balanceOf(address(allocation)), 0);
    }

    function testCannotDistributeTwice() public {
        allocation.configureRecipient(
            allocation.STAKING_VALIDATOR(),
            stakingRecipient
        );

        allocation.distribute(allocation.STAKING_VALIDATOR());

        (bool success,) = address(allocation).call(
            abi.encodeCall(
                SyncoAllocation.distribute,
                (allocation.STAKING_VALIDATOR())
            )
        );

        assertFalse(success, "Second distribution must fail");
    }

    function testUnauthorizedCannotDistribute() public {
        UnauthorizedCaller attacker = new UnauthorizedCaller();

        bool success = attacker.tryDistribute(
            allocation,
            allocation.STAKING_VALIDATOR()
        );

        assertFalse(success, "Unauthorized distribution must fail");
    }

    function testCannotConfigureInvalidCategory() public {
        (bool success,) = address(allocation).call(
            abi.encodeCall(
                SyncoAllocation.configureRecipient,
                (bytes32("INVALID"), stakingRecipient)
            )
        );

        assertFalse(success, "Invalid category must fail");
    }

    function testCannotDistributeWithoutEnoughTokens() public {
        SyncoToken emptyToken = new SyncoToken(address(this));

        SyncoAllocation emptyAllocation = new SyncoAllocation(
            address(emptyToken),
            address(this)
        );

        emptyAllocation.configureRecipient(
            emptyAllocation.STAKING_VALIDATOR(),
            stakingRecipient
        );

        (bool success,) = address(emptyAllocation).call(
            abi.encodeCall(
                SyncoAllocation.distribute,
                (emptyAllocation.STAKING_VALIDATOR())
            )
        );

        assertFalse(success, "Distribution without funds must fail");
    }
}
