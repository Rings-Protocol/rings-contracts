// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract GetVotes is VotingEscrowTest {
    uint256 internal constant MAXTIME = 2 * 365 * 86_400;
    uint256 internal constant WEEK = 7 * 86_400;

    function test_getvotes_Normal(address pranker, uint256 amount, uint256 duration, uint256 wait) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400 + 1, MAXTIME);
        wait = bound(wait, 1, duration - 7 days);

        vm.prank(pranker);
        votingEscrow.delegate(address(bob));

        uint256 startTimestamp = block.timestamp;
        uint256 tokenId = createLockPranked(pranker, amount, duration);

        vm.warp(block.timestamp + wait);

        uint256 lockedEnd = votingEscrow.locked__end(tokenId);
        uint256 slope = amount / MAXTIME;
        uint256 bias = slope * (lockedEnd - startTimestamp);
        uint256 estimated = bias - (slope * wait);
        assertEq(votingEscrow.getVotes(bob), estimated, "Balance should be amount");
    }

    function test_getvotes_NotSet(address pranker, uint256 amount, uint256 duration, uint256 wait) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400 + 1, MAXTIME);
        wait = bound(wait, 1, duration - 7 days);

        uint256 startTimestamp = block.timestamp;
        uint256 tokenId = createLockPranked(pranker, amount, duration);

        vm.warp(block.timestamp + wait);

        uint256 lockedEnd = votingEscrow.locked__end(tokenId);
        uint256 slope = amount / MAXTIME;
        uint256 bias = slope * (lockedEnd - startTimestamp);
        uint256 estimated = bias - (slope * wait);
        assertEq(votingEscrow.getVotes(bob), 0, "Balance should be amount");
    }
}
