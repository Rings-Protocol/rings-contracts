// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract BalanceOf is VotingEscrowTest {

  uint internal constant MAXTIME = 2 * 365 * 86400;

    function testFuzz_balanceOf_multiple(address pranker, uint256 amount, uint256 duration, uint8 nftNumber) public {
      vm.assume(pranker != address(0));
      amount = bound(amount, 1, 10e25);
      duration = bound(duration, 7 * 86400, MAXTIME);

      for (uint256 i = 0; i < nftNumber; ++i) {
        createLockPranked(pranker, 1e18, duration);
      }
      assertEq(votingEscrow.balanceOf(pranker), uint(nftNumber), "Owner of token should be pranker");
    }

    function testFuzz_balanceOf_InvalidOwner(address pranker) public view {
      assertEq(votingEscrow.balanceOf(pranker), 0, "Balance of invalid owner should be zero");
    }

    function test_balanceOf_ZeroOwner() public view {
      assertEq(votingEscrow.balanceOf(zero), 0, "Balance of zero owner should be zero");
    }
}