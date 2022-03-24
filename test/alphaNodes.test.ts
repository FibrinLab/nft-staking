const { expect } = require("chai");
const { ethers } = require("hardhat");
 
const accountAddress = '0x290D41a4A585e4b2EC53C9563363a3F076856e8e'

describe("Alpha Nodes", function () {
  before(async function() {
    const DDAddress = '0x441Dc67bf945c4D886bB20e589eccD8A86E9109B'
    this.DividendDistributor = await ethers.getContractAt('DividendDistributor', DDAddress)
    this.AlphaToken = await ethers.getContractAt('ALPHATEST4', alphaTokenAddress)
    this.ALPHAPrinter = await ethers.getContractFactory("ALPHAPrinter");
  })

  beforeEach(async function() {
    let me = await this.AlphaToken.balanceOf(accountAddress)
    console.log(me)
    this.printerContract = await this.ALPHAPrinter.deploy();
    await this.printerContract.deployed();
    await this.AlphaToken.approve(accountAddress, '1000000000000000000000000')
    // await this.AlphaToken.approve(this.printerContract.address, '1000000000000000000000000')
    // await this.AlphaToken.setFree(this.printerContract.address);
    // await this.AlphaToken.setFree(this.printerContract.address);
    // const filPrinterTx = await this.AlphaToken.transferFrom(accountAddress, this.printerContract.address, '10000000');
    // await filPrinterTx.wait();
    
  })

  it("Should work", async function() {
    // // let unpaid = await this.DividendDistributor.getUnpaidEarnings(accountAddress)
    // console.log(unpaid)
    // // await this.DividendDistributor.claimDividend();
    // await this.printerContract.printToken('0x83a283641C6B4DF383BCDDf807193284C84c5342')
    // unpaid = await this.DividendDistributor.getUnpaidEarnings(accountAddress)
    // console.log(unpaid)
  })

  // it("Should be able to set launched property on contract", async function () {
  //   let launched = await this.alphaToken.launched();
  //   expect(await this.alphaToken.launched()).to.equal(false);
  //   const launchTx = await this.alphaToken.launch();

  //   // // wait until the transaction is mined
  //   await launchTx.wait();
  //   launched = await this.alphaToken.launched();
  //   expect(await this.alphaToken.launched()).to.equal(true);
  // });

  // it("Should return total fee:", async function () {
  //   let totalFee = await this.alphaToken.getTotalFee();
  //   console.log('total fee : ', totalFee)
  //   expect(await this.alphaToken.getTotalFee()).to.equal(1800);    
  // });

  // it("Should return LP backing:", async function () {
  //   let getLiquidityBacking = await this.alphaToken.getLiquidityBacking(1);
  //   console.log('getLiquidityBacking : ', getLiquidityBacking)
  //   expect(await this.alphaToken.getLiquidityBacking(1)).to.not.equal(1);    
  // });

  // it("Should return Total Supply:", async function () {
  //   let totalSupply = await this.alphaToken.totalSupply();
  //   console.log('totalSupply : ', totalSupply)
  //   expect(await this.alphaToken.totalSupply()).to.equal(1000000000000000000000000);    
  // });

  // it("Should return Token Decimals:", async function () {
  //   let totalSupply = await this.alphaToken.totalSupply();
  //   console.log('totalSupply : ', totalSupply)
  //   expect(await this.alphaToken.totalSupply()).to.equal(1000000000000000000000000);    
  // });

  // it("Should require swap back time lock to be greater than or equal to zero", async function() {
  //   await this.printerContract.setSwapBackTimeLock(1);
  //   let swapTimeLock = await this.alphaToken.swapTimeLock();
  //   console.log('swapTimeLock : ', swapTimeLock)
  //   expect(swapTimeLock).to.equal(60) // should equal 60 seconds
  // })
  
});
