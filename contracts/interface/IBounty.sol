// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title IBounty Interface
 * @dev Interface and data structures for the bounty system
 */

interface IBounty {
    enum Status { 
        Open, 
        Claimed, 
        Submitted, 
        Voting, 
        Approved, 
        Rejected, 
        Cancelled, 
        Expired 
    }

    struct BountyInfo {
        address creator;
        string description;
        uint256 reward;
        address claimant;
        string submission;
        Status status;
        uint256 createdAt;
        uint256 expiryTime;
        uint256 votingDeadline;
        uint256 minimumQuorum;
        uint256 daoMemberCount;
    }

    struct VotingResults {
        uint256 votesFor;
        uint256 votesAgainst;
        uint256 totalVotes;
        bool quorumMet;
    }

    struct TimeInfo {
        uint256 bountyTimeLeft;
        uint256 votingTimeLeft;
    }

    event BountyCreated(address indexed creator, uint256 reward, uint256 expiryTime);
    event Claimed(address indexed claimant);
    event Submitted(string submission);
    event Voted(address indexed voter, bool approve);
    event VotingFinalized(bool approved, uint256 totalVotes);
    event Cancelled(string reason);
    event Expired();
    event QuorumNotMet(uint256 totalVotes, uint256 requiredQuorum);

    function claim() external;
    function submit(string calldata _submission) external;
    function vote(bool approve) external;
    function finalizeVoting() external;
    function cancel(string calldata reason) external;
    function handleExpiry() external;

    function getDetails() external view returns (BountyInfo memory);
    function getVotingResults() external view returns (VotingResults memory);
    function isDaoMember(address account) external view returns (bool);
    function hasUserVoted(address account) external view returns (bool);
    function getTimeRemaining() external view returns (TimeInfo memory);
    function isExpired() external view returns (bool);
    function getBalance() external view returns (uint256);
}