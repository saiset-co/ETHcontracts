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
  //const StakingUGOLD = await StartDeploy("UndeadsStakingUGOLD",TokenUDS.address,TokenUGOLD.address,NFT.address,AMM.address);
  const StakingUGOLD=0;

  

  console.log("Account after balance:", ToFloat(await owner.getBalance()));
  return { owner, otherAccount, StakingUDS, StakingUGOLD, TokenUDS, TokenUGOLD, NFT, AMM};
}
async function deploySmarts2() {

  const [owner, otherAccount] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", owner.address);
  console.log("Account befor balance:", ToFloat(await owner.getBalance()));

  const TokenUDS = await hre.ethers.getContractAt("UDSTest", "0xce682Da3ACa043C20496914886ff0DecBDb2A5D3",owner);
  const TokenUGOLD = await hre.ethers.getContractAt("UGOLDTest", "0x7099D11c912fa517896eC470FcdEE0d2f3C57e62",owner);
  const NFT = await hre.ethers.getContractAt("NFTTest", "0x2744a9c96E2CFc3037a9F1f1C295e3e68FdaAD78",owner);
  const AMM = await hre.ethers.getContractAt("AMMTest", "0xaa39ee070cbCFb7c635149Ef329BbD9CbAAb4e26",owner);
  

  const StakingUDS = await hre.ethers.getContractAt("UndeadsStakingUDS", "0x32647b5E47493e958575a7828F64A486280dA72c",owner);
  const StakingUGOLD=0;
  

  console.log("Account after balance:", ToFloat(await owner.getBalance()));
  return { owner, otherAccount, StakingUDS, StakingUGOLD, TokenUDS, TokenUGOLD, NFT, AMM};
}

async function deploySmarts3() {

  const [owner, otherAccount] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", owner.address);
  console.log("Account befor balance:", ToFloat(await owner.getBalance()));

  const TokenUDS = await hre.ethers.getContractAt("UDSTest", "0x93F08d3f9B8A1564E40366bD5ACA7d98DBde7e1C",owner);
  const TokenUGOLD = await hre.ethers.getContractAt("UGOLDTest", "0x1793dc4e43a200BaA27B57E83ED33d759819f0A3",owner);
  const NFT = await hre.ethers.getContractAt("NFTTest", "0x0C6D544edD924A7E9436BE9bA929f5ffed480fbe",owner);
  const AMM = await hre.ethers.getContractAt("AMMTest", "0x57688Bd7De1b1eDA05eB1e2C2C8558E01A1429Ca",owner);
  

  const StakingUDS = await hre.ethers.getContractAt("UndeadsStakingUDS", "0x719D62Cd89cA70b5b4c168E7d66E3a4c2aAc7C6E",owner);
  const StakingUGOLD=0;
  

  console.log("Account after balance:", ToFloat(await owner.getBalance()));
  return { owner, otherAccount, StakingUDS, StakingUGOLD, TokenUDS, TokenUGOLD, NFT, AMM};
}


async function deploySmartTest() {
  const { owner, otherAccount, StakingUDS, StakingUGOLD, TokenUDS, TokenUGOLD, NFT, AMM} = await deploySmarts();

  await TestMint(owner, otherAccount, StakingUDS, TokenUDS, TokenUGOLD, NFT, AMM);
  await TestMint2(owner, otherAccount, StakingUDS, TokenUDS, TokenUGOLD, NFT, AMM);
  await Test1(owner, otherAccount, StakingUDS, TokenUDS, TokenUGOLD, NFT, AMM);
  //await Test2(owner, otherAccount, StakingUGOLD, TokenUGOLD);

}




async function Test_1min_stake() 
{
  //var Block = await hre.ethers.provider.getBlock("latest");
  //console.log("Block:",Block.timestamp,JSON.stringify(Block,"",4));
  //return;

  const { owner, otherAccount, StakingUDS, StakingUGOLD, TokenUDS, TokenUGOLD, NFT, AMM} = await deploySmarts3();
  var Staking=StakingUDS;

  /*
  console.log("transfer to ",otherAccount.address);
  await (await owner.sendTransaction({
    to: otherAccount.address,
    value: FromSum18(100),
  })).wait();
  */



  console.log("Balance otherAccount:", ToFloat(await otherAccount.getBalance()));


  await TestMint(owner, otherAccount, StakingUDS, TokenUDS, TokenUGOLD, NFT, AMM);
  await TestMint2(owner, otherAccount, StakingUDS, TokenUDS, TokenUGOLD, NFT, AMM);
  //return;

  var StartBlocknum = (await hre.ethers.provider.getBlockNumber()) >>> 0;
  console.log("--------------------StartBlocknum:",StartBlocknum);

  var Block = await hre.ethers.provider.getBlock("latest");
  var Start=Block.timestamp;
  console.log("--------------------Start time:",Start);

  var Period=60;
  var PeriodCount=1440;
  console.log("--------------------setup");
  await (await Staking.setup(FromSum18(50*1e6), Start, Period,15,PeriodCount,60,(8*1e9/100/60)>>>0)).wait();


  console.log("--------------------stake");
  await (await Staking.stake(FromSum18(100), 60, 0)).wait();
  console.log("poolStake1:",ToFloat(await Staking.poolStake()));
  await (await Staking.stake(FromSum18(100), 730, 0)).wait();
  console.log("poolStake2:",ToFloat(await Staking.poolStake()));
  await (await Staking.connect(otherAccount).stake(FromSum18(0.000001), 60, 2)).wait();

  console.log("allReward: ",ToFloat(await Staking.allReward()),"/",ToFloat(await Staking.poolStake()));

}

