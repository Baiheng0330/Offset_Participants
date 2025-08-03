// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Pausable.sol";
import "@openzeppelin/contracts/utils/ReentrancyGuard.sol";
import "./interfaces/IGreenChainSystem.sol";

/**
 * @title PointsToken
 * @dev ERC-20 token representing GreenChain points earned through carbon offset activities
 */
contract PointsToken is IPointsToken, ERC20, Ownable, Pausable, ReentrancyGuard {
    
    // External contract addresses
    address public participantRegistry;
    address public couponExchange;
    
    // Points metadata
    string public constant POINTS_SYMBOL = "GCP";
    string public constant POINTS_NAME = "GreenChain Points";
    uint8 public constant DECIMALS = 18;
    
    // Modifiers
    modifier onlyAuthorized() {
        require(
            msg.sender == owner() || 
            msg.sender == participantRegistry || 
            msg.sender == couponExchange,
            "Not authorized"
        );
        _;
    }
    
    constructor(address _participantRegistry, address _couponExchange) 
        ERC20(POINTS_NAME, POINTS_SYMBOL)
        Ownable(msg.sender)
    {
        participantRegistry = _participantRegistry;
        couponExchange = _couponExchange;
    }
    
    /**
     * @dev Mint points to an address (authorized contracts only)
     * @param to Recipient address
     * @param amount Points amount
     * @param reason Reason for minting
     */
    function mint(
        address to, 
        uint256 amount, 
        string memory reason
    ) external override onlyAuthorized whenNotPaused {
        require(to != address(0), "Cannot mint to zero address");
        require(amount > 0, "Amount must be greater than 0");
        require(bytes(reason).length > 0, "Reason required");
        
        _mint(to, amount);
        
        emit PointsMinted(to, amount, reason);
    }
    
    /**
     * @dev Burn points from an address (authorized contracts only)
     * @param from Address to burn from
     * @param amount Points amount
     * @param reason Reason for burning
     */
    function burn(
        address from, 
        uint256 amount, 
        string memory reason
    ) external override onlyAuthorized whenNotPaused {
        require(from != address(0), "Cannot burn from zero address");
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(from) >= amount, "Insufficient balance");
        require(bytes(reason).length > 0, "Reason required");
        
        _burn(from, amount);
        
        emit PointsBurned(from, amount, reason);
    }
    
    /**
     * @dev Transfer points between addresses (authorized contracts only)
     * @param from Source address
     * @param to Destination address
     * @param amount Points amount
     */
    function transferPoints(
        address from, 
        address to, 
        uint256 amount
    ) external override onlyAuthorized whenNotPaused {
        require(from != address(0), "Cannot transfer from zero address");
        require(to != address(0), "Cannot transfer to zero address");
        require(amount > 0, "Amount must be greater than 0");
        require(balanceOf(from) >= amount, "Insufficient balance");
        
        _transfer(from, to, amount);
        
        emit PointsTransferred(from, to, amount);
    }
    
    /**
     * @dev Get points balance for an address
     * @param account Address to check
     * @return Points balance
     */
    function balanceOf(address account) public view override(ERC20, IPointsToken) returns (uint256) {
        return super.balanceOf(account);
    }
    
    /**
     * @dev Get points balance for an address (alias for balanceOf)
     * @param account Address to check
     * @return Points balance
     */
    function getBalance(address account) external view returns (uint256) {
        return balanceOf(account);
    }
    
    /**
     * @dev Get total points supply
     * @return Total supply
     */
    function totalSupply() public view override(ERC20, IPointsToken) returns (uint256) {
        return super.totalSupply();
    }
    
    /**
     * @dev Standard ERC-20 transfer (disabled for regular users)
     */
    function transfer(address to, uint256 amount) public override returns (bool) {
        revert("Direct transfers disabled. Use authorized contracts.");
    }
    
    /**
     * @dev Standard ERC-20 transferFrom (disabled for regular users)
     */
    function transferFrom(address from, address to, uint256 amount) public override returns (bool) {
        revert("Direct transfers disabled. Use authorized contracts.");
    }
    
    /**
     * @dev Standard ERC-20 approve (disabled for regular users)
     */
    function approve(address spender, uint256 amount) public override returns (bool) {
        revert("Approvals disabled for GreenChain Points.");
    }
    
    /**
     * @dev Standard ERC-20 increaseAllowance (disabled for regular users)
     */
    function increaseAllowance(address spender, uint256 addedValue) public returns (bool) {
        revert("Allowances disabled for GreenChain Points.");
    }
    
    /**
     * @dev Standard ERC-20 decreaseAllowance (disabled for regular users)
     */
    function decreaseAllowance(address spender, uint256 subtractedValue) public returns (bool) {
        revert("Allowances disabled for GreenChain Points.");
    }
    
    /**
     * @dev Get points statistics
     * @return Total minted, total burned, current supply
     */
    function getPointsStats() external view returns (uint256, uint256, uint256) {
        return (totalSupply(), 0, totalSupply()); // Burned points not tracked separately in this implementation
    }
    
    /**
     * @dev Get points earned by address in a time range
     * @param account Address to check
     * @param fromTime Start time
     * @param toTime End time
     * @return Points earned in time range
     */
    function getPointsEarnedInRange(
        address account, 
        uint256 fromTime, 
        uint256 toTime
    ) external view returns (uint256) {
        // This would require additional event tracking for precise calculation
        // For now, return current balance as approximation
        return balanceOf(account);
    }
    
    /**
     * @dev Update external contract addresses (owner only)
     */
    function updateContractAddresses(address _participantRegistry, address _couponExchange) external onlyOwner {
        participantRegistry = _participantRegistry;
        couponExchange = _couponExchange;
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
     * @dev Override decimals to match specification
     */
    function decimals() public view virtual override returns (uint8) {
        return DECIMALS;
    }
} 