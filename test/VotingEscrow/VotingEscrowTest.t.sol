// SPDX-License-Identifier: Unlicensed
pragma solidity ^0.8.24;

import "../MainnetTest.t.sol";
import { VotingEscrow } from "src/VotingEscrow.sol";
import { ScUSD } from "test/mocks/scUSD.sol";
import { VeArtProxy } from "src/VeArtProxy.sol";

contract VotingEscrowTest is MainnetTest {
    VotingEscrow votingEscrow;
    ScUSD scUSD;
    VeArtProxy veArtProxy;

    function setUp() public virtual override {
        super.setUp();
        //fork(); // If needed

        vm.startPrank(owner);

        scUSD = new ScUSD();
        veArtProxy = new VeArtProxy();
        votingEscrow = new VotingEscrow(address(scUSD), address(veArtProxy));

        vm.stopPrank();
    }

    function createLock(uint256 value, uint256 duration) public returns (uint256) {
        scUSD.approve(address(votingEscrow), value);
        return votingEscrow.create_lock(value, duration);
    }

    function createLockPranked(address pranker, uint256 value, uint256 duration) public returns (uint256) {
        vm.startPrank(pranker);
        deal(address(scUSD), pranker, value);
        uint256 tokenId = createLock(value, duration);
        vm.stopPrank();
        return tokenId;
    }

    function createLockForPranked(address pranker, address recipient, uint256 value, uint256 duration) public returns (uint256) {
        vm.startPrank(pranker);
        deal(address(scUSD), pranker, value);
        scUSD.approve(address(votingEscrow), value);
        uint256 tokenId = votingEscrow.create_lock_for(value, duration, recipient);
        vm.stopPrank();
        return tokenId;
    }

    function dealApproveAsset(address to, uint256 value) public {
        deal(address(scUSD), to, value);
        vm.prank(to);
        scUSD.approve(address(votingEscrow), value);
    }

    function approve(address spender, uint256 tokenId) public {
        votingEscrow.approve(spender, tokenId);
    }

    function approvePranked(address pranker, address spender, uint256 tokenId) public {
        vm.prank(pranker);
        approve(spender, tokenId);
    }

    function setApprovalForAllPranked(address pranker, address operator, bool approved) public {
        vm.prank(pranker);
        votingEscrow.setApprovalForAll(operator, approved);
    }

    function increaseLockPranked(address pranker, uint256 tokenId, uint256 unlockTime) public {
        vm.prank(pranker);
        votingEscrow.increase_unlock_time(tokenId, unlockTime);
    }
}