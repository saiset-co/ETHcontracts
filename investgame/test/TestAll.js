const {
  time,
  loadFixture,
} = require("@nomicfoundation/hardhat-network-helpers");
const { anyValue } = require("@nomicfoundation/hardhat-chai-matchers/withArgs");
const { expect } = require("chai");


//const hre = require("hardhat");
const {deploySmarts}=require("../scripts/common.js");


describe("investgame", function () {

  describe("Deployment", function () {
    it("Check1", async function () {
      await loadFixture(deploySmarts);
      //const { owner, otherAccount, Contract, Voting} = await loadFixture(deploySmarts);
      //expect(await Contract.admin()).to.equal(owner.address);
    });

  });
});


