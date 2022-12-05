const hre = require("hardhat");
require("./env-lib.js");

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
/*
async function deploySmart0() {

  const [owner, otherAccount] = await hre.ethers.getSigners();
  console.log("-->", owner.address, hre.ethers.Wallet.isSigner(owner));

  console.log("Deploying contracts with the account:", owner.address);
  console.log("Account befor balance:", (await owner.getBalance()).toString());


  const Certificate = await StartDeploy("Certificate");
  return { Certificate };
}
//*/
async function deploySmarts() {
  const [owner, otherAccount] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", owner.address);
  console.log("Account befor balance:", (await owner.getBalance()).toString());

  const Certificate = await StartDeploy("Certificate");

  const Governance = await StartDeploy("GovernanceToken");
  const Staking = await StartDeploy("Staking", Governance.address);
  const Token = await StartDeploy("GameToken");

  const Course = await StartDeploy("CoursesNFT");
  const Metable = await StartDeploy("Metable", Token.address, Course.address);

  const Tickets = await StartDeploy("Tickets", Metable.address, Token.address, Course.address);

  await Governance.setSmart(Staking.address);
  await Token.setSmart(Metable.address);
  await Token.setSmart(Tickets.address);

  //await Metable.setCourse(Course.address);


  //console.log("Owner:", (await Course.owner()).toString());

  console.log("Account after balance:", (await owner.getBalance()).toString());
  return { owner, otherAccount, Certificate, Governance, Staking, Token, Metable, Course, Tickets };
}

async function deploySmarts2() {
  const [owner, otherAccount] = await hre.ethers.getSigners();
  console.log("Deploying contracts with the account:", owner.address);
  console.log("Account befor balance:", (await owner.getBalance()).toString());

  
  const Certificate = await hre.ethers.getContractAt("Certificate", "0x8fbe360A78c12E60EA8318bD64F27289290AFC22",owner);
  const Governance = await hre.ethers.getContractAt("GovernanceToken", "0x34CfDFFec1241bE03976E5B0D07F2c69569DE697",owner);
  const Staking = await hre.ethers.getContractAt("Staking", "0xc8E45df1bD9F803bA2bBbd386b6d3D5a854293A8",owner);
  const Token = await hre.ethers.getContractAt("GameToken", "0xC01616cA82596128887368D5BcDA17e15E57e13e",owner);

  
  const Course = await hre.ethers.getContractAt("CoursesNFT", "0x5fB589b1b4e7129a3747C2786a2AD668cC0E7eb8",owner);
  const Metable = await hre.ethers.getContractAt("Metable", "0x4c504A8FBA715b05512eff6AC25934DFDc34373c",owner);
  const Token2 = await hre.ethers.getContractAt("GameToken", Token.address, otherAccount);
  const Tickets = await hre.ethers.getContractAt("Tickets", "0x2D4013b69fbeDaDAE381FC59bfa0Bb45B73DC0B4",owner);

  //await Governance.setSmart(Staking.address);
  //await Token.setSmart(Metable.address);
  //await Token.setSmart(Tickets.address);

  //await Metable.setCourse(Course.address);


  //console.log("Owner:", (await Course.owner()).toString());

  console.log("Account after balance:", (await owner.getBalance()).toString());
  return { owner, otherAccount, Certificate, Governance, Staking, Token, Metable, Course, Tickets };
}

