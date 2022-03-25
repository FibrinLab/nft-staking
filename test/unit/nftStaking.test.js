const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@openzeppelin/test-helpers")

const ADMIN_ROLE = "ADMIN_ROLE";
const ddAddress = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266';

describe("Alpha Staking", function() {

    this.beforeEach("Should verify the admin",async () => {
        const Staking = await ethers.getContractFactory("nftStaking");
        [
            owner, 
            addr1,
            addr2,
            minter,
            ...addrs
        ] = await ethers.getSigners();
        ERC20Mock = await ethers.getContractFactory("ERC20Mock", minter);
        stakeToken = await ERC20Mock.deploy("Alpha", "APL", "10000000000");
        NFT = await ethers.getContractFactory("NFT", minter);
        nft = await NFT.deploy("AlphaNFT", "ANFT");
        const staking = await Staking.deploy();
        dstake = await staking.deployed();

        
    });

    // beforeEach(async function() {
    //     await dstake.grantRole(ADMIN_ROLE, ddAddress);
    // });

    // it('Deploying address has admin role', async function() {
    //     expect((await dstake.hasRole(ethers.utils.parseBytes32String(ADMIN_ROLE), ddAddress)).to.equal('true'))
    // });
})