async function Test_1min_reward() 
{
  //var Block = await hre.ethers.provider.getBlock("latest");
  //console.log("Block:",Block.timestamp,JSON.stringify(Block,"",4));
  //return;

  const { owner, otherAccount, StakingUDS, StakingUGOLD, TokenUDS, TokenUGOLD, NFT, AMM} = await deploySmarts3();
  var Staking=StakingUDS;

  var StartBlocknum = (await hre.ethers.provider.getBlockNumber()) >>> 0;
  var Block = await hre.ethers.provider.getBlock("latest");
  console.log("--------------------StartBlocknum:",StartBlocknum," time:",Block.timestamp);


  var List=await Staking.listSessions(owner.address,0,10);
  console.log("Stakes:  ",ToFloat(List[0].info.Stake),",",ToFloat(List[1].info.Stake));
  console.log("Rewards: ",ToFloat(List[0].reward),",",ToFloat(List[1].reward));
  
 
  
 
  console.log("--------------------reward 1");
  console.log("1 TokenUDS: ",ToFloat(await TokenUDS.balanceOf(owner.address)));
  await (await Staking.reward(1)).wait();
  await (await Staking.reward(2)).wait();
  console.log("2 TokenUDS: ",ToFloat(await TokenUDS.balanceOf(owner.address)));

}

async function Test_1min_unstake() 
{
  //var Block = await hre.ethers.provider.getBlock("latest");
  //console.log("Block:",Block.timestamp,JSON.stringify(Block,"",4));
  //return;

  const { owner, otherAccount, StakingUDS, StakingUGOLD, TokenUDS, TokenUGOLD, NFT, AMM} = await deploySmarts3();
  var Staking=StakingUDS;

  var StartBlocknum = (await hre.ethers.provider.getBlockNumber()) >>> 0;
  var Block = await hre.ethers.provider.getBlock("latest");
  console.log("--------------------StartBlocknum:",StartBlocknum," time:",Block.timestamp);


  var List=await Staking.listSessions(owner.address,0,10);
  console.log("Stakes:  ",ToFloat(List[0].info.Stake),",",ToFloat(List[1].info.Stake));
  console.log("Rewards: ",ToFloat(List[0].reward),",",ToFloat(List[1].reward));
  var WaitSec=Block.timestamp-List[0].info.End;
  if(WaitSec<=0)
  {
    console.log("For unstake wait ",-WaitSec,"sec");
    return;
  }
  
 
  
 
  console.log("--------------------reward 1");
  console.log("1 TokenUDS: ",ToFloat(await TokenUDS.balanceOf(owner.address)));
  await (await Staking.reward(2)).wait();
  console.log("2 TokenUDS: ",ToFloat(await TokenUDS.balanceOf(owner.address)));


  console.log("--------------------unstake 1");
  await (await Staking.unstake(1)).wait();
  console.log("3 TokenUDS: ",ToFloat(await TokenUDS.balanceOf(owner.address)));
  console.log("     UGOLD: ",ToFloat(await TokenUGOLD.balanceOf(owner.address)));
  

  console.log("--------------------unstake 2");
  console.log("1 TokenUDS: ",ToFloat(await TokenUDS.balanceOf(otherAccount.address)));
  await (await Staking.connect(otherAccount).unstake(1)).wait();
  console.log("3 TokenUDS: ",ToFloat(await TokenUDS.balanceOf(otherAccount.address)));
  console.log("     UGOLD: ",ToFloat(await TokenUGOLD.balanceOf(otherAccount.address)));

}



async function TestMint(owner, otherAccount, Staking, TokenUDS, TokenUGOLD, NFT, AMM) 
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
  //return;

}  

async function TestMint2(owner, otherAccount, Staking, TokenUDS, TokenUGOLD, NFT, AMM) 
{
  console.log("--------------------Mint2");
  await (await NFT.Mint(otherAccount.address)).wait();
  await (await TokenUDS.connect(otherAccount).Mint(FromSum18(1e6))).wait();
  await (await TokenUDS.connect(otherAccount).approve(Staking.address,FromSum18(1e6))).wait();
  await (await NFT.connect(otherAccount).approve(Staking.address,2)).wait();

  console.log("--------------------");
  //return;

}  

async function Test1(owner, otherAccount, Staking, TokenUDS, TokenUGOLD, NFT, AMM) 
{
  

  
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
module.exports.deploySmarts = Test_1min_stake;
module.exports.deploySmarts = Test_1min_reward;

module.exports.deploySmarts = Test_1min_unstake;


