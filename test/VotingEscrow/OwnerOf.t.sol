// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract OwnerOf is VotingEscrowTest {

  uint internal constant MAXTIME = 2 * 365 * 86400;

    function testFuzz_ownerOf_Normal(address pranker, uint256 amount, uint256 duration) public {
      vm.assume(pranker != address(0));
      amount = bound(amount, 1, 10e25);
      duration = bound(duration, 7 * 86400, MAXTIME);

      uint256 tokenId = createLockPranked(pranker, amount, duration);
      assertEq(votingEscrow.ownerOf(tokenId), pranker, "Owner of token should be pranker");
    }

    function testFuzz_ownerOf_InvalidToken(address pranker, uint256 tokenId) public {
      vm.assume(pranker != address(0));

      vm.prank(pranker);
      assertEq(votingEscrow.ownerOf(tokenId), zero, "Owner of token should be zero");
    }

    function testFuzz_ownerOf_ZeroToken(address pranker) public {
      vm.assume(pranker != address(0));
      vm.prank(pranker);
      assertEq(votingEscrow.ownerOf(0), zero, "Owner of token should be zero");
    }
}