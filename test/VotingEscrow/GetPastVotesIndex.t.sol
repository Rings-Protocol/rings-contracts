// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract GetPastVotesIndex is VotingEscrowTest {
  uint internal constant MAXTIME = 2 * 365 * 86400;
  uint internal constant WEEK = 7 * 86400;

    function test_getPastVotesIndex_NoCheckpoint(address pranker) public {
      assertEq(votingEscrow.getPastVotesIndex(pranker, block.timestamp), 0, "Index should be 0");
    }

    function test_getPastVotesIndex_BeforeCheckpoint(address pranker, uint256 amount, uint256 duration, uint256 wait) public {
      vm.assume(pranker != address(0));
      amount = bound(amount, 1, 10e25);
      duration = bound(duration, 7 * 86400 + 1, MAXTIME);
      wait = bound(wait, 7 * 86400, MAXTIME);

      uint256 startTimestamp = block.timestamp;

      vm.warp(block.timestamp + wait);

      uint256 tokenId = createLockPranked(pranker, amount, duration);

      assertEq(votingEscrow.getPastVotesIndex(pranker, startTimestamp), 0, "Index should be 0");
    }

    function test_getpastvotesindex_LastCheckpoint(address pranker, uint256 amount, uint256 duration, uint256 wait) public {
      vm.assume(pranker != address(0));
      amount = bound(amount, 1, 10e25);
      duration = bound(duration, 7 * 86400 + 1, MAXTIME);
      wait = bound(wait, 1, duration - 7 days);

      uint256 startTimestamp = block.timestamp;
      uint256 tokenId = createLockPranked(pranker, amount, duration);

      vm.warp(block.timestamp + wait);
      assertEq(votingEscrow.getPastVotesIndex(pranker, block.timestamp), 0, "Index should be 0");
    }

    function test_getpastvotesindex_IntermediateCheckpoint(address pranker, uint256 amount, uint256 duration, uint256 wait) public {
      vm.assume(pranker != address(0));
      amount = bound(amount, 1, 10e25);
      duration = bound(duration, 7 * 86400 + 2, MAXTIME);
      wait = bound(wait, 1, (duration - 7 days) / 2);

      uint256 startTimestamp = block.timestamp;
      uint256 tokenId = createLockPranked(pranker, amount, duration);

      vm.warp(block.timestamp + wait * 2);

      vm.prank(pranker);
      votingEscrow.delegate(address(bob));

      uint256 numCheckpoints = votingEscrow.numCheckpoints(bob);
      console.log(numCheckpoints);
      (uint256 ts) = votingEscrow.checkpoints(bob, 1);
      console.log(ts);

      assertEq(votingEscrow.getPastVotesIndex(bob, startTimestamp +  wait), 0, "Index should be 0");
    }
}