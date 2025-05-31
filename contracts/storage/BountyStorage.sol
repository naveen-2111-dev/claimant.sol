// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../interface/IBounty.sol";

/**
 * @title BountyStorage
 * @dev Storage layout and management for bounty contracts
 */

abstract contract BountyStorage {

    // Main bounty information
    IBounty.BountyInfo public bountyInfo;
    
    // Voting-related storage (kept separate for gas optimization)
    struct VotingStorage {
        uint256 votesFor;
        uint256 votesAgainst;
        mapping(address => bool) hasVoted;
        mapping(address => bool) daoMembers;
    }
    
    VotingStorage internal votingData;
    
    // Additional tracking
    mapping(address => uint256) public memberVoteCount;
    uint256 public totalVotingRounds;
    
    /**
     * @dev Initialize storage with bounty data
     */
    function _initializeStorage(
        address _creator,
        string memory _description,
        uint256 _reward,
        uint256 _duration,
        address[] memory _daoMembers
    ) internal {
        bountyInfo = IBounty.BountyInfo({
            creator: _creator,
            description: _description,
            reward: _reward,
            claimant: address(0),
            submission: "",
            status: IBounty.Status.Open,
            createdAt: block.timestamp,
            expiryTime: block.timestamp + _duration,
            votingDeadline: 0,
            minimumQuorum: (_daoMembers.length * 30) / 100, 
            daoMemberCount: _daoMembers.length
        });
        
        // Initialize DAO members
        for (uint256 i = 0; i < _daoMembers.length; i++) {
            votingData.daoMembers[_daoMembers[i]] = true;
        }
    }
    
    /**
     * @dev Reset voting data for new round
     */
    function _resetVoting() internal {
        votingData.votesFor = 0;
        votingData.votesAgainst = 0;
        totalVotingRounds++;
        
        // Note: hasVoted mapping is intentionally not reset
        // This prevents re-voting in the same submission round
    }
    
    /**
     * @dev Get voting data (internal view)
     */
    function _getVotingData() internal view returns (uint256, uint256) {
        return (votingData.votesFor, votingData.votesAgainst);
    }
    
    /**
     * @dev Check if address is DAO member
     */
    function _isDaoMember(address account) internal view returns (bool) {
        return votingData.daoMembers[account];
    }
    
    /**
     * @dev Check if user has voted
     */
    function _hasVoted(address account) internal view returns (bool) {
        return votingData.hasVoted[account];
    }
    
    /**
     * @dev Record vote
     */
    function _recordVote(address voter, bool approve) internal {
        votingData.hasVoted[voter] = true;
        memberVoteCount[voter]++;
        
        if (approve) {
            votingData.votesFor++;
        } else {
            votingData.votesAgainst++;
        }
    }
}