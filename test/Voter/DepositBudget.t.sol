// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VoterTest.t.sol";

contract DepositBudget is VoterTest {

    error NullAmount();
    error DepositFrozen();

    event BudgetDeposited(address indexed depositor, uint256 indexed period, uint256 amount);

    uint256 private constant WEEK = 86400 * 7;

    function setUp() public virtual override {
        super.setUp();
        
        deal(address(scUSD), address(this), 10e30);
        scUSD.approve(address(voter), type(uint256).max);
    }

    function test_deposit_success() public {
        uint256 amount = 10e18;

        uint256 prevThisBalance = scUSD.balanceOf(address(this));
        uint256 prevVoterBalance = scUSD.balanceOf(address(voter));

        uint256 currentPeriod = voter.currentPeriod();
        uint256 depositPeriod = (currentPeriod + (WEEK * 2));

        uint256 prevCurrentPeriodBudget = voter.periodBudget(currentPeriod);
        uint256 prevDepositPeriodBudget = voter.periodBudget(depositPeriod);

        vm.expectEmit(true, true, true, true);
        emit BudgetDeposited(address(this), depositPeriod, amount);

        voter.depositBudget(amount);

        assertEq(scUSD.balanceOf(address(this)), prevThisBalance - amount);
        assertEq(scUSD.balanceOf(address(voter)), prevVoterBalance + amount);

        assertEq(voter.periodBudget(currentPeriod), prevCurrentPeriodBudget);
        assertEq(voter.periodBudget(depositPeriod), prevDepositPeriodBudget + amount);
    }

    function test_deposit_success_fuzz(uint256 amount) public {
        vm.assume(amount > 0);
        vm.assume(amount < 10e25);

        uint256 prevThisBalance = scUSD.balanceOf(address(this));
        uint256 prevVoterBalance = scUSD.balanceOf(address(voter));

        uint256 currentPeriod = voter.currentPeriod();
        uint256 depositPeriod = (currentPeriod + (WEEK * 2));

        uint256 prevCurrentPeriodBudget = voter.periodBudget(currentPeriod);
        uint256 prevDepositPeriodBudget = voter.periodBudget(depositPeriod);

        vm.expectEmit(true, true, true, true);
        emit BudgetDeposited(address(this), depositPeriod, amount);

        voter.depositBudget(amount);

        assertEq(scUSD.balanceOf(address(this)), prevThisBalance - amount);
        assertEq(scUSD.balanceOf(address(voter)), prevVoterBalance + amount);

        assertEq(voter.periodBudget(currentPeriod), prevCurrentPeriodBudget);
        assertEq(voter.periodBudget(depositPeriod), prevDepositPeriodBudget + amount);
    }

    function test_deposit_subsequent_success() public {
        uint256 amount = 10e18;
        uint256 amount2 = 10e18;

        uint256 currentPeriod = voter.currentPeriod();
        uint256 depositPeriod = (currentPeriod + (WEEK * 2));
        uint256 depositPeriod2 = (currentPeriod + (WEEK * 3));

        uint256 prevCurrentPeriodBudget = voter.periodBudget(currentPeriod);
        uint256 prevDepositPeriodBudget = voter.periodBudget(depositPeriod);
        uint256 prevDepositPeriodBudget2 = voter.periodBudget(depositPeriod2);

        vm.expectEmit(true, true, true, true);
        emit BudgetDeposited(address(this), depositPeriod, amount);

        voter.depositBudget(amount);

        vm.warp(block.timestamp + 7 days);

        vm.expectEmit(true, true, true, true);
        emit BudgetDeposited(address(this), depositPeriod2, amount2);

        voter.depositBudget(amount2);

        assertEq(voter.periodBudget(currentPeriod), prevCurrentPeriodBudget);
        assertEq(voter.periodBudget(depositPeriod), prevDepositPeriodBudget + amount);
        assertEq(voter.periodBudget(depositPeriod2), prevDepositPeriodBudget2 + amount2);
    }

    function test_fail_deposit_frozen() public {
        vm.prank(owner);
        voter.triggerDepositFreeze();

        vm.expectRevert(DepositFrozen.selector);
        voter.depositBudget(1e18);
    }

    function test_fail_null_amount() public {
        vm.expectRevert(NullAmount.selector);
        voter.depositBudget(0);
    }

}