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
  await TokenUSD.Mint("1000000000000000000000");//1000
  await TokenSale.Mint("10000000000000000000000");//10000
  await TokenSale.transfer(Contract.address,"10000000000000000000000");//1000
  
  console.log("USD: ",ToFloat(await TokenUSD.balanceOf(owner.address)));
  console.log("Sale: ",ToFloat(await TokenSale.balanceOf(Contract.address)));
  
  await Contract.setCoin(TokenUSD.address,"1000000000000000000");

  var SaleStart="2000000000";
  await Contract.setSale(TokenSale.address,SaleStart,"10000000000","10000000000000000000000","1000000000000000000");

  console.log("----------buy----------------");
  console.log("1 USD: ",ToFloat(await TokenUSD.balanceOf(owner.address)));
  await TokenUSD.approve(Contract.address,"1000000000000000000000");
  await Contract.buyToken(TokenSale.address,SaleStart,TokenUSD.address,"200000000000000000000");//200
  console.log("Buy  : ",ToFloat(await TokenSale.balanceOf(owner.address)));
  console.log("2 USD: ",ToFloat(await TokenUSD.balanceOf(owner.address)));

  //await Contract.setValue(");
  //console.log("Get :",ToString(await Contract.getValue()));


  return { owner, otherAccount, Contract, TokenUSD, TokenSale};
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


module.exports.deploySmarts = deploySmarts;
module.exports.deploySmarts = deploySmartsTest;
//module.exports.deploySmarts=deployMumbai;


