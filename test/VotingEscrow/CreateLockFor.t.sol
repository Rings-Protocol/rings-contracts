// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";
import { SafeCastLib } from "solady/utils/SafeCastLib.sol";

contract CreateLockFor is VotingEscrowTest {
    uint256 internal constant MAXTIME = 2 * 365 * 86_400;
    uint256 internal constant WEEK = 7 * 86_400;

    function testFuzz_createLockFor_simple(address pranker, address recipient, uint256 amount, uint256 duration)
        public
    {
        vm.assume(pranker != address(0));
        vm.assume(recipient != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockForPranked(pranker, recipient, amount, duration);

        (int128 balance, uint256 end) = votingEscrow.locked(tokenId);
        assertEq(balance, SafeCastLib.toInt128(amount), "Value should be amount");
        assertEq(end, (block.timestamp + duration) / WEEK * WEEK, "Value should be duration from now rounded to week");
        assertEq(votingEscrow.ownerOf(tokenId), recipient, "Owner should be pranker");
    }

    function testFuzz_createLockFor_InvalidAmount(address pranker, address recipient, uint256 duration) public {
        vm.assume(pranker != address(0));
        duration = bound(duration, 7 * 86_400, MAXTIME);

        vm.expectRevert();
        vm.prank(pranker);
        uint256 tokenId = votingEscrow.create_lock_for(0, duration, recipient);
    }

    function testFuzz_createLockFor_ZeroDuration(address pranker, address recipient, uint256 amount) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);

        dealApproveAsset(pranker, amount);

        vm.expectRevert();
        vm.prank(pranker);
        uint256 tokenId = votingEscrow.create_lock_for(amount, 0, recipient);
    }

    function testFuzz_createLockFor_TooLongDuration(
        address pranker,
        address recipient,
        uint256 amount,
        uint256 duration
    ) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, MAXTIME + 7 days, type(uint256).max);

        dealApproveAsset(pranker, amount);

        vm.expectRevert();
        vm.prank(pranker);
        uint256 tokenId = votingEscrow.create_lock_for(amount, duration, recipient);
    }
}
