// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract Constructor is VotingEscrowTest {
    /// @dev ERC165 interface ID of ERC165
    bytes4 internal constant ERC165_INTERFACE_ID = 0x01ffc9a7;

    /// @dev ERC165 interface ID of ERC721
    bytes4 internal constant ERC721_INTERFACE_ID = 0x80ac58cd;

    /// @dev ERC165 interface ID of ERC721Metadata
    bytes4 internal constant ERC721_METADATA_INTERFACE_ID = 0x5b5e139f;

    function test_constructor_Normal() public view {
        assertEq(votingEscrow.token(), address(scUSD), "Asset is not scUSD");
        assertEq(votingEscrow.artProxy(), address(veArtProxy), "ArtProxy is not VeArtProxy");
        assertEq(votingEscrow.voter(), address(0), "Voter is set");
        assertEq(votingEscrow.team(), owner, "Team is not owner");

        (,, uint256 ts, uint256 blk) = votingEscrow.point_history(0);
        assertEq(blk, block.number, "Block number is not current block number");
        assertEq(ts, vm.getBlockTimestamp(), "Timestamp is not current timestamp");
    }
}
