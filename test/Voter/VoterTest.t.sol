// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.24;

import "../MainnetTest.t.sol";
import { VotingEscrow } from "src/VotingEscrow.sol";
import { VeArtProxy } from "src/VeArtProxy.sol";
import { ScUSD } from "test/mocks/scUSD.sol";
import { Voter } from "src/Voter.sol";

contract VoterTest is MainnetTest {
    Voter voter;
    VotingEscrow ve;
    ScUSD scUSD;
    VeArtProxy veArtProxy;

    uint256 internal constant WEEK = 86_400 * 7;
    uint256 internal constant MAX_WEIGHT = 10_000; // 100% in BPS
    uint256 internal constant UNIT = 1e18;
    uint256 internal constant MAXTIME = 2 * 365 * 86_400;

    function setUp() public virtual override {
        super.setUp();
        //fork(); // If needed
        vm.warp(1_729_068_300); // random timestamp taken

        vm.startPrank(owner);

        scUSD = new ScUSD();
        veArtProxy = new VeArtProxy();
        ve = new VotingEscrow(address(scUSD), address(veArtProxy));
        voter = new Voter(address(owner), address(ve), address(scUSD));

        ve.setVoter(address(voter));

        vm.stopPrank();
    }

    function createNft(address owner, uint256 balance) public returns (uint256) {
        deal(address(scUSD), owner, balance);

        vm.startPrank(owner);
        scUSD.approve(address(ve), balance);
        uint256 tokenId = ve.create_lock(balance, MAXTIME);
        vm.stopPrank();

        return tokenId;
    }

    function updateNftBalance(uint256 tokenId, uint256 balance) public {
        // ve.setBalanceOfNFT(tokenId, balance);
    }
}
