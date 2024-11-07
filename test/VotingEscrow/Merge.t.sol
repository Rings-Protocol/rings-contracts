// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract Merge is VotingEscrowTest {
    uint256 internal constant MAXTIME = 2 * 365 * 86_400;
    uint256 internal constant WEEK = 7 * 86_400;

    function testFuzz_merge_Normal(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);

        uint256 from = createLockPranked(pranker, amount, duration);
        uint256 to = createLockPranked(pranker, amount, duration);

        vm.prank(pranker);
        votingEscrow.merge(from, to);
        (int128 balance, uint256 end) = votingEscrow.locked(to);
        assertEq(uint256(uint128(balance)), amount * 2, "Balance should be doubled");
        assertEq(end, (block.timestamp + duration) / WEEK * WEEK, "End should be the same");
    }

    function testFuzz_merge_Longer(address pranker, uint256 amount, uint256 duration, uint256 secondDuration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME - 7 * 86_400);
        secondDuration = bound(secondDuration, 7 * 86_400, MAXTIME - duration);

        uint256 from = createLockPranked(pranker, amount, duration);
        uint256 to = createLockPranked(pranker, amount, duration + secondDuration);

        vm.prank(pranker);
        votingEscrow.merge(from, to);
        (int128 balance, uint256 end) = votingEscrow.locked(to);
        assertEq(uint256(uint128(balance)), amount * 2, "Balance should be doubled");
        assertEq(end, (block.timestamp + duration + secondDuration) / WEEK * WEEK, "End should be the the longest");
    }

    function testFuzz_merge_Shorter(address pranker, uint256 amount, uint256 duration, uint256 secondDuration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME - 7 * 86_400);
        secondDuration = bound(secondDuration, 7 * 86_400, MAXTIME - duration);

        uint256 from = createLockPranked(pranker, amount, duration + secondDuration);
        uint256 to = createLockPranked(pranker, amount, duration);

        vm.prank(pranker);
        votingEscrow.merge(from, to);
        (int128 balance, uint256 end) = votingEscrow.locked(to);
        assertEq(uint256(uint128(balance)), amount * 2, "Balance should be doubled");
        assertEq(end, (block.timestamp + duration + secondDuration) / WEEK * WEEK, "End should be the the longest");
    }

    function testFuzz_merge_FromNotAllowed(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME - 7 * 86_400);

        uint256 from = createLockPranked(alice, amount, duration);
        uint256 to = createLockPranked(pranker, amount, duration);

        vm.prank(pranker);
        vm.expectRevert();
        votingEscrow.merge(from, to);
    }

    function testFuzz_merge_ToNotAllowed(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME - 7 * 86_400);

        uint256 from = createLockPranked(pranker, amount, duration);
        uint256 to = createLockPranked(alice, amount, duration);

        vm.prank(pranker);
        vm.expectRevert();
        votingEscrow.merge(from, to);
    }

    function testFuzz_merge_Same(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME - 7 * 86_400);

        uint256 from = createLockPranked(pranker, amount, duration);

        vm.prank(pranker);
        vm.expectRevert();
        votingEscrow.merge(from, from);
    }

    function testFuzz_merge_FromAttached(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME - 7 * 86_400);

        uint256 from = createLockPranked(pranker, amount, duration);
        uint256 to = createLockPranked(pranker, amount, duration);

        // Attach the from lock
        address team = makeAddr("team");
        address voter = makeAddr("voter");

        vm.prank(owner);
        votingEscrow.setTeam(team);
        vm.prank(team);
        votingEscrow.setVoter(address(voter));

        vm.prank(voter);
        votingEscrow.attach(from);
        // End of attaching

        vm.prank(pranker);
        vm.expectRevert();
        votingEscrow.merge(from, to);
    }

    function testFuzz_merge_FromVoting(address pranker, uint256 amount, uint256 duration) public {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME - 7 * 86_400);

        uint256 from = createLockPranked(pranker, amount, duration);
        uint256 to = createLockPranked(pranker, amount, duration);

        // Attach the from lock
        address team = makeAddr("team");
        address voter = makeAddr("voter");

        vm.prank(owner);
        votingEscrow.setTeam(team);
        vm.prank(team);
        votingEscrow.setVoter(address(voter));

        vm.prank(voter);
        votingEscrow.voting(from);
        // End of attaching

        vm.prank(pranker);
        vm.expectRevert();
        votingEscrow.merge(from, to);
    }
}