async function deployMumbai() {
  const { owner, otherAccount, Certificate, Governance, Staking, Token, Metable, Course, Tickets } = await deploySmarts2();

  const Metable2 = await hre.ethers.getContractAt("Metable", Metable.address, otherAccount);
  const Course2 = await hre.ethers.getContractAt("CoursesNFT", Course.address, otherAccount);
  const Tickets2 = await hre.ethers.getContractAt("Tickets", Tickets.address, otherAccount);
  const Token2 = await hre.ethers.getContractAt("GameToken", Token.address, otherAccount);

  var PriceToken = 1 * 1e9;
  //await Token.Mint("1000000000000000000000");
  console.log("totalSupply:", ToFloat(await Token.totalSupply()));
  //await Token.MintTo(owner.address,20);
  //await Token.setSale("500000000000000000000", PriceToken);
  //await Token.buyToken({ value: 200 * PriceToken });
  console.log("Tokens 1:", ToFloat(await Token.balanceOf(owner.address)));



  var PriceSale = "30000000000000000000";
  var PriceRent = "5000000000000000000";

  const LAND = "land";
  const BUILD = "build";
  var Meta1 = JSON.stringify({ name: "Tile", description: "Genesis item" });
  //Meta1="";
  await Metable.Mint(LAND, "land", Meta1, 2,0, PriceSale,1);//1
  await Metable.Mint(LAND, "land", Meta1, 3,0, PriceSale,1);//2

  var Meta3 = JSON.stringify({ name: "Oxford", description: "University of Oxford" });
  var Meta4 = JSON.stringify({ name: "Patrick Hospital", description: "St. Patrick Hospital and Health Sciences Center" });
  //Meta3="";Meta4="";

  /*
  console.log("=============Mints=============");
  await Metable.Mint(BUILD, "school", Meta3, 6,3, PriceSale,1);//3
  await Metable.Mint(BUILD, "hospital", Meta4, 8,2, PriceSale,1);//4
  await Metable.Mint(BUILD, "hospital", Meta4, 8,0, PriceSale,1);//5
  await Metable.Mint(BUILD, "school", Meta3, 6,0, PriceSale,1);//6

  await Metable.buyNFT(2);//land
  await Metable.buyNFT(3);//school
  await Metable.buyNFT(4);//hospital
  

  //link hospitals to land
  await Metable.linkToNFT(3, 2);
  await Metable.linkToNFT(4, 2);


  console.log("Tokens:", ToFloat(await Token.balanceOf(owner.address)));
  console.log("=============Sale=============");
  await Metable.setSale(3, PriceSale);
  await Metable.setSale(4, PriceSale);
  console.log("Sale list:", (await Metable.listSale(0, 100)).toString());

  await Metable.buyNFT(3);
  await Metable.buyNFT(4);
  console.log("Tokens:", ToFloat(await Token.balanceOf(owner.address)));
  await Metable.withdrawToken();
  console.log("Tokens:", ToFloat(await Token.balanceOf(owner.address)));



  console.log("=============Rent Bid=============");
  var PriceRent = "1000000000000000000";
  await Metable.setRentBid(3, PriceRent, 10000,2);
  await Metable.setRentBid(3, PriceRent, 10000,3);
  await Metable.setRentBid(4, PriceRent, 10000,1);

  console.log("Rent bind list:", (await Metable.listRentBid(0, 100)).toString());
  

  //User
  console.log("=============User:",otherAccount.address);
  await Token2.buyToken({ value: 100 * PriceToken });
  console.log("Tokens 2:", ToFloat(await Token2.balanceOf(otherAccount.address)));

  console.log("=============Course2=============");
  await Course2.Mint("{number:1}");
  await Course2.Mint("{number:2}");
  console.log("ownerOf=",await Course2.ownerOf(1));


  console.log("=============buy rent=============");
  

  await Metable2.buyRentSchoolBid(3,1,0);
  await Metable2.buyRentSchoolBid(3,1,1);
  await Metable2.buyRentSchoolBid(3,2,2);
  //await Metable2.buyRentSchoolBid(3,3,1);
  await Metable2.buyRentBid(4,0);
  //await Metable2.buyRentBid(4,1);



  console.log("Tokens 2:", ToFloat(await Token2.balanceOf(otherAccount.address)));
  console.log("Rent bind list:", (await Metable.listRentBid(0, 100)).toString());

  //await Metable.setRentBid(3, PriceRent, 10000);

  var PriceTicket = "2000000000000000000";
    console.log("=============Tickets=============");
  await Tickets2.issueTickets(1,100,PriceTicket);

  await Metable2.buyNFT(6);//school
  await Tickets2.approveTickets(6,1);
  console.log("1 balanceOf:", ToString(await Tickets.balanceOf(Tickets.address,1)));

  await Tickets2.buyTickets(1,1);
  console.log("Tokens 1:", ToFloat(await Token2.balanceOf(owner.address)));
  await Tickets.buyTickets(1,1);
  console.log("Tokens 1:", ToFloat(await Token2.balanceOf(owner.address)));
  console.log("2 balanceOf:", ToString(await Tickets2.balanceOf(otherAccount.address,1)));
  console.log("1 balanceOf:", ToString(await Tickets.balanceOf(Tickets.address,1)));
  //console.log("Tokens:", (await Token.balanceOf(owner.address)).toString());
  //console.log("Owner:", (await Metable.owner()).toString());
  //console.log("Metable Owner:", (await Metable.ownerOf(3)).toString());
  //console.log("getMetadata:",await Metable.getMetadata(4));

  console.log("=============Rent Ask=============");
  await Metable2.setRentAsk(4, PriceRent, 10000);
  await Metable2.setRentAsk(4, PriceRent+1, 10000);
  console.log("1 Rent ask list:", (await Metable.listRentAsk(0, 100)).toString());
  await Metable2.removeRentAsk(4);
  await Metable2.setRentAsk(4, PriceRent, 10000);
  var ArrList = await Metable.listRentAsk(0, 100);
  console.log("Rent ask[0].Key:", (ArrList[0].Key).toString());
  
  console.log("Tokens 2:", ToFloat(await Token2.balanceOf(otherAccount.address)));
  console.log("Rents slots:", (await Metable.rentToken(4)).toString());
  await Metable.approveRentAsk(ArrList[0].Key, 1);
*/  
  console.log("Rents slots:", (await Metable.rentToken(4)).toString());
  console.log("2 Rent ask list:", (await Metable.listRentAsk(0, 100)).toString());
  console.log("Tokens 2:", ToFloat(await Token2.balanceOf(otherAccount.address)));
  
/*
  console.log("=============Tokens buy=============");
  console.log("Tokens:", ToFloat(await Token.balanceOf(owner.address)));
  var PriceUSD = "2000000000000000000";
  await Token.setSmartSale(Token.address,PriceUSD);
  
  await Token.approve(Token.address,"100000000000000000000");
  await Token.buyToken2(Token.address,"20000000000000000000");
  console.log("Tokens:", ToFloat(await Token.balanceOf(owner.address)));
  */  

  return { owner, otherAccount, Certificate, Governance, Staking, Token, Metable, Course, Tickets };

}


