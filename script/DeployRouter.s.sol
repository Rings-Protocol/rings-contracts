// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.24;

import { Script, console } from "forge-std/Script.sol";

import { Router } from "src/Router.sol";

contract DeployRouterScript is Script {
    address constant SCUSD = 0xd3DCe716f3eF535C5Ff8d041c1A41C3bd89b97aE;
    address constant SCETH = 0x3bcE5CB273F0F148010BbEa2470e7b5df84C7812;
    address constant SCBTC = 0xBb30e76d9Bb2CC9631F7fC5Eb8e87B5Aff32bFbd;
    address constant STKSCUSD = 0x4D85bA8c3918359c78Ed09581E5bc7578ba932ba;
    address constant STKSCETH = 0x455d5f11Fea33A8fa9D3e285930b478B6bF85265;
    address constant STKSCBTC = 0xD0851030C94433C261B405fEcbf1DEC5E15948d0;
    address constant WSTKSCUSD = 0x9fb76f7ce5FCeAA2C42887ff441D46095E494206;
    address constant WSTKSCETH = 0xE8a41c62BB4d5863C6eadC96792cFE90A1f37C47;
    address constant WSTKSCBTC = 0xDb58c4DB1a0f45DDA3d2F8e44C3300BB6510c866;
    address constant SCUSD_TELLER = 0x358CFACf00d0B4634849821BB3d1965b472c776a;
    address constant SCETH_TELLER = 0x31A5A9F60Dc3d62fa5168352CaF0Ee05aA18f5B8;
    address constant SCBTC_TELLER = 0xAce7DEFe3b94554f0704d8d00F69F273A0cFf079;
    address constant SCUSD_VOTING_ESCROW = 0x0966CAE7338518961c2d35493D3EB481A75bb86B;
    address constant SCETH_VOTING_ESCROW = 0x1Ec2b9a77A7226ACD457954820197F89B3E3a578;
    address constant SCBTC_VOTING_ESCROW = 0x7585D9C32Db1528cEAE4770Fd1d01B888F5afA9e;
    address constant STKSCUSD_TELLER = 0x5e39021Ae7D3f6267dc7995BB5Dd15669060DAe0;
    address constant STKSCETH_TELLER = 0x49AcEbF8f0f79e1Ecb0fd47D684DAdec81cc6562;
    address constant STKSCBTC_TELLER = 0x825254012306bB410b550631895fe58DdCE1f4a9;

    function setUp() public { }

    function run() external {
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.rememberKey(deployerPrivateKey);
        vm.startBroadcast(deployer);

        Router router = new Router();
        console.log("Router deployed at: ", address(router));

        router.setVault(SCUSD_TELLER, SCUSD);
        router.setVault(SCETH_TELLER, SCETH);
        router.setVault(SCBTC_TELLER, SCBTC);
        router.setVault(STKSCUSD_TELLER, STKSCUSD);
        router.setVault(STKSCETH_TELLER, STKSCETH);
        router.setVault(STKSCBTC_TELLER, STKSCBTC);

        router.setVotingEscrow(STKSCETH, SCETH_VOTING_ESCROW);
        router.setVotingEscrow(STKSCUSD, SCUSD_VOTING_ESCROW);
        router.setVotingEscrow(STKSCBTC, SCBTC_VOTING_ESCROW);

        router.setWrapper(STKSCUSD, WSTKSCUSD);
        router.setWrapper(STKSCETH, WSTKSCETH);
        router.setWrapper(STKSCBTC, WSTKSCBTC);

        vm.stopBroadcast();
    }
}
