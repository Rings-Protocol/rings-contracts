// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VoterTest.t.sol";

contract UpdateGaugeCap is VoterTest {
    address gauge1;
    address gauge2;

    uint256 internal newCap = 0.25e18;

    function setUp() public virtual override {
        super.setUp();

        gauge1 = makeAddr("gauge1");
        gauge2 = makeAddr("gauge2");

        vm.startPrank(owner);
        voter.addGauge(gauge1, "Mock Gauge 1", gaugeCap);
        vm.stopPrank();
    }

    function test_update_correctly() public {
        assertEq(voter.gaugeCaps(gauge1), gaugeCap, "Gauge cap should be the old one");

        vm.expectEmit(true, true, true, true);
        emit Voter.GaugeCapUpdated(gauge1, newCap);

        vm.prank(owner);
        voter.updateGaugeCap(gauge1, newCap);

        assertEq(voter.gaugeCaps(gauge1), newCap, "Gauge cap should be the new one");
    }

    function test_fail_not_listed() public {
        vm.expectRevert(Voter.GaugeNotListed.selector);
        vm.prank(owner);
        voter.updateGaugeCap(gauge2, newCap);
    }

    function test_fail_killed() public {
        vm.prank(owner);
        voter.killGauge(gauge1);

        vm.expectRevert(Voter.KilledGauge.selector);
        vm.prank(owner);
        voter.updateGaugeCap(gauge1, newCap);
    }

    function test_fail_zero_address() public {
        vm.expectRevert(Voter.ZeroAddress.selector);
        vm.prank(owner);
        voter.updateGaugeCap(zero, newCap);
    }

    function test_fail_invalid_cap(uint256 cap) public {
        vm.assume(cap > 1e18);

        vm.expectRevert(Voter.InvalidCap.selector);
        vm.prank(owner);
        voter.updateGaugeCap(gauge1, cap);
    }

    function test_fail_not_owner() public {
        vm.expectRevert();
        voter.updateGaugeCap(gauge1, newCap);
    }
}
