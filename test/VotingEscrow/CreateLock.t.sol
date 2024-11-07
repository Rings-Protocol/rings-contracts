// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";
import { SafeCastLib } from "solady/utils/SafeCastLib.sol";

contract CreateLock is VotingEscrowTest {
    uint256 internal constant MAXTIME = 2 * 365 * 86_400;
    uint256 internal constant WEEK = 7 * 86_400;

    function testFuzz_createLock_simple(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);

        (int128 balance, uint256 end) = votingEscrow.locked(tokenId);
        assertEq(balance, SafeCastLib.toInt128(amount), "Value should be amount");
        assertEq(end, (block.timestamp + duration) / WEEK * WEEK, "Value should be duration from now rounded to week");
        assertEq(votingEscrow.ownerOf(tokenId), pranker, "Owner should be pranker");
        //TODO check balance of
    }

    function testFuzz_createLock_InvalidAmount(address pranker, uint256 duration) public {
        vm.assume(pranker != address(0));
        duration = bound(duration, 7 * 86_400, MAXTIME);

        vm.expectRevert();
        vm.prank(pranker);
        uint256 tokenId = votingEscrow.create_lock(0, duration);
    }

    function testFuzz_createLock_ZeroDuration(address pranker, uint256 amount) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);

        dealApproveAsset(pranker, amount);

        vm.expectRevert();
        vm.prank(pranker);
        uint256 tokenId = votingEscrow.create_lock(amount, 0);
    }

    function testFuzz_createLock_TooLongDuration(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, MAXTIME + 7 days, type(uint256).max);

        dealApproveAsset(pranker, amount);

        vm.expectRevert();
        vm.prank(pranker);
        uint256 tokenId = votingEscrow.create_lock(amount, duration);
    }
}
