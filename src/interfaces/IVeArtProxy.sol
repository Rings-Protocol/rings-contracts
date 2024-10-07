// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.24;

interface IVeArtProxy {
    function _tokenURI(uint _tokenId, uint _balanceOf, uint _locked_end, uint _value) external pure returns (string memory output);
}