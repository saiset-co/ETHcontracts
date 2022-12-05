const hre = require("hardhat");
require("./env-lib.js")

const { time } = require("@nomicfoundation/hardhat-network-helpers");




async function deploySmarts() {
  const [owner, otherAccount] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", owner.address);
  console.log("Account befor balance:", (await owner.getBalance()).toString());

  const Contract = await StartDeploy("UndeadsStaking");
  const TokenUSD = await StartDeploy("USDTest");
  const TokenSale = await StartDeploy("USDTest");
  const NFT = await StartDeploy("SampleNFT");

  

  console.log("Account after balance:", (await owner.getBalance()).toString());
  return { owner, otherAccount, Contract, TokenUSD, TokenSale, NFT};
}


async function deploySmartTest() {

  const { owner, otherAccount, Contract, TokenUSD, TokenSale, NFT} = await deploySmarts();
  await TokenUSD.Mint(FromSum18(1000));
  await TokenSale.Mint(FromSum18(5000));
  await TokenSale.transfer(Contract.address,FromSum18(5000));

  await NFT.Mint(owner.address);

  //await TokenUSD.connect(otherAccount).Mint(FromSum18(100));
  //await TokenUSD.connect(otherAccount).approve(Contract.address,FromSum18(1000));
  
  console.log("USD: ",ToFloat(await TokenUSD.balanceOf(owner.address)));
  console.log("Sale: ",ToFloat(await TokenSale.balanceOf(Contract.address)));
  
  //await Contract.setCoin(TokenUSD.address,FromSum18(1));


}




module.exports.deploySmarts = deploySmartTest;


