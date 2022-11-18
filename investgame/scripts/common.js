const hre = require("hardhat");

const { time, setBalance, setCode, impersonateAccount, stopImpersonatingAccount } = require("@nomicfoundation/hardhat-network-helpers");

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

//const { MainAcc1 } = require("../../../../keys/test1.js");


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
  const Voting = await StartDeploy("Voting",Contract.address);

  const UniSwap = await StartDeploy("UniSwap");
  const TokenUSD = await StartDeploy("USDTest");
  const TokenMatic = await StartDeploy("TestCoin");
  const TokenA = await StartDeploy("TestCoin");
  const TokenB = await StartDeploy("TestCoin");

  console.log("Admin:", (await Contract.admin()).toString());

  //await setBalance(owner.address,FromSum18("100000"));

  console.log("Account after balance:", ToFloat(await owner.getBalance()).toString());
  return { owner, otherAccount, Contract, Voting, TokenA, TokenB, UniSwap, UniSwap, TokenUSD, TokenMatic };
}

async function deploySmartsTest1() {
  var Start = (await hre.ethers.provider.getBlockNumber()) >>> 0;
  console.log("Start:", Start);

  var { owner, otherAccount, Contract, Voting, TokenA, TokenB, UniSwap, UniSwap, TokenUSD, TokenMatic } = await deploySmarts();



  await TokenUSD.MintTo(Contract.address, FromSum6(1000));
  await TokenUSD.MintTo(otherAccount.address, FromSum6(1000));
  await TokenMatic.MintTo(otherAccount.address, FromSum18(1000));
  await TokenA.MintTo(otherAccount.address, FromSum18(1000));
  await TokenB.MintTo(otherAccount.address, FromSum18(1000));


  await startTest(otherAccount, Contract, Voting, TokenA, TokenB, UniSwap, UniSwap, TokenUSD, TokenMatic);

  return { owner, otherAccount, Contract, Voting, TokenA, TokenB, UniSwap, TokenUSD, TokenMatic};
}

async function SendImpMoney(TokenAddr,FromAddr,ToAddr,Amount) {
  
  impersonateAccount(FromAddr);
  var signer = await hre.ethers.getSigner(FromAddr);
  const Token = await hre.ethers.getContractAt("USDTest", TokenAddr, signer);

  console.log("REST1: ", ToFloat6(await Token.balanceOf(FromAddr)));
  await Token.connect(signer).transfer(ToAddr,Amount);
  console.log("REST2: ", ToFloat6(await Token.balanceOf(ToAddr)));
}

async function SendDeposit(ToAddr,Amount) 
{
  var TokenAddr="0xc2132d05d31c914a87c6611c10748aeb04b58e8f";
  var FromAddr="0xb2931fa6e3f82053620a1ff59e871e95a792a07c";
  impersonateAccount(FromAddr);
  var signer = await hre.ethers.getSigner(FromAddr);
  const Token = await hre.ethers.getContractAt("USDTest", TokenAddr, signer);

  console.log("REST1: ", ToFloat6(await Token.balanceOf(FromAddr)));
  //await Token.connect(signer).transfer(ToAddr,Amount);
  await Token.connect(signer).deposit(ToAddr,Amount);
  console.log("REST2: ", ToFloat6(await Token.balanceOf(ToAddr)));
}

