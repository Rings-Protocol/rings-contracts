// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VoterTest.t.sol";

contract Reset is VoterTest {
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

        createNft(1, address(alice), 175e18);
        createNft(2, address(bob), 225e18);
        createNft(3, address(alice), 150e18);
        createNft(4, address(bob), 12e18);

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

        vm.warp(block.timestamp + 6 hours);
    }

    function test_reset_votes_correctly() public {
        uint256 votingPower = ve.balanceOfNFT(1);

        uint256 nextPeriod = voter.currentPeriod() + WEEK;

        uint256 oldGaugeVotes1 = (votingPower * weights[0]) / MAX_WEIGHT;
        uint256 oldGaugeVotes2 = (votingPower * weights[1]) / MAX_WEIGHT;
        uint256 oldGaugeVotes3 = (votingPower * weights[2]) / MAX_WEIGHT;

        uint256 prevGauge1Votes = voter.votesPerPeriod(nextPeriod, gauge1);
        uint256 prevGauge2Votes = voter.votesPerPeriod(nextPeriod, gauge2);
        uint256 prevGauge3Votes = voter.votesPerPeriod(nextPeriod, gauge3);

        uint256 prevTotalVotes = voter.totalVotesPerPeriod(nextPeriod);

        vm.expectEmit(true, true, true, true);
        emit Voter.VoteReseted(address(alice), 1, gauge1);
        emit Voter.VoteReseted(address(alice), 1, gauge2);
        emit Voter.VoteReseted(address(alice), 1, gauge3);

        vm.prank(alice);
        voter.reset(1);

        assertEq(voter.lastVoted(1), block.timestamp);

        assertEq(voter.voteCastedPeriod(1, nextPeriod), false);

        assertEq(voter.votesPerPeriod(nextPeriod, gauge1), prevGauge1Votes - oldGaugeVotes1);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge2), prevGauge2Votes - oldGaugeVotes2);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge3), prevGauge3Votes - oldGaugeVotes3);

        assertEq(
            voter.totalVotesPerPeriod(nextPeriod),
            prevTotalVotes - oldGaugeVotes1 - oldGaugeVotes2 - oldGaugeVotes3
        );

        Voter.Vote memory vote1;
        Voter.Vote memory vote2;
        Voter.Vote memory vote3;
        (vote1.weight, vote1.votes) = voter.votes(1, nextPeriod, gauge1);
        (vote2.weight, vote2.votes) = voter.votes(1, nextPeriod, gauge2);
        (vote3.weight, vote3.votes) = voter.votes(1, nextPeriod, gauge3);
        assertEq(vote1.votes, 0);
        assertEq(vote1.weight, 0);
        assertEq(vote2.votes, 0);
        assertEq(vote2.weight, 0);
        assertEq(vote3.votes, 0);
        assertEq(vote3.weight, 0);

        assertEq(ve.voted(1), false);
        assertEq(ve._abstained(1), true);

    }

    function test_reset_does_nothing_if_no_votes_casted() public {
        uint256 nextPeriod = voter.currentPeriod() + WEEK;

        uint256 prevGaugeVotes1 = voter.votesPerPeriod(nextPeriod, gauge1);
        uint256 prevGaugeVotes2 = voter.votesPerPeriod(nextPeriod, gauge2);
        uint256 prevGaugeVotes3 = voter.votesPerPeriod(nextPeriod, gauge3);
        uint256 prevGaugeVotes4 = voter.votesPerPeriod(nextPeriod, gauge4);

        uint256 prevTotalVotes = voter.totalVotesPerPeriod(nextPeriod);

        vm.prank(bob);
        voter.reset(4);

        assertEq(voter.lastVoted(4), block.timestamp);

        assertEq(voter.voteCastedPeriod(4, nextPeriod), false);

        assertEq(voter.votesPerPeriod(nextPeriod, gauge1), prevGaugeVotes1);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge2), prevGaugeVotes2);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge3), prevGaugeVotes3);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge4), prevGaugeVotes4);

        assertEq(
            voter.totalVotesPerPeriod(nextPeriod),
            prevTotalVotes
        );

        assertEq(ve.voted(4), false);
        assertEq(ve._abstained(4), true);

    }

    function test_reset_votes_correctly_with_delegation() public {
        ve.delegateVotingControl(address(alice), 2);

        uint256 votingPower = ve.balanceOfNFT(2);

        uint256 nextPeriod = voter.currentPeriod() + WEEK;

        uint256 oldGaugeVotes2 = (votingPower * weights2[0]) / MAX_WEIGHT;
        uint256 oldGaugeVotes4 = (votingPower * weights2[1]) / MAX_WEIGHT;

        uint256 prevGauge2Votes = voter.votesPerPeriod(nextPeriod, gauge2);
        uint256 prevGauge4Votes = voter.votesPerPeriod(nextPeriod, gauge4);

        uint256 prevTotalVotes = voter.totalVotesPerPeriod(nextPeriod);

        vm.expectEmit(true, true, true, true);
        emit Voter.VoteReseted(address(alice), 2, gauge2);
        emit Voter.VoteReseted(address(alice), 2, gauge4);

        vm.prank(alice);
        voter.reset(2);

        assertEq(voter.lastVoted(2), block.timestamp);

        assertEq(voter.voteCastedPeriod(2, nextPeriod), false);

        assertEq(voter.votesPerPeriod(nextPeriod, gauge2), prevGauge2Votes - oldGaugeVotes2);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge4), prevGauge4Votes - oldGaugeVotes4);

        assertEq(
            voter.totalVotesPerPeriod(nextPeriod),
            prevTotalVotes - oldGaugeVotes2 - oldGaugeVotes4
        );

        Voter.Vote memory vote1;
        Voter.Vote memory vote2;
        (vote1.weight, vote1.votes) = voter.votes(2, nextPeriod, gauge2);
        (vote2.weight, vote2.votes) = voter.votes(2, nextPeriod, gauge4);
        assertEq(vote1.votes, 0);
        assertEq(vote1.weight, 0);
        assertEq(vote2.votes, 0);
        assertEq(vote2.weight, 0);

        assertEq(ve.voted(2), false);
        assertEq(ve._abstained(2), true);

    }

    function test_fail_voting_delay() public {
        vm.prank(bob);
        voter.vote(4, gauges, weights);

        vm.expectRevert(Voter.VoteDelayNotExpired.selector);

        vm.prank(bob);
        voter.reset(4);
    }

    function test_fail_not_allowed_delegate() public {
        vm.expectRevert(Voter.CannotVoteWithNft.selector);

        vm.prank(bob);
        voter.reset(1);
    }

    function test_multipleReset_votes_correctly() public {
        ve.delegateVotingControl(address(alice), 2);

        uint256[] memory nfts = new uint256[](3);
        nfts[0] = 1;
        nfts[1] = 2;
        nfts[2] = 3;

        uint256 votingPower = ve.balanceOfNFT(1);
        uint256 votingPower2 = ve.balanceOfNFT(2);
        uint256 votingPower3 = ve.balanceOfNFT(3);

        uint256 nextPeriod = voter.currentPeriod() + WEEK;

        uint256 oldGauge1Votes = ((votingPower * weights[0]) / MAX_WEIGHT) + ((votingPower3 * weights3[2]) / MAX_WEIGHT);
        uint256 oldGauge2Votes = ((votingPower * weights[1]) / MAX_WEIGHT) + ((votingPower2 * weights2[0]) / MAX_WEIGHT);
        uint256 oldGauge3Votes = ((votingPower * weights[2]) / MAX_WEIGHT) + ((votingPower3 * weights3[0]) / MAX_WEIGHT);
        uint256 oldGauge4Votes = ((votingPower2 * weights2[1]) / MAX_WEIGHT) + ((votingPower3 * weights3[1]) / MAX_WEIGHT);

        uint256 prevGauge1Votes = voter.votesPerPeriod(nextPeriod, gauge1);
        uint256 prevGauge2Votes = voter.votesPerPeriod(nextPeriod, gauge2);
        uint256 prevGauge3Votes = voter.votesPerPeriod(nextPeriod, gauge3);
        uint256 prevGauge4Votes = voter.votesPerPeriod(nextPeriod, gauge4);

        uint256 prevTotalVotes = voter.totalVotesPerPeriod(nextPeriod);

        vm.expectEmit(true, true, true, true);
        emit Voter.VoteReseted(address(alice), 1, gauge1);
        emit Voter.VoteReseted(address(alice), 1, gauge2);
        emit Voter.VoteReseted(address(alice), 1, gauge3);
        emit Voter.VoteReseted(address(alice), 2, gauge2);
        emit Voter.VoteReseted(address(alice), 2, gauge4);
        emit Voter.VoteReseted(address(alice), 3, gauge3);
        emit Voter.VoteReseted(address(alice), 3, gauge4);
        emit Voter.VoteReseted(address(alice), 3, gauge1);

        vm.prank(alice);
        voter.resetMultiple(nfts);

        assertEq(voter.lastVoted(1), block.timestamp);
        assertEq(voter.lastVoted(2), block.timestamp);
        assertEq(voter.lastVoted(3), block.timestamp);

        assertEq(voter.voteCastedPeriod(1, nextPeriod), false);
        assertEq(voter.voteCastedPeriod(2, nextPeriod), false);
        assertEq(voter.voteCastedPeriod(3, nextPeriod), false);

        assertEq(voter.votesPerPeriod(nextPeriod, gauge1), prevGauge1Votes - oldGauge1Votes);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge2), prevGauge2Votes - oldGauge2Votes);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge3), prevGauge3Votes - oldGauge3Votes);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge4), prevGauge4Votes - oldGauge4Votes);

        assertEq(
            voter.totalVotesPerPeriod(nextPeriod),
            prevTotalVotes - oldGauge1Votes - oldGauge2Votes - oldGauge3Votes - oldGauge4Votes
        );

        Voter.Vote memory vote1;
        Voter.Vote memory vote2;
        Voter.Vote memory vote3;
        (vote1.weight, vote1.votes) = voter.votes(1, nextPeriod, gauge1);
        (vote2.weight, vote2.votes) = voter.votes(1, nextPeriod, gauge2);
        (vote3.weight, vote3.votes) = voter.votes(1, nextPeriod, gauge3);
        assertEq(vote1.votes, 0);
        assertEq(vote1.weight, 0);
        assertEq(vote2.votes, 0);
        assertEq(vote2.weight, 0);
        assertEq(vote3.votes, 0);
        assertEq(vote3.weight, 0);
        (vote1.weight, vote1.votes) = voter.votes(2, nextPeriod, gauge2);
        (vote2.weight, vote2.votes) = voter.votes(2, nextPeriod, gauge4);
        assertEq(vote1.votes, 0);
        assertEq(vote1.weight, 0);
        assertEq(vote2.votes, 0);
        assertEq(vote2.weight, 0);
        assertEq(vote3.votes, 0);
        assertEq(vote3.weight, 0);
        (vote1.weight, vote1.votes) = voter.votes(3, nextPeriod, gauge3);
        (vote2.weight, vote2.votes) = voter.votes(3, nextPeriod, gauge4);
        (vote3.weight, vote3.votes) = voter.votes(3, nextPeriod, gauge1);
        assertEq(vote1.votes, 0);
        assertEq(vote1.weight, 0);
        assertEq(vote2.votes, 0);
        assertEq(vote2.weight, 0);
        assertEq(vote3.votes, 0);
        assertEq(vote3.weight, 0);

        assertEq(ve.voted(1), false);
        assertEq(ve.voted(2), false);
        assertEq(ve.voted(3), false);
        assertEq(ve._abstained(1), true);
        assertEq(ve._abstained(2), true);
        assertEq(ve._abstained(3), true);

    }

}