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

  const Contract = await StartDeploy("SaiOracle");

  console.log("Owner:", (await Contract.owner()).toString());

  console.log("Account after balance:", (await owner.getBalance()).toString());
  return { owner, otherAccount, Contract};
}

async function deploySmartsTest() {

  const { owner, otherAccount, Contract} = await deploySmarts();
  //await Contract.doFindValue(1);
  //return { owner, otherAccount, Contract};

  
  
  //await Contract.setIntervalDegree(32);
  
  /*
  var Key=await Contract.getTimeStamp();
  Key=Key>>>0;

  
  await Contract.setValue("{=Meta1:1000=}");
  await Contract.setValue("{Meta2:2000}");
  await Contract.setValue("{Meta3:3000}");
  await Contract.setValue("{Meta4:4000}");
  

  console.log("Key:",ToString(Key),Key%256);
  var Key2=(await Contract.getTimeStamp())>>>0;
  console.log("Get :",ToString(await Contract.getValue(Key2-3)));
  console.log("Find0:",ToString(await Contract.findValue0(Key2-1)));
  console.log("Find :",ToString(await Contract.findValue(Key2-1)));
  await Contract.doFindValue(Key2-1);
*/
  
  console.log("----------test--------------");
  //await Contract.setKeyValue(0x0100,"{Test1}");
  await Contract.setKeyValue(0x01000105,"{Test1}");
  await Contract.setKeyValue(0x01010307,"{Test2}");
  await Contract.setKeyValue(0x01010608,"{Test3}");
  
  //await Contract.setKeyValue(0x0020000000,"{0x0020000000}");
  //await Contract.setKeyValue(0x0200000002,"{Test5}");
  //await Contract.setKeyValue(0x0200000004,"{Test6}");
  
  var Key=0x01010607;
  console.log("Get :",ToString(await Contract.getValue(Key)));
  console.log("Find :",ToString(await Contract.findValue(Key)));
  
  //await Contract.doFindValue(Key);
  //await Contract.doFindValue(Key+1);
  //await Contract.doFindValue(Key+7);
  
  //1667332174
  //1667332185

  return { owner, otherAccount, Contract};
}

/*
async function deploySmarts2() {
  const [owner, otherAccount] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", owner.address);
  console.log("Account befor balance:", (await owner.getBalance()).toString());

  
  const Certificate = await hre.ethers.getContractAt("Certificate", "0x8fbe360A78c12E60EA8318bD64F27289290AFC22",owner);
  return { owner, otherAccount, Certificate, Governance, Staking, Token, Metable, Course, Tickets };
}


async function deployMumbai() {
  const { owner, otherAccount, Certificate, Governance, Staking, Token, Metable, Course, Tickets } = await deploySmarts2();
  const Metable2 = await hre.ethers.getContractAt("Metable", Metable.address, otherAccount);
  return { owner, otherAccount, Certificate, Governance, Staking, Token, Metable, Course, Tickets };
}
//*/



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


