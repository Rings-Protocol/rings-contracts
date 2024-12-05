// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";
import { SafeCastLib } from "solady/utils/SafeCastLib.sol";

contract IncreaseAmount is VotingEscrowTest {
    uint256 internal constant MAXTIME = 52 weeks;
    uint256 internal constant WEEK = 7 * 86_400;

    function testFuzz_increaseAmount_simple(address pranker, uint256 amount, uint256 secondAmount, uint256 duration)
        public
    {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        secondAmount = bound(secondAmount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);

        dealApproveAsset(pranker, secondAmount);
        vm.prank(pranker);
        votingEscrow.increase_amount(tokenId, secondAmount);

        (int128 balance,) = votingEscrow.locked(tokenId);
        assertEq(balance, SafeCastLib.toInt128(amount + secondAmount), "Value should be sum of amounts");
    }

    function testFuzz_increaseAmount_InvalidToken(uint256 tokenId) public {
        vm.expectRevert();
        votingEscrow.increase_amount(tokenId, 1);
    }

    function testFuzz_increaseAmount_InvalidAmount(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);

        vm.expectRevert();
        votingEscrow.increase_amount(tokenId, 0);
    }

    function testFuzz_increaseAmount_Expired(address pranker, uint256 amount, uint256 secondAmount, uint256 duration)
        public
    {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        secondAmount = bound(secondAmount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);

        vm.warp(vm.getBlockTimestamp() + duration + 1);

        dealApproveAsset(pranker, secondAmount);
        vm.prank(pranker);
        vm.expectRevert();
        votingEscrow.increase_amount(tokenId, secondAmount);
    }
}
