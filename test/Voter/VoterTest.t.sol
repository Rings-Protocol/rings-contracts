// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.24;

import "../MainnetTest.t.sol";
import { Voter } from "src/Voter.sol";
import { veNFT } from "test/mocks/veNFT.sol";
import { ScUSD } from "test/mocks/scUSD.sol";

contract VoterTest is MainnetTest {
    Voter voter;
    veNFT ve;
    ScUSD scUSD;

    uint256 internal constant WEEK = 86400 * 7;
    uint256 internal constant MAX_WEIGHT = 10000; // 100% in BPS
    uint256 internal constant UNIT = 1e18;

    function setUp() public virtual override {
        super.setUp();
        //fork(); // If needed
        vm.warp(1729068300); // random timestamp taken

        vm.startPrank(owner);

        scUSD = new ScUSD();
        ve = new veNFT();
        voter = new Voter(address(owner), address(ve), address(scUSD));

        vm.stopPrank();
    }

    function createNft(uint tokenId, address owner, uint256 balance) public {
        ve.setNftOwner(tokenId, owner);
        ve.setBalanceOfNFT(tokenId, balance);
    }

    function delegateVotingControl(address delegate, uint tokenId) public {
        ve.delegateVotingControl(delegate, tokenId);
    }

    function updateNftBalance(uint tokenId, uint256 balance) public {
        ve.setBalanceOfNFT(tokenId, balance);
    }

}