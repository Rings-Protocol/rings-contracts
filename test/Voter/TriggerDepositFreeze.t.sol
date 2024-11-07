// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VoterTest.t.sol";

contract TriggerDepositFreeze is VoterTest {
    function test_trigger_correctly() public {
        bool isFrozen = voter.isDepositFrozen();

        vm.expectEmit(true, true, true, true);
        emit Voter.DepositFreezeTriggered(!isFrozen);

        vm.prank(owner);
        voter.triggerDepositFreeze();

        assertEq(voter.isDepositFrozen(), !isFrozen, "Should inverse the deposit freeze state");
    }

    function test_trigger_subsepquent_correctly() public {
        vm.prank(owner);
        voter.triggerDepositFreeze();

        bool isFrozen = voter.isDepositFrozen();

        vm.expectEmit(true, true, true, true);
        emit Voter.DepositFreezeTriggered(!isFrozen);

        vm.prank(owner);
        voter.triggerDepositFreeze();

        assertEq(voter.isDepositFrozen(), !isFrozen, "Should inverse the deposit freeze state");
    }

    function test_fail_not_owner() public {
        vm.expectRevert();
        voter.triggerDepositFreeze();
    }
}
