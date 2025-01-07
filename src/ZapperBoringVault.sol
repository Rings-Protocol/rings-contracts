// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.24;

import { ITeller } from "src/interfaces/ITeller.sol";
import { WETH } from "solady/tokens/WETH.sol";
import { SafeTransferLib } from "solady/utils/SafeTransferLib.sol";

/// @title ZapperNativeTeller
/// @notice A contract to deposit ETH into Teller and bridge it to another chain in a single transaction.
/// @author 0xtekgrinder
contract ZapperNativeTeller {
    using SafeTransferLib for address;

    /*//////////////////////////////////////////////////////////////
                               CONSTANTS
    //////////////////////////////////////////////////////////////*/

    WETH public constant weth = WETH(payable(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2));
    ITeller public immutable teller;

    /*//////////////////////////////////////////////////////////////
                               CONSTRUCTOR
    //////////////////////////////////////////////////////////////*/

    constructor(ITeller definitiveTeller) {
        teller = definitiveTeller;
    }

    /*//////////////////////////////////////////////////////////////
                               DEPOSIT
    //////////////////////////////////////////////////////////////*/

    /**
     * @notice Deposits ETH into Teller and bridges it to another chain in a single transaction.
     * @param minimumMint The minimum amount of tokens to mint.
     * @param to The address to receive the bridged tokens.
     * @param bridgeWildCard The wildcard data for the bridge.
     * @param feeToken The token to pay the fee in.
     * @param maxFee The maximum fee to pay.
     * @return sharesBridged The amount of shares bridged.
     */
    function depositAndBridgeEth(
        uint256 minimumMint,
        address to,
        bytes calldata bridgeWildCard,
        address feeToken,
        uint256 maxFee
    ) external payable returns (uint256 sharesBridged) {
        uint256 amount = msg.value - maxFee;
        weth.deposit{ value: amount }();

        address(weth).safeApprove(address(teller), amount);
        sharesBridged = teller.depositAndBridge(address(weth), amount, minimumMint, to, bridgeWildCard, feeToken, maxFee);

        // refund remaining gas
        payable(msg.sender).transfer(address(this).balance);
    }
}
