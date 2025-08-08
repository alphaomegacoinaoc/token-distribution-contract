// require('@nomiclabs/hardhat-ethers');
// require('@nomiclabs/hardhat-etherscan');
require("@nomicfoundation/hardhat-verify");
require("@openzeppelin/hardhat-upgrades");

require('dotenv').config();

const{_RPC_URL_,BSC_RPC_URL_,PRIVATE_KEY,_ETHERSCAN_API_KEY,BSCTESTNET_API_KEY} = process.env;
/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: "0.8.27",
  settings: {
    optimizer: {
      viaIR: true,
      enabled: true,
      runs: 200, 
    },
  },
  debug: {
    revertStrings: "strip", // Disables revert strings
  },
  networks:{
    bscTestnet: {
      url: BSC_RPC_URL_,
      accounts: [`0x${PRIVATE_KEY}`]
      // timeout: 1200000,
      // pollingInterval: 10000,
      // gasPrice: 5000000000
    }
  },
  sourcify:{
    enabled: true,
  },
  etherscan:{
    apiKey: {
      bscTestnet: BSCTESTNET_API_KEY,
    },
    
  },
};
