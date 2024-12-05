// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract GetPastVotes is VotingEscrowTest {
    uint256 internal constant MAXTIME = 52 weeks;
    uint256 internal constant WEEK = 7 * 86_400;

    function testFuzz_getPastVotes_Single(address pranker, uint256 amount, uint256 duration, uint256 wait) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400 + 1, MAXTIME);
        wait = bound(wait, 1, duration - 7 days);

        uint256 startTimestamp = vm.getBlockTimestamp();
        uint256 tokenId = createLockPranked(pranker, amount, duration);

        uint256 lockedEnd = votingEscrow.locked__end(tokenId);
        uint256 slope = amount / MAXTIME;
        uint256 bias = slope * (lockedEnd - startTimestamp);
        uint256 estimated = bias - (slope * wait);
        assertEq(
            votingEscrow.getPastVotes(pranker, vm.getBlockTimestamp() + wait), estimated, "Vote power should be estimated"
        );
    }

    function testFuzz_getPastVotes_Multiple(
        address pranker,
        uint256 amount,
        uint256 duration,
        uint256 wait,
        uint8 tokens
    ) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400 + 1, MAXTIME);
        wait = bound(wait, 1, duration - 7 days);
        uint256 nbTokens = bound(tokens, 1, 25);
        uint256 startTimestamp = vm.getBlockTimestamp();
        uint256 tokenId;

        for (uint8 i = 0; i < nbTokens; i++) {
            tokenId = createLockPranked(pranker, amount, duration);
        }

        uint256 lockedEnd = votingEscrow.locked__end(tokenId);
        uint256 slope = amount / MAXTIME;
        uint256 bias = slope * (lockedEnd - startTimestamp);
        uint256 estimated = bias - (slope * wait);
        assertEq(
            votingEscrow.getPastVotes(pranker, vm.getBlockTimestamp() + wait),
            estimated * nbTokens,
            "Vote power should be estimated times nbTokens"
        );
    }

    function testFuzz_getPastVotes_Expired(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME - 7 * 86_400);

        uint256 tokenId = createLockPranked(pranker, amount, duration);

        assertEq(votingEscrow.getPastVotes(pranker, vm.getBlockTimestamp() + duration), 0, "Vote power should be 0");
    }

    function testFuzz_getPastVotes_Invalid(address pranker, uint256 timestamp) public view {
        assertEq(votingEscrow.getPastVotes(pranker, timestamp), 0, "Vote power should be 0");
    }
}
