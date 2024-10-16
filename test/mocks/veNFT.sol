// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

contract veNFT {

    mapping(uint => uint) public _balanceOfNFT;

    mapping(uint => address) public _ownerOfNFT;
    mapping(address => mapping(uint => bool)) public _isVotingApproved;

    mapping(uint => bool) public _voted;
    mapping(uint => bool) public _abstained;

    function setNftOwner(uint tokenId, address owner) external {
        _ownerOfNFT[tokenId] = owner;
    }

    function isVotingApprovedOrOwner(address voter, uint tokenId) external view returns (bool) {
        return _isVotingApproved[voter][tokenId] || _ownerOfNFT[tokenId] == voter;
    }
    function delegateVotingControl(address voter, uint tokenId) external {
        _isVotingApproved[voter][tokenId] = true;
    }

    function voted(uint tokenId) external view returns (bool) {
        return _voted[tokenId];
    }
    function voting(uint tokenId) external {
        _voted[tokenId] = true;
        _abstained[tokenId] = false;
    }
    function abstain(uint tokenId) external {
        _abstained[tokenId] = true;
        _voted[tokenId] = false;
    }

    function balanceOfNFT(uint tokenId) external view returns (uint) {
        return _balanceOfNFT[tokenId];
    }

    function setBalanceOfNFT(uint tokenId, uint balance) external {
        _balanceOfNFT[tokenId] = balance;
    }
    
}