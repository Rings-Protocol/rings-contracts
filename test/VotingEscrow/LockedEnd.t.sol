// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract LockedEnd is VotingEscrowTest {
    uint256 internal constant MAXTIME = 2 * 365 * 86_400;
    uint256 internal constant WEEK = 7 * 86_400;

    function testFuzz_lockedEnd_LockStart(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);

        assertEq(
            votingEscrow.locked__end(tokenId),
            (block.timestamp + duration) / WEEK * WEEK,
            "Value should be duration from now rounded to week"
        );
    }

    function testFuzz_lockedEnd_LockMiddle(address pranker, uint256 amount, uint256 duration, uint8 waitWeeks) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);
        waitWeeks = uint8(bound(waitWeeks, 1, duration / (7 * 86_400)));

        uint256 tokenId = createLockPranked(pranker, amount, duration);
        uint256 timestamp = block.timestamp;

        vm.warp(block.timestamp + uint256(waitWeeks) * 7 * 86_400);

        assertEq(
            votingEscrow.locked__end(tokenId),
            (timestamp + duration) / WEEK * WEEK,
            "Value should be duration from now rounded to week"
        );
    }

    function testFuzz_lockedEnd_extended(address pranker, uint256 amount, uint256 duration, uint8 weeksExtend) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME - 7 * 86_400);
        weeksExtend = uint8(bound(weeksExtend, 1, (MAXTIME - duration) / (7 * 86_400))); // 1 week to max duration

        uint256 tokenId = createLockPranked(pranker, amount, duration);
        uint256 timestamp = block.timestamp;

        uint256 end = (timestamp + duration + uint256(weeksExtend) * 7 * 86_400) / WEEK * WEEK;

        increaseLockPranked(pranker, tokenId, end);

        assertEq(
            votingEscrow.locked__end(tokenId),
            end / WEEK * WEEK,
            "Value should be duration + weeksExtend from now rounded to week"
        );
    }

    function testFuzz_lockedEnd_Invalid(uint256 tokenId) public {
        assertEq(votingEscrow.locked__end(tokenId), 0, "Unlock should be 0");
    }
}
