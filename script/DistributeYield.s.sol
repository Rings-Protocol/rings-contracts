// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { Script, console } from "forge-std/Script.sol";
import { Voter } from "src/Voter.sol";

contract DistributeYieldScript is Script {
    Voter voterUSD;
    Voter voterETH;

    function setUp() external {
        voterUSD = Voter(0xB84194E28f624BBBA3C9181F3a1120eE76469337);
        voterETH = Voter(0x43739B96B19aE7C2E0d80BE7832325846f55Fa05);
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