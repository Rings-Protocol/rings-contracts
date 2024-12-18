// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract Delegate is VotingEscrowTest {
    uint256 internal constant MAXTIME = 52 weeks;
    uint256 internal constant WEEK = 7 * 86_400;

    function testFuzz_delegate_Normal(address pranker, uint256 amount, uint256 duration, address delegate) public {
        vm.assume(pranker != address(0));
        vm.assume(delegate != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400 + 1, MAXTIME);

        uint256 tokenId = createLockPranked(pranker, amount, duration);

        vm.prank(pranker);
        votingEscrow.delegate(address(delegate));

        uint256 kappa = votingEscrow.checkpoints(delegate, 0);
        console.log("kappa", kappa);

        assertEq(votingEscrow.delegates(pranker), address(delegate), "Delegate is not delegate");
        assertEq(votingEscrow.numCheckpoints(delegate), 1, "Delegate has no checkpoints");
        //assertEq(ts, vm.getBlockTimestamp(), "Timestamp is not vm.getBlockTimestamp()");
        // assertEq(tokens[0], tokenId, "Balance is not balanceOf");
        //assertEq(tokens.length, 1, "Tokens length is not 1");
    }

    function testFuzz_delegate_Reset(address pranker, uint256 amount, uint256 duration, uint256 wait, address delegate)
        public
    {
        vm.assume(pranker != address(0));
        vm.assume(delegate != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400 + 1, MAXTIME);
        wait = bound(wait, 1, duration - 7 days);

        uint256 tokenId = createLockPranked(pranker, amount, duration);

        vm.prank(pranker);
        votingEscrow.delegate(delegate);

        //VotingEscrow.Checkpoint memory checkpoint = votingEscrow.checkpoints(delegate, 0);

        assertEq(votingEscrow.delegates(pranker), delegate, "Delegate is not delegate");
        assertEq(votingEscrow.numCheckpoints(delegate), 1, "Delegate has one checkpoints");
        //assertEq(checkpoint.timestamp, vm.getBlockTimestamp(), "Timestamp is not vm.getBlockTimestamp()");
        //assertEq(checkpoint.tokenIds[0], tokenId, "Balance is not balanceOf");
        //assertEq(checkpoint.tokenIds.length, 1, "Tokens length is not 1");

        vm.warp(vm.getBlockTimestamp() + wait);

        vm.prank(pranker);
        votingEscrow.delegate(pranker);

        //VotingEscrow.Checkpoint memory prankerCheckpoint = votingEscrow.checkpoints(pranker, 0);

        assertEq(votingEscrow.delegates(pranker), pranker, "Pranker is not delegate");
        assertEq(votingEscrow.numCheckpoints(pranker), 3, "Pranker has 3 checkpoints");
        //assertEq(prankerCheckpoint.timestamp, vm.getBlockTimestamp() + wait, "Timestamp is not
        // vm.getBlockTimestamp()");
        //assertEq(prankerCheckpoint.tokenIds[0], tokenId, "Balance is not balanceOf");
        //assertEq(prankerCheckpoint.tokenIds.length, 1, "Tokens length is not 1");
    }
}
