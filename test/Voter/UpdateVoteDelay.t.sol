// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VoterTest.t.sol";

contract UpdateVoteDelay is VoterTest {
    uint256 newVoteDelay = 6 hours;

    function test_update_correctly() public {
        uint256 oldVoteDelay = voter.voteDelay();

        vm.expectEmit(true, true, true, true);
        emit Voter.VoteDelayUpdated(oldVoteDelay, newVoteDelay);

        vm.prank(owner);
        voter.updateVoteDelay(newVoteDelay);

        assertEq(voter.voteDelay(), newVoteDelay, "Vote delay should be updated correctly");
    }

    function test_fail_invalid_parameter() public {
        vm.expectRevert(Voter.InvalidParameter.selector);
        vm.prank(owner);
        voter.updateVoteDelay(9 days);
    }

    function test_fail_not_owner() public {
        vm.expectRevert();
        voter.updateVoteDelay(newVoteDelay);
    }
}