// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract BalanceOfAtNFT is VotingEscrowTest {
    uint256 internal constant MAXTIME = 2 * 365 * 86_400;
    uint256 internal constant WEEK = 7 * 86_400;

    function testFuzz_balanceOfAtNFT_Simple(address pranker, uint256 amount, uint256 duration, uint256 wait) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400 + 1, MAXTIME);
        wait = bound(wait, 1, duration - 7 days);

        uint256 startTimestamp = block.timestamp;
        uint256 tokenId = createLockPranked(pranker, amount, duration);

        vm.roll(block.number + (wait / 15)); // 15 seconds per block, can be changed without incidence on the test
        vm.warp(block.timestamp + wait);

        uint256 lockedEnd = votingEscrow.locked__end(tokenId);
        uint256 slope = amount / MAXTIME;
        uint256 bias = slope * (lockedEnd - startTimestamp);
        uint256 estimated = bias - (slope * wait);
        assertApproxEqRel(votingEscrow.balanceOfAtNFT(tokenId, block.number), estimated, 10e12); // 0.000001% error
    }

    function testFuzz_balanceOfAtNFT_NoToken(uint256 tokenId, uint256 currentBlock, uint256 queryBlock) public {
        vm.assume(currentBlock > 1);
        queryBlock = bound(queryBlock, 1, currentBlock - 1);

        vm.roll(currentBlock);

        assertEq(votingEscrow.balanceOfAtNFT(tokenId, queryBlock), 0, "Balance should be 0");
    }

    function testFuzz_balanceOfAtNFT_FutureBlock(uint256 tokenId, uint256 blockNumber) public {
        blockNumber = bound(blockNumber, block.number + 1, 10_000_000_000_000_000);
        vm.expectRevert();
        votingEscrow.balanceOfAtNFT(tokenId, blockNumber);
    }
}
