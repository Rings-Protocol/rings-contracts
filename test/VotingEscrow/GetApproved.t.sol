// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract GetApproved is VotingEscrowTest {
  uint internal constant MAXTIME = 2 * 365 * 86400;

    function testFuzz_getApproved_Normal(address pranker, uint256 amount, uint256 duration) public {
      vm.assume(pranker != address(0));
      vm.assume(amount > 0);
      vm.assume(amount < 10e25);
      vm.assume(duration > 7 * 86400);
      vm.assume(duration < MAXTIME);

      uint256 tokenId = createLockPranked(pranker, amount, duration);
      approvePranked(pranker, alice, tokenId);
      assertEq(votingEscrow.getApproved(tokenId), alice, "Approved should be alice");
    }

    function testFuzz_getApproved_NotApproved(uint256 amount, uint256 duration) public {
      vm.assume(amount > 0);
      vm.assume(amount < 10e25);
      vm.assume(duration > 7 * 86400);
      vm.assume(duration < MAXTIME);

      uint256 tokenId = createLockPranked(alice, amount, duration);
      assertEq(votingEscrow.getApproved(tokenId), zero, "Approved should be zero");
    }

    function test_getApproved_ZeroToken() public view {
      assertEq(votingEscrow.getApproved(0), zero, "Approved of zero token should be zero");
    }
}