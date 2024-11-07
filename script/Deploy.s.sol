// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { Script, console } from "forge-std/Script.sol";
import { VeArtProxy } from "src/VeArtProxy.sol";
import { VotingEscrow } from "src/VotingEscrow.sol";
import { Voter } from "src/Voter.sol";

contract DeployScript is Script {
    address owner;
    address token;

    address deployer;

    VeArtProxy veArtProxy;
    VotingEscrow votingEscrow;
    Voter voter;

    function setUp() public {
        // All variables to set up the contracts
        // TODO: don't forget to update name and symbol of veNFT
        owner = address(0x0);
        token = address(0x0);
    }

    function _deployVeArtProxy() internal {
        veArtProxy = new VeArtProxy();
        console.log("VeArtProxy deployed at: ", address(veArtProxy));
    }

    function _deployVotingEscrow() internal {
        votingEscrow = new VotingEscrow(token, address(veArtProxy));
        console.log("VotingEscrow deployed at: ", address(votingEscrow));
    }

    function _deployVoter() internal {
        voter = new Voter(owner, address(votingEscrow), token);
        console.log("Voter deployed at: ", address(voter));
    }

    function _deployContracts() internal {
        _deployVeArtProxy();
        _deployVotingEscrow();
        _deployVoter();

        votingEscrow.setVoter(address(voter));
        votingEscrow.setTeam(owner);
    }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        deployer = vm.rememberKey(deployerPrivateKey);
        vm.startBroadcast(deployer);

        _deployContracts();

        vm.stopBroadcast();
    }
}
