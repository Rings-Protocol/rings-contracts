// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract TotalSupplyAt is VotingEscrowTest {

  uint internal constant MAXTIME = 2 * 365 * 86400;
  uint internal constant WEEK = 7 * 86400;

    function testFuzz_totalSupplyAt_Simple(address pranker, uint256 amount, uint256 duration, uint256 wait, uint8 nbToken) public {
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

      vm.roll(block.number + (wait / 15)); // 15 seconds per block, can be changed without incidence on the test
      vm.warp(block.timestamp + wait);
      
      uint256 lockedEnd = votingEscrow.locked__end(tokenId);
      uint256 slope = amount / MAXTIME;
      uint256 bias = slope * (lockedEnd - startTimestamp);
      uint256 estimated = bias - (slope * wait);

      assertApproxEqRel(votingEscrow.totalSupplyAt(block.number), estimated * nbToken, 10e12); // 0.000001% error
    }

    function testFuzz_totalSupplyAt_Expired(address pranker, uint256 amount, uint256 duration) public {
      vm.assume(pranker != address(0));
      amount = bound(amount, 1, 10e25);
      duration = bound(duration, 7 * 86400, MAXTIME - 7 * 86400);

      createLockPranked(pranker, amount, duration);

      vm.roll(block.number + (duration / 15)); // 15 seconds per block, can be changed without incidence on the test
      vm.warp(block.timestamp + duration);
      
      assertEq(votingEscrow.totalSupplyAt(block.number), 0, "Supply should be 0");
    }

    function testFuzz_totalSupplyAt_NoToken(uint256 currentBlock, uint256 queryBlock) public {
      vm.assume(currentBlock > 1);
      queryBlock = bound(queryBlock, 1, currentBlock - 1);

      vm.roll(currentBlock);
      
      assertEq(votingEscrow.totalSupplyAt(queryBlock), 0, "Supply should be 0");
    }
}