const hre = require("hardhat");

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
  const TokenFTX = await StartDeploy("USDTest");

  console.log("Owner:", (await Contract.owner()).toString());

  console.log("Account after balance:", ToFloat(await owner.getBalance()).toString());
  return { owner, otherAccount, Contract, UniSwap, TokenUSD, TokenFTX};
}

async function deploySmartsTest() {

  const { owner, otherAccount, Contract, UniSwap, TokenUSD, TokenFTX} = await deploySmarts();
  
  await TokenUSD.MintTo(Contract.address,FromSum18(10000));
  await TokenUSD.Mint(FromSum18(1000));
  await TokenFTX.Mint(FromSum18(2000));
  
  await TokenUSD.approve(Contract.address,FromSum18(1000));
  await TokenFTX.approve(Contract.address,FromSum18(1000));
  


  await (await Contract.setUniswap(UniSwap.address,UniSwap.address,TokenUSD.address,TokenUSD.address)).wait();
  console.log("USD: ",ToFloat(await TokenUSD.balanceOf(owner.address)));
  console.log("FTX: ",ToFloat(await TokenFTX.balanceOf(owner.address)));

  await Contract.setTradeToken(TokenUSD.address,1);
  await Contract.setListingPrice(TokenUSD.address,FromSum18(30));

  //console.log("getPool:",await Contract.getPool(TokenFTX.address,"0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270"));//WMATIC
  
  console.log("----------Listing-------------");
  await Contract.requestTradeToken(TokenFTX.address,TokenUSD.address);
  //await Contract.requestTradeToken(TokenUSD.address,TokenUSD.address);
  console.log("Request:",ToString(await Contract.listTradeRequest(0,10)));
  await Contract.approveTradeToken(TokenFTX.address,100);
  console.log("Request:",ToString(await Contract.listTradeRequest(0,10)));
  console.log("Rank:",ToString(await Contract.rankTradeToken(TokenFTX.address)));
  
  console.log("----------Deposit-------------");
  await Contract.deposit(TokenFTX.address,FromSum18(500));
  console.log("Balance USD:",ToFloat(await Contract.balanceOf(owner.address,TokenUSD.address)));
  console.log("Balance FTX:",ToFloat(await Contract.balanceOf(owner.address,TokenFTX.address)));

  console.log("----------Trade-------------");
  await Contract.trade(TokenFTX.address,TokenUSD.address,FromSum18(100));
  console.log("Balance USD:",ToFloat(await Contract.balanceOf(owner.address,TokenUSD.address)));
  console.log("Balance FTX:",ToFloat(await Contract.balanceOf(owner.address,TokenFTX.address)));

  console.log("----------Withdraw-------------");
  await Contract.withdraw(TokenFTX.address,FromSum18(400));
  await Contract.withdraw(TokenUSD.address,FromSum18(100));
  console.log("Balance USD:",ToFloat(await Contract.balanceOf(owner.address,TokenUSD.address)));
  console.log("Balance FTX:",ToFloat(await Contract.balanceOf(owner.address,TokenFTX.address)));

  console.log("----------Withdraw Owner-------------");
  console.log("1 Smart FTX:",ToFloat(await TokenFTX.balanceOf(Contract.address)));
  await (await Contract.withdrawCoins(TokenFTX.address,FromSum18(100))).wait();
  console.log("2 Smart FTX:",ToFloat(await TokenFTX.balanceOf(Contract.address)));
  
  console.log("------------------------------------------");
  console.log("USD: ",ToFloat(await TokenUSD.balanceOf(owner.address)));
  console.log("FTX: ",ToFloat(await TokenFTX.balanceOf(owner.address)));


  return { owner, otherAccount, Contract, UniSwap, TokenUSD, TokenFTX};
}




function FromSum18(Sum) {
  return ""+Sum+"000000000000000000";
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
module.exports.deploySmarts = deploySmartsTest;
//module.exports.deploySmarts=deployMumbai;


