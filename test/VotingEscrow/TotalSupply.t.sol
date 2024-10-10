// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract TotalSupply is VotingEscrowTest {

  uint internal constant MAXTIME = 2 * 365 * 86400;
  uint internal constant WEEK = 7 * 86400;

    function testFuzz_totalSupply_Simple(address pranker, uint256 amount, uint256 duration, uint256 wait, uint8 nbToken) public {
      vm.assume(pranker != address(0));
      vm.assume(nbToken > 0);
      amount = bound(amount, 1, 10e25);
      duration = bound(duration, 7 * 86400 + 1, MAXTIME);
      wait = bound(wait, 1, duration - 7 days);
      uint256 tokenId;

      uint256 startTimestamp = block.timestamp;

      for (uint8 i = 0; i < nbToken; i++) {
        tokenId = createLockPranked(pranker, amount, duration);
      }
      
      uint256 lockedEnd = votingEscrow.locked__end(tokenId);
      uint256 slope = amount / MAXTIME;
      uint256 bias = slope * (lockedEnd - startTimestamp);
      uint256 estimated = bias - (slope * wait);

      vm.warp(block.timestamp + wait);

      assertEq(votingEscrow.totalSupply(), estimated * nbToken, "Supply should be amount");
    }

    function testFuzz_totalSupply_Expired(address pranker, uint256 amount, uint256 duration) public {
      vm.assume(pranker != address(0));
      amount = bound(amount, 1, 10e25);
      duration = bound(duration, 7 * 86400, MAXTIME - 7 * 86400);

      createLockPranked(pranker, amount, duration);

      vm.warp(block.timestamp + duration);
      
      assertEq(votingEscrow.totalSupply(), 0, "Supply should be 0");
    }

    function testFuzz_totalSupply_Invalid() public view {
      assertEq(votingEscrow.totalSupply(), 0, "Supply should be 0");
    }
}