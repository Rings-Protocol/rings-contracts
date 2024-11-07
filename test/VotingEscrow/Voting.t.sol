// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract Voting is VotingEscrowTest {
    address internal team;
    address internal voter;

    function setUp() public override {
      super.setUp();

      team = makeAddr("team");
      voter = makeAddr("voter");

      vm.prank(owner);
      votingEscrow.setTeam(team);
      vm.prank(team);
      votingEscrow.setVoter(address(voter));
    }

    function testFuzz_voting_Normal(uint256 tokenId) public {
      vm.prank(voter);
      votingEscrow.voting(tokenId);
      assertEq(votingEscrow.voted(tokenId), true, "Voted is not true");
    }

    function testFuzz_voting_NotVoter(uint256 tokenId) public {
      vm.prank(alice);
      vm.expectRevert();
      votingEscrow.voting(tokenId);
    }
}