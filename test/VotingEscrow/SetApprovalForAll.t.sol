// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract SetApprovalForAll is VotingEscrowTest {
  uint internal constant MAXTIME = 2 * 365 * 86400;

    function testFuzz_setApprovalForAll_Normal(address pranker, uint256 amount, uint256 duration) public {
      vm.assume(pranker != address(0));
      amount = bound(amount, 1, 10e25);
      duration = bound(duration, 7 * 86400, MAXTIME);

      uint256 tokenId = createLockPranked(pranker, amount, duration);
      uint256 tokenId2 = createLockPranked(pranker, amount, duration);
      vm.prank(pranker);
      votingEscrow.setApprovalForAll(alice, true);
      assertTrue(votingEscrow.isApprovedForAll(pranker, alice), "Approved should be alice");
    }

    function testFuzz_setApprovalForAll_NotApproved(address pranker, uint256 amount, uint256 duration) public {
      vm.assume(pranker != address(0));
      amount = bound(amount, 1, 10e25);
      duration = bound(duration, 7 * 86400, MAXTIME);

      uint256 tokenId = createLockPranked(pranker, amount, duration);
      uint256 tokenId2 = createLockPranked(pranker, amount, duration);
      vm.prank(pranker);
      votingEscrow.setApprovalForAll(alice, false);
      assertFalse(votingEscrow.isApprovedForAll(pranker, alice), "Alice should not be approved");
    }

    function testFuzz_setApprovalForAll_ApprovalReset(address pranker, uint256 amount, uint256 duration) public {
      vm.assume(pranker != address(0));
      amount = bound(amount, 1, 10e25);
      duration = bound(duration, 7 * 86400, MAXTIME);

      uint256 tokenId = createLockPranked(pranker, amount, duration);
      uint256 tokenId2 = createLockPranked(pranker, amount, duration);
      vm.prank(pranker);
      votingEscrow.setApprovalForAll(alice, true);
      vm.prank(pranker);
      votingEscrow.setApprovalForAll(alice, false);
      assertFalse(votingEscrow.isApprovedForAll(pranker, alice), "Alice should not be approved");
    }
}