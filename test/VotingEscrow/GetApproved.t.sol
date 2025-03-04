// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract GetApproved is VotingEscrowTest {
    uint256 internal constant MAXTIME = 52 weeks;

    function testFuzz_getApproved_Normal(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);
        approvePranked(pranker, alice, tokenId);
        assertEq(votingEscrow.getApproved(tokenId), alice, "Approved should be alice");
    }

    function testFuzz_getApproved_NotApproved(uint256 amount, uint256 duration) public {
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(alice, amount, duration);
        assertEq(votingEscrow.getApproved(tokenId), zero, "Approved should be zero");
    }

    function test_getApproved_ZeroToken() public view {
        assertEq(votingEscrow.getApproved(0), zero, "Approved of zero token should be zero");
    }
}
