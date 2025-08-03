// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "./interfaces/IGreenChainSystem.sol";

/**
 * @title TierManager
 * @dev Manages tier progression, benefits, and multipliers for GreenChain participants
 */
contract TierManager is ITierManager, Ownable, Pausable {
    
    // Tier configuration mapping
    mapping(Tier => TierInfo) private _tierConfigs;
    
    // External contract addresses
    address public participantRegistry;
    address public badgeNFT;
    
    // Modifiers
    modifier onlyAuthorized() {
        require(msg.sender == owner() || msg.sender == participantRegistry, "Not authorized");
        _;
    }
    
    constructor(address _participantRegistry, address _badgeNFT) 
        Ownable(msg.sender)
    {
        participantRegistry = _participantRegistry;
        badgeNFT = _badgeNFT;
        _initializeTierConfigs();
    }
    
    /**
     * @dev Initialize default tier configurations
     */
    function _initializeTierConfigs() internal {
        // BRONZE Tier (0-999 points)
        _tierConfigs[Tier.BRONZE] = TierInfo({
            minPoints: 0,
            maxPoints: 999,
            multiplier: 100, // 1.0x multiplier
            couponBonus: 0, // No bonus
            hasPriorityAccess: false,
            hasExclusiveProjects: false,
            hasVipAccess: false,
            badgeURI: "ipfs://QmBronzeBadgeURI"
        });
        
        // SILVER Tier (1,000-4,999 points)
        _tierConfigs[Tier.SILVER] = TierInfo({
            minPoints: 1000,
            maxPoints: 4999,
            multiplier: 120, // 1.2x multiplier
            couponBonus: 10, // 10% bonus
            hasPriorityAccess: true,
            hasExclusiveProjects: false,
            hasVipAccess: false,
            badgeURI: "ipfs://QmSilverBadgeURI"
        });
        
        // GOLD Tier (5,000-19,999 points)
        _tierConfigs[Tier.GOLD] = TierInfo({
            minPoints: 5000,
            maxPoints: 19999,
            multiplier: 150, // 1.5x multiplier
            couponBonus: 20, // 20% bonus
            hasPriorityAccess: true,
            hasExclusiveProjects: true,
            hasVipAccess: false,
            badgeURI: "ipfs://QmGoldBadgeURI"
        });
        
        // PLATINUM Tier (20,000+ points)
        _tierConfigs[Tier.PLATINUM] = TierInfo({
            minPoints: 20000,
            maxPoints: type(uint256).max,
            multiplier: 200, // 2.0x multiplier
            couponBonus: 30, // 30% bonus
            hasPriorityAccess: true,
            hasExclusiveProjects: true,
            hasVipAccess: true,
            badgeURI: "ipfs://QmPlatinumBadgeURI"
        });
    }
    
    /**
     * @dev Calculate tier based on points
     * @param points Total points earned
     * @return Tier enum value
     */
    function calculateTier(uint256 points) external pure override returns (Tier) {
        if (points >= 20000) {
            return Tier.PLATINUM;
        } else if (points >= 5000) {
            return Tier.GOLD;
        } else if (points >= 1000) {
            return Tier.SILVER;
        } else {
            return Tier.BRONZE;
        }
    }
    
    /**
     * @dev Get tier information
     * @param tier Tier enum value
     * @return TierInfo structure
     */
    function getTierInfo(Tier tier) external view override returns (TierInfo memory) {
        return _tierConfigs[tier];
    }
    
    /**
     * @dev Get tier multiplier (in basis points)
     * @param tier Tier enum value
     * @return Multiplier in basis points (e.g., 120 = 1.2x)
     */
    function getTierMultiplier(Tier tier) external view override returns (uint256) {
        return _tierConfigs[tier].multiplier;
    }
    
    /**
     * @dev Get tier coupon bonus (in basis points)
     * @param tier Tier enum value
     * @return Coupon bonus in basis points (e.g., 10 = 10%)
     */
    function getTierCouponBonus(Tier tier) external view override returns (uint256) {
        return _tierConfigs[tier].couponBonus;
    }
    
    /**
     * @dev Check if tier has priority access
     * @param tier Tier enum value
     * @return True if tier has priority access
     */
    function hasPriorityAccess(Tier tier) external view returns (bool) {
        return _tierConfigs[tier].hasPriorityAccess;
    }
    
    /**
     * @dev Check if tier has exclusive project access
     * @param tier Tier enum value
     * @return True if tier has exclusive access
     */
    function hasExclusiveAccess(Tier tier) external view returns (bool) {
        return _tierConfigs[tier].hasExclusiveProjects;
    }
    
    /**
     * @dev Check if tier has VIP access
     * @param tier Tier enum value
     * @return True if tier has VIP access
     */
    function hasVipAccess(Tier tier) external view returns (bool) {
        return _tierConfigs[tier].hasVipAccess;
    }
    
    /**
     * @dev Get tier requirements for next tier
     * @param currentTier Current tier
     * @return Points required for next tier, 0 if at max tier
     */
    function getNextTierRequirements(Tier currentTier) external view returns (uint256) {
        if (currentTier == Tier.PLATINUM) {
            return 0; // Already at max tier
        }
        
        Tier nextTier;
        if (currentTier == Tier.BRONZE) {
            nextTier = Tier.SILVER;
        } else if (currentTier == Tier.SILVER) {
            nextTier = Tier.GOLD;
        } else if (currentTier == Tier.GOLD) {
            nextTier = Tier.PLATINUM;
        }
        
        return _tierConfigs[nextTier].minPoints;
    }
    
    /**
     * @dev Check if participant is eligible for tier upgrade
     * @param currentPoints Current total points
     * @param currentTier Current tier level
     * @return eligible True if eligible for upgrade
     * @return nextTier Next tier level
     * @return pointsNeeded Points needed for next tier
     */
    function checkTierUpgrade(uint256 currentPoints, Tier currentTier) external view returns (
        bool eligible,
        Tier nextTier,
        uint256 pointsNeeded
    ) {
        // Calculate tier based on points
        Tier calculatedTier;
        if (currentPoints >= 20000) {
            calculatedTier = Tier.PLATINUM;
        } else if (currentPoints >= 5000) {
            calculatedTier = Tier.GOLD;
        } else if (currentPoints >= 1000) {
            calculatedTier = Tier.SILVER;
        } else {
            calculatedTier = Tier.BRONZE;
        }
        
        if (calculatedTier > currentTier) {
            eligible = true;
            nextTier = calculatedTier;
            pointsNeeded = 0; // Already eligible
        } else {
            eligible = false;
            nextTier = currentTier;
            
            // Calculate points needed for next tier
            if (currentTier == Tier.PLATINUM) {
                pointsNeeded = 0; // Already at max tier
            } else if (currentTier == Tier.BRONZE) {
                pointsNeeded = _tierConfigs[Tier.SILVER].minPoints;
            } else if (currentTier == Tier.SILVER) {
                pointsNeeded = _tierConfigs[Tier.GOLD].minPoints;
            } else if (currentTier == Tier.GOLD) {
                pointsNeeded = _tierConfigs[Tier.PLATINUM].minPoints;
            }
        }
    }
    
    /**
     * @dev Get tier benefits summary
     * @param tier Tier enum value
     * @return Benefits string
     */
    function getTierBenefits(Tier tier) external view returns (string memory) {
        TierInfo memory info = _tierConfigs[tier];
        
        string memory benefits = "";
        
        if (info.multiplier > 100) {
            benefits = string(abi.encodePacked(
                benefits,
                "Points Multiplier: ", _uint2str((info.multiplier * 100) / 100), "x. "
            ));
        }
        
        if (info.couponBonus > 0) {
            benefits = string(abi.encodePacked(
                benefits,
                "Coupon Bonus: +", _uint2str(info.couponBonus), "%. "
            ));
        }
        
        if (info.hasPriorityAccess) {
            benefits = string(abi.encodePacked(benefits, "Priority Project Access. "));
        }
        
        if (info.hasExclusiveProjects) {
            benefits = string(abi.encodePacked(benefits, "Exclusive Offset Projects. "));
        }
        
        if (info.hasVipAccess) {
            benefits = string(abi.encodePacked(benefits, "VIP Early Access. "));
        }
        
        return benefits;
    }
    
    /**
     * @dev Update tier configuration (owner only)
     * @param tier Tier to update
     * @param tierInfo New tier configuration
     */
    function updateTierConfig(Tier tier, TierInfo memory tierInfo) external override onlyOwner {
        require(tierInfo.minPoints < tierInfo.maxPoints, "Invalid point range");
        require(tierInfo.multiplier >= 100, "Multiplier must be at least 100");
        require(tierInfo.couponBonus <= 100, "Coupon bonus cannot exceed 100%");
        
        _tierConfigs[tier] = tierInfo;
        
        emit TierConfigUpdated(tier, tierInfo);
    }
    
    /**
     * @dev Update external contract addresses (owner only)
     */
    function updateContractAddresses(address _participantRegistry, address _badgeNFT) external onlyOwner {
        participantRegistry = _participantRegistry;
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
     * @dev Upgrade participant tier (called by authorized contracts)
     * @param participantAddress Participant address
     * @param newTier New tier level
     */
    function upgradeTier(address participantAddress, Tier newTier) external onlyAuthorized {
        require(participantAddress != address(0), "Invalid participant address");
        require(uint256(newTier) <= 3, "Invalid tier level");
        
        // This function would typically be called by ParticipantRegistry
        // after verifying the participant has enough points
        emit TierUpgraded(participantAddress, Tier.BRONZE, newTier, 0);
    }
    
    /**
     * @dev Convert uint to string
     */
    function _uint2str(uint256 _i) internal pure returns (string memory) {
        if (_i == 0) {
            return "0";
        }
        
        uint256 j = _i;
        uint256 length;
        
        while (j != 0) {
            length++;
            j /= 10;
        }
        
        bytes memory bstr = new bytes(length);
        uint256 k = length;
        
        while (_i != 0) {
            k -= 1;
            uint8 temp = (48 + uint8(_i - _i / 10 * 10));
            bytes1 b1 = bytes1(temp);
            bstr[k] = b1;
            _i /= 10;
        }
        
        return string(bstr);
    }
} 