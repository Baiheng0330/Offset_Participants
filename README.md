# GreenChain Participant Record & Tier System

A comprehensive blockchain-based carbon offset platform that gamifies sustainability through participant records, tier progression, points economics, and reward systems.

## 🌱 Overview

GreenChain is a decentralized platform that incentivizes carbon offset activities through a sophisticated tier system, point economics, and gamification features. Users earn points for their carbon offset activities, progress through tiers with increasing benefits, and can redeem rewards through a coupon exchange system.

## 🏗️ System Architecture

### Core Smart Contracts

1. **ParticipantRegistry** - Main user data management
2. **TierManager** - Tier logic and progression mechanics
3. **PointsToken** - ERC-20 token for points management
4. **BadgeNFT** - ERC-721 tokens for achievements and tier badges
5. **CouponExchange** - Points to rewards conversion system
6. **RewardsVault** - Coupon inventory management

### Data Storage Strategy

**On-Chain Data (Immutable)**
- Total points earned
- Current tier level
- Badge ownership
- Major milestones
- Offset certificates

**Off-Chain Data (Mutable)**
- User profile details
- Activity logs
- Coupon redemption history
- Social features data
- Analytics data

## 🎯 Features

### Tier System

| Tier | Points Range | Multiplier | Coupon Bonus | Benefits |
|------|-------------|------------|--------------|----------|
| **BRONZE** | 0-999 | 1.0x | 0% | Basic offset tracking |
| **SILVER** | 1,000-4,999 | 1.2x | 10% | Priority project access, Silver badge |
| **GOLD** | 5,000-19,999 | 1.5x | 20% | Exclusive projects, Quarterly reports, Gold badge |
| **PLATINUM** | 20,000+ | 2.0x | 30% | VIP access, Personal dashboard, Annual certificate, Platinum badge |

### Point Economics

- **Base Rate**: 10 points per kg CO₂ offset
- **Streak Bonus**: 5% additional points for consistent activity
- **Referral Bonus**: 50 points for successful referrals
- **Tier Multipliers**: Applied to all point earnings

### Gamification Features

- **Achievement Badges**: NFT-based badges for milestones
- **Tier Progression**: Visual progression through sustainability levels
- **Reward System**: Convert points to real-world rewards
- **Community Features**: Referral bonuses and social sharing

## 🚀 Quick Start

### Prerequisites

- Node.js (v16 or higher)
- npm or yarn
- Hardhat

### Installation

```bash
# Clone the repository
git clone <repository-url>
cd greenchain-participant-system

# Install dependencies
npm install

# Compile contracts
npm run compile

# Run tests
npm test

# Deploy to local network
npm run deploy
```

### Environment Setup

Create a `.env` file with the following variables:

```env
PRIVATE_KEY=your_private_key_here
SEPOLIA_URL=your_sepolia_rpc_url
MAINNET_URL=your_mainnet_rpc_url
ETHERSCAN_API_KEY=your_etherscan_api_key
```

## 📋 Contract Deployment

### Local Development

```bash
# Start local Hardhat node
npm run node

# Deploy contracts
npm run deploy
```

### Testnet Deployment

```bash
# Deploy to Sepolia testnet
npm run deploy:testnet
```

### Mainnet Deployment

```bash
# Deploy to mainnet
npm run deploy:mainnet
```

## 🔧 Usage Examples

### Participant Registration

```javascript
// Register a new participant
await participantRegistry.registerParticipant("QmProfileHash123");

// Check participant status
const participant = await participantRegistry.getParticipant(userAddress);
console.log("Tier:", participant.currentTier);
console.log("Points:", participant.totalPoints);
```

### Earning Points

```javascript
// Award points for CO2 offset (authorized contracts only)
await participantRegistry.updateParticipant(
    userAddress,
    500, // points
    50,  // kg CO2 offset
    "Solar panel installation"
);
```

### Tier Progression

```javascript
// Check current tier
const tier = await tierManager.calculateTier(participant.totalPoints);

// Get tier benefits
const benefits = await tierManager.getTierBenefits(tier);
console.log("Benefits:", benefits);
```

### Coupon Exchange

```javascript
// Create a new coupon
await couponExchange.createCoupon(
    "Starbucks $5 Gift Card",
    "Enjoy a coffee on us!",
    500, // points cost
    500, // value in cents
    "FOOD",
    1000 // max supply
);

// Purchase coupon
const userCouponId = await couponExchange.purchaseCoupon(couponId);

// Redeem coupon
const redemptionCode = await couponExchange.redeemCoupon(userCouponId);
```

### Badge Management

```javascript
// Get user badges
const userBadges = await badgeNFT.getUserBadges(userAddress);

// Get badge details
const badge = await badgeNFT.getBadge(badgeId);
console.log("Badge Type:", badge.badgeType);
console.log("Earned Date:", badge.earnedDate);
```

## 🧪 Testing

Run the comprehensive test suite:

```bash
# Run all tests
npm test

# Run specific test file
npx hardhat test test/GreenChainSystem.test.js

# Run with coverage
npm run coverage
```

## 📊 Gas Optimization

The contracts are optimized for gas efficiency:

- Efficient data structures
- Minimal storage operations
- Optimized loops and mappings
- Batch operations where possible

## 🔒 Security Features

- **Access Control**: Role-based permissions
- **Pausable**: Emergency pause functionality
- **Reentrancy Protection**: Secure against reentrancy attacks
- **Input Validation**: Comprehensive parameter validation
- **Upgradeable**: Contract upgrade mechanisms

## 🌐 Integration

### Frontend Integration

```javascript
// Connect to contracts
const provider = new ethers.providers.Web3Provider(window.ethereum);
const signer = provider.getSigner();

const participantRegistry = new ethers.Contract(
    PARTICIPANT_REGISTRY_ADDRESS,
    PARTICIPANT_REGISTRY_ABI,
    signer
);

// Register participant
await participantRegistry.registerParticipant(profileHash);
```

### Backend Integration

```javascript
// Monitor events
participantRegistry.on("ParticipantRegistered", (wallet, joinDate) => {
    console.log("New participant:", wallet);
});

// Update participant data
await participantRegistry.updateParticipant(
    wallet,
    points,
    co2Offset,
    activity
);
```

## 📈 Analytics & Monitoring

### Key Metrics

- Total participants
- Points distribution
- Tier distribution
- Coupon redemption rates
- Badge acquisition rates

### Event Tracking

Monitor these key events:
- `ParticipantRegistered`
- `PointsEarned`
- `TierUpgraded`
- `BadgeMinted`
- `CouponPurchased`
- `CouponRedeemed`

## 🔄 Roadmap

### Phase 2: Advanced Features
- [ ] Social features and community challenges
- [ ] Advanced gamification mechanics
- [ ] Integration with external carbon offset projects
- [ ] Mobile app development

### Phase 3: Ecosystem Expansion
- [ ] DeFi integration for point staking
- [ ] Cross-chain compatibility
- [ ] Enterprise partnerships
- [ ] Carbon credit marketplace

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 🆘 Support

For support and questions:
- Create an issue on GitHub
- Join our Discord community
- Email: support@greenchain.com

## 🙏 Acknowledgments

- OpenZeppelin for secure contract libraries
- Hardhat for development framework
- Ethereum community for blockchain infrastructure

---

**GreenChain** - Building a sustainable future through blockchain technology 🌱 