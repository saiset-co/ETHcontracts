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
  console.log("Account befor balance:", (await owner.getBalance()).toString());

  const Contract = await StartDeploy("SaiSaleVesting");
  const TokenUSD = await StartDeploy("USDTest");
  const TokenSale = await StartDeploy("USDTest");

  console.log("Owner:", (await Contract.owner()).toString());

  console.log("Account after balance:", (await owner.getBalance()).toString());
  return { owner, otherAccount, Contract, TokenUSD, TokenSale};
}

async function deploySmartsTest() {

  const { owner, otherAccount, Contract, TokenUSD, TokenSale} = await deploySmarts();
  //console.log("FromSum18(1)=",FromSum18(1));
  await TokenUSD.Mint(FromSum18(1000));
  await TokenSale.Mint(FromSum18(5000));
  await TokenSale.transfer(Contract.address,FromSum18(5000));
  
  console.log("USD: ",ToFloat(await TokenUSD.balanceOf(owner.address)));
  console.log("Sale: ",ToFloat(await TokenSale.balanceOf(Contract.address)));
  
  var Rate =FromSum18(1);
  var Price=Rate;
  await Contract.setCoin(TokenUSD.address,Rate);


  var SaleStart=(await Contract.currentBlock())>>>0;
  var Vesting = SaleStart + 2;
  console.log("SaleStart:",SaleStart);
  await Contract.setSale(TokenSale.address, FromSum18(5000), Price, SaleStart,SaleStart+10,Vesting);
  console.log("Sale info:",ToString(await Contract.getSale(TokenSale.address,SaleStart)));
  
  console.log("Block:",ToString(await Contract.currentBlock()));

  console.log("----------buy----------------");
  console.log("1 USD: ",ToFloat(await TokenUSD.balanceOf(owner.address)));
  await TokenUSD.approve(Contract.address,FromSum18(1000));
  
  //SaleStart="1000000001";
  await Contract.buyToken(TokenSale.address,SaleStart,TokenUSD.address,FromSum18(200));
  console.log("2 USD: ",ToFloat(await TokenUSD.balanceOf(owner.address)));
  console.log("Balance",ToFloat(await Contract.balanceOf(TokenSale.address,SaleStart)));
  console.log("Token: ",ToFloat(await TokenSale.balanceOf(owner.address)));
/*
  console.log("----------pause----------------");
  await TokenUSD.Mint(0);
  console.log("Block:",ToString(await Contract.currentBlock()));
  await sleep(1000);
  await TokenUSD.Mint(0);
  console.log("Block:",ToString(await Contract.currentBlock()));
*/



  console.log("----------withdraw client----------------");
  await Contract.withdraw(TokenSale.address,SaleStart);
  //return { owner, otherAccount, Contract, TokenUSD, TokenSale};

  
  console.log("Balance",ToFloat(await Contract.balanceOf(TokenSale.address,SaleStart)));
  console.log("Token: ",ToFloat(await TokenSale.balanceOf(owner.address)));

  
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


