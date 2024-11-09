// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VoterTest.t.sol";

contract Recast is VoterTest {
    address delegate;

    address gauge1;
    address gauge2;
    address gauge3;
    address gauge4;

    address[] gauges;
    uint256[] weights;
    address[] gauges2;
    uint256[] weights2;
    address[] gauges3;
    uint256[] weights3;

    function setUp() public virtual override {
        super.setUp();

        delegate = makeAddr("delegate");

        gauge1 = makeAddr("gauge1");
        gauge2 = makeAddr("gauge2");
        gauge3 = makeAddr("gauge3");
        gauge4 = makeAddr("gauge4");

        deal(address(scUSD), address(this), 10e30);
        scUSD.approve(address(voter), type(uint256).max);
        voter.depositBudget(10e19);

        createNft(address(alice), 175e18);
        createNft(address(bob), 225e18);
        createNft(address(alice), 150e18);
        createNft(address(bob), 12e18);

        vm.startPrank(owner);
        voter.addGauge(gauge1, "Mock Gauge 1");
        voter.addGauge(gauge2, "Mock Gauge 2");
        voter.addGauge(gauge3, "Mock Gauge 3");
        voter.addGauge(gauge4, "Mock Gauge 4");
        vm.stopPrank();

        gauges.push(gauge1);
        gauges.push(gauge2);
        gauges.push(gauge3);
        weights.push(5000);
        weights.push(2000);
        weights.push(3000);
        gauges2.push(gauge2);
        gauges2.push(gauge4);
        weights2.push(3000);
        weights2.push(7000);
        gauges3.push(gauge3);
        gauges3.push(gauge4);
        gauges3.push(gauge1);
        weights3.push(1000);
        weights3.push(6000);
        weights3.push(3000);

        vm.prank(alice);
        voter.vote(1, gauges, weights);

        vm.prank(bob);
        voter.vote(2, gauges2, weights2);

        vm.prank(alice);
        voter.vote(3, gauges3, weights3);

        vm.warp(vm.getBlockTimestamp() + 5 days); // only 5 days here since taken start timestamp is at the end of the period
    }

    function test_recast_votes_correctly() public {
        updateNftBalance(1, 165e18); // to mimic voting power decrease

        uint256 votingPower = ve.balanceOfNFT(1);

        uint256 gaugeVotes1 = (votingPower * weights[0]) / MAX_WEIGHT;
        uint256 gaugeVotes2 = (votingPower * weights[1]) / MAX_WEIGHT;
        uint256 gaugeVotes3 = (votingPower * weights[2]) / MAX_WEIGHT;

        uint256 currentPeriod = voter.currentPeriod();
        uint256 nextPeriod = currentPeriod + WEEK;

        Voter.Vote memory oldVote1;
        Voter.Vote memory oldVote2;
        Voter.Vote memory oldVote3;
        (oldVote1.weight, oldVote1.votes) = voter.votes(1, currentPeriod, gauge1);
        (oldVote2.weight, oldVote2.votes) = voter.votes(1, currentPeriod, gauge2);
        (oldVote3.weight, oldVote3.votes) = voter.votes(1, currentPeriod, gauge3);

        uint256 prevGauge1Votes = voter.votesPerPeriod(nextPeriod, gauge1);
        uint256 prevGauge2Votes = voter.votesPerPeriod(nextPeriod, gauge2);
        uint256 prevGauge3Votes = voter.votesPerPeriod(nextPeriod, gauge3);

        uint256 prevTotalVotes = voter.totalVotesPerPeriod(nextPeriod);

        vm.expectEmit(true, true, true, true);
        emit Voter.Voted(address(alice), 1, gauge1, vm.getBlockTimestamp(), 5000, gaugeVotes1);
        emit Voter.Voted(address(alice), 1, gauge2, vm.getBlockTimestamp(), 2000, gaugeVotes2);
        emit Voter.Voted(address(alice), 1, gauge3, vm.getBlockTimestamp(), 3000, gaugeVotes3);

        vm.prank(alice);
        voter.recast(1);

        assertEq(voter.lastVoted(1), vm.getBlockTimestamp());

        assertEq(voter.voteCastedPeriod(1, nextPeriod), true);

        assertEq(voter.votesPerPeriod(nextPeriod, gauge1), prevGauge1Votes + gaugeVotes1);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge2), prevGauge2Votes + gaugeVotes2);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge3), prevGauge3Votes + gaugeVotes3);

        assertEq(voter.totalVotesPerPeriod(nextPeriod), prevTotalVotes + gaugeVotes1 + gaugeVotes2 + gaugeVotes3);

        Voter.Vote memory vote1;
        Voter.Vote memory vote2;
        Voter.Vote memory vote3;
        (vote1.weight, vote1.votes) = voter.votes(1, nextPeriod, gauge1);
        (vote2.weight, vote2.votes) = voter.votes(1, nextPeriod, gauge2);
        (vote3.weight, vote3.votes) = voter.votes(1, nextPeriod, gauge3);
        assertEq(vote1.votes, gaugeVotes1);
        assertEq(vote2.votes, gaugeVotes2);
        assertEq(vote3.votes, gaugeVotes3);
        assertEq(vote1.weight, oldVote1.weight);
        assertEq(vote2.weight, oldVote2.weight);
        assertEq(vote3.weight, oldVote3.weight);

        assertEq(voter.gaugeVote(1, nextPeriod, 0), gauge1);
        assertEq(voter.gaugeVote(1, nextPeriod, 1), gauge2);
        assertEq(voter.gaugeVote(1, nextPeriod, 2), gauge3);

        assertEq(ve.voted(1), true);
    }

    function test_recast_votes_correctly_with_delegation() public {
        vm.prank(bob);
        ve.approveVoting(address(alice), 2);

        uint256 votingPower = ve.balanceOfNFT(2);

        uint256 gaugeVotes2 = (votingPower * weights2[0]) / MAX_WEIGHT;
        uint256 gaugeVotes4 = (votingPower * weights2[1]) / MAX_WEIGHT;

        uint256 currentPeriod = voter.currentPeriod();
        uint256 nextPeriod = currentPeriod + WEEK;

        Voter.Vote memory oldVote1;
        Voter.Vote memory oldVote2;
        (oldVote1.weight, oldVote1.votes) = voter.votes(2, currentPeriod, gauge2);
        (oldVote2.weight, oldVote2.votes) = voter.votes(2, currentPeriod, gauge4);

        uint256 prevGauge2Votes = voter.votesPerPeriod(nextPeriod, gauge2);
        uint256 prevGauge4Votes = voter.votesPerPeriod(nextPeriod, gauge4);

        uint256 prevTotalVotes = voter.totalVotesPerPeriod(nextPeriod);

        vm.expectEmit(true, true, true, true);
        emit Voter.Voted(address(alice), 2, gauge2, vm.getBlockTimestamp(), weights2[0], gaugeVotes2);
        emit Voter.Voted(address(alice), 2, gauge4, vm.getBlockTimestamp(), weights2[1], gaugeVotes4);

        vm.prank(alice);
        voter.recast(2);

        assertEq(voter.lastVoted(2), vm.getBlockTimestamp());

        assertEq(voter.voteCastedPeriod(2, nextPeriod), true);

        assertEq(voter.votesPerPeriod(nextPeriod, gauge2), prevGauge2Votes + gaugeVotes2);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge4), prevGauge4Votes + gaugeVotes4);

        assertEq(voter.totalVotesPerPeriod(nextPeriod), prevTotalVotes + gaugeVotes2 + gaugeVotes4);

        Voter.Vote memory vote1;
        Voter.Vote memory vote2;
        (vote1.weight, vote1.votes) = voter.votes(2, nextPeriod, gauge2);
        (vote2.weight, vote2.votes) = voter.votes(2, nextPeriod, gauge4);
        assertEq(vote1.votes, gaugeVotes2);
        assertEq(vote2.votes, gaugeVotes4);
        assertEq(vote1.weight, oldVote1.weight);
        assertEq(vote2.weight, oldVote2.weight);

        assertEq(voter.gaugeVote(2, nextPeriod, 0), gauge2);
        assertEq(voter.gaugeVote(2, nextPeriod, 1), gauge4);

        assertEq(ve.voted(2), true);
    }

    function test_recast_success_reset_previous_vote() public {
        uint256 votingPower = ve.balanceOfNFT(1);

        uint256 oldGaugeVotes2 = (votingPower * weights2[0]) / MAX_WEIGHT;
        uint256 oldGaugeVotes4 = (votingPower * weights2[1]) / MAX_WEIGHT;

        vm.prank(alice);
        voter.vote(1, gauges2, weights2);

        vm.warp(vm.getBlockTimestamp() + 6 hours);

        votingPower = ve.balanceOfNFT(1);

        uint256 gaugeVotes1 = (votingPower * weights[0]) / MAX_WEIGHT;
        uint256 gaugeVotes2 = (votingPower * weights[1]) / MAX_WEIGHT;
        uint256 gaugeVotes3 = (votingPower * weights[2]) / MAX_WEIGHT;

        uint256 nextPeriod = voter.currentPeriod() + WEEK;

        uint256 prevGauge1Votes = voter.votesPerPeriod(nextPeriod, gauge1);
        uint256 prevGauge2Votes = voter.votesPerPeriod(nextPeriod, gauge2);
        uint256 prevGauge3Votes = voter.votesPerPeriod(nextPeriod, gauge3);
        uint256 prevGauge4Votes = voter.votesPerPeriod(nextPeriod, gauge4);

        uint256 prevTotalVotes = voter.totalVotesPerPeriod(nextPeriod);

        vm.expectEmit(true, true, true, true);
        emit Voter.VoteReseted(address(alice), 1, gauge2);
        emit Voter.VoteReseted(address(alice), 1, gauge4);
        emit Voter.Voted(address(alice), 1, gauge1, vm.getBlockTimestamp(), weights[0], gaugeVotes1);
        emit Voter.Voted(address(alice), 1, gauge2, vm.getBlockTimestamp(), weights[1], gaugeVotes2);
        emit Voter.Voted(address(alice), 1, gauge3, vm.getBlockTimestamp(), weights[2], gaugeVotes3);

        vm.prank(alice);
        voter.recast(1);

        assertEq(voter.lastVoted(1), vm.getBlockTimestamp());

        assertEq(voter.voteCastedPeriod(1, nextPeriod), true);

        assertEq(voter.votesPerPeriod(nextPeriod, gauge1), prevGauge1Votes + gaugeVotes1);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge2), prevGauge2Votes - oldGaugeVotes2 + gaugeVotes2);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge3), prevGauge3Votes + gaugeVotes3);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge4), prevGauge4Votes - oldGaugeVotes4);

        assertEq(
            voter.totalVotesPerPeriod(nextPeriod),
            prevTotalVotes - oldGaugeVotes2 - oldGaugeVotes4 + gaugeVotes1 + gaugeVotes2 + gaugeVotes3
        );

        Voter.Vote memory vote1;
        Voter.Vote memory vote2;
        Voter.Vote memory vote3;
        (vote1.weight, vote1.votes) = voter.votes(1, nextPeriod, gauge1);
        (vote2.weight, vote2.votes) = voter.votes(1, nextPeriod, gauge2);
        (vote3.weight, vote3.votes) = voter.votes(1, nextPeriod, gauge3);
        assertEq(vote1.votes, gaugeVotes1);
        assertEq(vote1.weight, weights[0]);
        assertEq(vote2.votes, gaugeVotes2);
        assertEq(vote2.weight, weights[1]);
        assertEq(vote3.votes, gaugeVotes3);
        assertEq(vote3.weight, weights[2]);

        assertEq(voter.gaugeVote(1, nextPeriod, 0), gauge1);
        assertEq(voter.gaugeVote(1, nextPeriod, 1), gauge2);
        assertEq(voter.gaugeVote(1, nextPeriod, 2), gauge3);

        assertEq(ve.voted(1), true);
    }

    function test_fail_nothing_to_recast() public {
        vm.expectRevert(Voter.NoVoteToRecast.selector);

        vm.prank(bob);
        voter.recast(4);
    }

    function test_fail_voting_delay() public {
        vm.prank(bob);
        voter.vote(4, gauges, weights);

        vm.expectRevert(Voter.VoteDelayNotExpired.selector);

        vm.prank(bob);
        voter.recast(4);
    }

    function test_fail_not_allowed_delegate() public {
        vm.expectRevert(Voter.CannotVoteWithNft.selector);

        vm.prank(bob);
        voter.recast(1);
    }

    function test_voteMultiple_success() public {
        uint256[] memory tokenIds = new uint256[](3);
        tokenIds[0] = 1;
        tokenIds[1] = 2;
        tokenIds[2] = 3;

        vm.prank(bob);
        ve.approveVoting(address(alice), 2);

        uint256 totalCastedVotes = 0;

        uint256 votingPower1 = ve.balanceOfNFT(1);
        uint256 votingPower2 = ve.balanceOfNFT(2);
        uint256 votingPower3 = ve.balanceOfNFT(3);

        uint256 gaugeVotes1;
        uint256 gaugeVotes2;
        uint256 gaugeVotes3;
        uint256 gaugeVotes4;
        gaugeVotes1 += (votingPower1 * weights[0]) / MAX_WEIGHT;
        gaugeVotes2 += (votingPower1 * weights[1]) / MAX_WEIGHT;
        gaugeVotes3 += (votingPower1 * weights[2]) / MAX_WEIGHT;
        gaugeVotes2 += (votingPower2 * weights2[0]) / MAX_WEIGHT;
        gaugeVotes4 += (votingPower2 * weights2[1]) / MAX_WEIGHT;
        gaugeVotes3 += (votingPower3 * weights3[0]) / MAX_WEIGHT;
        gaugeVotes4 += (votingPower3 * weights3[1]) / MAX_WEIGHT;
        gaugeVotes1 += (votingPower3 * weights3[2]) / MAX_WEIGHT;

        totalCastedVotes = gaugeVotes1 + gaugeVotes2 + gaugeVotes3;

        uint256 nextPeriod = voter.currentPeriod() + WEEK;

        uint256 prevGauge1Votes = voter.votesPerPeriod(nextPeriod, gauge1);
        uint256 prevGauge2Votes = voter.votesPerPeriod(nextPeriod, gauge2);
        uint256 prevGauge3Votes = voter.votesPerPeriod(nextPeriod, gauge3);
        uint256 prevGauge4Votes = voter.votesPerPeriod(nextPeriod, gauge4);

        uint256 prevTotalVotes = voter.totalVotesPerPeriod(nextPeriod);

        vm.expectEmit(true, true, true, true);
        emit Voter.Voted(
            address(alice), 1, gauge1, vm.getBlockTimestamp(), weights[0], (votingPower1 * weights[0]) / MAX_WEIGHT
        );
        emit Voter.Voted(
            address(alice), 1, gauge2, vm.getBlockTimestamp(), weights[1], (votingPower1 * weights[1]) / MAX_WEIGHT
        );
        emit Voter.Voted(
            address(alice), 1, gauge3, vm.getBlockTimestamp(), weights[2], (votingPower1 * weights[2]) / MAX_WEIGHT
        );
        emit Voter.Voted(
            address(alice), 2, gauge2, vm.getBlockTimestamp(), weights2[0], (votingPower2 * weights2[0]) / MAX_WEIGHT
        );
        emit Voter.Voted(
            address(alice), 2, gauge4, vm.getBlockTimestamp(), weights2[1], (votingPower2 * weights2[1]) / MAX_WEIGHT
        );
        emit Voter.Voted(
            address(alice), 3, gauge3, vm.getBlockTimestamp(), weights3[0], (votingPower3 * weights3[0]) / MAX_WEIGHT
        );
        emit Voter.Voted(
            address(alice), 3, gauge4, vm.getBlockTimestamp(), weights3[1], (votingPower3 * weights3[1]) / MAX_WEIGHT
        );
        emit Voter.Voted(
            address(alice), 3, gauge1, vm.getBlockTimestamp(), weights3[2], (votingPower3 * weights3[2]) / MAX_WEIGHT
        );

        vm.prank(alice);
        voter.recastMultiple(tokenIds);

        assertEq(voter.lastVoted(1), vm.getBlockTimestamp());
        assertEq(voter.lastVoted(2), vm.getBlockTimestamp());
        assertEq(voter.lastVoted(3), vm.getBlockTimestamp());

        assertEq(voter.voteCastedPeriod(1, nextPeriod), true);
        assertEq(voter.voteCastedPeriod(2, nextPeriod), true);
        assertEq(voter.voteCastedPeriod(3, nextPeriod), true);

        assertEq(voter.votesPerPeriod(nextPeriod, gauge1), prevGauge1Votes + gaugeVotes1);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge2), prevGauge2Votes + gaugeVotes2);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge3), prevGauge3Votes + gaugeVotes3);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge4), prevGauge4Votes + gaugeVotes4);

        assertEq(
            voter.totalVotesPerPeriod(nextPeriod),
            prevTotalVotes + gaugeVotes1 + gaugeVotes2 + gaugeVotes3 + gaugeVotes4
        );

        Voter.Vote memory vote1;
        Voter.Vote memory vote2;
        Voter.Vote memory vote3;
        (vote1.weight, vote1.votes) = voter.votes(1, nextPeriod, gauge1);
        (vote2.weight, vote2.votes) = voter.votes(1, nextPeriod, gauge2);
        (vote3.weight, vote3.votes) = voter.votes(1, nextPeriod, gauge3);
        assertEq(vote1.votes, (votingPower1 * weights[0]) / MAX_WEIGHT);
        assertEq(vote1.weight, weights[0]);
        assertEq(vote2.votes, (votingPower1 * weights[1]) / MAX_WEIGHT);
        assertEq(vote2.weight, weights[1]);
        assertEq(vote3.votes, (votingPower1 * weights[2]) / MAX_WEIGHT);
        assertEq(vote3.weight, weights[2]);

        (vote1.weight, vote1.votes) = voter.votes(2, nextPeriod, gauge2);
        (vote2.weight, vote2.votes) = voter.votes(2, nextPeriod, gauge4);
        assertEq(vote1.votes, (votingPower2 * weights2[0]) / MAX_WEIGHT);
        assertEq(vote1.weight, weights2[0]);
        assertEq(vote2.votes, (votingPower2 * weights2[1]) / MAX_WEIGHT);
        assertEq(vote2.weight, weights2[1]);

        (vote1.weight, vote1.votes) = voter.votes(3, nextPeriod, gauge3);
        (vote2.weight, vote2.votes) = voter.votes(3, nextPeriod, gauge4);
        (vote3.weight, vote3.votes) = voter.votes(3, nextPeriod, gauge1);
        assertEq(vote1.votes, (votingPower3 * weights3[0]) / MAX_WEIGHT);
        assertEq(vote1.weight, weights3[0]);
        assertEq(vote2.votes, (votingPower3 * weights3[1]) / MAX_WEIGHT);
        assertEq(vote2.weight, weights3[1]);
        assertEq(vote3.votes, (votingPower3 * weights3[2]) / MAX_WEIGHT);
        assertEq(vote3.weight, weights3[2]);

        assertEq(voter.gaugeVote(1, nextPeriod, 0), gauge1);
        assertEq(voter.gaugeVote(1, nextPeriod, 1), gauge2);
        assertEq(voter.gaugeVote(1, nextPeriod, 2), gauge3);

        assertEq(voter.gaugeVote(2, nextPeriod, 0), gauge2);
        assertEq(voter.gaugeVote(2, nextPeriod, 1), gauge4);

        assertEq(voter.gaugeVote(3, nextPeriod, 0), gauge3);
        assertEq(voter.gaugeVote(3, nextPeriod, 1), gauge4);
        assertEq(voter.gaugeVote(3, nextPeriod, 2), gauge1);

        assertEq(ve.voted(1), true);
        assertEq(ve.voted(2), true);
        assertEq(ve.voted(3), true);
    }
}