async function deploySmartsTest2() {


  var Start = (await hre.ethers.provider.getBlockNumber()) >>> 0;
  console.log("Start:", Start);


  var [owner, otherAccount] = await hre.ethers.getSigners();
  //SendDeposit(otherAccount.address,FromSum6(1000));
  //SendDeposit(otherAccount.address,"0x100000");
  //return {};


  var { owner, Contract, Voting, TokenA, TokenB } = await deploySmarts();


  //var owner2 = new hre.ethers.Wallet(MainAcc1, hre.ethers.provider);
  //console.log("owner2", owner2.address);

  const TokenMatic = await hre.ethers.getContractAt("TestCoin", "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270", otherAccount);
  const TokenUSD = await hre.ethers.getContractAt("USDTest", "0xc2132d05d31c914a87c6611c10748aeb04b58e8f", owner);
  var Factory = await hre.ethers.getContractAt("UniSwap", "0x1F98431c8aD98523631AE4a59f267346ea31F984", owner);
  var UniSwap = await hre.ethers.getContractAt("UniSwap", "0xE592427A0AEce92De3Edee1F18E0157C05861564", owner);

  await setBalance(otherAccount.address, FromSum18("200000"));

  SendImpMoney("0xc2132d05d31c914a87c6611c10748aeb04b58e8f","0xf89d7b9c864f589bbf53a82105107622b35eaa40",otherAccount.address,FromSum6(1000));
  await TokenMatic.deposit({value:FromSum18(100000)});


  console.log("WUSDT: ", ToFloat6(await TokenUSD.balanceOf(otherAccount.address)));
  console.log("WMATIC: ", ToFloat(await TokenMatic.balanceOf(otherAccount.address)));

  


  await startTest(otherAccount, Contract, Voting, TokenA, TokenB, Factory, UniSwap, TokenUSD, TokenMatic);
  return { owner, otherAccount, Contract, Voting, TokenA, TokenB, UniSwap, TokenUSD, TokenMatic};
}
async function startTest(client, Contract0, Voting, TokenA, TokenB, Factory, UniSwap, TokenUSD0, TokenMatic0) 
{
  await startTest1(client, Contract0, Voting, TokenA, TokenB, Factory, UniSwap, TokenUSD0, TokenMatic0);
  await startTest2(client, Contract0, Voting, TokenA, TokenB, Factory, UniSwap, TokenUSD0, TokenMatic0);
}

