// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract TokenOfOwnerByIndex is VotingEscrowTest {
    uint256 internal constant MAXTIME = 52 weeks;

    function testFuzz_tokenOfOwnerByIndex_multiple(address pranker, uint256 amount, uint256 duration, uint8 nftNumber)
        public
    {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);
        uint256[] memory indexes = new uint256[](nftNumber);

        for (uint256 i = 0; i < nftNumber; ++i) {
            indexes[i] = createLockPranked(pranker, 1e18, duration);
        }

        for (uint256 i = 0; i < nftNumber; ++i) {
            assertEq(votingEscrow.tokenOfOwnerByIndex(pranker, i), indexes[i], "Value should be token id");
        }
    }

    function testFuzz_tokenOfOwnerByIndex_InvalidOwner(address pranker) public view {
        assertEq(votingEscrow.tokenOfOwnerByIndex(pranker, 0), 0, "Token id should be 0");
    }

    function testFuzz_tokenOfOwnerByIndex_InvalidIndex(address pranker, uint256 index, uint256 amount, uint256 duration)
        public
    {
        vm.assume(pranker != address(0));
        amount = bound(amount, 1, 10e25);
        duration = bound(duration, 7 * 86_400, MAXTIME);
        vm.assume(index != 0);

        uint256 tokenId = createLockPranked(pranker, amount, duration);
        assertEq(votingEscrow.tokenOfOwnerByIndex(pranker, index), 0, "Token id should be 0");
    }
}
