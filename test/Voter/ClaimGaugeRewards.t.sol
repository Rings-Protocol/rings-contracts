// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VoterTest.t.sol";

contract ClaimGaugeRewards is VoterTest {
    address gauge1;
    address gauge2;
    address gauge3;
    address gauge4;
    address gauge5;

    address wrongGauge;

    address[] gauges;
    uint256[] weights;
    address[] gauges2;
    uint256[] weights2;
    address[] gauges3;
    uint256[] weights3;

    uint256 startTs;

    function setUp() public virtual override {
        super.setUp();

        startTs = block.timestamp;

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
        createNft(address(alice), 150e18);
        createNft(address(bob), 12e18);

        vm.startPrank(owner);
        voter.addGauge(gauge1, "Mock Gauge 1");
        voter.addGauge(gauge2, "Mock Gauge 2");
        voter.addGauge(gauge3, "Mock Gauge 3");
        voter.addGauge(gauge4, "Mock Gauge 4");
        voter.addGauge(gauge5, "Mock Gauge 5");
        vm.stopPrank();

        vm.warp(startTs + 5 days);

        voter.depositBudget(10e19);

        gauges.push(gauge1);
        gauges.push(gauge2);
        gauges.push(gauge3);
        weights.push(5000);
        weights.push(2000);
        weights.push(3000);
        gauges2.push(gauge1);
        gauges2.push(gauge2);
        weights2.push(3000);
        weights2.push(7000);
        gauges3.push(gauge2);
        gauges3.push(gauge3);
        gauges3.push(gauge4);
        weights3.push(1000);
        weights3.push(6000);
        weights3.push(3000);

        vm.prank(alice);
        voter.vote(1, gauges, weights);

        vm.prank(bob);
        voter.vote(2, gauges2, weights2);

        vm.prank(alice);
        voter.vote(3, gauges3, weights3);

        vm.prank(owner);
        voter.killGauge(gauge4);

        vm.warp(startTs + 12 days);
    }

    function test_claim_1_period_correctly() public {
        uint256 currentPeriod = voter.currentPeriod();

        uint256 gaugeVotes = voter.votesPerPeriod(currentPeriod, gauge1);
        uint256 totalVotes = voter.totalVotesPerPeriod(currentPeriod);

        uint256 gaugeRelativeWeight = gaugeVotes * UNIT / totalVotes;
        uint256 periodBudget = voter.periodBudget(currentPeriod);

        uint256 expectedReward = periodBudget * gaugeRelativeWeight / UNIT;

        uint256 prevGaugeBalancer = scUSD.balanceOf(gauge1);
        uint256 prevVoterBalance = scUSD.balanceOf(address(voter));

        vm.expectEmit(true, true, true, true);
        emit Voter.RewardClaimed(gauge1, expectedReward);
        emit IERC20.Transfer(address(voter), gauge1, expectedReward);

        uint256 claimedAmount = voter.claimGaugeRewards(gauge1);

        assertEq(claimedAmount, expectedReward);

        assertEq(scUSD.balanceOf(gauge1), prevGaugeBalancer + expectedReward);
        assertEq(scUSD.balanceOf(address(voter)), prevVoterBalance - expectedReward);

        assertEq(voter.gaugesDistributionTimestamp(gauge1), currentPeriod + WEEK);
    }

    function test_claim_multiple_periods_correctly() public {
        uint256 firstPeriod = ((startTs + 12 days) / WEEK) * WEEK;

        // Deposit the budgets and recast the votes for the periods to pass

        voter.depositBudget(10e19);
        vm.prank(alice);
        voter.recast(1);
        vm.prank(bob);
        voter.recast(2);

        vm.warp(startTs + 19 days);

        voter.depositBudget(10e19);
        vm.prank(alice);
        voter.recast(1);
        vm.prank(bob);
        voter.recast(2);

        vm.warp(startTs + 26 days);

        voter.depositBudget(10e19);
        vm.prank(alice);
        voter.recast(1);
        vm.prank(bob);
        voter.recast(2);

        vm.warp(startTs + 33 days);

        uint256 currentPeriod = voter.currentPeriod();

        uint256 expectedReward;
        uint256 periodIter = firstPeriod;

        while (periodIter <= currentPeriod) {
            uint256 gaugeVotes = voter.votesPerPeriod(periodIter, gauge1);
            uint256 totalVotes = voter.totalVotesPerPeriod(periodIter);

            uint256 gaugeRelativeWeight = gaugeVotes * UNIT / totalVotes;
            uint256 periodBudget = voter.periodBudget(periodIter);

            expectedReward += periodBudget * gaugeRelativeWeight / UNIT;

            periodIter += WEEK;
        }

        uint256 prevGaugeBalancer = scUSD.balanceOf(gauge1);
        uint256 prevVoterBalance = scUSD.balanceOf(address(voter));

        vm.expectEmit(true, true, true, true);
        emit Voter.RewardClaimed(gauge1, expectedReward);
        emit IERC20.Transfer(address(voter), gauge1, expectedReward);

        uint256 claimedAmount = voter.claimGaugeRewards(gauge1);

        assertEq(claimedAmount, expectedReward);

        assertEq(scUSD.balanceOf(gauge1), prevGaugeBalancer + expectedReward);
        assertEq(scUSD.balanceOf(address(voter)), prevVoterBalance - expectedReward);

        assertEq(voter.gaugesDistributionTimestamp(gauge1), currentPeriod + WEEK);
    }

    function test_no_claim_no_votes_received() public {
        vm.warp(startTs + 20 days);

        uint256 prevGaugeBalancer = scUSD.balanceOf(gauge5);
        uint256 prevVoterBalance = scUSD.balanceOf(address(voter));

        uint256 claimedAmount = voter.claimGaugeRewards(gauge5);

        assertEq(claimedAmount, 0);

        assertEq(scUSD.balanceOf(gauge1), prevGaugeBalancer);
        assertEq(scUSD.balanceOf(address(voter)), prevVoterBalance);
    }

    function test_no_claim_not_listed() public {
        vm.warp(startTs + 20 days);

        uint256 prevGaugeBalancer = scUSD.balanceOf(wrongGauge);
        uint256 prevVoterBalance = scUSD.balanceOf(address(voter));

        uint256 claimedAmount = voter.claimGaugeRewards(wrongGauge);

        assertEq(claimedAmount, 0);

        assertEq(scUSD.balanceOf(gauge1), prevGaugeBalancer);
        assertEq(scUSD.balanceOf(address(voter)), prevVoterBalance);
    }

    function test_no_claim_killed() public {
        vm.warp(startTs + 20 days);

        uint256 prevGaugeBalancer = scUSD.balanceOf(gauge4);
        uint256 prevVoterBalance = scUSD.balanceOf(address(voter));

        uint256 claimedAmount = voter.claimGaugeRewards(gauge4);

        assertEq(claimedAmount, 0);

        assertEq(scUSD.balanceOf(gauge1), prevGaugeBalancer);
        assertEq(scUSD.balanceOf(address(voter)), prevVoterBalance);
    }
}
