// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract TransferFrom is VotingEscrowTest {
    uint256 internal constant MAXTIME = 2 * 365 * 86_400;

    function testFuzz_transferFrom_owner(uint256 amount, uint256 duration) public {
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(alice, amount, duration);

        vm.prank(alice);
        votingEscrow.transferFrom(alice, bob, tokenId);

        assertEq(votingEscrow.ownerOf(tokenId), bob, "Bob should be new owner");
    }

    function testFuzz_transferFrom_approved(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(alice, amount, duration);
        approvePranked(alice, pranker, tokenId);

        vm.prank(pranker);
        votingEscrow.transferFrom(alice, bob, tokenId);

        assertEq(votingEscrow.ownerOf(tokenId), bob, "Bob should be new owner");
    }

    function testFuzz_transferFrom_approvedForAll(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(alice, amount, duration);
        setApprovalForAllPranked(alice, pranker, true);

        vm.prank(pranker);
        votingEscrow.transferFrom(alice, bob, tokenId);

        assertEq(votingEscrow.ownerOf(tokenId), bob, "Bob should be new owner");
    }

    function testFuzz_transferFrom_bothApproved(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(alice, amount, duration);
        approvePranked(alice, pranker, tokenId);
        setApprovalForAllPranked(alice, pranker, true);

        vm.prank(pranker);
        votingEscrow.transferFrom(alice, bob, tokenId);

        assertEq(votingEscrow.ownerOf(tokenId), bob, "Bob should be new owner");
    }

    function testFuzz_transferFrom_ApprovalReset(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);
        approvePranked(pranker, alice, tokenId);
        approvePranked(pranker, zero, tokenId);

        vm.expectRevert();
        vm.prank(alice);
        votingEscrow.transferFrom(pranker, bob, tokenId);
    }

    function testFuzz_transferFrom_ApprovalForAllReset(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);
        setApprovalForAllPranked(pranker, alice, true);
        setApprovalForAllPranked(pranker, alice, false);

        vm.expectRevert();
        vm.prank(alice);
        votingEscrow.transferFrom(pranker, bob, tokenId);
    }

    function testFuzz_transferFrom_bothApprovalReset(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);
        approvePranked(pranker, alice, tokenId);
        approvePranked(pranker, zero, tokenId);
        setApprovalForAllPranked(pranker, alice, true);
        setApprovalForAllPranked(pranker, alice, false);

        vm.expectRevert();
        vm.prank(alice);
        votingEscrow.transferFrom(pranker, bob, tokenId);
    }
}