async function startTest2(client, Contract0, Voting0, TokenA, TokenB, Factory, UniSwap, TokenUSD0, TokenMatic0) 
{

  console.log("----------Test voting-------------");
  await (await Voting0.transfer(client.address,FromSum18(100000))).wait();

  var Voting= Voting0.connect(client);
  var TokenUSD = TokenUSD0.connect(client);
  var Contract = Contract0.connect(client);

  await (await Contract0.transferAdminship(Voting.address)).wait();

  var List;
  console.log("----------SetPeriod");
  var Period=100;
  await (await Voting.proposalSetPeriod(Period)).wait();
  List = await Voting.listProposal(0, 10);
  await (await Voting.approveVote(List[0].key)).wait();
  List = await Voting.listProposal(0, 10);
  console.log("List:", ToString(List));
  console.log("Period:", ToString(await Voting.ProposalPeriod()));

  

  console.log("----------SetPrice");
  await (await Voting.proposalSetPrice(FromSum18(0.001))).wait();
  await (await Voting.proposalSetPrice(FromSum18(0.0001))).wait();
  List = await Voting.listProposal(0, 10);
  console.log("List:", (await Voting.lengthProposal())>>>0, "=>", ToString(List));

  await (await Voting.vote(List[0].key,1,FromSum18(50000))).wait();
  await (await Voting.vote(List[0].key,1,FromSum18(50000))).wait();
  await (await Voting.vote(List[1].key,1,FromSum18(60000))).wait();


  await time.increaseTo((await time.latest()) +Period+1);
  await (await Voting.transfer(Voting.address,FromSum18(10000))).wait();
  //await (await Voting.vote(List[0].key,1,FromSum18(100))).wait();
  await (await Voting.approveVote(List[1].key)).wait();
  await (await Voting.approveVote(List[0].key)).wait();
  List = await Voting.listProposal(0, 10);
  console.log("List:", (await Voting.lengthProposal())>>>0, "=>", ToString(List));
  var Price=await Voting.ProposalPrice();
  console.log("Price:", ToFloat(Price));

  console.log("----------MintTo");
  await (await Voting.proposalMintTo(client.address,FromSum18(50000),{value:Price})).wait();
  await time.increaseTo((await time.latest()) +Period);
  console.log("1 DAO: ", ToFloat(await Voting.balanceOf(client.address)));
  List = await Voting.listProposal(0, 10);
  await (await Voting.approveVote(List[0].key)).wait();
  console.log("2 DAO: ", ToFloat(await Voting.balanceOf(client.address)));
  
  console.log("----------TransferFromTo");
  await (await Voting.proposalTransferFromTo(Voting.address,client.address,FromSum18(10000),{value:Price})).wait();
  await time.increaseTo((await time.latest()) +Period);
  console.log("1 DAO: ", ToFloat(await Voting.balanceOf(client.address)));
  List = await Voting.listProposal(0, 10);
  await (await Voting.approveVote(List[0].key)).wait();
  console.log("2 DAO: ", ToFloat(await Voting.balanceOf(client.address)));


  console.log("----------Withdraw");
  await (await Voting.proposalWithdraw(client.address,await Voting.balanceFee(),{value:Price})).wait();
  await time.increaseTo((await time.latest()) +Period);
  console.log("1 ETH: ", ToFloat(await Voting.balanceFee()));
  List = await Voting.listProposal(0, 10);
  await (await Voting.approveVote(List[0].key)).wait();
  console.log("2 ETH: ", ToFloat(await Voting.balanceFee()));

  console.log("----------SetListingPrice");
  await (await Voting.proposalSetListingPrice(TokenUSD.address,FromSum6(2),{value:Price})).wait();
  List = await Voting.listProposal(0, 10);
  await (await Voting.vote(List[0].key,1,FromSum18(10000))).wait();
  await (await Voting.vote(List[0].key,0,FromSum18(9000))).wait();
  await time.increaseTo((await time.latest()) +Period);
  console.log("1 PriceList: ", ToFloat6(await Contract.getListingPrice(TokenUSD.address)));
  await (await Voting.approveVote(List[0].key)).wait();
  console.log("2 PriceList: ", ToFloat6(await Contract.getListingPrice(TokenUSD.address)));
  
  console.log("----------SetTradeToken");
  await (await Voting.proposalSetTradeToken(TokenUSD.address,"{rank:2,Level:12345}",{value:Price})).wait();
  List = await Voting.listProposal(0, 10);
  await time.increaseTo((await time.latest()) +Period);
  console.log("1 rankTradeToken: ", ToString(await Contract.rankTradeToken(TokenUSD.address)));
  await (await Voting.approveVote(List[0].key)).wait();
  console.log("2 rankTradeToken: ", ToString(await Contract.rankTradeToken(TokenUSD.address)));
  
  console.log("----------ApproveTradeToken");
  console.log("1 USD: ", ToFloat6(await TokenUSD.balanceOf(client.address)));
  await TokenUSD.approve(Contract.address, FromSum6(1000));
  await (await Contract.requestTradeToken(TokenA.address,TokenUSD.address)).wait();
  console.log("2 USD: ", ToFloat6(await TokenUSD.balanceOf(client.address)));
  await (await Voting.proposalApproveTradeToken(TokenA.address,"{rank:100,Level:20000, name='Token A'}",{value:Price})).wait();
  List = await Voting.listProposal(0, 10);
  await time.increaseTo((await time.latest()) +Period);
  console.log("1 rankTradeToken: ", ToString(await Contract.rankTradeToken(TokenA.address)));
  await (await Voting.approveVote(List[0].key)).wait();
  console.log("2 rankTradeToken: ", ToString(await Contract.rankTradeToken(TokenA.address)));

  console.log("----------DelTradeToken");
  await (await Voting.proposalDelTradeToken(TokenA.address,{value:Price})).wait();
  List = await Voting.listProposal(0, 10);
  await time.increaseTo((await time.latest()) +Period);
  console.log("1 rankTradeToken: ", ToString(await Contract.rankTradeToken(TokenA.address)));
  await (await Voting.approveVote(List[0].key)).wait();
  console.log("2 rankTradeToken: ", ToString(await Contract.rankTradeToken(TokenA.address)));

  console.log("----------WithdrawListFee");
  var Fee=await Contract.balanceFee(TokenUSD.address);
  console.log("1 FEE: ", ToFloat6(Fee));
  await (await Voting.proposalWithdrawListFee(TokenUSD.address,client.address,Fee,{value:Price})).wait();
  List = await Voting.listProposal(0, 10);
  await time.increaseTo((await time.latest()) +Period);
  console.log("1 USD: ", ToFloat6(await TokenUSD.balanceOf(client.address)));
  await (await Voting.approveVote(List[0].key)).wait();
  console.log("2 USD: ", ToFloat6(await TokenUSD.balanceOf(client.address)));
  
}



