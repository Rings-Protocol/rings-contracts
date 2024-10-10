// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract TokenURI is VotingEscrowTest {

  uint internal constant MAXTIME = 2 * 365 * 86400;

    function testFuzz_tokenURI_Normal(address pranker, uint256 amount, uint256 duration) public {
      vm.assume(pranker != address(0));
      vm.assume(amount > 0);
      vm.assume(duration > 7 * 86400);
      vm.assume(duration < MAXTIME);

      uint256 tokenId = createLockPranked(pranker, amount, duration);
      string memory ret = votingEscrow.tokenURI(tokenId);
      assertTrue(bytes(ret).length > 0, "Token URI should not be empty");
    }

    function testFuzz_tokenURI_ZeroToken(address pranker, uint256 amount, uint256 duration) public {
      vm.assume(pranker != address(0));
      vm.assume(amount > 0);
      vm.assume(duration > 7 * 86400);
      vm.assume(duration < MAXTIME);

      createLockPranked(pranker, amount, duration);
      vm.expectRevert();
      votingEscrow.tokenURI(0);
    }

    function testFuzz_tokenURI_InvalidId(address pranker, uint256 tokenId) public {
      vm.assume(pranker != address(0));
      vm.expectRevert();
      vm.prank(pranker);
      votingEscrow.tokenURI(tokenId);
    }
}