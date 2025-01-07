// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import { ZapperNativeTeller, ITeller } from "src/ZapperNativeTeller.sol";
import "forge-std/Test.sol";

contract ZapperNativeTellerTest is Test {

    ZapperNativeTeller zapperNativeTeller;

    address constant TELLER = 0x31A5A9F60Dc3d62fa5168352CaF0Ee05aA18f5B8;
    address constant VAULT = 0x3bcE5CB273F0F148010BbEa2470e7b5df84C7812;

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl("mainnet"));

        zapperNativeTeller = new ZapperNativeTeller(ITeller(TELLER), VAULT);
    }

    function test_depositAndBridgeEth() public {
        address to = address(this);
        bytes memory bridgeWildCard = hex"000000000000000000000000000000000000000000000000000000000000767c";
        uint256 maxFee = 39607027400426;

        deal(address(this), 10e18);
        zapperNativeTeller.depositAndBridgeEth{value: 10e18}(0, to, bridgeWildCard, 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE, maxFee);
    }
}
