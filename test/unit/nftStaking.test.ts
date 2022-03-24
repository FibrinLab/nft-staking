const { expect } = require("chai");
const { ether } = require("hardhat");

describe("Alpha Staking", function() {
    it("Should verify the admin",async () => {
        const Staking = ethers.getContractFactory("nftStaking");
        const staking = Staking.deploy();
        await staking.deployed();

        expect(await staking.)
    })
})