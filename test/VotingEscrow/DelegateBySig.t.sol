// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract DelegateBySig is VotingEscrowTest {
    uint256 internal constant MAXTIME = 52 weeks;
    uint256 internal constant WEEK = 7 * 86_400;

    function createDelegationSignature(Vm.Wallet memory delegator, address delegate, uint256 nonce, uint256 expiry)
        public
        returns (uint8 v, bytes32 r, bytes32 s)
    {
        bytes32 domainSeparator = keccak256(
            abi.encode(
                votingEscrow.DOMAIN_TYPEHASH(),
                keccak256(bytes(votingEscrow.name())),
                keccak256(bytes(votingEscrow.version())),
                block.chainid,
                address(votingEscrow)
            )
        );
        bytes32 structHash = keccak256(abi.encode(votingEscrow.DELEGATION_TYPEHASH(), delegate, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));

        (v, r, s) = vm.sign(delegator, digest);
    }

    function testFuzz_delegatebysig_Normal(address pranker, address delegate, uint256 expiry) public {
        vm.assume(pranker != address(0));
        vm.assume(delegate != address(0));
        vm.assume(pranker != delegate);
        vm.assume(expiry > vm.getBlockTimestamp());
        Vm.Wallet memory delegator = vm.createWallet("testFuzz_delegatebysig_Normal");
        uint256 nonce = 0;
        (uint8 v, bytes32 r, bytes32 s) = createDelegationSignature(delegator, delegate, nonce, expiry);

        vm.prank(pranker);
        votingEscrow.delegateBySig(delegate, nonce, expiry, v, r, s);

        assertEq(votingEscrow.delegates(delegator.addr), address(delegate), "Delegate is not delegate");
        assertEq(votingEscrow.numCheckpoints(delegate), 1, "Delegate has no checkpoints");
        //assertEq(ts, vm.getBlockTimestamp(), "Timestamp is not vm.getBlockTimestamp()");
        // assertEq(tokens[0], tokenId, "Balance is not balanceOf");
        //assertEq(tokens.length, 1, "Tokens length is not 1");
    }

    function testFuzz_delegatebysig_senderIsDelegate(address pranker, uint256 expiry) public {
        vm.assume(pranker != address(0));
        vm.assume(expiry > vm.getBlockTimestamp());
        Vm.Wallet memory delegator = vm.createWallet("testFuzz_delegatebysig_senderIsDelegate");
        uint256 nonce = 0;
        (uint8 v, bytes32 r, bytes32 s) = createDelegationSignature(delegator, pranker, nonce, expiry);

        vm.prank(pranker);
        vm.expectRevert();
        votingEscrow.delegateBySig(pranker, nonce, expiry, v, r, s);
    }

    function testFuzz_delegatebysig_zeroDelegate(address pranker, uint256 expiry) public {
        vm.assume(pranker != address(0));
        vm.assume(expiry > vm.getBlockTimestamp());
        Vm.Wallet memory delegator = vm.createWallet("testFuzz_delegatebysig_zeroDelegate");
        uint256 nonce = 0;
        (uint8 v, bytes32 r, bytes32 s) = createDelegationSignature(delegator, zero, nonce, expiry);

        vm.prank(pranker);
        vm.expectRevert();
        votingEscrow.delegateBySig(zero, nonce, expiry, v, r, s);
    }

    function testFuzz_delegatebysig_invalidNonce(address pranker, address delegate, uint256 expiry, uint256 nonce)
        public
    {
        vm.assume(pranker != address(0));
        vm.assume(delegate != address(0));
        vm.assume(pranker != delegate);
        vm.assume(expiry > vm.getBlockTimestamp());
        vm.assume(nonce > 0);
        Vm.Wallet memory delegator = vm.createWallet("testFuzz_delegatebysig_invalidNonce");
        (uint8 v, bytes32 r, bytes32 s) = createDelegationSignature(delegator, delegate, nonce, expiry);

        vm.prank(pranker);
        vm.expectRevert();
        votingEscrow.delegateBySig(delegate, nonce, expiry, v, r, s);
    }

    function testFuzz_delegatebysig_expired(address pranker, address delegate, uint256 expiry, uint256 time) public {
        vm.assume(pranker != address(0));
        vm.assume(delegate != address(0));
        vm.assume(pranker != delegate);
        vm.assume(time > 0);
        expiry = bound(expiry, 0, time - 1);
        Vm.Wallet memory delegator = vm.createWallet("testFuzz_delegatebysig_expired");
        uint256 nonce = 0;
        (uint8 v, bytes32 r, bytes32 s) = createDelegationSignature(delegator, delegate, nonce, expiry);

        vm.warp(time);

        vm.prank(pranker);
        vm.expectRevert();
        votingEscrow.delegateBySig(delegate, nonce, expiry, v, r, s);
    }

    function testFuzz_delegatebysig_invalidSignature(
        address pranker,
        address delegate,
        uint256 expiry,
        uint8 v,
        bytes32 r,
        bytes32 s
    ) public {
        vm.assume(pranker != address(0));
        vm.assume(delegate != address(0));
        vm.assume(pranker != delegate);
        vm.assume(expiry > vm.getBlockTimestamp());
        uint256 nonce = 0;

        bytes32 domainSeparator = keccak256(
            abi.encode(
                votingEscrow.DOMAIN_TYPEHASH(),
                keccak256(bytes(votingEscrow.name())),
                keccak256(bytes(votingEscrow.version())),
                block.chainid,
                address(votingEscrow)
            )
        );
        bytes32 structHash = keccak256(abi.encode(votingEscrow.DELEGATION_TYPEHASH(), delegate, nonce, expiry));
        bytes32 digest = keccak256(abi.encodePacked("\x19\x01", domainSeparator, structHash));
        address signer = ecrecover(digest, v, r, s);
        vm.assume(signer == address(0));

        vm.prank(pranker);
        vm.expectRevert();
        votingEscrow.delegateBySig(delegate, nonce, expiry, v, r, s);
    }
}
