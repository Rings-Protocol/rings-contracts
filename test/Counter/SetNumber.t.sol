// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.24;

import "./CounterTest.t.sol";

contract SetNumber is CounterTest {
    function test_setNumber_simple() public {
        counter.setNumber(42);
        assertEq(counter.number(), 42);
    }
}