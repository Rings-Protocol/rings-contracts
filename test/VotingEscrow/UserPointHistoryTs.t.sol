// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract UserPointHistoryTs is VotingEscrowTest {

  uint internal constant MAXTIME = 2 * 365 * 86400;

    function testFuzz_userPointHistoryTs_LockStart(address pranker, uint256 amount, uint256 duration) public {
      vm.assume(pranker != address(0));
      amount = bound(amount, 1, 10e25);
      duration = bound(duration, 7 * 86400, MAXTIME);

      uint256 tokenId = createLockPranked(pranker, amount, duration);
      uint256 idx = votingEscrow.user_point_epoch(tokenId);
      
      assertEq(votingEscrow.user_point_history__ts(tokenId, idx), block.timestamp, "Value should be current timestamp");
    }

    function testFuzz_userPointHistoryTs_LockMiddle(address pranker, uint256 amount, uint256 duration, uint8 waitWeeks) public {
      vm.assume(pranker != address(0));
      amount = bound(amount, 1, 10e25);
      duration = bound(duration, 7 * 86400, MAXTIME);
      waitWeeks = uint8(bound(waitWeeks, 1, duration / (7 * 86400)));

      uint256 tokenId = createLockPranked(pranker, amount, duration);
      uint256 timestamp = block.timestamp;

      vm.warp(block.timestamp + uint256(waitWeeks) * 7 * 86400);
      votingEscrow.checkpoint();
      uint256 idx = votingEscrow.user_point_epoch(tokenId);
      
      assertEq(votingEscrow.user_point_history__ts(tokenId, idx), timestamp, "Value should be current timestamp");
    }

    function testFuzz_userPointHistoryTs_Invalid(uint256 tokenId, uint256 idx) public {
      idx = bound(idx, 0, 1000000000 - 1);

      assertEq(votingEscrow.user_point_history__ts(tokenId, idx), 0, "Ts should be 0");
    }
}