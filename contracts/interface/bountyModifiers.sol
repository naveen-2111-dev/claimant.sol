// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "../storage/BountyStorage.sol";
import "../lib/BountyErrors.sol";
import "../interface/IBounty.sol";

/**
 * @title BountyModifiers
 * @dev Modifiers for access control and validation
 */

abstract contract BountyModifiers is BountyStorage {
    
    /**
     * @dev Restricts access to bounty creator only
     */
    modifier onlyCreator() {
        if (msg.sender != bountyInfo.creator) {
            revert BountyErrors.OnlyCreator();
        }
        _;
    }
    
    /**
     * @dev Restricts access to bounty claimant only
     */
    modifier onlyClaimant() {
        if (msg.sender != bountyInfo.claimant) {
            revert BountyErrors.OnlyClaimant();
        }
        _;
    }
    
    /**
     * @dev Restricts access to DAO members only
     */
    modifier onlyDAOMember() {
        if (!_isDaoMember(msg.sender)) {
            revert BountyErrors.OnlyDAOMember();
        }
        _;
    }
    
    /**
     * @dev Ensures bounty hasn't expired
     */
    modifier notExpired() {
        if (_isExpired()) {
            if (bountyInfo.status != IBounty.Status.Approved) {
                bountyInfo.status = IBounty.Status.Expired;
                // Note: Emit event in the main contract, not in modifier
            }
            revert BountyErrors.BountyExpired();
        }
        _;
    }
    
    /**
     * @dev Validates bounty status matches expected
     */
    modifier onlyStatus(IBounty.Status expectedStatus) {
        if (bountyInfo.status != expectedStatus) {
            revert BountyErrors.InvalidStatus();
        }
        _;
    }
    
    /**
     * @dev Ensures voting is currently active
     */
    modifier duringVoting() {
        if (bountyInfo.status != IBounty.Status.Voting) {
            revert BountyErrors.InvalidStatus();
        }
        if (block.timestamp > bountyInfo.votingDeadline) {
            revert BountyErrors.VotingEnded();
        }
        _;
    }
    
    /**
     * @dev Ensures voting period has ended
     */
    modifier afterVoting() {
        if (bountyInfo.status != IBounty.Status.Voting) {
            revert BountyErrors.InvalidStatus();
        }
        if (block.timestamp <= bountyInfo.votingDeadline) {
            revert BountyErrors.VotingInProgress();
        }
        _;
    }
    
    /**
     * @dev Prevents double voting
     */
    modifier hasNotVoted() {
        if (_hasVoted(msg.sender)) {
            revert BountyErrors.AlreadyVoted();
        }
        _;
    }
    
    /**
     * @dev Validates string input length
     */
    modifier validStringLength(string calldata str, uint256 maxLength) {
        if (bytes(str).length == 0 || bytes(str).length > maxLength) {
            revert BountyErrors.EmptySubmission();
        }
        _;
    }
    
    /**
     * @dev Ensures sufficient contract balance
     */
    modifier sufficientBalance(uint256 amount) {
        if (address(this).balance < amount) {
            revert BountyErrors.InsufficientBalance();
        }
        _;
    }
    
    /**
     * @dev Internal function to check if bounty is expired
     */
    function _isExpired() internal view returns (bool) {
        return block.timestamp > bountyInfo.expiryTime && 
               bountyInfo.status != IBounty.Status.Approved;
    }
}