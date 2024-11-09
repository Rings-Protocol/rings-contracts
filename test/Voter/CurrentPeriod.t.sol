// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VoterTest.t.sol";

contract CuurentPeriod is VoterTest {
    function test_return_correct_period() public {
        uint256 startTs = vm.getBlockTimestamp();

        assertEq(voter.currentPeriod(), (startTs / WEEK) * WEEK, "1st check failed");

        uint256 newTs = startTs + 1 days;
        vm.warp(newTs);

        assertEq(voter.currentPeriod(), ((startTs + 1 days) / WEEK) * WEEK, "2nd check failed");

        newTs += 4 days;
        vm.warp(newTs);

        assertEq(voter.currentPeriod(), ((startTs + 5 days) / WEEK) * WEEK, "3rd check failed");

        newTs += 10 days;
        vm.warp(newTs);

        assertEq(voter.currentPeriod(), ((startTs + 15 days) / WEEK) * WEEK, "4th check failed");
    }
}
