const hre = require("hardhat");
require("./env-lib.js")

const { time } = require("@nomicfoundation/hardhat-network-helpers");




async function deploySmarts() {


  const [owner, otherAccount] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", owner.address);
  console.log("Account befor balance:", ToFloat(await owner.getBalance()));

  const TokenUDS = await StartDeploy("UDSTest");
  const TokenUGOLD = await StartDeploy("UGOLDTest");
  const AMM = await StartDeploy("UniswapV2AMM",TokenUDS.address,TokenUGOLD.address);
 

  console.log("Account after balance:", ToFloat(await owner.getBalance()));
  return { owner, otherAccount, TokenUDS, TokenUGOLD, AMM};
}


async function testAMM()
{
  const { owner, otherAccount, TokenUDS, TokenUGOLD, AMM} = await deploySmarts();
  var Start=(await time.latest())>>>0;
  console.log("--------------------Start:",Start);
  

  console.log("--------------------Mint");
  await (await TokenUDS.Mint(FromSum18(2e6))).wait();
  //await (await TokenUDS.transfer(AMM.address,FromSum18(50e6))).wait();
  await (await TokenUGOLD.Mint(FromSum18(2e6))).wait();
  await (await TokenUDS.approve(AMM.address,FromSum18(10e6))).wait();
  await (await TokenUGOLD.approve(AMM.address,FromSum18(10e6))).wait();

  await (await TokenUDS.connect(otherAccount).Mint(FromSum18(1e6))).wait();
  await (await TokenUDS.connect(otherAccount).approve(AMM.address,FromSum18(10e6))).wait();
  await (await TokenUGOLD.connect(otherAccount).Mint(FromSum18(1e6))).wait();
  await (await TokenUGOLD.connect(otherAccount).approve(AMM.address,FromSum18(10e6))).wait();
  

  console.log("--------------------addLiquidity");
  var TimeTo=100+(await time.latest())>>>0;
  await (await AMM.addLiquidity(TokenUDS.address,TokenUGOLD.address,FromSum18(1.1e6),FromSum18(1.1e6),0,0,owner.address,TimeTo)).wait();
  console.log("LP Token: ",ToFloat(await AMM.balanceOf(owner.address)));

  console.log("--------------------addLiquidity2");
  await (await AMM.setAllowForAll(true)).wait();
  await (await AMM.connect(otherAccount).addLiquidity(TokenUDS.address,TokenUGOLD.address,FromSum18(0.1e6),FromSum18(1.1e6),0,0,otherAccount.address,TimeTo)).wait();
  console.log("LP Token: ",ToFloat(await AMM.balanceOf(otherAccount.address)));

  console.log("--------------------removeLiquidity");
  //await (await AMM.approve(owner.address,FromSum18(10e6))).wait();
  await (await AMM.removeLiquidity(TokenUDS.address,TokenUGOLD.address,FromSum18(1e5),0,0,owner.address,TimeTo)).wait();
  console.log("LP Token: ",ToFloat(await AMM.balanceOf(owner.address)));


  await (await AMM.setFee(TokenUDS.address,3)).wait();
  await (await AMM.setFee(TokenUGOLD.address,5)).wait();
  //*
  console.log("--------------------swap");
  console.log("   UDS  : ",ToFloat(await TokenUDS.balanceOf(owner.address)));
  console.log("   UGOLD: ",ToFloat(await TokenUGOLD.balanceOf(owner.address)));
  await (await AMM.swapTokensForExactTokens(FromSum18(1e3),FromSum18(2e3),[TokenUDS.address,TokenUGOLD.address],owner.address,TimeTo)).wait();
  
  await (await AMM.swapExactTokensForTokens(FromSum18(1e3),0,[TokenUDS.address,TokenUGOLD.address],owner.address,TimeTo)).wait();
  console.log("   UDS  : ",ToFloat(await TokenUDS.balanceOf(owner.address)));
  console.log("   UGOLD: ",ToFloat(await TokenUGOLD.balanceOf(owner.address)));

  //return;
  await (await AMM.swapExactTokensForTokens(FromSum18(1e3),0,[TokenUGOLD.address,TokenUDS.address],owner.address,TimeTo)).wait();
  console.log("   UDS  : ",ToFloat(await TokenUDS.balanceOf(owner.address)));
  console.log("   UGOLD: ",ToFloat(await TokenUGOLD.balanceOf(owner.address)));
//*/
  console.log("--------------------swap2");
  await (await AMM.connect(otherAccount).swapExactTokensForTokens(FromSum18(1e3),0,[TokenUDS.address,TokenUGOLD.address],otherAccount.address,TimeTo)).wait();
  console.log("   UDS  : ",ToFloat(await TokenUDS.balanceOf(otherAccount.address)));
  console.log("   UGOLD: ",ToFloat(await TokenUGOLD.balanceOf(otherAccount.address)));
  await (await AMM.connect(otherAccount).swapTokensForExactTokens(FromSum18(1e3),FromSum18(2e3),[TokenUGOLD.address,TokenUDS.address],otherAccount.address,TimeTo)).wait();
  console.log("   UDS  : ",ToFloat(await TokenUDS.balanceOf(otherAccount.address)));
  console.log("   UGOLD: ",ToFloat(await TokenUGOLD.balanceOf(otherAccount.address)));


  console.log("--------------------removeLiquidity next");
  await (await AMM.removeLiquidity(TokenUDS.address,TokenUGOLD.address,FromSum18(1e5),0,0,owner.address,TimeTo)).wait();
  console.log("LP Token: ",ToFloat(await AMM.balanceOf(owner.address)));
  console.log("   UDS  : ",ToFloat(await TokenUDS.balanceOf(owner.address)));
  console.log("   UGOLD: ",ToFloat(await TokenUGOLD.balanceOf(owner.address)));

}



module.exports.deploySmarts = testAMM;


