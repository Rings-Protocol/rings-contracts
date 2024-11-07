// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VoterTest.t.sol";

contract Vote is VoterTest {
    address delegate;

    address gauge1;
    address gauge2;
    address gauge3;
    address gauge4;
    address gauge5;

    address wrongGauge;

    function setUp() public virtual override {
        super.setUp();

        delegate = makeAddr("delegate");

        gauge1 = makeAddr("gauge1");
        gauge2 = makeAddr("gauge2");
        gauge3 = makeAddr("gauge3");
        gauge4 = makeAddr("gauge4");
        gauge5 = makeAddr("gauge5");

        wrongGauge = makeAddr("wrongGauge");
        
        deal(address(scUSD), address(this), 10e30);
        scUSD.approve(address(voter), type(uint256).max);
        voter.depositBudget(10e19);

        createNft(address(alice), 175e18);
        createNft(address(bob), 225e18);
        createNft(address(alice), 100e18);

        vm.startPrank(owner);
        voter.addGauge(gauge1, "Mock Gauge 1");
        voter.addGauge(gauge2, "Mock Gauge 2");
        voter.addGauge(gauge3, "Mock Gauge 3");
        voter.addGauge(gauge4, "Mock Gauge 4");
        voter.addGauge(gauge5, "Mock Gauge 5");
        vm.stopPrank();
    }
    
    function test_vote_success() public {
        address[] memory gauges = new address[](3);
        uint256[] memory weights = new uint256[](3);
        gauges[0] = gauge1;
        gauges[1] = gauge2;
        gauges[2] = gauge3;
        weights[0] = 5000;
        weights[1] = 2000;
        weights[2] = 3000;

        uint256 votingPower = ve.balanceOfNFT(1);

        uint256 gaugeVotes1 = (votingPower * weights[0]) / MAX_WEIGHT;
        uint256 gaugeVotes2 = (votingPower * weights[1]) / MAX_WEIGHT;
        uint256 gaugeVotes3 = (votingPower * weights[2]) / MAX_WEIGHT;

        uint256 nextPeriod = voter.currentPeriod() + WEEK;

        uint256 prevGauge1Votes = voter.votesPerPeriod(nextPeriod, gauge1);
        uint256 prevGauge2Votes = voter.votesPerPeriod(nextPeriod, gauge2);
        uint256 prevGauge3Votes = voter.votesPerPeriod(nextPeriod, gauge3);

        uint256 prevTotalVotes = voter.totalVotesPerPeriod(nextPeriod);

        vm.expectEmit(true, true, true, true);
        emit Voter.Voted(address(alice), 1, gauge1, block.timestamp, 5000, gaugeVotes1);
        emit Voter.Voted(address(alice), 1, gauge2, block.timestamp, 2000, gaugeVotes2);
        emit Voter.Voted(address(alice), 1, gauge3, block.timestamp, 3000, gaugeVotes3);

        vm.prank(alice);
        voter.vote(1, gauges, weights);

        assertEq(voter.lastVoted(1), block.timestamp);

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
    
    function test_vote_multiple_nfts() public {
        address[] memory gauges = new address[](3);
        uint256[] memory weights = new uint256[](3);
        gauges[0] = gauge1;
        gauges[1] = gauge2;
        gauges[2] = gauge3;
        weights[0] = 5000;
        weights[1] = 2000;
        weights[2] = 3000;
        address[] memory gauges2 = new address[](2);
        uint256[] memory weights2 = new uint256[](2);
        gauges2[0] = gauge2;
        gauges2[1] = gauge4;
        weights2[0] = 3000;
        weights2[1] = 7000;
        address[] memory gauges3 = new address[](3);
        uint256[] memory weights3 = new uint256[](3);
        gauges3[0] = gauge3;
        gauges3[1] = gauge4;
        gauges3[2] = gauge5;
        weights3[0] = 1000;
        weights3[1] = 6000;
        weights3[2] = 3000;

        updateNftBalance(3, 150e18);

        uint256 totalCastedVotes = 0;

        uint256 votingPower1 = ve.balanceOfNFT(1);
        uint256 votingPower2 = ve.balanceOfNFT(2);
        uint256 votingPower3 = ve.balanceOfNFT(3);

        uint256 gaugeVotes1 = (votingPower1 * weights[0]) / MAX_WEIGHT;
        uint256 gaugeVotes2 = ((votingPower1 * weights[1]) / MAX_WEIGHT) + ((votingPower2 * weights2[0]) / MAX_WEIGHT);
        uint256 gaugeVotes3 = ((votingPower1 * weights[2]) / MAX_WEIGHT) + ((votingPower3 * weights3[0]) / MAX_WEIGHT);
        uint256 gaugeVotes4 = ((votingPower2 * weights2[1]) / MAX_WEIGHT) + ((votingPower3 * weights3[1]) / MAX_WEIGHT);
        uint256 gaugeVotes5 = (votingPower3 * weights3[2]) / MAX_WEIGHT;

        totalCastedVotes = gaugeVotes1 + gaugeVotes2 + gaugeVotes3 + gaugeVotes4 + gaugeVotes5;

        uint256 nextPeriod = voter.currentPeriod() + WEEK;

        uint256 prevGauge1Votes = voter.votesPerPeriod(nextPeriod, gauge1);
        uint256 prevGauge2Votes = voter.votesPerPeriod(nextPeriod, gauge2);
        uint256 prevGauge3Votes = voter.votesPerPeriod(nextPeriod, gauge3);
        uint256 prevGauge4Votes = voter.votesPerPeriod(nextPeriod, gauge4);
        uint256 prevGauge5Votes = voter.votesPerPeriod(nextPeriod, gauge5);

        uint256 prevTotalVotes = voter.totalVotesPerPeriod(nextPeriod);

        vm.prank(alice);
        voter.vote(1, gauges, weights);

        vm.prank(bob);
        voter.vote(2, gauges2, weights2);

        vm.prank(alice);
        voter.vote(3, gauges3, weights3);

        assertEq(voter.votesPerPeriod(nextPeriod, gauge1), prevGauge1Votes + gaugeVotes1);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge2), prevGauge2Votes + gaugeVotes2);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge3), prevGauge3Votes + gaugeVotes3);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge4), prevGauge4Votes + gaugeVotes4);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge5), prevGauge5Votes + gaugeVotes5);

        assertEq(voter.totalVotesPerPeriod(nextPeriod), prevTotalVotes + totalCastedVotes);
    }

    function test_vote_success_fuzz(uint256 nftBalance, uint256 _weight1) public {
        nftBalance = bound(nftBalance, 10e16, 10e21);
        _weight1 = bound(_weight1, 100, 9900);

        vm.mockCall(address(ve), abi.encodeWithSelector(ve.balanceOfNFT.selector, 1), abi.encode(nftBalance));

        address[] memory gauges = new address[](2);
        uint256[] memory weights = new uint256[](2);
        gauges[0] = gauge1;
        gauges[1] = gauge2;
        weights[0] = _weight1;
        weights[1] = MAX_WEIGHT - _weight1;

        uint256 gaugeVotes1 = (nftBalance * weights[0]) / MAX_WEIGHT;
        uint256 gaugeVotes2 = (nftBalance * weights[1]) / MAX_WEIGHT;

        uint256 nextPeriod = voter.currentPeriod() + WEEK;

        uint256 prevGauge1Votes = voter.votesPerPeriod(nextPeriod, gauge1);
        uint256 prevGauge2Votes = voter.votesPerPeriod(nextPeriod, gauge2);

        uint256 prevTotalVotes = voter.totalVotesPerPeriod(nextPeriod);

        vm.expectEmit(true, true, true, true);
        emit Voter.Voted(address(alice), 1, gauge1, block.timestamp, weights[0], gaugeVotes1);
        emit Voter.Voted(address(alice), 1, gauge2, block.timestamp, weights[1], gaugeVotes2);

        vm.prank(alice);
        voter.vote(1, gauges, weights);

        assertEq(voter.lastVoted(1), block.timestamp);

        assertEq(voter.voteCastedPeriod(1, nextPeriod), true);

        assertEq(voter.votesPerPeriod(nextPeriod, gauge1), prevGauge1Votes + gaugeVotes1);
        assertEq(voter.votesPerPeriod(nextPeriod, gauge2), prevGauge2Votes + gaugeVotes2);

        assertEq(voter.totalVotesPerPeriod(nextPeriod), prevTotalVotes + gaugeVotes1 + gaugeVotes2);

        Voter.Vote memory vote1;
        Voter.Vote memory vote2;
        (vote1.weight, vote1.votes) = voter.votes(1, nextPeriod, gauge1);
        (vote2.weight, vote2.votes) = voter.votes(1, nextPeriod, gauge2);
        assertEq(vote1.votes, gaugeVotes1);
        assertEq(vote1.weight, weights[0]);
        assertEq(vote2.votes, gaugeVotes2);
        assertEq(vote2.weight, weights[1]);

        assertEq(voter.gaugeVote(1, nextPeriod, 0), gauge1);
        assertEq(voter.gaugeVote(1, nextPeriod, 1), gauge2);

        assertEq(ve.voted(1), true);
    }

    function test_vote_delegate_success() public {
        address[] memory gauges = new address[](3);
        uint256[] memory weights = new uint256[](3);
        gauges[0] = gauge1;
        gauges[1] = gauge2;
        gauges[2] = gauge3;
        weights[0] = 5000;
        weights[1] = 2000;
        weights[2] = 3000;

        vm.prank(alice);
        ve.approveVoting(address(bob), 1);

        uint256 votingPower = ve.balanceOfNFT(1);

        uint256 gaugeVotes1 = (votingPower * weights[0]) / MAX_WEIGHT;
        uint256 gaugeVotes2 = (votingPower * weights[1]) / MAX_WEIGHT;
        uint256 gaugeVotes3 = (votingPower * weights[2]) / MAX_WEIGHT;

        uint256 nextPeriod = voter.currentPeriod() + WEEK;

        uint256 prevGauge1Votes = voter.votesPerPeriod(nextPeriod, gauge1);
        uint256 prevGauge2Votes = voter.votesPerPeriod(nextPeriod, gauge2);
        uint256 prevGauge3Votes = voter.votesPerPeriod(nextPeriod, gauge3);

        uint256 prevTotalVotes = voter.totalVotesPerPeriod(nextPeriod);

        vm.expectEmit(true, true, true, true);
        emit Voter.Voted(address(bob), 1, gauge1, block.timestamp, 5000, gaugeVotes1);
        emit Voter.Voted(address(bob), 1, gauge2, block.timestamp, 2000, gaugeVotes2);
        emit Voter.Voted(address(bob), 1, gauge3, block.timestamp, 3000, gaugeVotes3);

        vm.prank(bob);
        voter.vote(1, gauges, weights);

        assertEq(voter.lastVoted(1), block.timestamp);

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

    function test_vote_success_reset_previous_vote() public {
        address[] memory oldGauges = new address[](2);
        uint256[] memory oldWeights = new uint256[](2);
        oldGauges[0] = gauge2;
        oldGauges[1] = gauge4;
        oldWeights[0] = 3000;
        oldWeights[1] = 7000;

        address[] memory gauges = new address[](3);
        uint256[] memory weights = new uint256[](3);
        gauges[0] = gauge1;
        gauges[1] = gauge2;
        gauges[2] = gauge3;
        weights[0] = 5000;
        weights[1] = 2000;
        weights[2] = 3000;

        uint256 votingPower = ve.balanceOfNFT(1);

        uint256 oldGaugeVotes2 = (votingPower * oldWeights[0]) / MAX_WEIGHT;
        uint256 oldGaugeVotes4 = (votingPower * oldWeights[1]) / MAX_WEIGHT;

        vm.prank(alice);
        voter.vote(1, oldGauges, oldWeights);

        vm.warp(block.timestamp + 6 hours);
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
        emit Voter.Voted(address(alice), 1, gauge1, block.timestamp, 5000, gaugeVotes1);
        emit Voter.Voted(address(alice), 1, gauge2, block.timestamp, 2000, gaugeVotes2);
        emit Voter.Voted(address(alice), 1, gauge3, block.timestamp, 3000, gaugeVotes3);

        vm.prank(alice);
        voter.vote(1, gauges, weights);

        assertEq(voter.lastVoted(1), block.timestamp);

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

    function test_fail_array_length_mismatch() public {
        address[] memory gauges = new address[](3);
        uint256[] memory weights = new uint256[](2);
        gauges[0] = gauge1;
        gauges[1] = gauge2;
        gauges[2] = gauge3;
        weights[0] = 5000;
        weights[1] = 2000;

        vm.expectRevert(Voter.ArrayLengthMismatch.selector);

        vm.prank(alice);
        voter.vote(1, gauges, weights);
    }

    function test_fail_address_zero() public {
        address[] memory gauges = new address[](3);
        uint256[] memory weights = new uint256[](3);
        gauges[0] = gauge1;
        gauges[1] = zero;
        gauges[2] = gauge3;
        weights[0] = 5000;
        weights[1] = 2000;
        weights[2] = 3000;

        vm.expectRevert(Voter.ZeroAddress.selector);

        vm.prank(alice);
        voter.vote(1, gauges, weights);
    }

    function test_fail_gauge_not_listed() public {
        address[] memory gauges = new address[](3);
        uint256[] memory weights = new uint256[](3);
        gauges[0] = gauge1;
        gauges[1] = wrongGauge;
        gauges[2] = gauge3;
        weights[0] = 5000;
        weights[1] = 2000;
        weights[2] = 3000;

        vm.expectRevert(Voter.GaugeNotListed.selector);

        vm.prank(alice);
        voter.vote(1, gauges, weights);
    }

    function test_fail_gauge_killed() public {
        address[] memory gauges = new address[](3);
        uint256[] memory weights = new uint256[](3);
        gauges[0] = gauge1;
        gauges[1] = gauge2;
        gauges[2] = gauge3;
        weights[0] = 5000;
        weights[1] = 2000;
        weights[2] = 3000;

        vm.prank(owner);
        voter.killGauge(gauge3);

        vm.expectRevert(Voter.KilledGauge.selector);

        vm.prank(alice);
        voter.vote(1, gauges, weights);
    }

    function test_fail_vote_weights_overflow() public {
        address[] memory gauges = new address[](3);
        uint256[] memory weights = new uint256[](3);
        gauges[0] = gauge1;
        gauges[1] = gauge2;
        gauges[2] = gauge3;
        weights[0] = 5000;
        weights[1] = 2500;
        weights[2] = 3500;

        vm.expectRevert(Voter.VoteWeightOverflow.selector);

        vm.prank(alice);
        voter.vote(1, gauges, weights);
    }

    function test_fail_no_voting_power() public {
        address[] memory gauges = new address[](3);
        uint256[] memory weights = new uint256[](3);
        gauges[0] = gauge1;
        gauges[1] = gauge2;
        gauges[2] = gauge3;
        weights[0] = 5000;
        weights[1] = 2000;
        weights[2] = 3000;

        vm.warp(block.timestamp + MAXTIME);
        vm.expectRevert(Voter.NoVotingPower.selector);

        vm.prank(alice);
        voter.vote(3, gauges, weights);
    }

    function test_fail_voting_delay() public {
        address[] memory gauges = new address[](3);
        uint256[] memory weights = new uint256[](3);
        gauges[0] = gauge1;
        gauges[1] = gauge2;
        gauges[2] = gauge3;
        weights[0] = 5000;
        weights[1] = 2000;
        weights[2] = 3000;


        vm.prank(alice);
        voter.vote(1, gauges, weights);

        vm.expectRevert(Voter.VoteDelayNotExpired.selector);

        vm.prank(alice);
        voter.vote(1, gauges, weights);
    }

    function test_fail_not_allowed_delegate() public {
        address[] memory gauges = new address[](3);
        uint256[] memory weights = new uint256[](3);
        gauges[0] = gauge1;
        gauges[1] = gauge2;
        gauges[2] = gauge3;
        weights[0] = 5000;
        weights[1] = 2000;
        weights[2] = 3000;

        vm.expectRevert(Voter.CannotVoteWithNft.selector);

        vm.prank(bob);
        voter.vote(1, gauges, weights);
    }
    
    function test_voteMultiple_success() public {
        address[] memory gauges = new address[](3);
        uint256[] memory weights = new uint256[](3);
        gauges[0] = gauge1;
        gauges[1] = gauge2;
        gauges[2] = gauge3;
        weights[0] = 5000;
        weights[1] = 2000;
        weights[2] = 3000;

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
        gaugeVotes1 += (votingPower1 * weights[0]) / MAX_WEIGHT;
        gaugeVotes2 += (votingPower1 * weights[1]) / MAX_WEIGHT;
        gaugeVotes3 += (votingPower1 * weights[2]) / MAX_WEIGHT;
        gaugeVotes1 += (votingPower2 * weights[0]) / MAX_WEIGHT;
        gaugeVotes2 += (votingPower2 * weights[1]) / MAX_WEIGHT;
        gaugeVotes3 += (votingPower2 * weights[2]) / MAX_WEIGHT;
        gaugeVotes1 += (votingPower3 * weights[0]) / MAX_WEIGHT;
        gaugeVotes2 += (votingPower3 * weights[1]) / MAX_WEIGHT;
        gaugeVotes3 += (votingPower3 * weights[2]) / MAX_WEIGHT;

        totalCastedVotes = gaugeVotes1 + gaugeVotes2 + gaugeVotes3;

        uint256 nextPeriod = voter.currentPeriod() + WEEK;

        uint256 prevGauge1Votes = voter.votesPerPeriod(nextPeriod, gauge1);
        uint256 prevGauge2Votes = voter.votesPerPeriod(nextPeriod, gauge2);
        uint256 prevGauge3Votes = voter.votesPerPeriod(nextPeriod, gauge3);

        uint256 prevTotalVotes = voter.totalVotesPerPeriod(nextPeriod);

        vm.expectEmit(true, true, true, true);
        emit Voter.Voted(address(alice), 1, gauge1, block.timestamp, 5000, (votingPower1 * weights[0]) / MAX_WEIGHT);
        emit Voter.Voted(address(alice), 1, gauge2, block.timestamp, 2000, (votingPower1 * weights[1]) / MAX_WEIGHT);
        emit Voter.Voted(address(alice), 1, gauge3, block.timestamp, 3000, (votingPower1 * weights[2]) / MAX_WEIGHT);
        emit Voter.Voted(address(alice), 2, gauge1, block.timestamp, 5000, (votingPower2 * weights[0]) / MAX_WEIGHT);
        emit Voter.Voted(address(alice), 2, gauge2, block.timestamp, 2000, (votingPower2 * weights[1]) / MAX_WEIGHT);
        emit Voter.Voted(address(alice), 2, gauge3, block.timestamp, 3000, (votingPower2 * weights[2]) / MAX_WEIGHT);
        emit Voter.Voted(address(alice), 3, gauge1, block.timestamp, 5000, (votingPower3 * weights[0]) / MAX_WEIGHT);
        emit Voter.Voted(address(alice), 3, gauge2, block.timestamp, 2000, (votingPower3 * weights[1]) / MAX_WEIGHT);
        emit Voter.Voted(address(alice), 3, gauge3, block.timestamp, 3000, (votingPower3 * weights[2]) / MAX_WEIGHT);

        vm.prank(alice);
        voter.voteMultiple(tokenIds, gauges, weights);

        assertEq(voter.lastVoted(1), block.timestamp);
        assertEq(voter.lastVoted(2), block.timestamp);
        assertEq(voter.lastVoted(3), block.timestamp);

        assertEq(voter.voteCastedPeriod(1, nextPeriod), true);
        assertEq(voter.voteCastedPeriod(2, nextPeriod), true);
        assertEq(voter.voteCastedPeriod(3, nextPeriod), true);

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
        assertEq(vote1.votes, (votingPower1 * weights[0]) / MAX_WEIGHT);
        assertEq(vote1.weight, weights[0]);
        assertEq(vote2.votes, (votingPower1 * weights[1]) / MAX_WEIGHT);
        assertEq(vote2.weight, weights[1]);
        assertEq(vote3.votes, (votingPower1 * weights[2]) / MAX_WEIGHT);
        assertEq(vote3.weight, weights[2]);

        (vote1.weight, vote1.votes) = voter.votes(2, nextPeriod, gauge1);
        (vote2.weight, vote2.votes) = voter.votes(2, nextPeriod, gauge2);
        (vote3.weight, vote3.votes) = voter.votes(2, nextPeriod, gauge3);
        assertEq(vote1.votes, (votingPower2 * weights[0]) / MAX_WEIGHT);
        assertEq(vote1.weight, weights[0]);
        assertEq(vote2.votes, (votingPower2 * weights[1]) / MAX_WEIGHT);
        assertEq(vote2.weight, weights[1]);
        assertEq(vote3.votes, (votingPower2 * weights[2]) / MAX_WEIGHT);
        assertEq(vote3.weight, weights[2]);

        (vote1.weight, vote1.votes) = voter.votes(3, nextPeriod, gauge1);
        (vote2.weight, vote2.votes) = voter.votes(3, nextPeriod, gauge2);
        (vote3.weight, vote3.votes) = voter.votes(3, nextPeriod, gauge3);
        assertEq(vote1.votes, (votingPower3 * weights[0]) / MAX_WEIGHT);
        assertEq(vote1.weight, weights[0]);
        assertEq(vote2.votes, (votingPower3 * weights[1]) / MAX_WEIGHT);
        assertEq(vote2.weight, weights[1]);
        assertEq(vote3.votes, (votingPower3 * weights[2]) / MAX_WEIGHT);
        assertEq(vote3.weight, weights[2]);

        assertEq(voter.gaugeVote(1, nextPeriod, 0), gauge1);
        assertEq(voter.gaugeVote(1, nextPeriod, 1), gauge2);
        assertEq(voter.gaugeVote(1, nextPeriod, 2), gauge3);

        assertEq(voter.gaugeVote(2, nextPeriod, 0), gauge1);
        assertEq(voter.gaugeVote(2, nextPeriod, 1), gauge2);
        assertEq(voter.gaugeVote(2, nextPeriod, 2), gauge3);

        assertEq(voter.gaugeVote(3, nextPeriod, 0), gauge1);
        assertEq(voter.gaugeVote(3, nextPeriod, 1), gauge2);
        assertEq(voter.gaugeVote(3, nextPeriod, 2), gauge3);

        assertEq(ve.voted(1), true);
        assertEq(ve.voted(2), true);
        assertEq(ve.voted(3), true);
    }

}