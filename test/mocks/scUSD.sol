// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import { ERC20 } from "solady/tokens/ERC20.sol";

contract ScUSD is ERC20 {

    function name() public pure override returns (string memory) {
        return "Sonic USD";
    }

    function symbol() public pure override returns (string memory) {
        return "scUSD";
    }
}