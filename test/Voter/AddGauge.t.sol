// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VoterTest.t.sol";

contract AddGauge is VoterTest {

    error GaugeAlreadyListed();
    error ZeroAddress();

    event GaugeAdded(address indexed gauge);
    
    address gauge;

    function setUp() public virtual override {
        super.setUp();

        gauge = makeAddr("gauge");
    }

    function test_add_correctly() public {
        uint256 prevGaugeCount = voter.gaugesCount();

        vm.expectEmit(true, true, true, true);
        emit GaugeAdded(gauge);

        vm.prank(owner);
        voter.addGauge(gauge, "Mock Gauge");

        assertEq(voter.gaugesCount(), prevGaugeCount + 1, "Gauge count should increase by 1");
        assertEq(voter.gauges(0), gauge, "Gauge should be in the correct spot in the list");
        assertEq(voter.gaugeIndex(gauge), 0, "Gauge should have the correct index");
        assertEq(voter.isGauge(gauge), true, "Gauge should be valid");
        assertEq(voter.isAlive(gauge), true, "Gauge should be alive");
        assertEq(
            voter.gaugesDistributionTimestamp(gauge),
            voter.currentPeriod(),
            "Gauge should have next distribution timestamp set to current period"
        );
        assertEq(voter.gaugeLabel(gauge), "Mock Gauge", "Gauge should have the correct label");
    }

    function test_add_correctly_subsequents() public {
        address gauge2 = makeAddr("gauge2");
        address gauge3 = makeAddr("gauge3");

        vm.prank(owner);
        voter.addGauge(gauge, "Mock Gauge");

        uint256 prevGaugeCount = voter.gaugesCount();

        vm.expectEmit(true, true, true, true);
        emit GaugeAdded(gauge2);

        vm.prank(owner);
        voter.addGauge(gauge2, "Mock Gauge 2");

        vm.expectEmit(true, true, true, true);
        emit GaugeAdded(gauge3);

        vm.prank(owner);
        voter.addGauge(gauge3, "Mock Gauge 3");

        assertEq(voter.gaugesCount(), prevGaugeCount + 2, "Gauge count should increase by 2");
        assertEq(voter.gauges(1), gauge2, "Gauge should be in the correct spot in the list");
        assertEq(voter.gauges(2), gauge3, "Gauge should be in the correct spot in the list");
        assertEq(voter.gaugeIndex(gauge2), 1, "Gauge should have the correct index");
        assertEq(voter.gaugeIndex(gauge3), 2, "Gauge should have the correct index");
        assertEq(voter.isGauge(gauge2), true, "Gauge should be valid");
        assertEq(voter.isAlive(gauge2), true, "Gauge should be alive");
        assertEq(voter.isGauge(gauge3), true, "Gauge should be valid");
        assertEq(voter.isAlive(gauge3), true, "Gauge should be alive");
        assertEq(
            voter.gaugesDistributionTimestamp(gauge2),
            voter.currentPeriod(),
            "Gauge should have next distribution timestamp set to current period"
        );
        assertEq(
            voter.gaugesDistributionTimestamp(gauge3),
            voter.currentPeriod(),
            "Gauge should have next distribution timestamp set to current period"
        );
        assertEq(voter.gaugeLabel(gauge2), "Mock Gauge 2", "Gauge should have the correct label");
        assertEq(voter.gaugeLabel(gauge3), "Mock Gauge 3", "Gauge should have the correct label");
    }

    function test_fail_already_listed() public {
        vm.prank(owner);
        voter.addGauge(gauge, "Mock Gauge");

        vm.expectRevert(GaugeAlreadyListed.selector);
        vm.prank(owner);
        voter.addGauge(gauge, "Mock Gauge");
    }

    function test_fail_address_zero() public {
        vm.expectRevert(ZeroAddress.selector);
        vm.prank(owner);
        voter.addGauge(zero, "Mock Gauge");
    }

    function test_fail_not_owner() public {
        vm.expectRevert();
        voter.addGauge(gauge, "Mock Gauge");
    }

}