// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";
import "../mocks/InvalidReceiver.sol";

contract SafeTransferFrom is VotingEscrowTest {
    uint256 internal constant MAXTIME = 2 * 365 * 86_400;

    function testFuzz_safeTransferFrom_owner(uint256 amount, uint256 duration) public {
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(alice, amount, duration);

        vm.prank(alice);
        votingEscrow.safeTransferFrom(alice, bob, tokenId);

        assertEq(votingEscrow.ownerOf(tokenId), bob, "Bob should be new owner");
    }

    function testFuzz_safeTransferFrom_approved(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(alice, amount, duration);
        approvePranked(alice, pranker, tokenId);

        vm.prank(pranker);
        votingEscrow.safeTransferFrom(alice, bob, tokenId);

        assertEq(votingEscrow.ownerOf(tokenId), bob, "Bob should be new owner");
    }

    function testFuzz_safeTransferFrom_approvedForAll(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(alice, amount, duration);
        setApprovalForAllPranked(alice, pranker, true);

        vm.prank(pranker);
        votingEscrow.safeTransferFrom(alice, bob, tokenId);

        assertEq(votingEscrow.ownerOf(tokenId), bob, "Bob should be new owner");
    }

    function testFuzz_safeTransferFrom_bothApproved(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(alice, amount, duration);
        approvePranked(alice, pranker, tokenId);
        setApprovalForAllPranked(alice, pranker, true);

        vm.prank(pranker);
        votingEscrow.safeTransferFrom(alice, bob, tokenId);

        assertEq(votingEscrow.ownerOf(tokenId), bob, "Bob should be new owner");
    }

    function testFuzz_safeTransferFrom_ApprovalReset(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);
        approvePranked(pranker, alice, tokenId);
        approvePranked(pranker, zero, tokenId);

        vm.expectRevert();
        vm.prank(alice);
        votingEscrow.safeTransferFrom(pranker, bob, tokenId);
    }

    function testFuzz_safeTransferFrom_ApprovalForAllReset(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);
        setApprovalForAllPranked(pranker, alice, true);
        setApprovalForAllPranked(pranker, alice, false);

        vm.expectRevert();
        vm.prank(alice);
        votingEscrow.safeTransferFrom(pranker, bob, tokenId);
    }

    function testFuzz_safeTransferFrom_bothApprovalReset(address pranker, uint256 amount, uint256 duration) public {
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
        votingEscrow.safeTransferFrom(pranker, bob, tokenId);
    }

    function testFuzz_safeTransferFrom_invalidReceiver(uint256 amount, uint256 duration) public {
        uint256 tokenId = createLockPranked(alice, 1e18, 180 * 86_400);
        InvalidReceiver invalidReceiver = new InvalidReceiver();

        vm.prank(alice);
        vm.expectRevert();
        votingEscrow.safeTransferFrom(alice, address(invalidReceiver), tokenId);
    }
}
