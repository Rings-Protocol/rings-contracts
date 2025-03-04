// SPDX-License-Identifier: MIT
pragma solidity 0.8.24;

import { Base64 } from "./libraries/Base64.sol";
import { IVeArtProxy } from "./interfaces/IVeArtProxy.sol";

/// @title VeArtProxy
/// @author Rings Protocol
/// @notice VeArtProxy is a contract for generating SVG images for VeArt NFTs
/// it is a fork of Thena's VeArtProxy contract
contract VeArtProxy is IVeArtProxy {
    /*//////////////////////////////////////////////////////////////
                              CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor() { }

    /*//////////////////////////////////////////////////////////////
                            VIEW FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Returns the SVG image for a given token
     * @param _tokenId The token ID
     * @param _balanceOf The balance of the token
     * @param _locked_end The end of the lock period
     * @param _value The value of the token
     * @return output The SVG image
     */
    function _tokenURI(uint256 _tokenId, uint256 _balanceOf, uint256 _locked_end, uint256 _value)
        external
        pure
        returns (string memory output)
    {
        output =
            '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 350 350"><style>.base { fill: white; font-family: serif; font-size: 14px; }</style><rect width="100%" height="100%" fill="black" /><text x="10" y="20" class="base">';
        output =
            string(abi.encodePacked(output, "token ", toString(_tokenId), '</text><text x="10" y="40" class="base">'));
        output = string(
            abi.encodePacked(output, "balanceOf ", toString(_balanceOf), '</text><text x="10" y="60" class="base">')
        );
        output = string(
            abi.encodePacked(output, "locked_end ", toString(_locked_end), '</text><text x="10" y="80" class="base">')
        );
        output = string(abi.encodePacked(output, "value ", toString(_value), "</text></svg>"));

        string memory json = Base64.encode(
            bytes(
                string(
                    abi.encodePacked(
                        '{"name": "lock #',
                        toString(_tokenId),
                        '", "description": "Rings locks, can be used to boost gauge yields, vote on token emission, and receive bribes", "image": "data:image/svg+xml;base64,',
                        Base64.encode(bytes(output)),
                        '"}'
                    )
                )
            )
        );
        output = string(abi.encodePacked("data:application/json;base64,", json));
    }

    /*//////////////////////////////////////////////////////////////
                            INTERNAL FUNCTIONS
    //////////////////////////////////////////////////////////////*/

    function toString(uint256 value) internal pure returns (string memory) {
        // Inspired by OraclizeAPI's implementation - MIT license
        // https://github.com/oraclize/ethereum-api/blob/b42146b063c7d6ee1358846c198246239e9360e8/oraclizeAPI_0.4.25.sol

        if (value == 0) {
            return "0";
        }
        uint256 temp = value;
        uint256 digits;
        while (temp != 0) {
            digits++;
            temp /= 10;
        }
        bytes memory buffer = new bytes(digits);
        while (value != 0) {
            digits -= 1;
            buffer[digits] = bytes1(uint8(48 + uint256(value % 10)));
            value /= 10;
        }
        return string(buffer);
    }
}
