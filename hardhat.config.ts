import "@nomiclabs/hardhat-waffle";
import "@nomiclabs/hardhat-ethers";
import "@typechain/hardhat";

import { task } from "hardhat/config";
import type { HardhatUserConfig } from "hardhat/types";
import * as dotenv from "dotenv";

dotenv.config();
const AVALANCHE_MAINNET_URL = process.env.AVALANCHE_MAINNET_URL;

// secrets file is in gitignore and should NEVER EVER EVER be committed to git.
const secrets = require('./secrets');

// npx hardhat run --network hardhat scripts/deploy.js
// npx hardhat run --network mainnet scripts/deploy.js

// This is a sample Hardhat task. To learn how to create your own go to
// https://hardhat.org/guides/create-task.html
task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) {
    console.log(account.address);
  }
});

const snowtraceAPIKey = 'YAJSABKAA973A3Y8T5U94KUJN6YIWA5Z8R'

// private key from your deploying wallet -- NEVER EVER EVER COMMIT TO GIT
const testKey = secrets.privateKey;
const testingAccount = secrets.testingAccount;
// You need to export an object to set up your config
// Go to https://hardhat.org/config/ to learn more

/**
 * @type import('hardhat/config').HardhatUserConfig
 */
const config: HardhatUserConfig = {
  solidity: {
    version: "0.8.7",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },
  // @ts-ignore
  etherscan: {
    apiKey: {
      avalanche: snowtraceAPIKey,
      avalancheFujiTestnet: snowtraceAPIKey
    }
  },
  networks: {
    hardhat: {
      chainId: 43114,
      gasPrice: 225000000000,
      throwOnTransactionFailures: false,
      loggingEnabled: true,
      accounts: [{
        privateKey: `0x${testingAccount}`,
        balance: '100000000000000000000000000'
      }],
      forking: {
        url: AVALANCHE_MAINNET_URL as string,
        enabled: true,
        blockNumber: 11442930,        
      },
    },
    fuji: {
      url: 'https://api.avax-test.network/ext/bc/C/rpc',
      gasPrice: "auto",
      chainId: 43113,
      accounts: [`0x${testKey}`]
    },
    mainnet: {
      url: 'https://api.avax.network/ext/bc/C/rpc',
      gasPrice: "auto",
      chainId: 43114,
      accounts: [`0x${testKey}`]
    }
  }
};

export default config;
