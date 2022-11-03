require("@nomicfoundation/hardhat-toolbox");


require("@nomiclabs/hardhat-ethers");

//require("hardhat-gas-reporter");


// task action function receives the Hardhat Runtime Environment as second argument
task(
  "blockNumber",
  "Prints the current block number",
  async (_, { ethers }) => {
    await ethers.provider.getBlockNumber().then((blockNumber) => {
      console.log("Current block number: " + blockNumber);
    });
  }
);

async function LogBalance(address)
{
  console.log(address,hre.ethers.utils.formatEther(await hre.ethers.provider.getBalance(address)));
}

task("accounts", "Prints the list of accounts", async (taskArgs, hre) => {
  const accounts = await hre.ethers.getSigners();

  for (const account of accounts) 
  {
    LogBalance(account.address);
  }
    await LogBalance("0x9e5c9e00212799f620093316Abd37Df7B4b03376");
  

  
    await ethers.provider.getBlockNumber().then((blockNumber) => {
      console.log("Current block number: " + blockNumber);
    });
  

});



const {PivateKeyArr} = require("../../keys/test1.js");

/** @type import('hardhat/config').HardhatUserConfig */
module.exports = {
  solidity: {
    version: "0.8.7",
    settings: {
      optimizer: {
        enabled: true,
        runs: 200
      }
    }
  },

  defaultNetwork: "localhost",
  //defaultNetwork: "mumbai",
  networks: {
    localhost: {
      url: "http://127.0.0.1:8545",
      gasPrice: 20000000000,
      accountsBalance: "30000000000000000000000",
      hardfork2: "merge",
      coinbase: "0x6103b3AF382A728c8107f3C2dB2D78672ed8978e",
    },
    hardhat: {
      gasPrice: 20000000000,
      mnemonic: "test test test test test test test test test test test junk",
      accountsBalance: "20000000000000000000000",
      hardfork2: "merge",
      coinbase: "0x9e5c9e00212799f620093316Abd37Df7B4b03376",
      loggingEnabled: true,
    },
    mumbai: {
      url: "https://rpc-mumbai.maticvigil.com",
      chainId: 80001,
      gasPrice: 2600000000,
      accounts: PivateKeyArr//{ mnemonic: "write invite clog length trash hip vault eagle bundle glare immense amount" }
    },

    testnetb: {
      url: "https://data-seed-prebsc-1-s1.binance.org:8545",
      chainId: 97,
      gasPrice: 20000000000,
      accounts: PivateKeyArr,
    },
    mainnetb: {
      url: "https://bsc-dataseed.binance.org/",
      chainId: 56,
      gasPrice: 20000000000,
      accounts: PivateKeyArr,
    }
  },

  mocha: {
    timeout: 20000,
    reporter: 'eth-gas-reporter',
  },
  gasReporter: {
    enabled: true,
    //currency: 'CHF',
    //gasPrice: 21
  }  

};
