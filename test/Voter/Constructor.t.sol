// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VoterTest.t.sol";

contract Constructor is VoterTest {
    function test_constructor_Normal() public view {
        assertEq(address(voter.baseAsset()), address(scUSD), "Asset is not scUSD");
        assertEq(voter.ve(), address(ve), "ve is not VeNFT");
        assertEq(voter.owner(), owner, "Owner is not owner");
    }
}
