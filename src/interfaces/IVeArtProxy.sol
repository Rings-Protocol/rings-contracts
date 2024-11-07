// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.24;

interface IVeArtProxy {
    function _tokenURI(uint256 _tokenId, uint256 _balanceOf, uint256 _locked_end, uint256 _value)
        external
        pure
        returns (string memory output);
}
