// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract SetVoter is VotingEscrowTest {
    address internal team;

    function setUp() public override {
      super.setUp();

      team = makeAddr("team");
      vm.prank(owner);
      votingEscrow.setTeam(team);
    }

    function test_setVoter_Normal() public {
      vm.prank(team);
      votingEscrow.setVoter(address(alice));
      assertEq(votingEscrow.voter(), address(alice), "Voter is not alice");
    }

    function test_setVoter_NotOwner() public {
      vm.prank(alice);
      vm.expectRevert();
      votingEscrow.setVoter(address(alice));
    }
}