const hre = require("hardhat");

const { time,setBalance,setCode,impersonateAccount,stopImpersonatingAccount } = require("@nomicfoundation/hardhat-network-helpers");

/*
export { mine } from "./helpers/mine";
export { mineUpTo } from "./helpers/mineUpTo";
export { dropTransaction } from "./helpers/dropTransaction";
export { getStorageAt } from "./helpers/getStorageAt";
export { impersonateAccount } from "./helpers/impersonateAccount";
export { setBalance } from "./helpers/setBalance";
export { setBlockGasLimit } from "./helpers/setBlockGasLimit";
export { setCode } from "./helpers/setCode";
export { setCoinbase } from "./helpers/setCoinbase";
export { setNonce } from "./helpers/setNonce";
export { setPrevRandao } from "./helpers/setPrevRandao";
export { setStorageAt } from "./helpers/setStorageAt";
export { setNextBlockBaseFeePerGas } from "./helpers/setNextBlockBaseFeePerGas";
export { stopImpersonatingAccount } from "./helpers/stopImpersonatingAccount";
export { takeSnapshot, SnapshotRestorer } from "./helpers/takeSnapshot";
*/

//await time.increaseTo(SaleStart+2100);

//require("@nomiclabs/hardhat-ethers");

const {MainAcc1} = require("../../../../keys/test1.js");


async function StartDeploy(Name, Param1) {
  console.log("Start deploy", Name, Param1 ? "with params length=" + (arguments.length - 1) : "");

  var ArrArgs = [];
  for (var i = 1; i < arguments.length; i++) {
    ArrArgs.push(arguments[i]);
  }

  var ContractTx = await hre.ethers.deployContract(Name, ArrArgs);//signerOrOptions


  //await ContractTx.deployed();
  console.log(`Deployed ${Name} to ${ContractTx.address}`);
  return ContractTx;
}


async function deploySmarts() {
  const [owner, otherAccount] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", owner.address);
  console.log("Account befor balance:", ToFloat(await owner.getBalance()).toString());

  const Contract = await StartDeploy("InvestGame");
  const UniSwap = await StartDeploy("UniSwap");
  const TokenUSD = await StartDeploy("USDTest");
  const TokenMatic = await StartDeploy("USDTest");

  console.log("Admin:", (await Contract.admin()).toString());

  //await setBalance(owner.address,FromSum18("100000"));
 
  console.log("Account after balance:", ToFloat(await owner.getBalance()).toString());
  return { owner, otherAccount, Contract, UniSwap, TokenUSD, TokenMatic};
}

async function deploySmartsTest1() {
  var Start=(await hre.ethers.provider.getBlockNumber())>>>0;
  console.log("Start:",Start);

  var { owner, otherAccount, Contract, UniSwap, TokenUSD, TokenMatic} = await deploySmarts();


  
  await TokenUSD.MintTo(Contract.address,FromSum6(5));
  await TokenUSD.MintTo(otherAccount.address,FromSum6(100));
  await TokenMatic.MintTo(otherAccount.address,FromSum18(5));
  

  startTest(otherAccount, Contract, UniSwap,UniSwap, TokenUSD, TokenMatic);

  return {owner, Contract, UniSwap, TokenUSD, TokenMatic};
}


async function deploySmartsTest2() {


  var Start=(await hre.ethers.provider.getBlockNumber())>>>0;
  console.log("Start:",Start);

  var { owner, Contract} = await deploySmarts();

  
    var owner2 = new hre.ethers.Wallet(MainAcc1,hre.ethers.provider);
    console.log("owner2", owner2.address);
  
  
  
    const TokenMatic = await hre.ethers.getContractAt("USDTest", "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270",owner2);
    const TokenUSD = await hre.ethers.getContractAt("USDTest", "0xc2132d05d31c914a87c6611c10748aeb04b58e8f",owner2);
    var Factory = await hre.ethers.getContractAt("UniSwap", "0x1F98431c8aD98523631AE4a59f267346ea31F984",owner2);
    var UniSwap = await hre.ethers.getContractAt("UniSwap", "0xE592427A0AEce92De3Edee1F18E0157C05861564",owner2);
    await setBalance(owner2.address,FromSum18("1000"));
  
  
    //console.log("Account balance:", ToFloat(await owner2.getBalance()).toString());
  
    
  
    console.log("WUSDT: ",ToFloat6(await TokenUSD.balanceOf(owner2.address)));
    console.log("WMATIC: ",ToFloat(await TokenMatic.balanceOf(owner2.address)));
  
    //await TokenUSD.connect(owner2).transfer(owner.address,FromSum6(1))
  
    startTest(owner2, Contract, Factory,UniSwap, TokenUSD, TokenMatic);
    return {owner, Contract, UniSwap, TokenUSD, TokenMatic};
  }
  

