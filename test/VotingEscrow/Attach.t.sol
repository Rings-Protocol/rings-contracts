// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract Attach is VotingEscrowTest {
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

    function testFuzz_attach_Normal(uint256 tokenId) public {
        vm.prank(voter);
        votingEscrow.attach(tokenId);
        assertEq(votingEscrow.attachments(tokenId), 1, "Number of attachments is not 1");
    }

    function testFuzz_attach_multiple(uint256 tokenId, uint16 multiple) public {
        vm.startPrank(voter);

        for (uint256 i = 0; i < multiple; i++) {
            votingEscrow.attach(tokenId);
        }

        vm.stopPrank();

        assertEq(votingEscrow.attachments(tokenId), multiple, "Number of attachments is not multiple");
    }

    function testFuzz_attach_NotVoter(uint256 tokenId) public {
        vm.prank(alice);
        vm.expectRevert();
        votingEscrow.attach(tokenId);
    }
}
