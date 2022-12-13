const hre = require("hardhat");
require("./env-lib.js")

const { time } = require("@nomicfoundation/hardhat-network-helpers");




async function deploySmarts() {
  const [owner, otherAccount] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", owner.address);
  console.log("Account befor balance:", (await owner.getBalance()).toString());

  const TokenUDS = await StartDeploy("USDTest");
  const TokenUGOLD = await StartDeploy("USDTest");
  const TokenSale = await StartDeploy("USDTest");
  const NFT = await StartDeploy("SampleNFT");
  const AMM = await StartDeploy("AMMTest");

  const StakingUDS = await StartDeploy("UndeadsStakingUDS",TokenUDS.address,TokenUGOLD.address,NFT.address,AMM.address);

  

  console.log("Account after balance:", (await owner.getBalance()).toString());
  return { owner, otherAccount, StakingUDS, TokenUDS, TokenUGOLD, NFT, AMM};
}


async function deploySmartTest() {

  const { owner, otherAccount, StakingUDS, TokenUDS, TokenUGOLD, NFT, AMM} = await deploySmarts();
  await TokenUDS.Mint(FromSum18(51*1e6));
  await TokenUDS.transfer(StakingUDS.address,FromSum18(50*1e6));
  await TokenUGOLD.Mint(FromSum18(1e6));
  await NFT.Mint(owner.address);

  await TokenUDS.connect(otherAccount).Mint(FromSum18(1e6));  

  await TokenUDS.approve(StakingUDS.address,FromSum18(1e6));
  await TokenUDS.connect(otherAccount).approve(StakingUDS.address,FromSum18(1e6));

  
  console.log("TokenUDS: ",ToFloat(await TokenUDS.balanceOf(owner.address)));

  var Start=(await time.latest())>>>0;
  console.log("--------------------Start:",Start);
  var Period=24*3600;
  var PeriodCount=100;
  Start=Start+10;
  await (await StakingUDS.setup(FromSum18(50*1e6), Start, Period,15,PeriodCount,2,1e9/10)).wait();

  await time.increaseTo(Start);

  console.log("--------------------stake");
  await (await StakingUDS.stake(FromSum18(100), 30, 0)).wait();
  //await (await StakingUDS.connect(otherAccount).stake(FromSum18(100), 60, 0)).wait();

  console.log("allReward: ",ToFloat(await StakingUDS.allReward()),"/",ToFloat(await StakingUDS.poolStake()));

  //console.log("List: ",ToString(await StakingUDS.listSessions(owner.address,0,10)));
  await time.increaseTo(Start+16);
  console.log("List: ",ToString(await StakingUDS.listSessions(owner.address,0,10)));
  
  await time.increaseTo(Start+1*Period);
  console.log("List: ",ToString(await StakingUDS.listSessions(owner.address,0,10)));
  //333333329999999999999999
  //21428562728571593999999999
 


}




module.exports.deploySmarts = deploySmartTest;


