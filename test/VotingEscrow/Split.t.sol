// SPDX-License-Identifier: Unlicensed
pragma solidity 0.8.24;

import "./VotingEscrowTest.t.sol";

contract Split is VotingEscrowTest {
  uint internal constant MAXTIME = 2 * 365 * 86400;
  uint internal constant WEEK = 7 * 86400;

    function testFuzz_split_Normal(address pranker, uint256 amount, uint256 duration, uint128[] calldata weights, uint8 slices) public {
      vm.assume(pranker != address(0));
      vm.assume(weights.length > 0 && weights[0] > 0);
      amount = bound(amount, 1, 10e25);
      duration = bound(duration, 7 * 86400, MAXTIME);
      slices = uint8(bound(slices, 1, 10));
      slices = uint8(bound(slices, 1, weights.length));
      uint256[] memory newWeights = new uint256[](slices);
      uint256 amountsSum = 0;

      for (uint8 i = 0; i < slices; i++) {
        newWeights[i] = weights[i];
        amountsSum += weights[i];
      }

      uint256 from = createLockPranked(pranker, amount, duration);

      vm.prank(pranker);
      votingEscrow.split(newWeights, from);

      for (uint8 i = 0; i < slices; i++) {
        uint256 tokenId = from + i + 1;
        (int128 balance, uint256 end) = votingEscrow.locked(tokenId);
        assertEq(uint256(uint128(balance)), amount * newWeights[i] / amountsSum, "Balance should be the same");
        assertEq(end, (block.timestamp + duration) / WEEK * WEEK, "End should be the same");
      }
    }

    function testFuzz_split_FromNotAllowed(address pranker, uint256 amount, uint256 duration) public {
      vm.assume(pranker != address(0));
      amount = bound(amount, 1, 10e25);
      duration = bound(duration, 7 * 86400, MAXTIME - 7 * 86400);


      uint256 from = createLockPranked(alice, amount, duration);
      uint256[] memory slices = new uint256[](2);
      slices[0] = 1;
      slices[1] = 1;

      vm.prank(pranker);
      vm.expectRevert();
      votingEscrow.split(slices, from);
    }

    function testFuzz_split_FromAttached(address pranker, uint256 amount, uint256 duration) public {
      vm.assume(pranker != address(0));
      amount = bound(amount, 1, 10e25);
      duration = bound(duration, 7 * 86400, MAXTIME - 7 * 86400);

      uint256 from = createLockPranked(pranker, amount, duration);
      uint256[] memory slices = new uint256[](2);
      slices[0] = 1;
      slices[1] = 1;

      // Attach the from lock
      address team = makeAddr("team");
      address voter = makeAddr("voter");

      vm.prank(owner);
      votingEscrow.setTeam(team);
      vm.prank(team);
      votingEscrow.setVoter(address(voter));

      vm.prank(voter);
      votingEscrow.attach(from);
      // End of attaching

      vm.prank(pranker);
      vm.expectRevert();
      votingEscrow.split(slices, from);
    }

    function testFuzz_split_FromVoting(address pranker, uint256 amount, uint256 duration) public {
      vm.assume(pranker != address(0));
      amount = bound(amount, 1, 10e25);
      duration = bound(duration, 7 * 86400, MAXTIME - 7 * 86400);

      uint256 from = createLockPranked(pranker, amount, duration);
      uint256[] memory slices = new uint256[](2);
      slices[0] = 1;
      slices[1] = 1;

      // Attach the from lock
      address team = makeAddr("team");
      address voter = makeAddr("voter");

      vm.prank(owner);
      votingEscrow.setTeam(team);
      vm.prank(team);
      votingEscrow.setVoter(address(voter));

      vm.prank(voter);
      votingEscrow.voting(from);
      // End of attaching

      vm.prank(pranker);
      vm.expectRevert();
      votingEscrow.split(slices, from);
    }
}