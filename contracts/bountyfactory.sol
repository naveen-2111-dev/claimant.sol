// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./Bounty.sol";
import "./interface/IBounty.sol";
import "./interface/constants.sol";
import "./lib/BountyErrors.sol";

/**
 * @title BountyFactory
 * @dev Factory contract for creating and managing bounties
 */
contract BountyFactory is Ownable, ReentrancyGuard {

    address[] public allBounties;
    mapping(address => address[]) public creatorBounties;
    mapping(address => bool) public isValidBounty;

    uint256 public totalBountiesCreated;
    uint256 public totalValueLocked;

    uint256 public factoryFeePercentage = 0;
    address public feeRecipient;
    bool public factoryPaused = false;

    event BountyCreated(
        address indexed bountyAddress, 
        address indexed creator, 
        uint256 reward,
        uint256 indexed bountyId
    );
    event FactoryConfigUpdated(uint256 feePercentage, address feeRecipient);
    event FactoryPausedToggled(bool paused);
    event FeesWithdrawn(address recipient, uint256 amount);

    modifier whenNotPaused() {
        require(!factoryPaused, "Factory is paused");
        _;
    }

    modifier validFeePercentage(uint256 _feePercentage) {
        require(_feePercentage <= 1000, "Fee cannot exceed 10%");
        _;
    }

    constructor(address _initialOwner) Ownable(_initialOwner) {
        feeRecipient = _initialOwner;
    }

    function createBounty(
        string calldata _description,
        address[] calldata _daoMembers,
        uint256 _customDuration
    ) 
        external 
        payable 
        whenNotPaused 
        nonReentrant 
        returns (address bountyAddress) 
    {
        require(msg.value >= BountyConstants.MIN_REWARD, "Reward too low");
        require(_daoMembers.length >= BountyConstants.MIN_DAO_MEMBERS, "Not enough DAO members");
        require(_daoMembers.length <= BountyConstants.MAX_DAO_MEMBERS, "Too many DAO members");

        uint256 factoryFee = (msg.value * factoryFeePercentage) / 10000;
        uint256 bountyReward = msg.value - factoryFee;

        Bounty newBounty = new Bounty{value: bountyReward}(
            msg.sender,
            _description,
            bountyReward,
            _daoMembers,
            _customDuration
        );

        bountyAddress = address(newBounty);

        allBounties.push(bountyAddress);
        creatorBounties[msg.sender].push(bountyAddress);
        isValidBounty[bountyAddress] = true;
        totalBountiesCreated++;
        totalValueLocked += bountyReward;

        if (factoryFee > 0 && feeRecipient != address(0)) {
            payable(feeRecipient).transfer(factoryFee);
        }

        emit BountyCreated(bountyAddress, msg.sender, bountyReward, totalBountiesCreated);
    }

    function createMultipleBounties(
        string[] calldata _descriptions,
        address[][] calldata _daoMembersArray,
        uint256[] calldata _customDurations,
        uint256[] calldata _rewards
    ) 
        external 
        payable 
        whenNotPaused 
        nonReentrant 
        returns (address[] memory bountyAddresses) 
    {
        require(
            _descriptions.length == _daoMembersArray.length &&
            _descriptions.length == _customDurations.length &&
            _descriptions.length == _rewards.length,
            "Array length mismatch"
        );

        uint256 totalRequired = 0;
        for (uint256 i = 0; i < _rewards.length; i++) {
            totalRequired += _rewards[i];
        }

        uint256 totalFees = (totalRequired * factoryFeePercentage) / 10000;
        require(msg.value >= totalRequired + totalFees, "Insufficient payment");

        bountyAddresses = new address[](_descriptions.length);
        address sender = msg.sender;

        for (uint256 i = 0; i < _descriptions.length; i++) {
            bountyAddresses[i] = _deploySingleBounty(
                sender,
                _descriptions[i],
                _rewards[i],
                _daoMembersArray[i],
                _customDurations[i]
            );
        }

        if (totalFees > 0 && feeRecipient != address(0)) {
            payable(feeRecipient).transfer(totalFees);
        }

        if (msg.value > totalRequired + totalFees) {
            payable(sender).transfer(msg.value - totalRequired - totalFees);
        }
    }

    function _deploySingleBounty(
        address _creator,
        string calldata _description,
        uint256 _reward,
        address[] calldata _daoMembers,
        uint256 _customDuration
    ) private returns (address bountyAddress) {
        uint256 factoryFee = (_reward * factoryFeePercentage) / 10000;
        uint256 bountyReward = _reward - factoryFee;

        Bounty newBounty = new Bounty{value: bountyReward}(
            _creator,
            _description,
            bountyReward,
            _daoMembers,
            _customDuration
        );

        bountyAddress = address(newBounty);
        allBounties.push(bountyAddress);
        creatorBounties[_creator].push(bountyAddress);
        isValidBounty[bountyAddress] = true;
        totalBountiesCreated++;
        totalValueLocked += bountyReward;

        emit BountyCreated(bountyAddress, _creator, bountyReward, totalBountiesCreated);
    }

    function getAllBounties() external view returns (address[] memory) {
        return allBounties;
    }

    function getBountiesByCreator(address creator) external view returns (address[] memory) {
        return creatorBounties[creator];
    }

    function updateFactoryConfig(uint256 _feePercentage, address _feeRecipient) 
        external 
        onlyOwner 
        validFeePercentage(_feePercentage) 
    {
        factoryFeePercentage = _feePercentage;
        feeRecipient = _feeRecipient;
        emit FactoryConfigUpdated(_feePercentage, _feeRecipient);
    }

    function toggleFactoryPause() external onlyOwner {
        factoryPaused = !factoryPaused;
        emit FactoryPausedToggled(factoryPaused);
    }

    function withdrawFees() external onlyOwner {
        uint256 balance = address(this).balance;
        require(balance > 0, "No fees to withdraw");
        payable(feeRecipient).transfer(balance);
        emit FeesWithdrawn(feeRecipient, balance);
    }
}
