const hre = require("hardhat");
require("./env-lib.js")

const { time } = require("@nomicfoundation/hardhat-network-helpers");

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
  console.log("Account befor balance:", (await owner.getBalance()).toString());

  const Contract = await StartDeploy("MetableVesting");
  const TokenUSD = await StartDeploy("USDTest");
  const TokenSale = await StartDeploy("USDTest");

  console.log("Owner:", (await Contract.owner()).toString());

  console.log("Account after balance:", (await owner.getBalance()).toString());
  return { owner, otherAccount, Contract, TokenUSD, TokenSale};
}


async function deploySmartVesting() {

  const { owner, otherAccount, Contract, TokenUSD, TokenSale} = await deploySmarts();
  //console.log("FromSum18(1)=",FromSum18(1));
  await TokenUSD.Mint(FromSum18(1000));
  await TokenSale.Mint(FromSum18(5000));
  await TokenSale.transfer(Contract.address,FromSum18(5000));

  //await TokenUSD.connect(otherAccount).Mint(FromSum18(100));
  //await TokenUSD.connect(otherAccount).approve(Contract.address,FromSum18(1000));
  
  console.log("USD: ",ToFloat(await TokenUSD.balanceOf(owner.address)));
  console.log("Sale: ",ToFloat(await TokenSale.balanceOf(Contract.address)));
  
  var Rate =FromSum18(1);
  await Contract.setCoin(TokenUSD.address,Rate);

  var Price=FromSum18(2);

  
  var SaleStart=1 + (await time.latest())>>>0;
  var timeCliff = SaleStart + 2000;
  console.log("SaleStart:",SaleStart);
  await Contract.setSale(TokenSale.address, FromSum18(5000), Price, SaleStart,SaleStart+1000,timeCliff,7,100,10000);
  console.log("Sale info:",ToString(await Contract.getSale(TokenSale.address,SaleStart)));
  
  await time.increaseTo(SaleStart+2);

  console.log("----------buy----------------");
  console.log("1 USD: ",ToFloat(await TokenUSD.balanceOf(owner.address)));
  await TokenUSD.approve(Contract.address,FromSum18(1000));
  
  //SaleStart="1000000001";
  await Contract.buyToken(TokenSale.address,SaleStart,TokenUSD.address,FromSum18(100));
  console.log("2 USD: ",ToFloat(await TokenUSD.balanceOf(owner.address)));

  console.log("Purchase",ToFloat(await Contract.balanceOf(TokenSale.address,SaleStart)));
  //console.log("Token: ",ToFloat(await TokenSale.balanceOf(owner.address)));

  console.log("Sale info:",ToString(await Contract.getSale(TokenSale.address,SaleStart)));
  //await Contract.connect(otherAccount).buyToken(TokenSale.address,SaleStart,TokenUSD.address,FromSum18(100));

  console.log("----------withdraw period 0----------------");
  await time.increaseTo(timeCliff-1);
  await Contract.withdraw(TokenSale.address,SaleStart);
  console.log("Purchase",ToFloat(await Contract.balanceOf(TokenSale.address,SaleStart)));
  console.log("Token: ",ToFloat(await TokenSale.balanceOf(owner.address)));

  console.log("----------withdraw period 1----------------");
  await time.increaseTo(timeCliff-1 + 100);
  await Contract.withdraw(TokenSale.address,SaleStart);
  console.log("Purchase",ToFloat(await Contract.balanceOf(TokenSale.address,SaleStart)));
  console.log("Token: ",ToFloat(await TokenSale.balanceOf(owner.address)));

  console.log("----------withdraw period 4----------------");
  await time.increaseTo(timeCliff-1 + 400);
  await Contract.withdraw(TokenSale.address,SaleStart);
  console.log("Purchase",ToFloat(await Contract.balanceOf(TokenSale.address,SaleStart)));
  console.log("Token: ",ToFloat(await TokenSale.balanceOf(owner.address)));


  console.log("----------withdraw period last----------------");
  await time.increaseTo(timeCliff-1 + 1000);
  
  await Contract.withdraw(TokenSale.address,SaleStart);
  console.log("Purchase",ToFloat(await Contract.balanceOf(TokenSale.address,SaleStart)));
  console.log("Token: ",ToFloat(await TokenSale.balanceOf(owner.address)));

  //await Contract.withdraw(TokenSale.address,SaleStart);
  
  //TokenUSD.on("Transfer", (setter, NewGreeting, event)=> {   console.log("New Transfer is", NewGreeting);  })//ok
  
  console.log("----------withdraw----------------");
  var res=await Contract.withdrawCoins(TokenUSD.address);
  var res2=await res.wait();
  //console.log(res.hash);//JSON.stringify(res))
  //console.log(JSON.stringify(res2));
  //var receipt = hre.ethers.getTransactionReceipt(res.hash).then(console.log);
  //console.log(JSON.stringify(hre.ethers));
  
  
  
  console.log("USD:   ",ToFloat(await TokenUSD.balanceOf(owner.address)));


  
  
  return { owner, otherAccount, Contract, TokenUSD, TokenSale};
}




module.exports.deploySmarts = deploySmartVesting;


