// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract Abstain is VotingEscrowTest {
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

    function testFuzz_abstain_Normal(uint256 tokenId) public {
        vm.prank(voter);
        votingEscrow.abstain(tokenId);
        assertEq(votingEscrow.voted(tokenId), false, "Voted is not false");
    }

    function testFuzz_abstain_NotVoter(uint256 tokenId) public {
        vm.prank(alice);
        vm.expectRevert();
        votingEscrow.abstain(tokenId);
    }
}
