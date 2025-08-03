const { ethers } = require("hardhat");

async function main() {
    console.log("🚀 Deploying GreenChain Participant Record & Tier System...");
    
    // Get deployer account
    const [deployer] = await ethers.getSigners();
    console.log("📝 Deploying contracts with account:", deployer.address);
    console.log("💰 Account balance:", (await deployer.getBalance()).toString());
    
    // Deploy contracts in order
    console.log("\n📦 Deploying TierManager...");
    const TierManager = await ethers.getContractFactory("TierManager");
    const tierManager = await TierManager.deploy(ethers.ZeroAddress, ethers.ZeroAddress);
    await tierManager.waitForDeployment();
    console.log("✅ TierManager deployed to:", await tierManager.getAddress());
    
    console.log("\n📦 Deploying PointsToken...");
    const PointsToken = await ethers.getContractFactory("PointsToken");
    const pointsToken = await PointsToken.deploy(ethers.ZeroAddress, ethers.ZeroAddress);
    await pointsToken.waitForDeployment();
    console.log("✅ PointsToken deployed to:", await pointsToken.getAddress());
    
    console.log("\n📦 Deploying BadgeNFT...");
    const BadgeNFT = await ethers.getContractFactory("BadgeNFT");
    const badgeNFT = await BadgeNFT.deploy(ethers.ZeroAddress, await tierManager.getAddress());
    await badgeNFT.waitForDeployment();
    console.log("✅ BadgeNFT deployed to:", await badgeNFT.getAddress());
    
    console.log("\n📦 Deploying RewardsVault...");
    const RewardsVault = await ethers.getContractFactory("RewardsVault");
    const rewardsVault = await RewardsVault.deploy(ethers.ZeroAddress, ethers.ZeroAddress);
    await rewardsVault.waitForDeployment();
    console.log("✅ RewardsVault deployed to:", await rewardsVault.getAddress());
    
    console.log("\n📦 Deploying CouponExchange...");
    const CouponExchange = await ethers.getContractFactory("CouponExchange");
    const couponExchange = await CouponExchange.deploy(
        await pointsToken.getAddress(),
        ethers.ZeroAddress,
        await tierManager.getAddress(),
        await rewardsVault.getAddress()
    );
    await couponExchange.waitForDeployment();
    console.log("✅ CouponExchange deployed to:", await couponExchange.getAddress());
    
    console.log("\n📦 Deploying ParticipantRegistry...");
    const ParticipantRegistry = await ethers.getContractFactory("ParticipantRegistry");
    const participantRegistry = await ParticipantRegistry.deploy(
        await tierManager.getAddress(),
        await pointsToken.getAddress(),
        await badgeNFT.getAddress()
    );
    await participantRegistry.waitForDeployment();
    console.log("✅ ParticipantRegistry deployed to:", await participantRegistry.getAddress());
    
    // Update contract addresses
    console.log("\n🔗 Updating contract addresses...");
    
    await tierManager.updateContractAddresses(await participantRegistry.getAddress(), await badgeNFT.getAddress());
    console.log("✅ TierManager addresses updated");
    
    await pointsToken.updateContractAddresses(await participantRegistry.getAddress(), await couponExchange.getAddress());
    console.log("✅ PointsToken addresses updated");
    
    await badgeNFT.updateContractAddresses(await participantRegistry.getAddress(), await tierManager.getAddress());
    console.log("✅ BadgeNFT addresses updated");
    
    await rewardsVault.updateContractAddresses(await couponExchange.getAddress(), await participantRegistry.getAddress());
    console.log("✅ RewardsVault addresses updated");
    
    await couponExchange.updateContractAddresses(
        await pointsToken.getAddress(),
        await participantRegistry.getAddress(),
        await tierManager.getAddress(),
        await rewardsVault.getAddress()
    );
    console.log("✅ CouponExchange addresses updated");
    
    // Create sample coupons
    console.log("\n🎫 Creating sample coupons...");
    
    await couponExchange.createCoupon(
        "Starbucks $5 Gift Card",
        "Enjoy a coffee on us! Valid at any Starbucks location.",
        500, // 500 points
        500, // $5.00 value in cents
        "FOOD",
        1000 // Max supply
    );
    console.log("✅ Created Starbucks coupon");
    
    await couponExchange.createCoupon(
        "Amazon $10 Gift Card",
        "Shop sustainably on Amazon with your GreenChain rewards.",
        1000, // 1000 points
        1000, // $10.00 value in cents
        "SHOPPING",
        500 // Max supply
    );
    console.log("✅ Created Amazon coupon");
    
    await couponExchange.createCoupon(
        "Uber $15 Ride Credit",
        "Take a ride with Uber and reduce your carbon footprint.",
        1500, // 1500 points
        1500, // $15.00 value in cents
        "TRAVEL",
        300 // Max supply
    );
    console.log("✅ Created Uber coupon");
    
    // Deposit rewards to vault
    console.log("\n💰 Depositing rewards to vault...");
    
    await rewardsVault.depositReward(1, 5000); // $50 worth of Starbucks coupons
    await rewardsVault.depositReward(2, 5000); // $50 worth of Amazon coupons
    await rewardsVault.depositReward(3, 4500); // $45 worth of Uber coupons
    console.log("✅ Rewards deposited to vault");
    
    console.log("\n🎉 GreenChain system deployment complete!");
    console.log("\n📋 Contract Addresses:");
    console.log("ParticipantRegistry:", await participantRegistry.getAddress());
    console.log("TierManager:", await tierManager.getAddress());
    console.log("PointsToken:", await pointsToken.getAddress());
    console.log("BadgeNFT:", await badgeNFT.getAddress());
    console.log("CouponExchange:", await couponExchange.getAddress());
    console.log("RewardsVault:", await rewardsVault.getAddress());
    
    console.log("\n🔧 Next Steps:");
    console.log("1. Verify contracts on Etherscan");
    console.log("2. Set up frontend integration");
    console.log("3. Configure IPFS for profile data");
    console.log("4. Deploy to testnet for testing");
    console.log("5. Deploy to mainnet for production");
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error("❌ Deployment failed:", error);
        process.exit(1);
    }); 