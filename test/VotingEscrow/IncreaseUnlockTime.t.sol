// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";
import { SafeCastLib } from "solady/utils/SafeCastLib.sol";

contract IncreaseUnlockTime is VotingEscrowTest {
    uint256 internal constant MAXTIME = 52 weeks;
    uint256 internal constant WEEK = 7 * 86_400;

    function testFuzz_increaseUnlockTime_simple(
        address pranker,
        uint256 amount,
        uint256 duration,
        uint256 secondDuration
    ) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME - 7 days);
        secondDuration = bound(secondDuration, 7 days, MAXTIME - duration);

        uint256 timestamp = vm.getBlockTimestamp();
        uint256 tokenId = createLockPranked(pranker, amount, duration);

        vm.prank(pranker);
        votingEscrow.increase_unlock_time(tokenId, duration + secondDuration);

        (, uint256 end) = votingEscrow.locked(tokenId);
        assertEq(end, (timestamp + duration + secondDuration) / WEEK * WEEK, "Value should be sum of durations");
    }

    function testFuzz_increaseUnlockTime_InvalidToken(uint256 tokenId) public {
        vm.expectRevert();
        votingEscrow.increase_unlock_time(tokenId, vm.getBlockTimestamp() + 1);
    }

    function testFuzz_increaseUnlockTime_InvalidDuration(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);

        vm.expectRevert();
        vm.prank(pranker);
        votingEscrow.increase_unlock_time(tokenId, 0);
    }

    function testFuzz_increaseUnlockTime_TooLowDuration(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 4 weeks, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);

        vm.prank(pranker);
        vm.expectRevert();
        votingEscrow.increase_unlock_time(tokenId, duration - 2 weeks);
    }

    function testFuzz_increaseUnlockTime_Expired(
        address pranker,
        uint256 amount,
        uint256 duration,
        uint256 secondDuration
    ) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME - 7 days);
        secondDuration = bound(secondDuration, 7 days, MAXTIME - duration);

        uint256 timestamp = vm.getBlockTimestamp();
        uint256 tokenId = createLockPranked(pranker, amount, duration);

        vm.warp(vm.getBlockTimestamp() + duration + 1);

        vm.prank(pranker);
        vm.expectRevert();
        votingEscrow.increase_unlock_time(tokenId, timestamp + secondDuration);
    }
}
