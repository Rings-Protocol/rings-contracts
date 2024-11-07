// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract Delegates is VotingEscrowTest {
    function test_delegates_Normal() public {
        vm.prank(alice);
        votingEscrow.delegate(address(bob));

        assertEq(votingEscrow.delegates(alice), address(bob), "Delegate is not bob");
    }

    function test_delegates_NotSet() public view {
        assertEq(votingEscrow.delegates(alice), address(alice), "Delegate is not alice");
    }
}