async function startTest1(client, Contract0, Voting, TokenA, TokenB, Factory, UniSwap, TokenUSD0, TokenMatic0) {

  console.log("----------startTest-------------");

  var Contract = Contract0.connect(client);
  var TokenUSD = TokenUSD0.connect(client);
  var TokenMatic = TokenMatic0.connect(client);

  await TokenUSD.approve(Contract.address, FromSum6(1000));
  await TokenMatic.approve(Contract.address, FromSum18(1000));

  await (await Contract0.setUniswap(Factory.address, UniSwap.address, TokenUSD.address, TokenUSD.address)).wait();
  //await (await Contract.setUniswap("0x1F98431c8aD98523631AE4a59f267346ea31F984","0xE592427A0AEce92De3Edee1F18E0157C05861564","0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270","0xc2132d05d31c914a87c6611c10748aeb04b58e8f")).wait();
  console.log("USD:   ", ToFloat6(await TokenUSD.balanceOf(client.address)));
  console.log("Matic: ", ToFloat(await TokenMatic.balanceOf(client.address)));


  var ListingPrice = FromSum6(10);
  await Contract0.setTradeToken(TokenUSD.address, "{rank:1}");
  await Contract0.setListingPrice(TokenUSD.address, ListingPrice);

  console.log("getPool:", await Contract.getPool(TokenMatic.address, TokenUSD.address));//WMATIC-USDT

  console.log("----------Listing-------------");
  await Contract.requestTradeToken(TokenMatic.address, TokenUSD.address);
  //await Contract.requestTradeToken(TokenUSD.address,TokenUSD.address);
  console.log("Request:", ToString(await Contract.listTradeRequest(0, 10)));


  await Contract0.approveTradeToken(TokenMatic.address, "{rank:100}");
  console.log("Request:", ToString(await Contract.listTradeRequest(0, 10)));
  console.log("Rank:", ToString(await Contract.rankTradeToken(TokenMatic.address)));

  console.log("----------Deposit-------------");
  await Contract.deposit(TokenMatic.address, FromSum18(205));
  console.log("Client USD  :", ToFloat6(await Contract.balanceOf(client.address, TokenUSD.address)));
  console.log("Client Matic:", ToFloat(await Contract.balanceOf(client.address, TokenMatic.address)));

  console.log("----------Trade-------------");
  await Contract.trade(TokenMatic.address, TokenUSD.address, FromSum18(200));
  console.log("Client USD  :", ToFloat6(await Contract.balanceOf(client.address, TokenUSD.address)));
  console.log("Client Matic:", ToFloat(await Contract.balanceOf(client.address, TokenMatic.address)));

  console.log("----------Withdraw-------------");
  await Contract.withdraw(TokenUSD.address, FromSum6(150));
  console.log("Client USD  :", ToFloat6(await Contract.balanceOf(client.address, TokenUSD.address)));
  await Contract.withdraw(TokenMatic.address, FromSum18(5));
  console.log("Client Matic:", ToFloat(await Contract.balanceOf(client.address, TokenMatic.address)));
  console.log("USD:   ", ToFloat6(await TokenUSD.balanceOf(client.address)));
  console.log("Matic: ", ToFloat(await TokenMatic.balanceOf(client.address)));

  console.log("----------Withdraw Fee -------------");
  await Contract0.withdrawListFee(TokenUSD.address,client.address, FromSum6(10));
  console.log("USD:    ", ToFloat6(await TokenUSD.balanceOf(client.address)));
  console.log("RestFee:", ToFloat6(await Contract.balanceFee(TokenUSD.address)));

}

