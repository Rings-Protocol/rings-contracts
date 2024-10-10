// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract SetTeam is VotingEscrowTest {

    function test_setTeam_Normal() public {
      vm.prank(owner);
      votingEscrow.setTeam(address(alice));
      assertEq(votingEscrow.team(), address(alice), "Team is not alice");
    }

    function test_setTeam_NotOwner() public {
      vm.prank(alice);
      vm.expectRevert();
      votingEscrow.setTeam(address(alice));
    }
}