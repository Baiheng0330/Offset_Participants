// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IGreenChainSystem.sol";

/**
 * @title CouponExchange
 * @dev Manages coupon creation, purchase, and redemption using GreenChain points
 */
contract CouponExchange is ICouponExchange, Ownable, Pausable, ReentrancyGuard {
    uint256 private _couponIds;
    uint256 private _userCouponIdCounter;
    
    mapping(uint256 => Coupon) private _coupons;
    mapping(uint256 => UserCoupon) private _userCoupons;
    mapping(address => uint256[]) private _userCouponIds;
    mapping(uint256 => uint256[]) private _couponUserCoupons;
    
    address public pointsToken;
    address public participantRegistry;
    address public tierManager;
    address public rewardsVault;
    
    modifier onlyAuthorized() {
        require(
            msg.sender == owner() || 
            msg.sender == participantRegistry || 
            msg.sender == tierManager,
            "Not authorized"
        );
        _;
    }
    
    constructor(
        address _pointsToken,
        address _participantRegistry,
        address _tierManager,
        address _rewardsVault
    ) 
        Ownable(msg.sender)
    {
        pointsToken = _pointsToken;
        participantRegistry = _participantRegistry;
        tierManager = _tierManager;
        rewardsVault = _rewardsVault;
    }
    
    function createCoupon(
        string memory name,
        string memory description,
        uint256 pointsCost,
        uint256 value,
        string memory category,
        uint256 maxSupply
    ) external override onlyOwner returns (uint256) {
        require(bytes(name).length > 0, "Name required");
        require(pointsCost > 0, "Points cost must be greater than 0");
        require(value > 0, "Value must be greater than 0");
        require(maxSupply > 0, "Max supply must be greater than 0");
        
        _couponIds++;
        uint256 couponId = _couponIds;
        
        _coupons[couponId] = Coupon({
            couponId: couponId,
            name: name,
            description: description,
            pointsCost: pointsCost,
            value: value,
            category: category,
            isActive: true,
            maxSupply: maxSupply,
            currentSupply: 0
        });
        
        emit CouponCreated(couponId, name, pointsCost, value);
        return couponId;
    }
    
    function purchaseCoupon(uint256 couponId) external override whenNotPaused nonReentrant returns (uint256) {
        require(_coupons[couponId].isActive, "Coupon not active");
        require(_coupons[couponId].currentSupply < _coupons[couponId].maxSupply, "Coupon sold out");
        
        Coupon storage coupon = _coupons[couponId];
        uint256 pointsCost = coupon.pointsCost;
        
        // Check if user is registered
        require(IParticipantRegistry(participantRegistry).isRegistered(msg.sender), "Not registered");
        
        // Get user's tier for bonus calculation
        IParticipantRegistry.Participant memory participant = IParticipantRegistry(participantRegistry).getParticipant(msg.sender);
        ITierManager.Tier userTier = ITierManager.Tier(participant.currentTier);
        uint256 tierBonus = ITierManager(tierManager).getTierCouponBonus(userTier);
        
        // Apply tier bonus to coupon value
        uint256 bonusValue = (coupon.value * tierBonus) / 100;
        uint256 totalValue = coupon.value + bonusValue;
        
        // Burn points from user
        IPointsToken(pointsToken).burn(msg.sender, pointsCost, string(abi.encodePacked("Purchased coupon: ", coupon.name)));
        
        // Create user coupon
        _userCouponIdCounter++;
        uint256 userCouponId = _userCouponIdCounter;
        
        _userCoupons[userCouponId] = UserCoupon({
            couponId: couponId,
            owner: msg.sender,
            purchaseDate: block.timestamp,
            isRedeemed: false,
            redemptionDate: 0,
            redemptionCode: ""
        });
        
        _userCouponIds[msg.sender].push(userCouponId);
        _couponUserCoupons[couponId].push(userCouponId);
        
        // Update coupon supply
        coupon.currentSupply++;
        
        emit CouponPurchased(msg.sender, couponId, pointsCost);
        return userCouponId;
    }
    
    function redeemCoupon(uint256 userCouponId) external override whenNotPaused nonReentrant returns (string memory) {
        require(_userCoupons[userCouponId].couponId != 0, "User coupon does not exist");
        require(_userCoupons[userCouponId].owner == msg.sender, "Not coupon owner");
        require(!_userCoupons[userCouponId].isRedeemed, "Coupon already redeemed");
        
        UserCoupon storage userCoupon = _userCoupons[userCouponId];
        userCoupon.isRedeemed = true;
        userCoupon.redemptionDate = block.timestamp;
        
        // Generate redemption code
        string memory redemptionCode = _generateRedemptionCode(userCouponId);
        userCoupon.redemptionCode = redemptionCode;
        
        emit CouponRedeemed(msg.sender, userCoupon.couponId, redemptionCode);
        return redemptionCode;
    }
    
    function getCoupon(uint256 couponId) external view override returns (Coupon memory) {
        return _coupons[couponId];
    }
    
    function getUserCoupons(address user) external view override returns (UserCoupon[] memory) {
        uint256[] memory userCouponIdList = _userCouponIds[user];
        UserCoupon[] memory result = new UserCoupon[](userCouponIdList.length);
        
        for (uint256 i = 0; i < userCouponIdList.length; i++) {
            result[i] = _userCoupons[userCouponIdList[i]];
        }
        
        return result;
    }
    
    function getAvailableCoupons() external view override returns (uint256[] memory) {
        uint256 totalCoupons = _couponIds;
        uint256[] memory availableCoupons = new uint256[](totalCoupons);
        uint256 availableCount = 0;
        
        for (uint256 i = 1; i <= totalCoupons; i++) {
            if (_coupons[i].isActive && _coupons[i].currentSupply < _coupons[i].maxSupply) {
                availableCoupons[availableCount] = i;
                availableCount++;
            }
        }
        
        // Resize array to actual count
        uint256[] memory result = new uint256[](availableCount);
        for (uint256 i = 0; i < availableCount; i++) {
            result[i] = availableCoupons[i];
        }
        
        return result;
    }
    
    function getCouponWithTierBonus(uint256 couponId, address user) external view returns (uint256, uint256) {
        Coupon memory coupon = _coupons[couponId];
        if (!coupon.isActive) return (0, 0);
        
        // Get user's tier bonus
        IParticipantRegistry.Participant memory participant = IParticipantRegistry(participantRegistry).getParticipant(user);
        ITierManager.Tier userTier = ITierManager.Tier(participant.currentTier);
        uint256 tierBonus = ITierManager(tierManager).getTierCouponBonus(userTier);
        
        uint256 bonusValue = (coupon.value * tierBonus) / 100;
        uint256 totalValue = coupon.value + bonusValue;
        
        return (coupon.pointsCost, totalValue);
    }
    
    function updateCoupon(uint256 couponId, bool isActive) external onlyOwner {
        require(_coupons[couponId].couponId != 0, "Coupon does not exist");
        _coupons[couponId].isActive = isActive;
    }
    
    function updateContractAddresses(
        address _pointsToken,
        address _participantRegistry,
        address _tierManager,
        address _rewardsVault
    ) external onlyOwner {
        pointsToken = _pointsToken;
        participantRegistry = _participantRegistry;
        tierManager = _tierManager;
        rewardsVault = _rewardsVault;
    }
    
    function pause() external onlyOwner {
        _pause();
    }
    
    function unpause() external onlyOwner {
        _unpause();
    }
    
    function _generateRedemptionCode(uint256 userCouponId) internal view returns (string memory) {
        return string(abi.encodePacked(
            "GC-",
            _uint2str(userCouponId),
            "-",
            _uint2str(block.timestamp)
        ));
    }
    
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

    /**
     * @dev Update exchange rates for coupons (owner only)
     * @param couponId Coupon ID to update
     * @param newPointsCost New points cost
     * @param newValue New coupon value
     */
    function updateExchangeRates(uint256 couponId, uint256 newPointsCost, uint256 newValue) external onlyOwner {
        require(_coupons[couponId].couponId != 0, "Coupon does not exist");
        require(newPointsCost > 0, "Points cost must be greater than 0");
        require(newValue > 0, "Value must be greater than 0");
        
        _coupons[couponId].pointsCost = newPointsCost;
        _coupons[couponId].value = newValue;
        
        emit CouponCreated(couponId, _coupons[couponId].name, newPointsCost, newValue);
    }
    
    /**
     * @dev Validate coupon redemption
     * @param userCouponId User coupon ID
     * @param redemptionCode Redemption code to validate
     * @return valid True if redemption is valid
     * @return couponInfo Coupon information if valid
     */
    function validateRedemption(uint256 userCouponId, string memory redemptionCode) external view returns (
        bool valid,
        Coupon memory couponInfo
    ) {
        UserCoupon memory userCoupon = _userCoupons[userCouponId];
        
        if (userCoupon.couponId == 0) {
            return (false, couponInfo);
        }
        
        if (!userCoupon.isRedeemed) {
            return (false, couponInfo);
        }
        
        if (keccak256(bytes(userCoupon.redemptionCode)) != keccak256(bytes(redemptionCode))) {
            return (false, couponInfo);
        }
        
        valid = true;
        couponInfo = _coupons[userCoupon.couponId];
    }
} 