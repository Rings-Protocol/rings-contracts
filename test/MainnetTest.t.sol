// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.24;

import "./BaseTest.t.sol";
import { IERC20 } from "openzeppelin-contracts/token/ERC20/ERC20.sol";

contract MainnetTest is BaseTest {
    // Put here the contracts that your project needs
    // E.g. IERC20 someToken = IERC20(0x0000000);

    address operator = makeAddr("operator");

    function setUp() public virtual {
        // Add known labels here
        // E.g. vm.label(address(someToken), "someToken");
    }

    function fork() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), 17_544_699); // Change the block number if needed
    }

    function fork(uint256 blockNumber) public {
        vm.createSelectFork(vm.rpcUrl("mainnet"), blockNumber);
    }
}
