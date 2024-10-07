// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.24;

import "../MainnetTest.t.sol";
import { Counter } from "src/Counter.sol";

contract CounterTest is MainnetTest {
    Counter counter;

    function setUp() public virtual override {
        super.setUp();
        fork(); // If needed

        vm.startPrank(owner);

        counter = new Counter();

        vm.stopPrank();
    }
}