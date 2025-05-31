// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

/**
 * @title BountyConstants
 * @dev Constants and configuration for the bounty system
 */

library BountyConstants {
    // Time constants
    uint256 public constant VOTING_PERIOD = 3 days;
    uint256 public constant DEFAULT_BOUNTY_DURATION = 30 days;
    uint256 public constant EMERGENCY_WAIT_PERIOD = 7 days;
    uint256 public constant MIN_BOUNTY_DURATION = 1 days;
    uint256 public constant MAX_BOUNTY_DURATION = 365 days;
    
    // Voting constants
    uint256 public constant MIN_QUORUM_PERCENTAGE = 30; // 30% minimum participation
    uint256 public constant MAX_QUORUM_PERCENTAGE = 100;
    uint256 public constant MIN_DAO_MEMBERS = 1;
    uint256 public constant MAX_DAO_MEMBERS = 100;
    
    // String limits (to prevent gas issues)
    uint256 public constant MAX_DESCRIPTION_LENGTH = 1000;
    uint256 public constant MAX_SUBMISSION_LENGTH = 2000;
    uint256 public constant MAX_CANCEL_REASON_LENGTH = 500;
    
    // Minimum reward (to prevent spam)
    uint256 public constant MIN_REWARD = 0.001 ether;
}