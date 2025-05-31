// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interface/IBounty.sol";
import "./interface/bountyModifiers.sol";
import "./interface/constants.sol";
import "./lib/BountyErrors.sol";

/**
 * @title Bounty
 * @dev Main bounty contract implementing the IBounty interface
 * @author Your Name
 */

contract Bounty is IBounty, BountyModifiers, ReentrancyGuard {

    constructor(
        address _creator,
        string memory _description,
        uint256 _reward,
        address[] memory _daoMembers,
        uint256 _customDuration
    ) payable {
        _validateConstructorInputs(_creator, _description, _reward, _daoMembers, _customDuration);
        uint256 duration = _customDuration > 0 ? _customDuration : BountyConstants.DEFAULT_BOUNTY_DURATION;
        _initializeStorage(_creator, _description, _reward, duration, _daoMembers);
        emit BountyCreated(_creator, _reward, bountyInfo.expiryTime);
    }

    /**
     * @dev Claim the bounty
     */
    function claim() 
        external 
        override 
        notExpired 
        onlyStatus(Status.Open) 
    {
        bountyInfo.claimant = msg.sender;
        bountyInfo.status = Status.Claimed;
        emit Claimed(msg.sender);
    }

    /**
     * @dev Submit work for the bounty
     */
    function submit(string calldata _submission) 
        external 
        override 
        onlyClaimant 
        notExpired 
        onlyStatus(Status.Claimed)
        validStringLength(_submission, BountyConstants.MAX_SUBMISSION_LENGTH)
    {
        bountyInfo.submission = _submission;
        bountyInfo.status = Status.Voting;
        bountyInfo.votingDeadline = block.timestamp + BountyConstants.VOTING_PERIOD;
        
        _resetVoting();
        
        emit Submitted(_submission);
    }

    /**
     * @dev Vote on a submission
     */
    function vote(bool approve) 
        external 
        override 
        onlyDAOMember 
        duringVoting 
        hasNotVoted 
    {
        _recordVote(msg.sender, approve);
        emit Voted(msg.sender, approve);
    }

    /**
     * @dev Finalize voting and determine outcome
     */
    function finalizeVoting() 
        external 
        override 
        afterVoting 
        nonReentrant 
    {
        (uint256 votesFor, uint256 votesAgainst) = _getVotingData();
        uint256 totalVotes = votesFor + votesAgainst;
        
        // Check quorum
        if (totalVotes < bountyInfo.minimumQuorum) {
            bountyInfo.status = Status.Rejected;
            emit QuorumNotMet(totalVotes, bountyInfo.minimumQuorum);
            emit VotingFinalized(false, totalVotes);
            return;
        }

        if (votesFor > votesAgainst) {
            bountyInfo.status = Status.Approved;
            _transferReward(bountyInfo.claimant);
            emit VotingFinalized(true, totalVotes);
        } else {
            bountyInfo.status = Status.Rejected;
            emit VotingFinalized(false, totalVotes);
        }
    }

    /**
     * @dev Cancel the bounty (creator only)
     */
    function cancel(string calldata reason) 
        external 
        override 
        onlyCreator 
        nonReentrant
        validStringLength(reason, BountyConstants.MAX_CANCEL_REASON_LENGTH)
    {
        if (bountyInfo.status != Status.Open && bountyInfo.status != Status.Rejected) {
            revert BountyErrors.InvalidStatus();
        }
        
        bountyInfo.status = Status.Cancelled;
        _transferReward(bountyInfo.creator);
        
        emit Cancelled(reason);
    }

    /**
     * @dev Handle bounty expiry
     */
    function handleExpiry() 
        external 
        override 
        nonReentrant 
    {
        if (!_isExpired()) {
            revert BountyErrors.NotExpired();
        }
        
        bountyInfo.status = Status.Expired;
        _transferReward(bountyInfo.creator);
        
        emit Expired();
    }

    /**
     * @dev Emergency withdrawal (creator only, after grace period)
     */
    function emergencyWithdraw() 
        external 
        onlyCreator 
        nonReentrant 
    {
        if (bountyInfo.status != Status.Expired) {
            revert BountyErrors.InvalidStatus();
        }
        if (block.timestamp <= bountyInfo.expiryTime + BountyConstants.EMERGENCY_WAIT_PERIOD) {
            revert BountyErrors.EmergencyPeriodNotReached();
        }
        
        uint256 balance = address(this).balance;
        if (balance > 0) {
            _transferReward(bountyInfo.creator);
        }
    }

    // VIEW FUNCTIONS

    function getDetails() external view override returns (BountyInfo memory) {
        return bountyInfo;
    }

    function getVotingResults() external view override returns (VotingResults memory) {
        (uint256 votesFor, uint256 votesAgainst) = _getVotingData();
        uint256 totalVotes = votesFor + votesAgainst;
        
        return VotingResults({
            votesFor: votesFor,
            votesAgainst: votesAgainst,
            totalVotes: totalVotes,
            quorumMet: totalVotes >= bountyInfo.minimumQuorum
        });
    }

    function isDaoMember(address account) external view override returns (bool) {
        return _isDaoMember(account);
    }

    function hasUserVoted(address account) external view override returns (bool) {
        return _hasVoted(account);
    }

    function getTimeRemaining() external view override returns (TimeInfo memory) {
        uint256 bountyTimeLeft = bountyInfo.expiryTime > block.timestamp ? 
            bountyInfo.expiryTime - block.timestamp : 0;
        
        uint256 votingTimeLeft = (bountyInfo.status == Status.Voting && bountyInfo.votingDeadline > block.timestamp) ? 
            bountyInfo.votingDeadline - block.timestamp : 0;
            
        return TimeInfo({
            bountyTimeLeft: bountyTimeLeft,
            votingTimeLeft: votingTimeLeft
        });
    }

    function isExpired() external view override returns (bool) {
        return _isExpired();
    }

    function getBalance() external view override returns (uint256) {
        return address(this).balance;
    }

    // INTERNAL FUNCTIONS

    function _validateConstructorInputs(
        address _creator,
        string memory _description,
        uint256 _reward,
        address[] memory _daoMembers,
        uint256 _customDuration
    ) internal view {
        if (msg.value != _reward) revert BountyErrors.InvalidReward();
        if (_reward < BountyConstants.MIN_REWARD) revert BountyErrors.InvalidReward();
        if (_daoMembers.length == 0) revert BountyErrors.EmptyDAOMembers();
        if (_daoMembers.length > BountyConstants.MAX_DAO_MEMBERS) revert BountyErrors.EmptyDAOMembers();
        if (bytes(_description).length == 0 || bytes(_description).length > BountyConstants.MAX_DESCRIPTION_LENGTH) {
            revert BountyErrors.EmptySubmission();
        }
        
        if (_customDuration > 0) {
            if (_customDuration < BountyConstants.MIN_BOUNTY_DURATION || 
                _customDuration > BountyConstants.MAX_BOUNTY_DURATION) {
                revert BountyErrors.InvalidDuration();
            }
        }
        
        // Check for duplicate DAO members
        for (uint256 i = 0; i < _daoMembers.length; i++) {
            if (_daoMembers[i] == address(0)) revert BountyErrors.DuplicateDAOMember();
            for (uint256 j = i + 1; j < _daoMembers.length; j++) {
                if (_daoMembers[i] == _daoMembers[j]) {
                    revert BountyErrors.DuplicateDAOMember();
                }
            }
        }
    }

    function _transferReward(address recipient) internal sufficientBalance(bountyInfo.reward) {
        (bool success, ) = payable(recipient).call{value: bountyInfo.reward}("");
        if (!success) revert BountyErrors.PaymentFailed();
    }
}