// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { Script, console } from "forge-std/Script.sol";
import { Voter } from "src/Voter.sol";

contract DistributeYieldScript is Script {
    Voter voterUSD;
    Voter voterETH;

    function setUp() external {
        voterUSD = Voter(0xF365C45B6913BE7Ab74C970D9227B9D0dfF44aFb);
        voterETH = Voter(0x9842be0f52569155fA58fff36E772bC79D92706e);
    }

    function _distributeYield(Voter _voter) internal {
        uint256 gaugesCount = _voter.gaugesCount();

        for (uint256 i = 0; i < gaugesCount; i++) {
            address gauge = _voter.gauges(i);
            _voter.claimGaugeRewards(gauge);
        }
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerPrivateKey);
        vm.startBroadcast(deployer);

        _distributeYield(voterUSD);
        _distributeYield(voterETH);

        vm.stopBroadcast();
    }
}