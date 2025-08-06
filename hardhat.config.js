require("@nomicfoundation/hardhat-toolbox");
require('dotenv').config();
require("@nomicfoundation/hardhat-verify");
require('@openzeppelin/hardhat-upgrades');
require("@nomicfoundation/hardhat-chai-matchers");

const { RPC_URL, AMOY_PRIVATE_KEY, AMOY_API_KEY, ETHERSCAN_API_KEY, PRIVATE_KEY } = process.env;

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.28",
  defaultNetwork: "amoy",
  settings: {
    optimizer: {
      enabled: true,
      runs: 200,
    },
  },
  networks: {
    amoy: {
      url: RPC_URL,
      accounts: [`0x${AMOY_PRIVATE_KEY}`],
      gas: "auto",
      gasPrice: "auto",
    },
    holesky: {
      url: "https://1rpc.io/holesky",
      accounts: [`0x${AMOY_PRIVATE_KEY}`]
    },
    hardhat: {
      chainId: 1337,
      allowUnlimitedContractSize: true,
      throwOnCallFailures: true,
      throwOnTransactionFailures: true,
      loggingEnabled: true,
    },
    bsctestnet: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      accounts: [`0x${PRIVATE_KEY}`]
    },
  },
  etherscan: {
    apiKey:{
      amoy: AMOY_API_KEY,
      holesky: ETHERSCAN_API_KEY,
      bscTestnet: "WESQI593MHJE6UQ9GITJNARFMYAXFJ4CCK"
    },
    customChains: [
      {
        network: "amoy",
        chainId: 80002,
        urls: {
          apiURL: "https://api-amoy.polygonscan.com/api",
          browserURL: "https://amoy.polygonscan.com/"
        }
      }
    ]
  },

  sourcify: {
    // Disabled by default
    // Doesn't need an API key
    enabled: true
  }
};