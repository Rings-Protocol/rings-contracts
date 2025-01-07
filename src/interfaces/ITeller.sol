// SPDX-License-Identifier: GPL-3.0-or-later
pragma solidity 0.8.24;

interface ITeller {
    function depositAndBridge(
        address depositAsset,
        uint256 depositAmount,
        uint256 minimumMint,
        address to,
        bytes calldata bridgeWildCard,
        address feeToken,
        uint256 maxFee
    ) external payable returns (uint256 sharesBridged);
}
