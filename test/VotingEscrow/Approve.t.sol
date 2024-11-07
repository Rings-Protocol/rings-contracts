// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract Approve is VotingEscrowTest {
    uint256 internal constant MAXTIME = 2 * 365 * 86_400;

    function testFuzz_approve_Normal(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);
        vm.prank(pranker);
        votingEscrow.approve(alice, tokenId);
        assertEq(votingEscrow.getApproved(tokenId), alice, "Approved should be alice");
    }

    function testFuzz_approve_ResetApproval(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);
        vm.prank(pranker);
        votingEscrow.approve(alice, tokenId);
        vm.prank(pranker);
        votingEscrow.approve(zero, tokenId);
        assertEq(votingEscrow.getApproved(tokenId), zero, "Approved should be zero");
    }
}
