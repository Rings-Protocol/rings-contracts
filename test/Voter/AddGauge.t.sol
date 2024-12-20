// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VoterTest.t.sol";

contract AddGauge is VoterTest {
    function test_add_correctly(address gauge) public {
        vm.assume(gauge != address(0));

        uint256 prevGaugeCount = voter.gaugesCount();

        vm.expectEmit(true, true, true, true);
        emit Voter.GaugeAdded(gauge, gaugeCap);

        vm.prank(owner);
        voter.addGauge(gauge, "Mock Gauge", gaugeCap);

        assertEq(voter.gaugesCount(), prevGaugeCount + 1, "Gauge count should increase by 1");
        assertEq(voter.gauges(0), gauge, "Gauge should be in the correct spot in the list");
        assertEq(voter.gaugeIndex(gauge), 0, "Gauge should have the correct index");
        assertEq(voter.gaugeCaps(gauge), gaugeCap, "Gauge should have the correct cap");
        assertEq(voter.isGauge(gauge), true, "Gauge should be valid");
        assertEq(voter.isAlive(gauge), true, "Gauge should be alive");
        assertEq(
            voter.gaugesDistributionTimestamp(gauge),
            voter.currentPeriod(),
            "Gauge should have next distribution timestamp set to current period"
        );
        assertEq(voter.gaugeLabel(gauge), "Mock Gauge", "Gauge should have the correct label");
    }

    function test_add_correctly_subsequents(address gauge, address gauge2, address gauge3) public {
        vm.assume(gauge != address(0));
        vm.assume(gauge2 != address(0));
        vm.assume(gauge3 != address(0));
        vm.assume(gauge != gauge2);
        vm.assume(gauge != gauge3);
        vm.assume(gauge2 != gauge3);

        vm.prank(owner);
        voter.addGauge(gauge, "Mock Gauge", gaugeCap);

        uint256 prevGaugeCount = voter.gaugesCount();

        vm.expectEmit(true, true, true, true);
        emit Voter.GaugeAdded(gauge2, 0.3e18);

        vm.prank(owner);
        voter.addGauge(gauge2, "Mock Gauge 2", 0.3e18);

        vm.expectEmit(true, true, true, true);
        emit Voter.GaugeAdded(gauge3, 0);

        vm.prank(owner);
        voter.addGauge(gauge3, "Mock Gauge 3", 0);

        assertEq(voter.gaugesCount(), prevGaugeCount + 2, "Gauge count should increase by 2");
        assertEq(voter.gauges(1), gauge2, "Gauge should be in the correct spot in the list");
        assertEq(voter.gauges(2), gauge3, "Gauge should be in the correct spot in the list");
        assertEq(voter.gaugeIndex(gauge2), 1, "Gauge should have the correct index");
        assertEq(voter.gaugeIndex(gauge3), 2, "Gauge should have the correct index");
        assertEq(voter.gaugeCaps(gauge2), 0.3e18, "Gauge should have the correct cap");
        assertEq(voter.gaugeCaps(gauge3), 0, "Gauge should have the correct cap");
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

    function test_fail_already_listed(address gauge) public {
        vm.assume(gauge != address(0));

        vm.prank(owner);
        voter.addGauge(gauge, "Mock Gauge", gaugeCap);

        vm.expectRevert(Voter.GaugeAlreadyListed.selector);
        vm.prank(owner);
        voter.addGauge(gauge, "Mock Gauge", gaugeCap);
    }

    function test_fail_address_zero() public {
        vm.expectRevert(Voter.ZeroAddress.selector);
        vm.prank(owner);
        voter.addGauge(zero, "Mock Gauge", gaugeCap);
    }

    function test_fail_invalid_cap(address gauge, uint256 cap) public {
        vm.assume(cap > 1e18);

        vm.expectRevert(Voter.InvalidCap.selector);
        vm.prank(owner);
        voter.addGauge(gauge, "Mock Gauge", cap);
    }

    function test_fail_not_owner(address gauge) public {
        vm.assume(gauge != address(0));

        vm.expectRevert();
        voter.addGauge(gauge, "Mock Gauge", gaugeCap);
    }
}
