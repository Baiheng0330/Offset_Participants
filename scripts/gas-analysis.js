const { ethers } = require("hardhat");

async function main() {
    console.log("🔍 Starting Gas Analysis for GreenChain Contracts...");
    
    // Get deployer account
    const [deployer] = await ethers.getSigners();
    
    // Deploy contracts
    console.log("\n📦 Deploying contracts for gas analysis...");
    
    const TierManager = await ethers.getContractFactory("TierManager");
    const tierManager = await TierManager.deploy(ethers.ZeroAddress, ethers.ZeroAddress);
    
    const PointsToken = await ethers.getContractFactory("PointsToken");
    const pointsToken = await PointsToken.deploy(ethers.ZeroAddress, ethers.ZeroAddress);
    
    const BadgeNFT = await ethers.getContractFactory("BadgeNFT");
    const badgeNFT = await BadgeNFT.deploy(ethers.ZeroAddress, await tierManager.getAddress());
    
    const RewardsVault = await ethers.getContractFactory("RewardsVault");
    const rewardsVault = await RewardsVault.deploy(ethers.ZeroAddress, ethers.ZeroAddress);
    
    const CouponExchange = await ethers.getContractFactory("CouponExchange");
    const couponExchange = await CouponExchange.deploy(
        await pointsToken.getAddress(),
        ethers.ZeroAddress,
        await tierManager.getAddress(),
        await rewardsVault.getAddress()
    );
    
    const ParticipantRegistry = await ethers.getContractFactory("ParticipantRegistry");
    const participantRegistry = await ParticipantRegistry.deploy(
        await tierManager.getAddress(),
        await pointsToken.getAddress(),
        await badgeNFT.getAddress()
    );
    
    // Update contract addresses
    await tierManager.updateContractAddresses(await participantRegistry.getAddress(), await badgeNFT.getAddress());
    await pointsToken.updateContractAddresses(await participantRegistry.getAddress(), await couponExchange.getAddress());
    await badgeNFT.updateContractAddresses(await participantRegistry.getAddress(), await tierManager.getAddress());
    await rewardsVault.updateContractAddresses(await couponExchange.getAddress(), await participantRegistry.getAddress());
    await couponExchange.updateContractAddresses(
        await pointsToken.getAddress(),
        await participantRegistry.getAddress(),
        await tierManager.getAddress(),
        await rewardsVault.getAddress()
    );
    
    console.log("\n📊 Gas Analysis Results:");
    console.log("=========================");
    
    // Test ParticipantRegistry functions
    console.log("\n🏛️  ParticipantRegistry Gas Usage:");
    
    const tx1 = await participantRegistry.connect(deployer).registerParticipant("QmProfileHash123");
    const receipt1 = await tx1.wait();
    console.log(`  registerParticipant(): ${receipt1.gasUsed.toString()} gas`);
    
    const tx2 = await participantRegistry.connect(deployer).updateParticipant(
        deployer.address,
        1000,
        100,
        "CO2 offset activity"
    );
    const receipt2 = await tx2.wait();
    console.log(`  updateParticipant(): ${receipt2.gasUsed.toString()} gas`);
    
    const tx3 = await participantRegistry.connect(deployer).recordOffsetActivity(
        deployer.address,
        10,
        "TRANSPORT",
        "Used public transportation",
        false
    );
    const receipt3 = await tx3.wait();
    console.log(`  recordOffsetActivity(): ${receipt3.gasUsed.toString()} gas`);
    
    // Test TierManager functions
    console.log("\n🏆 TierManager Gas Usage:");
    
    const tx4 = await tierManager.connect(deployer).checkTierUpgrade(1500, 0);
    const receipt4 = await tx4.wait();
    console.log(`  checkTierUpgrade(): ${receipt4.gasUsed.toString()} gas`);
    
    const tx5 = await tierManager.connect(deployer).upgradeTier(deployer.address, 1);
    const receipt5 = await tx5.wait();
    console.log(`  upgradeTier(): ${receipt5.gasUsed.toString()} gas`);
    
    // Test PointsToken functions
    console.log("\n💰 PointsToken Gas Usage:");
    
    const tx6 = await pointsToken.connect(deployer).mint(deployer.address, 500, "Test mint");
    const receipt6 = await tx6.wait();
    console.log(`  mint(): ${receipt6.gasUsed.toString()} gas`);
    
    const tx7 = await pointsToken.connect(deployer).burn(deployer.address, 100, "Test burn");
    const receipt7 = await tx7.wait();
    console.log(`  burn(): ${receipt7.gasUsed.toString()} gas`);
    
    // Test BadgeNFT functions
    console.log("\n🏅 BadgeNFT Gas Usage:");
    
    const tx8 = await badgeNFT.connect(deployer).mintBadge(
        deployer.address,
        "SPECIAL",
        "Test Badge",
        "Test Description",
        "ipfs://QmTest"
    );
    const receipt8 = await tx8.wait();
    console.log(`  mintBadge(): ${receipt8.gasUsed.toString()} gas`);
    
    // Test CouponExchange functions
    console.log("\n🎫 CouponExchange Gas Usage:");
    
    const tx9 = await couponExchange.connect(deployer).createCoupon(
        "Test Coupon",
        "Test Description",
        500,
        500,
        "FOOD",
        100
    );
    const receipt9 = await tx9.wait();
    console.log(`  createCoupon(): ${receipt9.gasUsed.toString()} gas`);
    
    const tx10 = await couponExchange.connect(deployer).purchaseCoupon(1);
    const receipt10 = await tx10.wait();
    console.log(`  purchaseCoupon(): ${receipt10.gasUsed.toString()} gas`);
    
    const tx11 = await couponExchange.connect(deployer).updateExchangeRates(1, 600, 600);
    const receipt11 = await tx11.wait();
    console.log(`  updateExchangeRates(): ${receipt11.gasUsed.toString()} gas`);
    
    // Test RewardsVault functions
    console.log("\n🏦 RewardsVault Gas Usage:");
    
    const tx12 = await rewardsVault.connect(deployer).depositReward(1, 1000);
    const receipt12 = await tx12.wait();
    console.log(`  depositReward(): ${receipt12.gasUsed.toString()} gas`);
    
    const tx13 = await rewardsVault.connect(deployer).manageInventory(1, 0, 500);
    const receipt13 = await tx13.wait();
    console.log(`  manageInventory(): ${receipt13.gasUsed.toString()} gas`);
    
    console.log("\n📈 Gas Optimization Recommendations:");
    console.log("=====================================");
    console.log("1. Consider using uint128 instead of uint256 for smaller values");
    console.log("2. Pack structs efficiently to reduce storage costs");
    console.log("3. Use events instead of storage for historical data");
    console.log("4. Batch operations where possible to reduce transaction overhead");
    console.log("5. Consider using libraries for complex calculations");
    console.log("6. Use unchecked blocks for arithmetic that cannot overflow");
    console.log("7. Minimize external calls in loops");
    console.log("8. Use storage pointers to avoid multiple SLOAD operations");
    
    console.log("\n✅ Gas analysis complete!");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Gas analysis failed:", error);
        process.exit(1);
    }); 