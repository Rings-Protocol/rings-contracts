// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VoterTest.t.sol";

contract ReviveGauge is VoterTest {

    error GaugeNotKilled();
    error ZeroAddress();
    error GaugeNotListed();

    event GaugeRevived(address indexed gauge);

    address gauge1;
    address gauge2;
    address gauge3;

    function setUp() public virtual override {
        super.setUp();

        gauge1 = makeAddr("gauge1");
        gauge2 = makeAddr("gauge2");
        gauge3 = makeAddr("gauge3");

        vm.startPrank(owner);
        voter.addGauge(gauge1, "Mock Gauge 1");
        voter.addGauge(gauge2, "Mock Gauge 2");
        vm.stopPrank();

        vm.prank(owner);
        voter.killGauge(gauge1);
    }

    function test_unkill_correctly() public {
        assertEq(voter.isAlive(gauge1), false, "Gauge should be killed");

        vm.expectEmit(true, true, true, true);
        emit GaugeRevived(gauge1);

        vm.prank(owner);
        voter.reviveGauge(gauge1);

        assertEq(voter.isAlive(gauge1), true, "Gauge should be alive");
    }

    function test_fail_not_listed() public {
        vm.expectRevert(GaugeNotListed.selector);
        vm.prank(owner);
        voter.reviveGauge(gauge3);
    }

    function test_fail_not_killed() public {
        vm.expectRevert(GaugeNotKilled.selector);
        vm.prank(owner);
        voter.reviveGauge(gauge2);
    }

    function test_fail_zero_address() public {
        vm.expectRevert(ZeroAddress.selector);
        vm.prank(owner);
        voter.reviveGauge(zero);
    }

    function test_fail_not_owner() public {
        vm.expectRevert();
        voter.reviveGauge(gauge1);
    }

}