// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { Script, console } from "forge-std/Script.sol";
//import { Counter } from "src/Counter.sol";

contract DeployScript is Script {
    address owner;

    function setUp() public {
        // All variables to set up the contracts
        owner = vm.envAddress("OWNER");
    }

    function _deployCounter() internal { // returns (Counter) {
        //Counter counter = new Counter();
        //console.log("Zap deployed at: %s", address(counter));

        //return counter;
    }

    function _deployContracts() internal {
        _deployCounter();
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerPrivateKey);
        vm.startBroadcast(deployer);

        _deployContracts();

        vm.stopBroadcast();
    }
}
