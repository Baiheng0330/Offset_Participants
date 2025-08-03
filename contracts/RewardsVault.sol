// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IGreenChainSystem.sol";

/**
 * @title RewardsVault
 * @dev Manages coupon inventory and reward distribution for GreenChain
 */
contract RewardsVault is IRewardsVault, Ownable, Pausable, ReentrancyGuard {
    
    // Coupon inventory mapping
    mapping(uint256 => uint256) private _couponInventory;
    
    // Total rewards tracking
    uint256 private _totalRewards;
    
    // External contract addresses
    address public couponExchange;
    address public participantRegistry;
    
    // Modifiers
    modifier onlyAuthorized() {
        require(
            msg.sender == owner() || 
            msg.sender == couponExchange || 
            msg.sender == participantRegistry,
            "Not authorized"
        );
        _;
    }
    
    constructor(address _couponExchange, address _participantRegistry) 
        Ownable(msg.sender)
    {
        couponExchange = _couponExchange;
        participantRegistry = _participantRegistry;
    }
    
    /**
     * @dev Deposit rewards for a specific coupon
     * @param couponId Coupon ID
     * @param amount Amount to deposit
     */
    function depositReward(uint256 couponId, uint256 amount) external override onlyAuthorized whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        
        _couponInventory[couponId] += amount;
        _totalRewards += amount;
        
        emit RewardDeposited(couponId, amount);
    }
    
    /**
     * @dev Withdraw rewards for a specific coupon
     * @param couponId Coupon ID
     * @param amount Amount to withdraw
     */
    function withdrawReward(uint256 couponId, uint256 amount) external override onlyAuthorized whenNotPaused {
        require(amount > 0, "Amount must be greater than 0");
        require(_couponInventory[couponId] >= amount, "Insufficient inventory");
        
        _couponInventory[couponId] -= amount;
        _totalRewards -= amount;
        
        emit RewardWithdrawn(couponId, amount);
    }
    
    /**
     * @dev Get reward balance for a specific coupon
     * @param couponId Coupon ID
     * @return Reward balance
     */
    function getRewardBalance(uint256 couponId) external view override returns (uint256) {
        return _couponInventory[couponId];
    }
    
    /**
     * @dev Get total rewards across all coupons
     * @return Total rewards
     */
    function getTotalRewards() external view override returns (uint256) {
        return _totalRewards;
    }
    
    /**
     * @dev Get coupon inventory status
     * @param couponId Coupon ID
     * @return Available amount, total deposited, total withdrawn
     */
    function getCouponInventoryStatus(uint256 couponId) external view returns (uint256, uint256, uint256) {
        uint256 available = _couponInventory[couponId];
        // Note: This simplified version doesn't track individual deposits/withdrawals
        // A more complex implementation would track these separately
        return (available, available, 0);
    }
    
    /**
     * @dev Check if coupon has sufficient inventory
     * @param couponId Coupon ID
     * @param requiredAmount Required amount
     * @return True if sufficient inventory
     */
    function hasSufficientInventory(uint256 couponId, uint256 requiredAmount) external view returns (bool) {
        return _couponInventory[couponId] >= requiredAmount;
    }
    
    /**
     * @dev Get all coupons with inventory
     * @return Array of coupon IDs with inventory
     */
    function getCouponsWithInventory() external view returns (uint256[] memory) {
        // This would require tracking all coupon IDs that have been deposited
        // For simplicity, return empty array - in production this would track active coupons
        return new uint256[](0);
    }
    
    /**
     * @dev Emergency withdrawal (owner only)
     * @param couponId Coupon ID
     * @param amount Amount to withdraw
     */
    function emergencyWithdraw(uint256 couponId, uint256 amount) external onlyOwner {
        require(amount > 0, "Amount must be greater than 0");
        require(_couponInventory[couponId] >= amount, "Insufficient inventory");
        
        _couponInventory[couponId] -= amount;
        _totalRewards -= amount;
        
        emit RewardWithdrawn(couponId, amount);
    }
    
    /**
     * @dev Update external contract addresses (owner only)
     */
    function updateContractAddresses(address _couponExchange, address _participantRegistry) external onlyOwner {
        couponExchange = _couponExchange;
        participantRegistry = _participantRegistry;
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
     * @dev Manage coupon inventory
     * @param couponId Coupon ID
     * @param action Action to perform (0=add, 1=remove, 2=reserve, 3=release)
     * @param amount Amount to manage
     * @return success True if operation successful
     * @return newBalance New inventory balance
     */
    function manageInventory(uint256 couponId, uint8 action, uint256 amount) external onlyAuthorized returns (
        bool success,
        uint256 newBalance
    ) {
        require(amount > 0, "Amount must be greater than 0");
        
        bool _success;
        uint256 _newBalance;
        
        if (action == 0) { // Add inventory
            _couponInventory[couponId] += amount;
            _totalRewards += amount;
            _success = true;
        } else if (action == 1) { // Remove inventory
            require(_couponInventory[couponId] >= amount, "Insufficient inventory");
            _couponInventory[couponId] -= amount;
            _totalRewards -= amount;
            _success = true;
        } else if (action == 2) { // Reserve inventory
            require(_couponInventory[couponId] >= amount, "Insufficient inventory");
            // In a more complex system, this would move inventory to a reserved state
            _success = true;
        } else if (action == 3) { // Release inventory
            // In a more complex system, this would release reserved inventory
            _success = true;
        } else {
            _success = false;
        }
        
        _newBalance = _couponInventory[couponId];
        return (_success, _newBalance);
    }
} 