const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("GreenChain Participant Record & Tier System", function () {
    let participantRegistry, tierManager, pointsToken, badgeNFT, couponExchange, rewardsVault;
    let owner, user1, user2, user3;
    
    beforeEach(async function () {
        [owner, user1, user2, user3] = await ethers.getSigners();
        
        // Deploy contracts
        const TierManager = await ethers.getContractFactory("TierManager");
        tierManager = await TierManager.deploy(ethers.ZeroAddress, ethers.ZeroAddress);
        
        const PointsToken = await ethers.getContractFactory("PointsToken");
        pointsToken = await PointsToken.deploy(ethers.ZeroAddress, ethers.ZeroAddress);
        
        const BadgeNFT = await ethers.getContractFactory("BadgeNFT");
        badgeNFT = await BadgeNFT.deploy(ethers.ZeroAddress, await tierManager.getAddress());
        
        const RewardsVault = await ethers.getContractFactory("RewardsVault");
        rewardsVault = await RewardsVault.deploy(ethers.ZeroAddress, ethers.ZeroAddress);
        
        const CouponExchange = await ethers.getContractFactory("CouponExchange");
        couponExchange = await CouponExchange.deploy(
            await pointsToken.getAddress(),
            ethers.ZeroAddress,
            await tierManager.getAddress(),
            await rewardsVault.getAddress()
        );
        
        const ParticipantRegistry = await ethers.getContractFactory("ParticipantRegistry");
        participantRegistry = await ParticipantRegistry.deploy(
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
    });
    
    describe("Participant Registration", function () {
        it("Should register a new participant", async function () {
            await participantRegistry.connect(user1).registerParticipant("QmProfileHash123");
            
            const participant = await participantRegistry.getParticipant(user1.address);
            expect(participant.wallet).to.equal(user1.address);
            expect(participant.totalPoints).to.equal(100); // Initial registration bonus
            expect(participant.currentTier).to.equal(0); // BRONZE tier
            expect(participant.isActive).to.be.true;
        });
        
        it("Should not allow duplicate registration", async function () {
            await participantRegistry.connect(user1).registerParticipant("QmProfileHash123");
            
            await expect(
                participantRegistry.connect(user1).registerParticipant("QmProfileHash456")
            ).to.be.revertedWith("Already registered");
        });
        
        it("Should mint initial points and badge on registration", async function () {
            await participantRegistry.connect(user1).registerParticipant("QmProfileHash123");
            
            const pointsBalance = await pointsToken.balanceOf(user1.address);
            expect(pointsBalance).to.equal(100);
            
            const userBadges = await badgeNFT.getUserBadges(user1.address);
            expect(userBadges.length).to.equal(1);
        });
    });
    
    describe("Tier System", function () {
        beforeEach(async function () {
            await participantRegistry.connect(user1).registerParticipant("QmProfileHash123");
        });
        
        it("Should start at BRONZE tier", async function () {
            const participant = await participantRegistry.getParticipant(user1.address);
            expect(participant.currentTier).to.equal(0); // BRONZE
        });
        
        it("Should upgrade to SILVER tier at 1000 points", async function () {
            await participantRegistry.connect(owner).updateParticipant(
                user1.address,
                1000,
                100,
                "CO2 offset activity"
            );
            
            const participant = await participantRegistry.getParticipant(user1.address);
            expect(participant.currentTier).to.equal(1); // SILVER
        });
        
        it("Should upgrade to GOLD tier at 5000 points", async function () {
            await participantRegistry.connect(owner).updateParticipant(
                user1.address,
                5000,
                500,
                "CO2 offset activity"
            );
            
            const participant = await participantRegistry.getParticipant(user1.address);
            expect(participant.currentTier).to.equal(2); // GOLD
        });
        
        it("Should upgrade to PLATINUM tier at 20000 points", async function () {
            await participantRegistry.connect(owner).updateParticipant(
                user1.address,
                20000,
                2000,
                "CO2 offset activity"
            );
            
            const participant = await participantRegistry.getParticipant(user1.address);
            expect(participant.currentTier).to.equal(3); // PLATINUM
        });
        
        it("Should apply tier multipliers correctly", async function () {
            // SILVER tier has 1.2x multiplier
            await participantRegistry.connect(owner).updateParticipant(
                user1.address,
                1000,
                100,
                "CO2 offset activity"
            );
            
            // Now earn 100 points with 1.2x multiplier
            await participantRegistry.connect(owner).updateParticipant(
                user1.address,
                100,
                10,
                "Additional activity"
            );
            
            const participant = await participantRegistry.getParticipant(user1.address);
            // 1100 + (100 * 1.2) = 1220 points
            expect(participant.totalPoints).to.equal(1220);
        });
    });
    
    describe("Points System", function () {
        beforeEach(async function () {
            await participantRegistry.connect(user1).registerParticipant("QmProfileHash123");
        });
        
        it("Should earn points for CO2 offset", async function () {
            await participantRegistry.connect(owner).updateParticipant(
                user1.address,
                500,
                50,
                "CO2 offset activity"
            );
            
            const participant = await participantRegistry.getParticipant(user1.address);
            expect(participant.totalPoints).to.equal(600); // 100 initial + 500 earned
        });
        
        it("Should calculate points correctly", async function () {
            const points = await participantRegistry.calculatePoints(10, false); // 10kg CO2, no streak
            expect(points).to.equal(100); // 10 * 10 base points
        });
        
        it("Should apply streak bonus", async function () {
            const points = await participantRegistry.calculatePoints(10, true); // 10kg CO2, with streak
            expect(points).to.equal(105); // 100 + 5% bonus
        });
        
        it("Should award referral bonus", async function () {
            await participantRegistry.connect(user2).registerParticipant("QmProfileHash456");
            
            await participantRegistry.connect(owner).awardReferralBonus(user1.address, user2.address);
            
            const participant = await participantRegistry.getParticipant(user1.address);
            expect(participant.totalPoints).to.equal(150); // 100 initial + 50 referral bonus
        });
    });
    
    describe("Badge System", function () {
        beforeEach(async function () {
            await participantRegistry.connect(user1).registerParticipant("QmProfileHash123");
        });
        
        it("Should mint BRONZE badge on registration", async function () {
            const userBadges = await badgeNFT.getUserBadges(user1.address);
            expect(userBadges.length).to.equal(1);
            
            const badge = await badgeNFT.getBadge(userBadges[0]);
            expect(badge.badgeType).to.equal("BRONZE");
        });
        
        it("Should mint tier badges on upgrade", async function () {
            await participantRegistry.connect(owner).updateParticipant(
                user1.address,
                1000,
                100,
                "CO2 offset activity"
            );
            
            const userBadges = await badgeNFT.getUserBadges(user1.address);
            expect(userBadges.length).to.equal(2); // BRONZE + SILVER
            
            const silverBadge = await badgeNFT.getBadge(userBadges[1]);
            expect(silverBadge.badgeType).to.equal("SILVER");
        });
        
        it("Should allow manual badge minting", async function () {
            await badgeNFT.connect(owner).mintBadge(
                user1.address,
                "SPECIAL",
                "First Week Active",
                "Completed first week of activities",
                "ipfs://QmSpecialBadge"
            );
            
            const userBadges = await badgeNFT.getUserBadges(user1.address);
            expect(userBadges.length).to.equal(2); // BRONZE + SPECIAL
        });
    });
    
    describe("Coupon Exchange", function () {
        beforeEach(async function () {
            await participantRegistry.connect(user1).registerParticipant("QmProfileHash123");
            await participantRegistry.connect(owner).updateParticipant(
                user1.address,
                2000,
                200,
                "CO2 offset activity"
            );
        });
        
        it("Should create coupons", async function () {
            await couponExchange.connect(owner).createCoupon(
                "Test Coupon",
                "Test Description",
                500,
                500,
                "FOOD",
                100
            );
            
            const coupon = await couponExchange.getCoupon(1);
            expect(coupon.name).to.equal("Test Coupon");
            expect(coupon.pointsCost).to.equal(500);
            expect(coupon.value).to.equal(500);
        });
        
        it("Should purchase coupons with points", async function () {
            await couponExchange.connect(owner).createCoupon(
                "Test Coupon",
                "Test Description",
                500,
                500,
                "FOOD",
                100
            );
            
            const tx = await couponExchange.connect(user1).purchaseCoupon(1);
            const receipt = await tx.wait();
            expect(receipt.status).to.equal(1);
            
            const pointsBalance = await pointsToken.balanceOf(user1.address);
            expect(pointsBalance).to.equal(1600); // 2100 - 500 = 1600
        });
        
        it("Should apply tier bonus to coupon value", async function () {
            await couponExchange.connect(owner).createCoupon(
                "Test Coupon",
                "Test Description",
                500,
                1000, // $10.00
                "FOOD",
                100
            );
            
            const [pointsCost, totalValue] = await couponExchange.getCouponWithTierBonus(1, user1.address);
            expect(pointsCost).to.equal(500);
            expect(totalValue).to.equal(1100); // $10.00 + 10% SILVER bonus = $11.00
        });
        
        it("Should redeem coupons", async function () {
            await couponExchange.connect(owner).createCoupon(
                "Test Coupon",
                "Test Description",
                500,
                500,
                "FOOD",
                100
            );
            
            const tx1 = await couponExchange.connect(user1).purchaseCoupon(1);
            const receipt1 = await tx1.wait();
            const userCouponId = 1; // First user coupon ID
            const tx2 = await couponExchange.connect(user1).redeemCoupon(userCouponId);
            const receipt2 = await tx2.wait();
            expect(receipt2.status).to.equal(1);
        });
    });
    
    describe("Rewards Vault", function () {
        it("Should deposit and track rewards", async function () {
            await rewardsVault.connect(owner).depositReward(1, 1000);
            
            const balance = await rewardsVault.getRewardBalance(1);
            expect(balance).to.equal(1000);
            
            const totalRewards = await rewardsVault.getTotalRewards();
            expect(totalRewards).to.equal(1000);
        });
        
        it("Should withdraw rewards", async function () {
            await rewardsVault.connect(owner).depositReward(1, 1000);
            await rewardsVault.connect(owner).withdrawReward(1, 500);
            
            const balance = await rewardsVault.getRewardBalance(1);
            expect(balance).to.equal(500);
        });
        
        it("Should check inventory sufficiency", async function () {
            await rewardsVault.connect(owner).depositReward(1, 1000);
            
            const hasInventory = await rewardsVault.hasSufficientInventory(1, 500);
            expect(hasInventory).to.be.true;
            
            const insufficientInventory = await rewardsVault.hasSufficientInventory(1, 1500);
            expect(insufficientInventory).to.be.false;
        });
    });
    
    describe("Access Control", function () {
        it("Should only allow authorized contracts to update participants", async function () {
            await participantRegistry.connect(user1).registerParticipant("QmProfileHash123");
            
            await expect(
                participantRegistry.connect(user2).updateParticipant(
                    user1.address,
                    100,
                    10,
                    "Unauthorized activity"
                )
            ).to.be.revertedWith("Not authorized");
        });
        
        it("Should only allow authorized contracts to mint points", async function () {
            await expect(
                pointsToken.connect(user1).mint(user1.address, 100, "Unauthorized mint")
            ).to.be.revertedWith("Not authorized");
        });
        
        it("Should only allow authorized contracts to mint badges", async function () {
            await expect(
                badgeNFT.connect(user1).mintBadge(
                    user1.address,
                    "SPECIAL",
                    "Test Badge",
                    "Test Description",
                    "ipfs://QmTest"
                )
            ).to.be.revertedWith("Not authorized");
        });
    });
    
    describe("Pausable Functionality", function () {
        beforeEach(async function () {
            await participantRegistry.connect(user1).registerParticipant("QmProfileHash123");
        });
        
        it("Should pause and unpause contracts", async function () {
            await participantRegistry.connect(owner).pause();
            
            await expect(
                participantRegistry.connect(user2).registerParticipant("QmProfileHash456")
            ).to.be.revertedWithCustomError(participantRegistry, "EnforcedPause");
            
            await participantRegistry.connect(owner).unpause();
            
            await participantRegistry.connect(user2).registerParticipant("QmProfileHash456");
            expect(await participantRegistry.isRegistered(user2.address)).to.be.true;
        });
    });

    describe("Enhanced Participant Functions", function () {
        beforeEach(async function () {
            await participantRegistry.connect(user1).registerParticipant("QmProfileHash123");
        });
        
        it("Should get tier level correctly", async function () {
            const tierLevel = await participantRegistry.getTierLevel(user1.address);
            expect(tierLevel).to.equal(0); // BRONZE
            
            await participantRegistry.connect(owner).updateParticipant(
                user1.address,
                1000,
                100,
                "CO2 offset activity"
            );
            
            const newTierLevel = await participantRegistry.getTierLevel(user1.address);
            expect(newTierLevel).to.equal(1); // SILVER
        });
        
        it("Should get comprehensive participant stats", async function () {
            const stats = await participantRegistry.getParticipantStats(user1.address);
            expect(stats.totalPoints).to.equal(100);
            expect(stats.currentTier).to.equal(0);
            expect(stats.joinDate).to.be.gt(0);
            expect(stats.lastActivityDate).to.be.gt(0);
            expect(stats.daysActive).to.be.gte(0);
            expect(stats.averagePointsPerDay).to.be.gte(0);
        });
        
        it("Should record offset activity correctly", async function () {
            await participantRegistry.connect(owner).recordOffsetActivity(
                user1.address,
                10, // 10kg CO2
                "TRANSPORT",
                "Used public transportation instead of car",
                false // no streak
            );
            
            const participant = await participantRegistry.getParticipant(user1.address);
            expect(participant.totalPoints).to.equal(200); // 100 initial + 100 from activity
        });
        
        it("Should apply streak bonus to offset activity", async function () {
            await participantRegistry.connect(owner).recordOffsetActivity(
                user1.address,
                10, // 10kg CO2
                "ENERGY",
                "Switched to renewable energy",
                true // with streak
            );
            
            const participant = await participantRegistry.getParticipant(user1.address);
            expect(participant.totalPoints).to.equal(205); // 100 initial + 105 from activity (with 5% bonus)
        });
    });
    
    describe("Enhanced Tier Manager Functions", function () {
        it("Should check tier upgrade eligibility", async function () {
            const [eligible, nextTier, pointsNeeded] = await tierManager.checkTierUpgrade(500, 0); // BRONZE with 500 points
            expect(eligible).to.be.false;
            expect(nextTier).to.equal(0); // Still BRONZE
            expect(pointsNeeded).to.equal(1000); // Need 1000 for SILVER
            
            const [eligible2, nextTier2, pointsNeeded2] = await tierManager.checkTierUpgrade(1500, 0); // BRONZE with 1500 points
            expect(eligible2).to.be.true;
            expect(nextTier2).to.equal(1); // SILVER
            expect(pointsNeeded2).to.equal(0); // Already eligible
        });
        
        it("Should upgrade tier correctly", async function () {
            await tierManager.connect(owner).upgradeTier(user1.address, 1); // Upgrade to SILVER
            // This would emit an event, which we can verify
        });
    });
    
    describe("Enhanced Points Token Functions", function () {
        beforeEach(async function () {
            await participantRegistry.connect(user1).registerParticipant("QmProfileHash123");
        });
        
        it("Should get balance using getBalance function", async function () {
            const balance = await pointsToken.getBalance(user1.address);
            expect(balance).to.equal(100);
        });
    });
    
    describe("Enhanced Badge NFT Functions", function () {
        beforeEach(async function () {
            await participantRegistry.connect(user1).registerParticipant("QmProfileHash123");
        });
        
        it("Should get badge metadata correctly", async function () {
            const userBadges = await badgeNFT.getUserBadges(user1.address);
            const badgeMetadata = await badgeNFT.getBadgeMetadata(userBadges[0]);
            expect(badgeMetadata.badgeType).to.equal("BRONZE");
            expect(badgeMetadata.name).to.equal("GreenChain Bronze Member");
        });
    });
    
    describe("Enhanced Coupon Exchange Functions", function () {
        beforeEach(async function () {
            await participantRegistry.connect(user1).registerParticipant("QmProfileHash123");
            await participantRegistry.connect(owner).updateParticipant(
                user1.address,
                2000,
                200,
                "CO2 offset activity"
            );
        });
        
        it("Should update exchange rates", async function () {
            await couponExchange.connect(owner).createCoupon(
                "Test Coupon",
                "Test Description",
                500,
                500,
                "FOOD",
                100
            );
            
            await couponExchange.connect(owner).updateExchangeRates(1, 600, 600);
            
            const coupon = await couponExchange.getCoupon(1);
            expect(coupon.pointsCost).to.equal(600);
            expect(coupon.value).to.equal(600);
        });
        
        it("Should validate redemption correctly", async function () {
            await couponExchange.connect(owner).createCoupon(
                "Test Coupon",
                "Test Description",
                500,
                500,
                "FOOD",
                100
            );
            
            await couponExchange.connect(user1).purchaseCoupon(1);
            const tx = await couponExchange.connect(user1).redeemCoupon(1);
            const receipt = await tx.wait();
            
            // Get the redemption code from the event
            const event = receipt.logs.find(log => {
                try {
                    const parsed = couponExchange.interface.parseLog(log);
                    return parsed.name === "CouponRedeemed";
                } catch {
                    return false;
                }
            });
            
            const redemptionCode = event ? couponExchange.interface.parseLog(event).args.redemptionCode : "GC-1-1234567890";
            
            const [valid, couponInfo] = await couponExchange.validateRedemption(1, redemptionCode);
            expect(valid).to.be.true;
            expect(couponInfo.name).to.equal("Test Coupon");
        });
        
        it("Should reject invalid redemption codes", async function () {
            await couponExchange.connect(owner).createCoupon(
                "Test Coupon",
                "Test Description",
                500,
                500,
                "FOOD",
                100
            );
            
            await couponExchange.connect(user1).purchaseCoupon(1);
            await couponExchange.connect(user1).redeemCoupon(1);
            
            const [valid, couponInfo] = await couponExchange.validateRedemption(1, "INVALID_CODE");
            expect(valid).to.be.false;
        });
    });
    
    describe("Enhanced Rewards Vault Functions", function () {
        it("Should manage inventory correctly", async function () {
            // Add inventory
            const tx1 = await rewardsVault.connect(owner).manageInventory(1, 0, 1000);
            const receipt1 = await tx1.wait();
            expect(receipt1.status).to.equal(1);
            
            // Check balance after adding
            const balance1 = await rewardsVault.getRewardBalance(1);
            expect(balance1).to.equal(1000);
            
            // Remove inventory
            const tx2 = await rewardsVault.connect(owner).manageInventory(1, 1, 300);
            const receipt2 = await tx2.wait();
            expect(receipt2.status).to.equal(1);
            
            // Check balance after removing
            const balance2 = await rewardsVault.getRewardBalance(1);
            expect(balance2).to.equal(700);
        });
        
        it("Should fail to remove more inventory than available", async function () {
            await rewardsVault.connect(owner).manageInventory(1, 0, 1000);
            
            await expect(
                rewardsVault.connect(owner).manageInventory(1, 1, 1500)
            ).to.be.revertedWith("Insufficient inventory");
        });
    });
}); 