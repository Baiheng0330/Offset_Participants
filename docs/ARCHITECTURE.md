# GreenChain System Architecture

## Overview

The GreenChain Participant Record & Tier System is a comprehensive blockchain-based platform designed to incentivize and track carbon offset activities through gamification, tier progression, and reward mechanisms.

## System Components

### 1. Smart Contract Architecture

#### Core Contracts

**ParticipantRegistry.sol**
- **Purpose**: Central participant data management
- **Key Functions**:
  - Participant registration and profile management
  - Points tracking and activity logging
  - Tier progression coordination
  - Referral bonus management
- **Data Storage**:
  - Participant profiles (wallet, points, tier, timestamps)
  - Activity history and CO2 offset records
  - IPFS hash references for off-chain data

**TierManager.sol**
- **Purpose**: Tier logic and progression mechanics
- **Key Functions**:
  - Tier calculation based on points
  - Multiplier and bonus management
  - Tier benefit configuration
  - Progression tracking
- **Tier Structure**:
  - BRONZE (0-999 points): 1.0x multiplier, 0% bonus
  - SILVER (1,000-4,999 points): 1.2x multiplier, 10% bonus
  - GOLD (5,000-19,999 points): 1.5x multiplier, 20% bonus
  - PLATINUM (20,000+ points): 2.0x multiplier, 30% bonus

**PointsToken.sol**
- **Purpose**: ERC-20 token for points management
- **Key Functions**:
  - Points minting and burning
  - Balance tracking
  - Transfer restrictions (authorized contracts only)
  - Supply management
- **Token Details**:
  - Symbol: GCP (GreenChain Points)
  - Decimals: 18
  - Non-transferable between users (system-controlled)

**BadgeNFT.sol**
- **Purpose**: ERC-721 tokens for achievements and tier badges
- **Key Functions**:
  - Badge minting and management
  - Metadata storage (IPFS)
  - User badge tracking
  - Badge type categorization
- **Badge Types**:
  - Tier badges (BRONZE, SILVER, GOLD, PLATINUM)
  - Achievement badges (SPECIAL)
  - Milestone badges

**CouponExchange.sol**
- **Purpose**: Points to rewards conversion system
- **Key Functions**:
  - Coupon creation and management
  - Purchase and redemption logic
  - Tier bonus application
  - Inventory tracking
- **Features**:
  - Tier-based value bonuses
  - Redemption code generation
  - Supply management
  - Category organization

**RewardsVault.sol**
- **Purpose**: Coupon inventory and reward distribution
- **Key Functions**:
  - Reward deposit and withdrawal
  - Inventory tracking
  - Supply management
  - Emergency controls

### 2. Data Flow Architecture

#### On-Chain Data Flow

```
User Activity → ParticipantRegistry → TierManager → PointsToken/BadgeNFT
     ↓
CO2 Offset → Points Calculation → Tier Check → Badge Minting
     ↓
Points Earned → CouponExchange → RewardsVault → Redemption
```

#### Off-Chain Data Flow

```
User Profile → IPFS Storage → Profile Hash → On-Chain Reference
     ↓
Activity Logs → Database → Analytics → Dashboard
     ↓
Social Features → API → Community → Engagement
```

### 3. Security Architecture

#### Access Control

- **Owner**: Full administrative control
- **Authorized Contracts**: Inter-contract communication
- **Participants**: Limited to registration and redemption
- **Emergency Pause**: System-wide pause capability

#### Security Features

- **Reentrancy Protection**: All external calls protected
- **Input Validation**: Comprehensive parameter checking
- **Pausable**: Emergency stop functionality
- **Upgradeable**: Contract upgrade mechanisms
- **Gas Optimization**: Efficient storage and operations

### 4. Economic Model

#### Point Economics

**Base Earning Rate**
- 10 points per kg CO₂ offset
- Configurable through contract parameters

**Multipliers**
- Tier-based multipliers (1.0x to 2.0x)
- Streak bonuses (5% additional)
- Event bonuses (configurable)

**Bonus System**
- Referral bonuses (50 points)
- Activity streak bonuses
- Special event bonuses
- Community engagement bonuses

#### Reward Economics

**Coupon Value**
- Base value in USD cents
- Tier-based bonus application
- Supply and demand management

**Redemption Process**
- Points → Coupon → Redemption Code
- Real-world value conversion
- Inventory management

### 5. Integration Architecture

#### Frontend Integration

