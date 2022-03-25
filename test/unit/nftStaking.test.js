const { expect, assert } = require("chai");
const { ethers } = require("hardhat");
const { time } = require("@openzeppelin/test-helpers");
const {
    isCallTrace,
  } = require("hardhat/internal/hardhat-network/stack-traces/message-trace");

const ADMIN_ROLE = "ADMIN_ROLE";
const ddAddress = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266';

describe("Alpha Staking", function() {
    let alphaStaking;
    let ALPHAStaking;
    let owner;
    let addr1;
    let addr2;
    let minter;
    let addrs;
    let ERC20Mock;
    let NFT;
    let nft;
    let stakeToken;

    beforeEach("Should verify the admin",async () => {
        ALPHAStaking = await ethers.getContractFactory("alphaStaking");
        [
            owner, 
            // addr1,
            // addr2,
            minter,
            ...addrs
        ] = await ethers.getSigners();
        ERC20Mock = await ethers.getContractFactory("ERC20Mock", minter);
        stakeToken = await ERC20Mock.deploy("Alpha", "APL", "10000000000");
        NFT = await ethers.getContractFactory("NFT", minter);
        nft = await NFT.deploy("AlphaNFT", "ANFT");
        // const staking = await Staking.deploy();
        // dstake = await staking.deployed();

        alphaStaking = await ALPHAStaking.deploy(stakeToken.address, nft.address);        
    });

    describe("Deployment", function() {
        it("Should set the correct owner", async function() {
            expect(await alphaStaking.owner()).to.equal(owner.address);
        });

        it("Should set correct state variables", async function () {
            expect(await alphaStaking.stakeToken()).to.equal(stakeToken.address);
            expect(await alphaStaking.nft()).to.equal(nft.address);
        });
    })

    // beforeEach(async function() {
    //     await dstake.grantRole(ADMIN_ROLE, ddAddress);
    // });

    // it('Deploying address has admin role', async function() {
    //     expect((await dstake.hasRole(ethers.utils.parseBytes32String(ADMIN_ROLE), ddAddress)).to.equal('true'))
    // });
})