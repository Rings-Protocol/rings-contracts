// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

contract InvalidReceiver {
    function onERC721Received(address, address, uint256, bytes memory) public pure returns (bytes4) {
        return bytes4(keccak256("invalid signature"));
    }
}
