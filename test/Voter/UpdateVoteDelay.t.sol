// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VoterTest.t.sol";

contract UpdateVoteDelay is VoterTest {

    error InvalidParameter();

    event VoteDelayUpdated(uint256 oldVoteDelay, uint256 newVoteDelay);

    uint256 newVoteDelay = 6 hours;

    function test_update_correctly() public {
        uint256 oldVoteDelay = voter.voteDelay();

        vm.expectEmit(true, true, true, true);
        emit VoteDelayUpdated(oldVoteDelay, newVoteDelay);

        vm.prank(owner);
        voter.updateVoteDelay(newVoteDelay);

        assertEq(voter.voteDelay(), newVoteDelay, "Vote delay should be updated correctly");
    }

    function test_fail_invalid_parameter() public {
        vm.expectRevert(InvalidParameter.selector);
        vm.prank(owner);
        voter.updateVoteDelay(9 days);
    }

    function test_fail_not_owner() public {
        vm.expectRevert();
        voter.updateVoteDelay(newVoteDelay);
    }
}