// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract SetArtProxy is VotingEscrowTest {

    function test_setArtProxy_Normal() public {
      vm.prank(owner);
      votingEscrow.setArtProxy(address(alice));
      assertEq(votingEscrow.artProxy(), address(alice), "Team is not alice");
    }

    function test_setArtProxy_NotOwner() public {
      vm.prank(alice);
      vm.expectRevert();
      votingEscrow.setArtProxy(address(alice));
    }
}