async function startTest(client, Contract0, Factory, UniSwap, TokenUSD0, TokenMatic0) {

  console.log("----------startTest-------------");

  var Contract=Contract0.connect(client);
  var TokenUSD=TokenUSD0.connect(client);
  var TokenMatic=TokenMatic0.connect(client);

  await TokenUSD.approve(Contract.address,FromSum6(1000));
  await TokenMatic.approve(Contract.address,FromSum18(1000));

  await (await Contract0.setUniswap(Factory.address,UniSwap.address,TokenUSD.address,TokenUSD.address)).wait();
  //await (await Contract.setUniswap("0x1F98431c8aD98523631AE4a59f267346ea31F984","0xE592427A0AEce92De3Edee1F18E0157C05861564","0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270","0xc2132d05d31c914a87c6611c10748aeb04b58e8f")).wait();
  console.log("USD:   ",ToFloat6(await TokenUSD.balanceOf(client.address)));
  console.log("Matic: ",ToFloat(await TokenMatic.balanceOf(client.address)));


  await Contract0.setTradeToken(TokenUSD.address,1);
  await Contract0.setListingPrice(TokenUSD.address,FromSum6(1));

  console.log("getPool:",await Contract.getPool(TokenMatic.address,TokenUSD.address));//WMATIC-USDT
  
  console.log("----------Listing-------------");
  await Contract.requestTradeToken(TokenMatic.address,TokenUSD.address);
  //await Contract.requestTradeToken(TokenUSD.address,TokenUSD.address);
  console.log("Request:",ToString(await Contract.listTradeRequest(0,10)));


  await Contract0.approveTradeToken(TokenMatic.address,100);
  console.log("Request:",ToString(await Contract.listTradeRequest(0,10)));
  console.log("Rank:",ToString(await Contract.rankTradeToken(TokenMatic.address)));
  
  console.log("----------Deposit-------------");
  await Contract.deposit(TokenMatic.address,FromSum18(5));
  console.log("Client USD  :",ToFloat6(await Contract.balanceOf(client.address,TokenUSD.address)));
  console.log("Client Matic:",ToFloat(await Contract.balanceOf(client.address,TokenMatic.address)));

  console.log("----------Trade-------------");
  await Contract.trade(TokenMatic.address,TokenUSD.address,FromSum18(4));
  //await Contract.trade(TokenMatic.address,TokenUSD.address,FromSum18(1000));
  console.log("Client USD  :",ToFloat6(await Contract.balanceOf(client.address,TokenUSD.address)));
  console.log("Client Matic:",ToFloat(await Contract.balanceOf(client.address,TokenMatic.address)));

  console.log("----------Withdraw-------------");
  await Contract.withdraw(TokenUSD.address,FromSum6(3));
  console.log("Client USD  :",ToFloat6(await Contract.balanceOf(client.address,TokenUSD.address)));
  await Contract.withdraw(TokenMatic.address,FromSum18(1));
  console.log("Client Matic:",ToFloat(await Contract.balanceOf(client.address,TokenMatic.address)));
  console.log("USD:   ",ToFloat6(await TokenUSD.balanceOf(client.address)));
  console.log("Matic: ",ToFloat(await TokenMatic.balanceOf(client.address)));

 
}





function FromSum18(Sum) {
  return hre.ethers.utils.parseEther(String(Sum));
  //return ""+Sum+"000000000000000000";
}
function FromSum6(Sum) {
  return ""+Sum+"000000";
}

function ToString(BigSum) {
  return BigSum.toString();
}

function ToFloat(BigSum) {
  const Cents=10n**18n;
  var Sum = BigInt(BigSum);
  var Str = Right("000000000000000000" + Sum % Cents, 18);
  return "" + Sum / Cents + "." + Str;
}
function ToFloat6(BigSum) {
  const Cents=10n**6n;
  var Sum = BigInt(BigSum);
  var Str = Right("000000" + Sum % Cents, 6);
  return "" + Sum / Cents + "." + Str;
}

function Right(Str, count) {
  if (Str.length > count)
    return Str.substr(Str.length - count, count);
  else
    return Str.substr(0, Str.length);
}


function sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}


module.exports.deploySmarts = deploySmarts;
module.exports.deploySmarts = deploySmartsTest1;
//module.exports.deploySmarts = deploySmartsTest2;