async function SmartsTest3() {
  const [owner, otherAccount] = await hre.ethers.getSigners();
  //console.log("account:", owner.address);
  //var owner2 = new hre.ethers.Wallet(MainAcc1,hre.ethers.provider);  console.log("owner2", owner2.address);

  var address2 = "0xf89d7b9c864f589bbf53a82105107622b35eaa40";
  const TokenUSD = await hre.ethers.getContractAt("USDTest", "0xc2132d05d31c914a87c6611c10748aeb04b58e8f");
  console.log("USD:   ", ToFloat6(await TokenUSD.balanceOf(address2)));


  impersonateAccount(address2);
  const signer = await hre.ethers.getSigner(address2);

  const Token = await StartDeploy("USDTest");
  console.log("Sender=", await Token.connect(signer).Sender());
  await Token.connect(signer).Test()
}

async function deployToPolygon() {
  var Start = (await hre.ethers.provider.getBlockNumber()) >>> 0;
  console.log("Start:", Start);

  const [owner, otherAccount] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", owner.address);
  console.log("Account befor balance:", ToFloat(await owner.getBalance()).toString());

  const TokenMatic = await hre.ethers.getContractAt("TestCoin", "0x0d500B1d8E8eF31E21C99d1Db9A6444d3ADf1270", owner);
  const TokenUSD = await hre.ethers.getContractAt("USDTest", "0xc2132d05d31c914a87c6611c10748aeb04b58e8f", owner);
  var Factory = await hre.ethers.getContractAt("UniSwap", "0x1F98431c8aD98523631AE4a59f267346ea31F984", owner);
  var UniSwap = await hre.ethers.getContractAt("UniSwap", "0xE592427A0AEce92De3Edee1F18E0157C05861564", owner);
  console.log("WUSDT: ", ToFloat6(await TokenUSD.balanceOf(otherAccount.address)));
  console.log("WMATIC: ", ToFloat(await TokenMatic.balanceOf(otherAccount.address)));

  
  var Contract = await hre.ethers.getContractAt("InvestGame", "0x651F64C82770c23D5CffddB2ac0a3310F559Bd20", owner);
  //const Contract = await StartDeploy("InvestGame");  await Contract.deployed();





  //await (await Contract.setUniswap(Factory.address, UniSwap.address, TokenUSD.address, TokenUSD.address)).wait();


  await (await Contract.setTradeToken(TokenUSD.address, "{rank:1}")).wait();
  await (await Contract.setListingPrice(TokenUSD.address, FromSum6(1))).wait();

  console.log("getPool:", await Contract.getPool(TokenMatic.address, TokenUSD.address));//WMATIC-USDT

  console.log("Account after balance:", ToFloat(await owner.getBalance()).toString());
  return { owner, otherAccount, Contract};

}


function FromSum18(Sum) {
  return hre.ethers.utils.parseUnits(String(Sum), 18);
}
function FromSum6(Sum) {
  return hre.ethers.utils.parseUnits(String(Sum), 6);
}

function ToString(BigSum) {
  return BigSum.toString();
}

function ToFloat(BigSum) {
  return hre.ethers.utils.formatUnits(BigSum, 18);
}
function ToFloat6(BigSum) {
  return hre.ethers.utils.formatUnits(BigSum, 6);
}

function Right(Str, count) {
  if (Str.length > count)
    return Str.substr(Str.length - count, count);
  else
    return Str.substr(0, Str.length);
}


function Sleep(ms) {
  return new Promise((resolve) => {
    setTimeout(resolve, ms);
  });
}


module.exports.deploySmarts = deploySmarts;
module.exports.deploySmarts = deploySmartsTest1;
//module.exports.deploySmarts = deploySmartsTest2;
//module.exports.deploySmarts = SmartsTest3;
//module.exports.deploySmarts = deployToPolygon;





