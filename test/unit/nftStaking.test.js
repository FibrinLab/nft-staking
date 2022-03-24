const { expect } = require("chai");
const { ethers } = require("hardhat");

const ADMIN_ROLE = "ADMIN_ROLE";
const ddAddress = '0xf39fd6e51aad88f6f4ce6ab8827279cfffb92266';

describe("Alpha Staking", function() {
    before("Should verify the admin",async () => {
        const Staking = await ethers.getContractFactory("nftStaking");
        const staking = await Staking.deploy();
        dstake = await staking.deployed();
    });

    beforeEach(async function() {
        await dstake.grantRole(ADMIN_ROLE, ddAddress);
    });

    it('Deploying address has admin role', async function() {
        expect((await dstake.hasRole(ethers.utils.parseBytes32String(ADMIN_ROLE), ddAddress)).to.equal('true'))
    });
})