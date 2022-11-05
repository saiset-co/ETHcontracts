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

  console.log("Owner:", (await Contract.owner()).toString());

  console.log("Account after balance:", (await owner.getBalance()).toString());
  return { owner, otherAccount, Contract};
}

async function deploySmartsTest() {

  const { owner, otherAccount, Contract} = await deploySmarts();
  //await Contract.doFindValue(1);
  //return { owner, otherAccount, Contract};

  
  
  //await Contract.setValue(");
  //console.log("Get :",ToString(await Contract.getValue()));


  return { owner, otherAccount, Contract};
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


