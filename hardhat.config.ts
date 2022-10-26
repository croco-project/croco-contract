import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-gas-reporter";
import "@nomiclabs/hardhat-etherscan";
import dotenv from "dotenv";

dotenv.config();

const config: HardhatUserConfig = {
    solidity: {
        version: "0.8.9",
        settings: {
            optimizer: {
                enabled: true,
                runs: 200
            }
        }
    },
    networks: {
        hardhat: {},
        'bsc-testnet': {
            url: process.env.BSC_TESTNET_API_KEY,
            accounts: [process.env.BSC_TESTNET_PRIVATE_KEY!]
        },
        mumbai: {
            url: process.env.MUMBAI_API_KEY,
            accounts: [process.env.GROELI_PRIVATE_KEY!]
        },
        goerli: {
            url: process.env.GROELI_API_KEY,
            accounts: [process.env.GROELI_PRIVATE_KEY!]
        },
        'optimism-goerli': {
            url: "https://goerli.optimism.io",
            accounts: [process.env.OPTIMISMGROELI_PRIVATE_KEY!]
        },
    },
    gasReporter: {
        currency: 'USD',
        gasPrice: 30,
        enabled: true
    },
    etherscan: {
        apiKey: process.env.BSCSCAN_API_KEY!
    }
};

export default config;
