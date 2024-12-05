// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";
import { SafeCastLib } from "solady/utils/SafeCastLib.sol";

contract Withdraw is VotingEscrowTest {
    uint256 internal constant MAXTIME = 52 weeks;
    uint256 internal constant WEEK = 7 * 86_400;

    function testFuzz_withdraw_simple(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 timestamp = vm.getBlockTimestamp();
        uint256 tokenId = createLockPranked(pranker, amount, duration);

        vm.warp(vm.getBlockTimestamp() + duration + 1);

        vm.prank(pranker);
        votingEscrow.withdraw(tokenId);

        assertEq(votingEscrow.balanceOf(pranker), 0, "Balance should be 0");
        assertEq(votingEscrow.totalSupply(), 0, "Total supply should be 0");
        assertEq(scUSD.balanceOf(pranker), amount, "Balance should be equal to amount");
        assertEq(votingEscrow.locked__end(tokenId), 0, "End should be 0");
    }

    function testFuzz_withdraw_InvalidToken(uint256 tokenId) public {
        vm.expectRevert();
        votingEscrow.withdraw(tokenId);
    }

    function testFuzz_withdraw_notExpired(address pranker, uint256 amount, uint256 duration, uint256 waitDuration)
        public
    {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400 + 1, MAXTIME);
        waitDuration = bound(waitDuration, 0, duration - 7 days);

        uint256 tokenId = createLockPranked(pranker, amount, duration);

        vm.warp(vm.getBlockTimestamp() + waitDuration);

        vm.expectRevert();
        vm.prank(pranker);
        votingEscrow.withdraw(tokenId);
    }

    function testFuzz_withdraw_notOwner(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 timestamp = vm.getBlockTimestamp();
        uint256 tokenId = createLockPranked(alice, amount, duration);

        vm.warp(vm.getBlockTimestamp() + duration + 1);

        vm.expectRevert();
        vm.prank(pranker);
        votingEscrow.withdraw(tokenId);
    }
}
