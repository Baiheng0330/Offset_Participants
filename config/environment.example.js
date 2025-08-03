// GreenChain Environment Configuration Example
// Copy this file to config/environment.js and fill in your values

module.exports = {
    // Network Configuration
    networks: {
        sepolia: {
            url: "https://sepolia.infura.io/v3/YOUR_INFURA_PROJECT_ID",
            chainId: 11155111
        },
        mainnet: {
            url: "https://mainnet.infura.io/v3/YOUR_INFURA_PROJECT_ID",
            chainId: 1
        },
        polygon: {
            url: "https://polygon-rpc.com",
            chainId: 137
        }
    },

    // Deployment Configuration
    deployer: {
        privateKey: "your_private_key_here_without_0x_prefix",
        address: "your_deployer_address_here"
    },

    // API Keys
    apiKeys: {
        etherscan: "your_etherscan_api_key_here",
        polygonscan: "your_polygonscan_api_key_here",
        alchemy: "your_alchemy_api_key"
    },

    // IPFS Configuration
    ipfs: {
        projectId: "your_ipfs_project_id",
        projectSecret: "your_ipfs_project_secret",
        gateway: "https://gateway.pinata.cloud/ipfs/"
    },

    // Database Configuration (for off-chain data)
    database: {
        url: "your_database_connection_string",
        redis: "your_redis_connection_string"
    },

    // External Service Configuration
    externalServices: {
        carbonOffsetApi: "your_carbon_offset_api_key",
        weatherApi: "your_weather_api_key"
    },

    // Gas Configuration
    gas: {
        limit: 5000000,
        price: 20000000000
    },

    // Contract Configuration
    contract: {
        initialPointsPerKgCO2: 10,
        streakBonusMultiplier: 5,
        referralBonus: 50,
        initialRegistrationBonus: 100
    },

    // Tier Configuration
    tiers: {
        bronze: {
            maxPoints: 999,
            multiplier: 100, // 1.0x
            couponBonus: 0
        },
        silver: {
            minPoints: 1000,
            maxPoints: 4999,
            multiplier: 120, // 1.2x
            couponBonus: 10
        },
        gold: {
            minPoints: 5000,
            maxPoints: 19999,
            multiplier: 150, // 1.5x
            couponBonus: 20
        },
        platinum: {
            minPoints: 20000,
            maxPoints: 999999999,
            multiplier: 200, // 2.0x
            couponBonus: 30
        }
    },

    // Coupon Configuration
    coupons: {
        categories: ["FOOD", "SHOPPING", "TRAVEL", "ENTERTAINMENT", "EDUCATION"],
        maxSupply: 10000
    },

    // Security Configuration
    security: {
        ownerAddress: "your_owner_address_here",
        adminAddress: "your_admin_address_here",
        emergencyPauseAddress: "your_emergency_pause_address_here"
    },

    // Monitoring Configuration
    monitoring: {
        sentryDsn: "your_sentry_dsn",
        logLevel: "info"
    },

    // Frontend Configuration
    frontend: {
        contractAddresses: {
            participantRegistry: "",
            tierManager: "",
            pointsToken: "",
            badgeNFT: "",
            couponExchange: "",
            rewardsVault: ""
        },
        networkId: 1,
        chainId: 1
    },

    // Testing Configuration
    testing: {
        privateKey: "your_test_private_key_here",
        networkUrl: "http://localhost:8545"
    }
}; 