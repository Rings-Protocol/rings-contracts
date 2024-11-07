// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VoterTest.t.sol";

contract KillGauge is VoterTest {
    address gauge1;
    address gauge2;

    function setUp() public virtual override {
        super.setUp();

        gauge1 = makeAddr("gauge1");
        gauge2 = makeAddr("gauge2");

        vm.startPrank(owner);
        voter.addGauge(gauge1, "Mock Gauge 1");
        vm.stopPrank();
    }

    function test_kill_correctly() public {
        assertEq(voter.isAlive(gauge1), true, "Gauge should be alive");

        vm.expectEmit(true, true, true, true);
        emit Voter.GaugeKilled(gauge1);

        vm.prank(owner);
        voter.killGauge(gauge1);

        assertEq(voter.isAlive(gauge1), false, "Gauge should not be alive");
    }

    function test_fail_not_listed() public {
        vm.expectRevert(Voter.GaugeNotListed.selector);
        vm.prank(owner);
        voter.killGauge(gauge2);
    }

    function test_fail_already_killed() public {
        vm.prank(owner);
        voter.killGauge(gauge1);

        vm.expectRevert(Voter.GaugeAlreadyKilled.selector);
        vm.prank(owner);
        voter.killGauge(gauge1);
    }

    function test_fail_zero_address() public {
        vm.expectRevert(Voter.ZeroAddress.selector);
        vm.prank(owner);
        voter.killGauge(zero);
    }

    function test_fail_not_owner() public {
        vm.expectRevert();
        voter.killGauge(gauge1);
    }

}