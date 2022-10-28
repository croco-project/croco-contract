import { HardhatUserConfig } from "hardhat/config";
import "@nomicfoundation/hardhat-toolbox";
import "hardhat-gas-reporter";
import "@nomiclabs/hardhat-etherscan";
import dotenv from "dotenv";

dotenv.config();

const ZeroPK = "0x0000000000000000000000000000000000000000000000000000000000000000";

const accounts = [
    process.env.ACC1_PRIVATE_KEY || ZeroPK,
    process.env.ACC2_PRIVATE_KEY || ZeroPK
];

const bscTestnetUrl = process.env.BSC_TESTNET_API_KEY || '';
const mumbaiUrl = process.env.MUMBAI_API_KEY || '';
const goerliUrl = process.env.BSC_TESTNET_API_KEY || '';


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
            url: bscTestnetUrl,
            accounts
        },
        mumbai: {
            url: mumbaiUrl,
            accounts
        },
        goerli: {
            url: goerliUrl,
            accounts
        },
        'optimism-goerli': {
            url: "https://goerli.optimism.io",
            accounts
        },
    },
    gasReporter: {
        currency: 'USD',
        token: 'BNB',
        coinmarketcap: '7c509189-8d56-4d3b-9381-4a24b2609ed2',
        gasPrice: 7,
        enabled: true
    },
    etherscan: {
        apiKey: process.env.BSCSCAN_API_KEY!
    }
};

export default config;
