// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract IsApprovedOrOwner is VotingEscrowTest {
    uint256 internal constant MAXTIME = 52 weeks;

    function testFuzz_isApprovedOrOwner_approved(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);
        approvePranked(pranker, alice, tokenId);
        assertTrue(votingEscrow.isApprovedOrOwner(alice, tokenId), "Alice should be approved");
    }

    function testFuzz_isApprovedOrOwner_approvedForAll(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);
        setApprovalForAllPranked(pranker, alice, true);
        assertTrue(votingEscrow.isApprovedOrOwner(alice, tokenId), "Alice should be approved");
    }

    function testFuzz_isApprovedOrOwner_bothApproved(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);
        approvePranked(pranker, alice, tokenId);
        setApprovalForAllPranked(pranker, alice, true);
        assertTrue(votingEscrow.isApprovedOrOwner(alice, tokenId), "Alice should be approved");
    }

    function testFuzz_isApprovedOrOwner_ApprovalReset(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);
        approvePranked(pranker, alice, tokenId);
        approvePranked(pranker, zero, tokenId);
        assertFalse(votingEscrow.isApprovedOrOwner(alice, tokenId), "Alice should not be approved");
    }

    function testFuzz_isApprovedOrOwner_ApprovalForAllReset(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);
        setApprovalForAllPranked(pranker, alice, true);
        setApprovalForAllPranked(pranker, alice, false);
        assertFalse(votingEscrow.isApprovedOrOwner(alice, tokenId), "Alice should not be approved");
    }

    function testFuzz_isApprovedOrOwner_bothApprovalReset(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);
        approvePranked(pranker, alice, tokenId);
        approvePranked(pranker, zero, tokenId);
        setApprovalForAllPranked(pranker, alice, true);
        setApprovalForAllPranked(pranker, alice, false);
        assertFalse(votingEscrow.isApprovedOrOwner(alice, tokenId), "Alice should not be approved");
    }
}
