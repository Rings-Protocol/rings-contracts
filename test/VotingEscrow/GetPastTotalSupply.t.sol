// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract GetPastTotalSupply is VotingEscrowTest {

  uint internal constant MAXTIME = 2 * 365 * 86400;
  uint internal constant WEEK = 7 * 86400;

    function testFuzz_getPastTotalSupply_Simple(address pranker, uint256 amount, uint256 duration, uint256 wait) public {
      vm.assume(pranker != address(0));
      amount = bound(amount, 1, 10e25);
      duration = bound(duration, 7 * 86400 + 1, MAXTIME);
      wait = bound(wait, 1, duration - 7 days);

      uint256 startTimestamp = block.timestamp;
      uint256 tokenId = createLockPranked(pranker, amount, duration);
      
      uint256 lockedEnd = votingEscrow.locked__end(tokenId);
      uint256 slope = amount / MAXTIME;
      uint256 bias = slope * (lockedEnd - startTimestamp);
      uint256 estimated = bias - (slope * wait);
      assertEq(votingEscrow.getPastTotalSupply(block.timestamp + wait), estimated, "Balance should be amount");
    }

    function testFuzz_getPastTotalSupply_Expired(address pranker, uint256 amount, uint256 duration) public {
      vm.assume(pranker != address(0));
      amount = bound(amount, 1, 10e25);
      duration = bound(duration, 7 * 86400, MAXTIME - 7 * 86400);

      createLockPranked(pranker, amount, duration);
      
      assertEq(votingEscrow.getPastTotalSupply(block.timestamp + duration), 0, "Balance should be 0");
    }

    function testFuzz_getPastTotalSupply_Invalid(uint256 timestamp, uint256 currentTimestamp) public {
      vm.assume(currentTimestamp > 0);
      timestamp = bound(timestamp, 1, currentTimestamp);

      vm.warp(currentTimestamp);

      assertEq(votingEscrow.getPastTotalSupply(timestamp), 0, "Balance should be 0");
    }
}