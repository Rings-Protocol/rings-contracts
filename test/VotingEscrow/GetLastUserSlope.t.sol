// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";
import "solady/utils/SafeCastLib.sol";

contract GetLastUserSlope is VotingEscrowTest {
    uint256 internal constant MAXTIME = 2 * 365 * 86_400;

    function testFuzz_getLastUserSlope_LockStart(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);

        assertEq(
            votingEscrow.get_last_user_slope(tokenId),
            SafeCastLib.toInt128(amount / MAXTIME),
            "Value should be amount / max duration"
        );
    }

    function testFuzz_getLastUserSlope_LockMiddle(address pranker, uint256 amount, uint256 duration, uint8 waitWeeks)
        public
    {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);
        waitWeeks = uint8(bound(waitWeeks, 1, duration / (7 * 86_400)));

        uint256 tokenId = createLockPranked(pranker, amount, duration);

        vm.warp(vm.getBlockTimestamp() + uint256(waitWeeks) * 7 * 86_400);
        votingEscrow.checkpoint();

        assertEq(
            votingEscrow.get_last_user_slope(tokenId),
            SafeCastLib.toInt128(amount / MAXTIME),
            "Value should be amount / max duration"
        );
    }

    function testFuzz_getLastUserSlope_InvalidToken(uint256 tokenId) public {
        assertEq(votingEscrow.get_last_user_slope(tokenId), 0, "Slope should be 0");
    }
}
