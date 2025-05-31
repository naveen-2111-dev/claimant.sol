// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title BountyErrors
 * @dev Custom errors for the bounty system
 */

library BountyErrors {
    // Setup errors
    error InvalidReward();
    error EmptyDAOMembers();
    error DuplicateDAOMember();
    error InvalidDuration();
    
    // Access control errors
    error UnauthorizedAccess();
    error OnlyCreator();
    error OnlyClaimant();
    error OnlyDAOMember();
    
    // Status errors
    error InvalidStatus();
    error BountyExpired();
    error VotingInProgress();
    error VotingEnded();
    error AlreadyClaimed();
    error AlreadyVoted();
    
    // Validation errors
    error EmptySubmission();
    error InsufficientQuorum();
    error QuorumNotReached();
    
    // Payment errors
    error PaymentFailed();
    error InsufficientBalance();
    error RefundFailed();
    
    // Emergency errors
    error NotExpired();
    error EmergencyPeriodNotReached();
    error EmergencyWithdrawalFailed();
}