```javascript
// Contract Connection
const provider = new ethers.providers.Web3Provider(window.ethereum);
const signer = provider.getSigner();

// Contract Instances
const participantRegistry = new ethers.Contract(ADDRESS, ABI, signer);
const pointsToken = new ethers.Contract(ADDRESS, ABI, signer);
const badgeNFT = new ethers.Contract(ADDRESS, ABI, signer);
const couponExchange = new ethers.Contract(ADDRESS, ABI, signer);
```

#### Backend Integration

```javascript
// Event Monitoring
participantRegistry.on("ParticipantRegistered", handleRegistration);
participantRegistry.on("PointsEarned", handlePointsEarned);
tierManager.on("TierUpgraded", handleTierUpgrade);
badgeNFT.on("BadgeMinted", handleBadgeMinted);
couponExchange.on("CouponPurchased", handleCouponPurchase);
```

#### External Service Integration

- **IPFS**: Profile and badge metadata storage
- **Carbon Offset APIs**: Activity verification
- **Weather APIs**: Environmental impact calculation
- **Analytics Services**: User behavior tracking

### 6. Scalability Considerations

#### Gas Optimization

- Efficient data structures
- Minimal storage operations
- Batch processing capabilities
- Optimized loops and mappings

#### Performance Optimization

- Event-driven architecture
- Off-chain computation
- Caching strategies
- Database indexing

#### Network Considerations

- Multi-chain compatibility
- Cross-chain bridges
- Layer 2 solutions
- Sidechain integration

### 7. Monitoring and Analytics

#### Key Metrics

**User Metrics**
- Total participants
- Active users
- Tier distribution
- Points distribution

**Activity Metrics**
- CO2 offset volume
- Points earned
- Badge acquisition
- Coupon redemption

**Economic Metrics**
- Points supply
- Coupon value
- Redemption rates
- Economic velocity

#### Event Tracking

```javascript
// Key Events
ParticipantRegistered(address wallet, uint256 joinDate)
PointsEarned(address wallet, uint256 points, uint256 co2Offset, string activity)
TierUpgraded(address wallet, Tier oldTier, Tier newTier, uint256 points)
BadgeMinted(address wallet, uint256 tokenId, string badgeType)
CouponPurchased(address user, uint256 couponId, uint256 pointsSpent)
CouponRedeemed(address user, uint256 couponId, string redemptionCode)
```

### 8. Deployment Architecture

#### Network Strategy

**Development**
- Local Hardhat network
- Ganache for testing
- Mock contracts for integration

**Testing**
- Sepolia testnet
- Goerli testnet
- Polygon Mumbai testnet

**Production**
- Ethereum mainnet
- Polygon mainnet
- Layer 2 solutions

#### Contract Deployment

```javascript
// Deployment Order
1. TierManager
2. PointsToken
3. BadgeNFT
4. RewardsVault
5. CouponExchange
6. ParticipantRegistry

// Address Updates
7. Update all contract references
8. Initialize configurations
9. Create sample data
```

### 9. Future Enhancements

#### Phase 2 Features

- **Social Features**: Community challenges and leaderboards
- **Advanced Gamification**: Quests, achievements, and competitions
- **DeFi Integration**: Point staking and yield farming
- **Cross-Chain**: Multi-chain compatibility

#### Phase 3 Features

- **Enterprise Integration**: Corporate carbon offset programs
- **Carbon Credit Marketplace**: Direct carbon credit trading
- **Mobile App**: Native mobile application
- **AI Integration**: Smart recommendations and predictions

### 10. Risk Management

#### Technical Risks

- **Smart Contract Vulnerabilities**: Comprehensive testing and auditing
- **Gas Price Volatility**: Gas optimization and L2 solutions
- **Network Congestion**: Multi-chain deployment strategy
- **Data Availability**: IPFS redundancy and backup strategies

#### Economic Risks

- **Point Inflation**: Controlled minting and burning mechanisms
- **Coupon Devaluation**: Supply management and value controls
- **Market Manipulation**: Anti-gaming mechanisms
- **Regulatory Changes**: Compliance and adaptability features

#### Operational Risks

- **Key Management**: Multi-signature and hardware wallet integration
- **Emergency Response**: Pause mechanisms and recovery procedures
- **Data Loss**: Backup and recovery strategies
- **Service Disruption**: Redundancy and failover systems

## Conclusion

The GreenChain system architecture provides a robust, scalable, and secure foundation for incentivizing carbon offset activities through blockchain technology. The modular design allows for easy upgrades and extensions while maintaining security and performance standards.

The combination of on-chain and off-chain data storage optimizes for both security and cost-effectiveness, while the comprehensive economic model ensures sustainable growth and user engagement. 