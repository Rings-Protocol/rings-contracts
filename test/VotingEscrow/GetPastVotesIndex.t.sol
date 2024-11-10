// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract GetPastVotesIndex is VotingEscrowTest {
    uint256 internal constant MAXTIME = 2 * 365 * 86_400;
    uint256 internal constant WEEK = 7 * 86_400;

    function test_getPastVotesIndex_NoCheckpoint(address pranker) public {
        assertEq(votingEscrow.getPastVotesIndex(pranker, vm.getBlockTimestamp()), 0, "Index should be 0");
    }

    function test_getPastVotesIndex_BeforeCheckpoint(address pranker, uint256 amount, uint256 duration, uint256 wait)
        public
    {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400 + 1, MAXTIME);
        wait = bound(wait, 7 * 86_400, MAXTIME);

        uint256 startTimestamp = vm.getBlockTimestamp();

        vm.warp(vm.getBlockTimestamp() + wait);

        uint256 tokenId = createLockPranked(pranker, amount, duration);

        assertEq(votingEscrow.getPastVotesIndex(pranker, startTimestamp), 0, "Index should be 0");
    }

    function test_getpastvotesindex_LastCheckpoint(address pranker, uint256 amount, uint256 duration, uint256 wait)
        public
    {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400 + 1, MAXTIME);
        wait = bound(wait, 1, duration - 7 days);

        uint256 startTimestamp = vm.getBlockTimestamp();
        uint256 tokenId = createLockPranked(pranker, amount, duration);

        vm.warp(vm.getBlockTimestamp() + wait);
        assertEq(votingEscrow.getPastVotesIndex(pranker, vm.getBlockTimestamp()), 0, "Index should be 0");
    }

    function test_getpastvotesindex_IntermediateCheckpoint(
        address pranker,
        uint256 amount,
        uint256 duration,
        uint256 wait
    ) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400 + 2, MAXTIME);
        wait = bound(wait, 1, (duration - 7 days) / 2);

        uint256 startTimestamp = vm.getBlockTimestamp();
        uint256 tokenId = createLockPranked(pranker, amount, duration);

        vm.warp(vm.getBlockTimestamp() + wait * 2);

        vm.prank(pranker);
        votingEscrow.delegate(address(bob));

        uint256 numCheckpoints = votingEscrow.numCheckpoints(bob);
        console.log(numCheckpoints);
        (uint256 ts) = votingEscrow.checkpoints(bob, 1);
        console.log(ts);

        assertEq(votingEscrow.getPastVotesIndex(bob, startTimestamp + wait), 0, "Index should be 0");
    }
}
