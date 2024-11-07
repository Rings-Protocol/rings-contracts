// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract Detach is VotingEscrowTest {
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

    function testFuzz_detach_Normal(uint256 tokenId) public {
        vm.prank(voter);
        votingEscrow.attach(tokenId);
        vm.prank(voter);
        votingEscrow.detach(tokenId);
        assertEq(votingEscrow.attachments(tokenId), 0, "Number of detachments is not 0");
    }

    function testFuzz_detach_multiple(uint256 tokenId, uint16 multiple) public {
        vm.startPrank(voter);

        for (uint256 i = 0; i < multiple; i++) {
            votingEscrow.attach(tokenId);
        }
        for (uint256 i = 0; i < multiple; i++) {
            votingEscrow.detach(tokenId);
        }

        vm.stopPrank();

        assertEq(votingEscrow.attachments(tokenId), 0, "Number of detachments is not 0");
    }

    //TODO no token

    function testFuzz_detach_NotVoter(uint256 tokenId) public {
        vm.prank(alice);
        vm.expectRevert();
        votingEscrow.detach(tokenId);
    }
}
