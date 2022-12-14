const hre = require("hardhat");
require("./env-lib.js")

const { time } = require("@nomicfoundation/hardhat-network-helpers");




async function deploySmarts() {


  const [owner, otherAccount] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", owner.address);
  console.log("Account befor balance:", ToFloat(await owner.getBalance()));

  const TokenUDS = await StartDeploy("UDSTest");
  const TokenUGOLD = await StartDeploy("UGOLDTest");
  const NFT = await StartDeploy("NFTTest");
  const AMM = await StartDeploy("AMMTest");

  const StakingUDS = await StartDeploy("UndeadsStakingUDS",TokenUDS.address,TokenUGOLD.address,NFT.address,AMM.address);
  const StakingUGOLD = await StartDeploy("UndeadsStakingUGOLD",TokenUDS.address,TokenUGOLD.address,NFT.address,AMM.address);

  

  console.log("Account after balance:", ToFloat(await owner.getBalance()));
  return { owner, otherAccount, StakingUDS, StakingUGOLD, TokenUDS, TokenUGOLD, NFT, AMM};
}


async function deploySmartTest() {
  const { owner, otherAccount, StakingUDS, StakingUGOLD, TokenUDS, TokenUGOLD, NFT, AMM} = await deploySmarts();

  await Test1(owner, otherAccount, StakingUDS, TokenUDS, TokenUGOLD, NFT, AMM);
  //await Test2(owner, otherAccount, StakingUGOLD, TokenUGOLD);

}





async function Test1(owner, otherAccount, Staking, TokenUDS, TokenUGOLD, NFT, AMM) 
{
  console.log("--------------------Mint");
  await (await TokenUDS.Mint(FromSum18(51e6))).wait();
  await (await TokenUDS.transfer(Staking.address,FromSum18(50e6))).wait();
  await (await TokenUGOLD.Mint(FromSum18(50e6))).wait();
  await (await TokenUGOLD.transfer(AMM.address,FromSum18(50e6))).wait();
  await (await NFT.Mint(owner.address)).wait();
  await (await NFT.approve(Staking.address,1)).wait();
  await (await TokenUDS.approve(Staking.address,FromSum18(1e6))).wait();

  console.log("--------------------");
  return;

  

  await (await NFT.Mint(otherAccount.address)).wait();
  await (await TokenUDS.connect(otherAccount).Mint(FromSum18(1e6))).wait();
  await (await TokenUDS.connect(otherAccount).approve(Staking.address,FromSum18(1e6))).wait();
  await (await NFT.connect(otherAccount).approve(Staking.address,2)).wait();

  
  console.log("TokenUDS: ",ToFloat(await TokenUDS.balanceOf(owner.address)));

  var Start=(await time.latest())>>>0;
  console.log("--------------------Start:",Start);
  Start=Start+10;

  var Period=24*3600;
  //var PeriodCount=730;
  //await (await Staking.setup(FromSum18(50*1e6), Start, Period,15,PeriodCount,60,(8*1e9/100/60)>>>0)).wait();
  var PeriodCount=1440;
  await (await Staking.setup(FromSum18(50*1e6), Start, Period,15,PeriodCount,60,(8*1e9/100/60)>>>0)).wait();
  

  await time.increaseTo(Start);

  console.log("--------------------stake");
  await (await Staking.stake(FromSum18(100), 60, 0)).wait();
  console.log("poolStake1:",ToFloat(await Staking.poolStake()));
  await (await Staking.stake(FromSum18(100), 730, 0)).wait();
  console.log("poolStake2:",ToFloat(await Staking.poolStake()));
  await (await Staking.connect(otherAccount).stake(FromSum18(0.000001), 60, 2)).wait();

  console.log("allReward: ",ToFloat(await Staking.allReward()),"/",ToFloat(await Staking.poolStake()));
 
  //console.log("List: ",ToString(await Staking.listSessions(owner.address,0,10)));
  //await time.increaseTo(Start+16);
  //console.log("List: ",ToString(await Staking.listSessions(owner.address,0,10)));
  
  await time.increaseTo(Start+60*Period);
  var List=await Staking.listSessions(owner.address,0,10);
  console.log("Stakes:  ",ToFloat(List[0].info.Stake),",",ToFloat(List[1].info.Stake));
  console.log("Rewards: ",ToFloat(List[0].reward),",",ToFloat(List[1].reward));
  
 
  
 
  //console.log("--------------------reward 1");
  await (await Staking.reward(1)).wait();
  //console.log("1 TokenUDS: ",ToFloat(await TokenUDS.balanceOf(owner.address)));

  await time.increaseTo(Start+PeriodCount*Period);
  console.log("--------------------unstake 1");
  await (await Staking.unstake(1)).wait();
  await (await Staking.unstake(2)).wait();
  console.log("TokenUDS: ",ToFloat(await TokenUDS.balanceOf(owner.address)));
  console.log("   UGOLD: ",ToFloat(await TokenUGOLD.balanceOf(owner.address)));
  

  


  //console.log("--------------------reward 2");
  await (await Staking.connect(otherAccount).reward(1)).wait();
  //console.log("1 TokenUDS: ",ToFloat(await TokenUDS.balanceOf(otherAccount.address)));

  //await time.increaseTo(Start+30*Period);
  console.log("--------------------unstake 2");
  await (await Staking.connect(otherAccount).unstake(1)).wait();
  console.log("TokenUDS: ",ToFloat(await TokenUDS.balanceOf(otherAccount.address)));
  console.log("   UGOLD: ",ToFloat(await TokenUGOLD.balanceOf(otherAccount.address)));

  //console.log("allReward: ",ToFloat(await Staking.allReward()),"/",ToFloat(await Staking.poolStake()));

}


async function Test2(owner, otherAccount, Staking, TokenUGOLD) 
{
  await TokenUGOLD.Mint(FromSum18(1e6));
  await TokenUGOLD.approve(Staking.address,FromSum18(1e6));

  await TokenUGOLD.connect(otherAccount).Mint(FromSum18(1e6));
  await TokenUGOLD.connect(otherAccount).approve(Staking.address,FromSum18(1e6));

  console.log("TokenUGOLD: ",ToFloat(await TokenUGOLD.balanceOf(owner.address)));

  var Start=(await time.latest())>>>0;
  console.log("--------------------Start:",Start);
  Start=Start+10;
  var Period=24*3600;
  //var PeriodCount=60;
  //await (await Staking.setup(FromSum18(3e6), Start, Period,15,PeriodCount,2,1e9/10)).wait();
  var PeriodCount=1440;
  await (await Staking.setup(FromSum18(3e6), Start, Period,15,PeriodCount,0,0)).wait();

  await time.increaseTo(Start);

  console.log("--------------------stake");
  await (await Staking.stake(FromSum18(100), 60)).wait();
  await (await Staking.connect(otherAccount).stake(FromSum18(100), 60)).wait();

  console.log("allReward: ",ToFloat(await Staking.allReward()),"/",ToFloat(await Staking.poolStake()));

  await time.increaseTo(Start+PeriodCount*Period);
  //console.log("List: ",ToString(await Staking.listSessions(owner.address,0,10)));

  console.log("   UGOLD: ",ToFloat(await TokenUGOLD.balanceOf(owner.address)));
  console.log("--------------------unstake");
  await (await Staking.unstake(1)).wait();
  console.log("   UGOLD: ",ToFloat(await TokenUGOLD.balanceOf(owner.address)));
  console.log("   Wallet:",ToFloat(await Staking.balanceOf(owner.address)));

}

module.exports.deploySmarts = deploySmartTest;