async function deploySmartsTest() {


  const { owner, otherAccount, Certificate, Governance, Staking, Token, Metable, Course, Tickets } = await deploySmarts();

  await Certificate.Mint(owner.address, 1);
  var id = (1n << 48n) + 1n;
  console.log("ownerOf:", id, (await Certificate.ownerOf(id)));


  var PriceToken = 1 * 1e9;
  await Token.Mint("1000000000000000000000");
  console.log("totalSupply:", ToFloat(await Token.totalSupply()));
  //await Token.MintTo(owner.address,20);
  await Token.setSale("500000000000000000000", PriceToken);
  await Token.buyToken({ value: 200 * PriceToken });
  console.log("Tokens 1:", ToFloat(await Token.balanceOf(owner.address)));

  console.log("=============Mints=============");

  var PriceSale = "30000000000000000000";
  const LAND = "land";
  const BUILD = "build";
  var Meta1 = JSON.stringify({ name: "Tile", description: "Genesis item" });
  Meta1="";
  await Metable.Mint(LAND, "land", Meta1, 2,0, PriceSale,1);//1
  await Metable.Mint(LAND, "land", Meta1, 3,0, PriceSale,1);//2

  var Meta3 = JSON.stringify({ name: "Oxford", description: "University of Oxford" });
  var Meta4 = JSON.stringify({ name: "Patrick Hospital", description: "St. Patrick Hospital and Health Sciences Center" });
  Meta3="";Meta4="";

  await Metable.Mint(BUILD, "school", Meta3, 6,3, PriceSale,1);//3
  await Metable.Mint(BUILD, "hospital", Meta4, 8,2, PriceSale,1);//4
  await Metable.Mint(BUILD, "hospital", Meta4, 8,0, PriceSale,1);//5
  await Metable.Mint(BUILD, "school", Meta3, 6,0, PriceSale,1);//6


  await Metable.buyNFT(2);//land
  await Metable.buyNFT(3);//school
  await Metable.buyNFT(4);//hospital
  

  //link hospitals to land
  await Metable.linkToNFT(3, 2);
  await Metable.linkToNFT(4, 2);


  console.log("Tokens:", ToFloat(await Token.balanceOf(owner.address)));
  console.log("=============Sale=============");
  await Metable.setSale(3, PriceSale);
  await Metable.setSale(4, PriceSale);
  console.log("Sale list:", (await Metable.listSale(0, 100)).toString());

  await Metable.buyNFT(3);
  await Metable.buyNFT(4);
  console.log("Tokens:", ToFloat(await Token.balanceOf(owner.address)));
  await Metable.withdrawToken();
  console.log("Tokens:", ToFloat(await Token.balanceOf(owner.address)));


  console.log("=============Rent Bid=============");
  var PriceRent = "1000000000000000000";
  //await Metable.setRentBid(3, PriceRent, 10000,2);
  await Metable.setRentBid(3, PriceRent, 10000,3);
  await Metable.setRentBid(4, PriceRent, 10000,1);
  console.log("Rent bind list:", (await Metable.listRentBid(0, 100)).toString());
  

  //User
  console.log("=============User:",otherAccount.address);
  const Token2 = await hre.ethers.getContractAt("GameToken", Token.address, otherAccount);
  await Token2.buyToken({ value: 100 * PriceToken });
  console.log("Tokens 2:", ToFloat(await Token2.balanceOf(otherAccount.address)));
  const Metable2 = await hre.ethers.getContractAt("Metable", Metable.address, otherAccount);

  console.log("=============Course2=============");
  const Course2 = await hre.ethers.getContractAt("CoursesNFT", Course.address, otherAccount);
  await Course2.Mint("{number:1}");
  await Course2.Mint("{number:2}");
  console.log("ownerOf=",await Course2.ownerOf(1));

  console.log("=============buy rent=============");
  

  await Metable2.buyRentSchoolBid(3,1,0);
  await Metable2.buyRentSchoolBid(3,1,1);
  await Metable2.buyRentSchoolBid(3,2,2);
  //await Metable2.buyRentSchoolBid(3,3,1);
  await Metable2.buyRentBid(4,0);
  //await Metable2.buyRentBid(4,1);
  console.log("Tokens 2:", ToFloat(await Token2.balanceOf(otherAccount.address)));
  console.log("Rent bind list:", (await Metable.listRentBid(0, 100)).toString());

  //await Metable.setRentBid(3, PriceRent, 10000);

  var PriceTicket = "2000000000000000000";
    console.log("=============Tickets=============");
  const Tickets2 = await hre.ethers.getContractAt("Tickets", Tickets.address, otherAccount);
  await Tickets2.issueTickets(1,100,PriceTicket);

  await Metable2.buyNFT(6);//school
  await Tickets2.approveTickets(6,1);
  console.log("1 balanceOf:", ToString(await Tickets.balanceOf(Tickets.address,1)));
  await Tickets2.buyTickets(1,1);
  console.log("Tokens 1:", ToFloat(await Token2.balanceOf(owner.address)));
  await Tickets.buyTickets(1,1);
  console.log("Tokens 1:", ToFloat(await Token2.balanceOf(owner.address)));
  console.log("2 balanceOf:", ToString(await Tickets2.balanceOf(otherAccount.address,1)));
  console.log("1 balanceOf:", ToString(await Tickets.balanceOf(Tickets.address,1)));
  //console.log("Tokens:", (await Token.balanceOf(owner.address)).toString());
  //console.log("Owner:", (await Metable.owner()).toString());
  //console.log("Metable Owner:", (await Metable.ownerOf(3)).toString());
  //console.log("getMetadata:",await Metable.getMetadata(4));

  console.log("=============Rent Ask=============");
  var PriceRent = "5000000000000000000";
  //await Metable2.setRentAsk(4, PriceRent, 10000);
  await Metable2.setRentAsk(4, PriceRent+1, 10000);
  console.log("1 Rent ask list:", (await Metable.listRentAsk(0, 100)).toString());
  await Metable2.removeRentAsk(4);
  await Metable2.setRentAsk(4, PriceRent, 10000);
  var ArrList = await Metable.listRentAsk(0, 100);
  console.log("Rent ask[0].Key:", (ArrList[0].Key).toString());
  
  console.log("Tokens 2:", ToFloat(await Token2.balanceOf(otherAccount.address)));
  console.log("Rents slots:", (await Metable.rentToken(4)).toString());
  await Metable.approveRentAsk(ArrList[0].Key, 1);
  console.log("Rents slots:", (await Metable.rentToken(4)).toString());
  console.log("2 Rent ask list:", (await Metable.listRentAsk(0, 100)).toString());
  console.log("Tokens 2:", ToFloat(await Token2.balanceOf(otherAccount.address)));
  

  console.log("=============Tokens buy=============");
  console.log("Tokens:", ToFloat(await Token.balanceOf(owner.address)));
  var PriceUSD = "2000000000000000000";
  await Token.setSmartSale(Token.address,PriceUSD);
  
  await Token.approve(Token.address,"100000000000000000000");
  await Token.buyToken2(Token.address,"20000000000000000000");
  console.log("Tokens:", ToFloat(await Token.balanceOf(owner.address)));
    

  return { owner, otherAccount, Certificate, Governance, Staking, Token, Metable, Course, Tickets };
}



module.exports.deploySmarts = deploySmarts;
module.exports.deploySmarts = deploySmartsTest;
//module.exports.deploySmarts=deployMumbai;


