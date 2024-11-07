// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VoterTest.t.sol";
import { Voter } from "src/Voter.sol";

contract Getters is VoterTest {
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

    uint256 startTs;
    uint256 inspectPeriod;

    function setUp() public virtual override {
        super.setUp();

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

        vm.startPrank(owner);
        voter.addGauge(gauge1, "Mock Gauge 1");
        voter.addGauge(gauge2, "Mock Gauge 2");
        voter.addGauge(gauge3, "Mock Gauge 3");
        voter.addGauge(gauge4, "Mock Gauge 4");
        vm.stopPrank();

        startTs = block.timestamp;

        vm.warp(startTs + 5 days);

        voter.depositBudget(10e19);

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

        vm.warp(startTs + 12 days);

        voter.depositBudget(10e19);
        vm.prank(alice);
        voter.recast(1);
        vm.prank(bob);
        voter.recast(2);
        vm.prank(alice);
        voter.recast(3);

        vm.warp(startTs + 19 days);

        voter.depositBudget(10e19);
        vm.prank(alice);
        voter.recast(1);
        vm.prank(bob);
        voter.recast(2);
        vm.prank(alice);
        voter.recast(3);

        inspectPeriod = ((startTs + 12 days) / WEEK) * WEEK;
    }

    function test_getNftCurrentVotes() public view {
        uint256 votingPower = ve.balanceOfNFT(1);

        Voter.CastedVote[] memory castedVotes = voter.getNftCurrentVotes(1);

        assertEq(castedVotes.length, 3);

        assertEq(castedVotes[0].gauge, gauge1);
        assertEq(castedVotes[0].weight, weights[0]);
        assertEq(castedVotes[0].votes, votingPower * weights[0] / MAX_WEIGHT);

        assertEq(castedVotes[1].gauge, gauge2);
        assertEq(castedVotes[1].weight, weights[1]);
        assertEq(castedVotes[1].votes, votingPower * weights[1] / MAX_WEIGHT);

        assertEq(castedVotes[2].gauge, gauge3);
        assertEq(castedVotes[2].weight, weights[2]);
        assertEq(castedVotes[2].votes, votingPower * weights[2] / MAX_WEIGHT);
    }

    function test_getNftCurrentVotesAtPeriod() public view {
        uint256 votingPower = ve.balanceOfNFTAt(3, startTs + 5 days);

        Voter.CastedVote[] memory castedVotes = voter.getNftCurrentVotesAtPeriod(3, inspectPeriod);

        assertEq(castedVotes.length, 3);

        assertEq(castedVotes[0].gauge, gauges3[0]);
        assertEq(castedVotes[0].weight, weights3[0]);
        assertEq(castedVotes[0].votes, votingPower * weights3[0] / MAX_WEIGHT);

        assertEq(castedVotes[1].gauge, gauges3[1]);
        assertEq(castedVotes[1].weight, weights3[1]);
        assertEq(castedVotes[1].votes, votingPower * weights3[1] / MAX_WEIGHT);

        assertEq(castedVotes[2].gauge, gauges3[2]);
        assertEq(castedVotes[2].weight, weights3[2]);
        assertEq(castedVotes[2].votes, votingPower * weights3[2] / MAX_WEIGHT);
    }

    function test_getTotalVotes() public view {
        uint256 expectedTotal = ve.balanceOfNFT(1);
        expectedTotal += ve.balanceOfNFT(2);
        expectedTotal += ve.balanceOfNFT(3);

        assertEq(voter.getTotalVotes(), expectedTotal);
    }

    function test_getGaugeVotes() public view {
        uint256 balance1 = ve.balanceOfNFT(1);
        uint256 balance2 = ve.balanceOfNFT(2);
        uint256 balance3 = ve.balanceOfNFT(3);
        uint256 expectedGauge1Votes = ((balance1 * weights[0]) / MAX_WEIGHT) + ((balance3 * weights3[2]) / MAX_WEIGHT);
        uint256 expectedGauge2Votes = ((balance1 * weights[1]) / MAX_WEIGHT) + ((balance2 * weights2[0]) / MAX_WEIGHT);
        uint256 expectedGauge3Votes = ((balance1 * weights[2]) / MAX_WEIGHT) + ((balance3 * weights3[0]) / MAX_WEIGHT);
        uint256 expectedGauge4Votes = ((balance2 * weights2[1]) / MAX_WEIGHT) + ((balance3 * weights3[1]) / MAX_WEIGHT);

        assertEq(voter.getGaugeVotes(gauge1), expectedGauge1Votes);
        assertEq(voter.getGaugeVotes(gauge2), expectedGauge2Votes);
        assertEq(voter.getGaugeVotes(gauge3), expectedGauge3Votes);
        assertEq(voter.getGaugeVotes(gauge4), expectedGauge4Votes);
    }

    function test_getNftVotesOnGauge() public view {
        uint256 balance1 = ve.balanceOfNFT(1);
        uint256 balance2 = ve.balanceOfNFT(2);
        uint256 balance3 = ve.balanceOfNFT(3);
        assertEq(voter.getNftVotesOnGauge(1, gauge1), (balance1 * weights[0]) / MAX_WEIGHT);
        assertEq(voter.getNftVotesOnGauge(1, gauge2), (balance1 * weights[1]) / MAX_WEIGHT);
        assertEq(voter.getNftVotesOnGauge(2, gauge2), (balance2 * weights2[0]) / MAX_WEIGHT);
        assertEq(voter.getNftVotesOnGauge(2, gauge4), (balance2 * weights2[1]) / MAX_WEIGHT);
        assertEq(voter.getNftVotesOnGauge(3, gauge4), (balance3 * weights3[1]) / MAX_WEIGHT);
    }

    function test_getTotalVotesAtPeriod() public view {
        uint256 expectedTotal = ve.balanceOfNFTAt(1, startTs + 5 days);
        expectedTotal += ve.balanceOfNFTAt(2, startTs + 5 days);
        expectedTotal += ve.balanceOfNFTAt(3, startTs + 5 days);

        assertEq(voter.getTotalVotesAtPeriod(inspectPeriod), expectedTotal);
    }

    function test_getGaugeVotesAtPeriod() public view {
        uint256 balance1 = ve.balanceOfNFTAt(1, startTs + 5 days);
        uint256 balance2 = ve.balanceOfNFTAt(2, startTs + 5 days);
        uint256 balance3 = ve.balanceOfNFTAt(3, startTs + 5 days);
        uint256 expectedGauge1Votes = ((balance1 * weights[0]) / MAX_WEIGHT) + ((balance3 * weights3[2]) / MAX_WEIGHT);
        uint256 expectedGauge2Votes = ((balance1 * weights[1]) / MAX_WEIGHT) + ((balance2 * weights2[0]) / MAX_WEIGHT);
        uint256 expectedGauge3Votes = ((balance1 * weights[2]) / MAX_WEIGHT) + ((balance3 * weights3[0]) / MAX_WEIGHT);
        uint256 expectedGauge4Votes = ((balance2 * weights2[1]) / MAX_WEIGHT) + ((balance3 * weights3[1]) / MAX_WEIGHT);

        assertEq(voter.getGaugeVotesAtPeriod(gauge1, inspectPeriod), expectedGauge1Votes);
        assertEq(voter.getGaugeVotesAtPeriod(gauge2, inspectPeriod), expectedGauge2Votes);
        assertEq(voter.getGaugeVotesAtPeriod(gauge3, inspectPeriod), expectedGauge3Votes);
        assertEq(voter.getGaugeVotesAtPeriod(gauge4, inspectPeriod), expectedGauge4Votes);
    }

    function test_getNftVotesOnGaugeAtPeriod() public view {
        uint256 balance1 = ve.balanceOfNFTAt(1, startTs + 5 days);
        uint256 balance2 = ve.balanceOfNFTAt(2, startTs + 5 days);
        uint256 balance3 = ve.balanceOfNFTAt(3, startTs + 5 days);

        assertEq(voter.getNftVotesOnGaugeAtPeriod(1, gauge1, inspectPeriod), (balance1 * weights[0]) / MAX_WEIGHT);
        assertEq(voter.getNftVotesOnGaugeAtPeriod(1, gauge2, inspectPeriod), (balance1 * weights[1]) / MAX_WEIGHT);
        assertEq(voter.getNftVotesOnGaugeAtPeriod(2, gauge2, inspectPeriod), (balance2 * weights2[0]) / MAX_WEIGHT);
        assertEq(voter.getNftVotesOnGaugeAtPeriod(2, gauge4, inspectPeriod), (balance2 * weights2[1]) / MAX_WEIGHT);
        assertEq(voter.getNftVotesOnGaugeAtPeriod(3, gauge4, inspectPeriod), (balance3 * weights3[1]) / MAX_WEIGHT);
    }

    function test_getGaugeRelativeWeight() public view {
        uint256 totalVotes = voter.getTotalVotes();
        uint256 expectedGauge1RelativeWeight = (voter.getGaugeVotes(gauge1) * UNIT) / totalVotes;
        uint256 expectedGauge2RelativeWeight = (voter.getGaugeVotes(gauge2) * UNIT) / totalVotes;
        uint256 expectedGauge3RelativeWeight = (voter.getGaugeVotes(gauge3) * UNIT) / totalVotes;
        uint256 expectedGauge4RelativeWeight = (voter.getGaugeVotes(gauge4) * UNIT) / totalVotes;

        assertEq(voter.getGaugeRelativeWeight(gauge1), expectedGauge1RelativeWeight);
        assertEq(voter.getGaugeRelativeWeight(gauge2), expectedGauge2RelativeWeight);
        assertEq(voter.getGaugeRelativeWeight(gauge3), expectedGauge3RelativeWeight);
        assertEq(voter.getGaugeRelativeWeight(gauge4), expectedGauge4RelativeWeight);
    }

    function test_getGaugeRelativeWeightAtPeriod() public view {
        uint256 totalVotes = voter.getTotalVotesAtPeriod(inspectPeriod);
        uint256 expectedGauge1RelativeWeight = (voter.getGaugeVotesAtPeriod(gauge1, inspectPeriod) * UNIT) / totalVotes;
        uint256 expectedGauge2RelativeWeight = (voter.getGaugeVotesAtPeriod(gauge2, inspectPeriod) * UNIT) / totalVotes;
        uint256 expectedGauge3RelativeWeight = (voter.getGaugeVotesAtPeriod(gauge3, inspectPeriod) * UNIT) / totalVotes;
        uint256 expectedGauge4RelativeWeight = (voter.getGaugeVotesAtPeriod(gauge4, inspectPeriod) * UNIT) / totalVotes;

        assertEq(voter.getGaugeRelativeWeightAtPeriod(gauge1, inspectPeriod), expectedGauge1RelativeWeight);
        assertEq(voter.getGaugeRelativeWeightAtPeriod(gauge2, inspectPeriod), expectedGauge2RelativeWeight);
        assertEq(voter.getGaugeRelativeWeightAtPeriod(gauge3, inspectPeriod), expectedGauge3RelativeWeight);
        assertEq(voter.getGaugeRelativeWeightAtPeriod(gauge4, inspectPeriod), expectedGauge4RelativeWeight);
    }

    function test_getGaugeRelativeWeightAtPeriod_beforeVotes() public view {
        uint256 p = ((startTs - WEEK) / WEEK) * WEEK;

        assertEq(voter.getGaugeRelativeWeightAtPeriod(gauge1, p), 0);
        assertEq(voter.getGaugeRelativeWeightAtPeriod(gauge2, p), 0);
        assertEq(voter.getGaugeRelativeWeightAtPeriod(gauge3, p), 0);
        assertEq(voter.getGaugeRelativeWeightAtPeriod(gauge4, p), 0);
    }

    function test_getGaugeRelativeWeight_killed_gauge() public {
        vm.prank(owner);
        voter.killGauge(gauge4);

        assertEq(voter.getGaugeRelativeWeight(gauge4), 0);
        assertEq(voter.getGaugeRelativeWeightAtPeriod(gauge4, inspectPeriod), 0);
    }

}