// SPDX-License-Identifier: MIT

pragma solidity ^0.6.0;

import "../Interfaces/ITimelock.sol";
import "../Interfaces/IStakedDVF.sol";

contract ReferendumManager {

      function quorumVotes() public pure returns (uint) { return 10000000e18; } // 10,000,000 = 10% of Dvf

      function votingPeriod() public pure returns (uint) { return 17280; } // ~3 days in blocks (assuming 15s blocks)

      uint public referendumCount;

      struct Referendum {
          uint id;
          uint votesSnapId;
          address newAdmin;
          uint startBlock;
          uint endBlock;
          uint forVotes;
          uint againstVotes;
          bool executed;
          mapping (address => Receipt) receipts;
      }

      /// @notice Ballot receipt record for a voter
      struct Receipt {
          bool hasVoted;
          bool support;
          uint256 votes;
      }

      /// @notice Possible states that a proposal may be in
      enum ReferendumState {
          Active,
          Defeated,
          Succeeded,
          Executed
      }

      /// @notice The official record of all proposals ever proposed
      mapping (uint => Referendum) public referendums;

      /// @notice An event emitted when a new proposal is created
      event ReferendumCreated(uint id, address proposer, address newAdmin, uint startBlock, uint endBlock, string description);

      /// @notice An event emitted when a vote has been cast on a proposal
      event VoteCast(address voter, uint proposalId, bool support, uint votes);

      /// @notice An event emitted when a proposal has been executed in the Timelock
      event ReferendumExecuted(uint id);

      function state(uint referendumId) public view returns (ReferendumState) {
          require(referendumCount >= referendumId && referendumId > 0, "Referendum::state: invalid proposal id");
          Referendum storage referendum = referendums[referendumId];
          if (block.number <= referendum.endBlock) {
              return ReferendumState.Active;
          } else if (referendum.forVotes <= referendum.againstVotes || referendum.forVotes < quorumVotes()) {
              return ReferendumState.Defeated;
          } else if (referendum.executed) {
              return ReferendumState.Executed;
          } else {
              return ReferendumState.Succeeded;
          }
      }

      ITimelock public timelock;
      IStakedDVF public xdvf;

      constructor(address timelock_, address xdvf_) public {
          timelock = ITimelock(timelock_);
          xdvf = IStakedDVF(xdvf_);
      }

      function initiateReplaceAdminReferendum(address pendingAdmin_, string memory description) public returns(uint256) {
        uint startBlock = block.number;
        uint endBlock = add256(startBlock, votingPeriod());

        uint256 snapId = xdvf.takeVoteSnapshotAtBlock();

        referendumCount++;
        Referendum memory newReferendum = Referendum({
            id: referendumCount,
            votesSnapId: snapId,
            newAdmin: pendingAdmin_,
            startBlock: startBlock,
            endBlock: endBlock,
            forVotes: 0,
            againstVotes: 0,
            executed: false
        });

        referendums[newReferendum.id] = newReferendum;

        emit ReferendumCreated(newReferendum.id, msg.sender, pendingAdmin_, startBlock, endBlock, description);
        return newReferendum.id;
      }

      function execute(uint referendumId) public {
          require(state(referendumId) == ReferendumState.Succeeded, "Referendum::execute: can only be executed if succeeded");
          Referendum storage referendum = referendums[referendumId];
          referendum.executed = true;
          timelock.confirmSuccessfulReferendum(referendum.newAdmin);
          emit ReferendumExecuted(referendumId);
      }

      function vote(uint referendumId, bool support) public {
          _castVote(msg.sender, referendumId, support);
      }

      function voteOnBehalf(address voter, uint referendumId, bool support) public {
          // require(isAllowed to vote on behalf);
          // _castVote(voter, referendumId, support);
      }

      function _castVote(address voter, uint referendumId, bool support) internal {
          require(state(referendumId) == ReferendumState.Active, "Referendum::voting is closed");
          Referendum storage referendum = referendums[referendumId];
          Receipt storage receipt = referendum.receipts[voter];
          require(receipt.hasVoted == false, "Referendum::_castVote: voter already voted");
          uint256 votes = getVotesForReferendum(voter, referendum.votesSnapId);

          if (support) {
              referendum.forVotes = add256(referendum.forVotes, votes);
          } else {
              referendum.againstVotes = add256(referendum.againstVotes, votes);
          }

          receipt.hasVoted = true;
          receipt.support = support;
          receipt.votes = votes;

          emit VoteCast(voter, referendumId, support, votes);
      }

      function getVotesForReferendum(address voter, uint256 snapId) public view returns (uint256) {
          return xdvf.balanceOfAt(voter, snapId);
      }

      function add256(uint256 a, uint256 b) internal pure returns (uint) {
          uint c = a + b;
          require(c >= a, "addition overflow");
          return c;
      }

}
