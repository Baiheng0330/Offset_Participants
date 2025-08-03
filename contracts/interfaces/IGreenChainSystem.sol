// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

/**
 * @title IGreenChainSystem
 * @dev Core interfaces for the GreenChain Carbon Offset Platform
 */

interface IParticipantRegistry {
    struct Participant {
        address wallet;
        uint256 totalPoints;
        uint256 currentTier;
        uint256 joinDate;
        uint256 lastActivityDate;
        bool isActive;
        string profileHash; // IPFS hash for off-chain profile data
    }

    event ParticipantRegistered(address indexed wallet, uint256 joinDate);
    event ParticipantUpdated(address indexed wallet, uint256 totalPoints, uint256 tier);
    event PointsEarned(address indexed wallet, uint256 points, uint256 co2Offset, string activity);

    function registerParticipant(string memory profileHash) external;
    function updateParticipant(address wallet, uint256 points, uint256 co2Offset, string memory activity) external;
    function getParticipant(address wallet) external view returns (Participant memory);
    function isRegistered(address wallet) external view returns (bool);
    function getTotalParticipants() external view returns (uint256);
}

interface ITierManager {
    enum Tier { BRONZE, SILVER, GOLD, PLATINUM }

    struct TierInfo {
        uint256 minPoints;
        uint256 maxPoints;
        uint256 multiplier; // Points multiplier (in basis points, e.g., 120 = 1.2x)
        uint256 couponBonus; // Coupon value bonus (in basis points)
        bool hasPriorityAccess;
        bool hasExclusiveProjects;
        bool hasVipAccess;
        string badgeURI;
    }

    event TierUpgraded(address indexed wallet, Tier oldTier, Tier newTier, uint256 points);
    event TierConfigUpdated(Tier tier, TierInfo tierInfo);

    function calculateTier(uint256 points) external pure returns (Tier);
    function getTierInfo(Tier tier) external view returns (TierInfo memory);
    function getTierMultiplier(Tier tier) external view returns (uint256);
    function getTierCouponBonus(Tier tier) external view returns (uint256);
    function updateTierConfig(Tier tier, TierInfo memory tierInfo) external;
}

interface IPointsToken {
    event PointsMinted(address indexed to, uint256 amount, string reason);
    event PointsBurned(address indexed from, uint256 amount, string reason);
    event PointsTransferred(address indexed from, address indexed to, uint256 amount);

    function mint(address to, uint256 amount, string memory reason) external;
    function burn(address from, uint256 amount, string memory reason) external;
    function transferPoints(address from, address to, uint256 amount) external;
    function balanceOf(address account) external view returns (uint256);
    function totalSupply() external view returns (uint256);
}

interface IBadgeNFT {
    struct Badge {
        uint256 tokenId;
        address owner;
        string badgeType; // "BRONZE", "SILVER", "GOLD", "PLATINUM", "SPECIAL"
        string name;
        string description;
        string imageURI;
        uint256 earnedDate;
        bool isActive;
    }

    event BadgeMinted(address indexed to, uint256 tokenId, string badgeType);
    event BadgeUpdated(uint256 tokenId, string badgeType);

    function mintBadge(address to, string memory badgeType, string memory name, string memory description, string memory imageURI) external returns (uint256);
    function getBadge(uint256 tokenId) external view returns (Badge memory);
    function getUserBadges(address user) external view returns (uint256[] memory);
    function updateBadge(uint256 tokenId, string memory badgeType) external;
    function burnBadge(uint256 tokenId) external;
}

interface ICouponExchange {
    struct Coupon {
        uint256 couponId;
        string name;
        string description;
        uint256 pointsCost;
        uint256 value; // Value in USD cents
        string category; // "FOOD", "SHOPPING", "TRAVEL", "ENTERTAINMENT"
        bool isActive;
        uint256 maxSupply;
        uint256 currentSupply;
    }

    struct UserCoupon {
        uint256 couponId;
        address owner;
        uint256 purchaseDate;
        bool isRedeemed;
        uint256 redemptionDate;
        string redemptionCode;
    }

    event CouponCreated(uint256 couponId, string name, uint256 pointsCost, uint256 value);
    event CouponPurchased(address indexed user, uint256 couponId, uint256 pointsSpent);
    event CouponRedeemed(address indexed user, uint256 couponId, string redemptionCode);

    function createCoupon(string memory name, string memory description, uint256 pointsCost, uint256 value, string memory category, uint256 maxSupply) external returns (uint256);
    function purchaseCoupon(uint256 couponId) external returns (uint256);
    function redeemCoupon(uint256 userCouponId) external returns (string memory);
    function getCoupon(uint256 couponId) external view returns (Coupon memory);
    function getUserCoupons(address user) external view returns (UserCoupon[] memory);
    function getAvailableCoupons() external view returns (uint256[] memory);
}

interface IRewardsVault {
    event RewardDeposited(uint256 couponId, uint256 amount);
    event RewardWithdrawn(uint256 couponId, uint256 amount);

    function depositReward(uint256 couponId, uint256 amount) external;
    function withdrawReward(uint256 couponId, uint256 amount) external;
    function getRewardBalance(uint256 couponId) external view returns (uint256);
    function getTotalRewards() external view returns (uint256);
} 