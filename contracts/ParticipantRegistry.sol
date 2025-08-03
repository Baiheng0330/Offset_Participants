// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IGreenChainSystem.sol";

/**
 * @title ParticipantRegistry
 * @dev Main contract for managing GreenChain participants, their points, and activity tracking
 */
contract ParticipantRegistry is IParticipantRegistry, Ownable, Pausable, ReentrancyGuard {
    
    // Mapping from wallet address to participant data
    mapping(address => Participant) private _participants;
    
    // Array of all registered participant addresses
    address[] private _participantAddresses;
    
    // Mapping from address to index in the array for efficient removal
    mapping(address => uint256) private _participantIndexes;
    
    // Total number of participants
    uint256 private _totalParticipants;
    
    // Points configuration
    uint256 public basePointsPerKgCO2 = 10; // Base points per kg of CO2 offset
    uint256 public streakBonusMultiplier = 5; // Additional points for activity streaks
    uint256 public referralBonus = 50; // Points for successful referrals
    
    // External contract addresses
    address public tierManager;
    address public pointsToken;
    address public badgeNFT;
    
    // Events
    event TierUpgraded(address indexed wallet, uint256 oldTier, uint256 newTier, uint256 points);
    
    // Modifiers
    modifier onlyRegistered() {
        require(_participants[msg.sender].isActive, "Participant not registered");
        _;
    }
    
    modifier onlyAuthorized() {
        require(msg.sender == owner() || msg.sender == tierManager, "Not authorized");
        _;
    }
    
    constructor(address _tierManager, address _pointsToken, address _badgeNFT) 
        Ownable(msg.sender)
    {
        tierManager = _tierManager;
        pointsToken = _pointsToken;
        badgeNFT = _badgeNFT;
    }
    
    /**
     * @dev Register a new participant
     * @param profileHash IPFS hash containing off-chain profile data
     */
    function registerParticipant(string memory profileHash) external override whenNotPaused nonReentrant {
        require(!_participants[msg.sender].isActive, "Already registered");
        require(bytes(profileHash).length > 0, "Profile hash required");
        
        Participant memory newParticipant = Participant({
            wallet: msg.sender,
            totalPoints: 0,
            currentTier: 0, // BRONZE tier
            joinDate: block.timestamp,
            lastActivityDate: block.timestamp,
            isActive: true,
            profileHash: profileHash
        });
        
        _participants[msg.sender] = newParticipant;
        _participantAddresses.push(msg.sender);
        _participantIndexes[msg.sender] = _participantAddresses.length - 1;
        _totalParticipants++;
        
        // Mint initial points for registration
        uint256 initialPoints = 100;
        _participants[msg.sender].totalPoints = initialPoints;
        
        // Mint points token
        IPointsToken(pointsToken).mint(msg.sender, initialPoints, "Registration bonus");
        
        // Mint BRONZE badge
        IBadgeNFT(badgeNFT).mintBadge(
            msg.sender,
            "BRONZE",
            "GreenChain Bronze Member",
            "Welcome to GreenChain! You've taken your first step towards a sustainable future.",
            "ipfs://QmBronzeBadgeURI"
        );
        
        emit ParticipantRegistered(msg.sender, block.timestamp);
        emit PointsEarned(msg.sender, initialPoints, 0, "Registration bonus");
    }
    
    /**
     * @dev Update participant points and activity (called by authorized contracts)
     * @param wallet Participant wallet address
     * @param points Points to add
     * @param co2Offset CO2 offset amount in kg
     * @param activity Activity description
     */
    function updateParticipant(
        address wallet,
        uint256 points,
        uint256 co2Offset,
        string memory activity
    ) external override onlyAuthorized {
        require(_participants[wallet].isActive, "Participant not found");
        require(points > 0, "Points must be greater than 0");
        
        Participant storage participant = _participants[wallet];
        
        // Calculate tier-based multiplier
        uint256 tierMultiplier = ITierManager(tierManager).getTierMultiplier(
            ITierManager.Tier(participant.currentTier)
        );
        
        // Apply tier multiplier to points
        uint256 adjustedPoints = (points * tierMultiplier) / 100;
        
        // Update participant data
        participant.totalPoints += adjustedPoints;
        participant.lastActivityDate = block.timestamp;
        
        // Check for tier upgrade
        ITierManager.Tier newTier = ITierManager(tierManager).calculateTier(participant.totalPoints);
        if (uint256(newTier) > participant.currentTier) {
            ITierManager.Tier oldTier = ITierManager.Tier(participant.currentTier);
            participant.currentTier = uint256(newTier);
            
            // Mint tier badge
            string memory tierName = _getTierName(newTier);
            IBadgeNFT(badgeNFT).mintBadge(
                wallet,
                tierName,
                string(abi.encodePacked("GreenChain ", tierName, " Member")),
                string(abi.encodePacked("Congratulations! You've reached ", tierName, " tier.")),
                string(abi.encodePacked("ipfs://Qm", tierName, "BadgeURI"))
            );
            
            emit TierUpgraded(wallet, uint256(oldTier), uint256(newTier), participant.totalPoints);
        }
        
        // Mint points token
        IPointsToken(pointsToken).mint(wallet, adjustedPoints, activity);
        
        emit ParticipantUpdated(wallet, participant.totalPoints, participant.currentTier);
        emit PointsEarned(wallet, adjustedPoints, co2Offset, activity);
    }
    
    /**
     * @dev Record carbon offset activity and award points
     * @param wallet Participant wallet address
     * @param co2OffsetKg CO2 offset amount in kg
     * @param activityType Type of activity (e.g., "TRANSPORT", "ENERGY", "WASTE")
     * @param activityDescription Detailed description of the activity
     * @param hasStreak Whether user has activity streak
     */
    function recordOffsetActivity(
        address wallet,
        uint256 co2OffsetKg,
        string memory activityType,
        string memory activityDescription,
        bool hasStreak
    ) external onlyAuthorized {
        require(_participants[wallet].isActive, "Participant not found");
        require(co2OffsetKg > 0, "CO2 offset must be greater than 0");
        require(bytes(activityType).length > 0, "Activity type required");
        require(bytes(activityDescription).length > 0, "Activity description required");
        
        // Calculate points based on CO2 offset
        uint256 basePoints = co2OffsetKg * basePointsPerKgCO2;
        if (hasStreak) {
            basePoints += (basePoints * streakBonusMultiplier) / 100;
        }
        
        // Update participant directly
        Participant storage participant = _participants[wallet];
        
        // Calculate tier-based multiplier
        uint256 tierMultiplier = ITierManager(tierManager).getTierMultiplier(
            ITierManager.Tier(participant.currentTier)
        );
        
        // Apply tier multiplier to points
        uint256 adjustedPoints = (basePoints * tierMultiplier) / 100;
        
        // Update participant data
        participant.totalPoints += adjustedPoints;
        participant.lastActivityDate = block.timestamp;
        
        // Check for tier upgrade
        ITierManager.Tier newTier = ITierManager(tierManager).calculateTier(participant.totalPoints);
        if (uint256(newTier) > participant.currentTier) {
            ITierManager.Tier oldTier = ITierManager.Tier(participant.currentTier);
            participant.currentTier = uint256(newTier);
            
            // Mint tier badge
            string memory tierName = _getTierName(newTier);
            IBadgeNFT(badgeNFT).mintBadge(
                wallet,
                tierName,
                string(abi.encodePacked("GreenChain ", tierName, " Member")),
                string(abi.encodePacked("Congratulations! You've reached ", tierName, " tier.")),
                string(abi.encodePacked("ipfs://Qm", tierName, "BadgeURI"))
            );
            
            emit TierUpgraded(wallet, uint256(oldTier), uint256(newTier), participant.totalPoints);
        }
        
        // Mint points token
        IPointsToken(pointsToken).mint(wallet, adjustedPoints, activityDescription);
        
        emit ParticipantUpdated(wallet, participant.totalPoints, participant.currentTier);
        emit PointsEarned(wallet, adjustedPoints, co2OffsetKg, activityDescription);
    }
    
    /**
     * @dev Get participant data
     * @param wallet Participant wallet address
     * @return Participant data structure
     */
    function getParticipant(address wallet) external view override returns (Participant memory) {
        return _participants[wallet];
    }
    
    /**
     * @dev Check if address is registered
     * @param wallet Address to check
     * @return True if registered
     */
    function isRegistered(address wallet) external view override returns (bool) {
        return _participants[wallet].isActive;
    }
    
    /**
     * @dev Get total number of participants
     * @return Total participant count
     */
    function getTotalParticipants() external view override returns (uint256) {
        return _totalParticipants;
    }
    
    /**
     * @dev Get all participant addresses
     * @return Array of participant addresses
     */
    function getAllParticipants() external view returns (address[] memory) {
        return _participantAddresses;
    }
    
    /**
     * @dev Calculate points for CO2 offset
     * @param co2Kg CO2 offset amount in kg
     * @param hasStreak Whether user has activity streak
     * @return Calculated points
     */
    function calculatePoints(uint256 co2Kg, bool hasStreak) external view returns (uint256) {
        uint256 basePoints = co2Kg * basePointsPerKgCO2;
        if (hasStreak) {
            basePoints += (basePoints * streakBonusMultiplier) / 100;
        }
        return basePoints;
    }
    
    /**
     * @dev Award referral bonus
     * @param referrer Referrer address
     * @param referee Referee address
     */
    function awardReferralBonus(address referrer, address referee) external onlyAuthorized {
        require(_participants[referrer].isActive, "Referrer not registered");
        require(_participants[referee].isActive, "Referee not registered");
        require(referrer != referee, "Cannot refer self");
        
        // Award points to referrer
        _participants[referrer].totalPoints += referralBonus;
        IPointsToken(pointsToken).mint(referrer, referralBonus, "Referral bonus");
        
        emit PointsEarned(referrer, referralBonus, 0, "Referral bonus");
    }
    
    /**
     * @dev Update points configuration (owner only)
     */
    function updatePointsConfig(
        uint256 _basePointsPerKgCO2,
        uint256 _streakBonusMultiplier,
        uint256 _referralBonus
    ) external onlyOwner {
        basePointsPerKgCO2 = _basePointsPerKgCO2;
        streakBonusMultiplier = _streakBonusMultiplier;
        referralBonus = _referralBonus;
    }
    
    /**
     * @dev Update external contract addresses (owner only)
     */
    function updateContractAddresses(
        address _tierManager,
        address _pointsToken,
        address _badgeNFT
    ) external onlyOwner {
        tierManager = _tierManager;
        pointsToken = _pointsToken;
        badgeNFT = _badgeNFT;
    }
    
    /**
     * @dev Pause contract (owner only)
     */
    function pause() external onlyOwner {
        _pause();
    }
    
    /**
     * @dev Unpause contract (owner only)
     */
    function unpause() external onlyOwner {
        _unpause();
    }
    
    /**
     * @dev Get tier name from enum
     */
    function _getTierName(ITierManager.Tier tier) internal pure returns (string memory) {
        if (tier == ITierManager.Tier.BRONZE) return "BRONZE";
        if (tier == ITierManager.Tier.SILVER) return "SILVER";
        if (tier == ITierManager.Tier.GOLD) return "GOLD";
        if (tier == ITierManager.Tier.PLATINUM) return "PLATINUM";
        return "UNKNOWN";
    }

    /**
     * @dev Get participant tier level
     * @param wallet Participant wallet address
     * @return Tier level (0=BRONZE, 1=SILVER, 2=GOLD, 3=PLATINUM)
     */
    function getTierLevel(address wallet) external view returns (uint256) {
        require(_participants[wallet].isActive, "Participant not found");
        return _participants[wallet].currentTier;
    }
    
    /**
     * @dev Get comprehensive participant statistics
     * @param wallet Participant wallet address
     * @return totalPoints Total points earned
     * @return currentTier Current tier level
     * @return joinDate Registration date
     * @return lastActivityDate Last activity date
     * @return daysActive Days since registration
     * @return averagePointsPerDay Average points earned per day
     */
    function getParticipantStats(address wallet) external view returns (
        uint256 totalPoints,
        uint256 currentTier,
        uint256 joinDate,
        uint256 lastActivityDate,
        uint256 daysActive,
        uint256 averagePointsPerDay
    ) {
        require(_participants[wallet].isActive, "Participant not found");
        
        Participant memory participant = _participants[wallet];
        totalPoints = participant.totalPoints;
        currentTier = participant.currentTier;
        joinDate = participant.joinDate;
        lastActivityDate = participant.lastActivityDate;
        
        // Calculate days active
        uint256 currentTime = block.timestamp;
        daysActive = (currentTime - joinDate) / 1 days;
        
        // Calculate average points per day
        if (daysActive > 0) {
            averagePointsPerDay = totalPoints / daysActive;
        } else {
            averagePointsPerDay = totalPoints;
        }
    }
    
} 