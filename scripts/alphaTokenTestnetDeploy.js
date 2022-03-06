require("@nomiclabs/hardhat-etherscan");
// We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

async function main() {
  // Hardhat always runs the compile task when running scripts with its command
  // line interface.
  //
  // If this script is run directly using `node` you may want to call compile
  // manually to make sure everything is compiled
  // await hre.run('compile');

  // We get the contract to deploy
  const contractConstuctorArgs = [
    // '0x60aE616a2155Ee3d9A68541Ba4544862310933d4', // router
    // '0xb97ef9ef8734c71904d8002f8b6bc66dd9c48a6e' // dividend token
  ]

  const TestNFT = await hre.ethers.getContractFactory('ALPHANodeNFT');
  
  const NFTMarketplace = await hre.ethers.getContractFactory('MagicGameMarketplace');
  
  const nftContract = await TestNFT.deploy();

  await nftContract.deployed();

  const marketPlacecontract = await NFTMarketplace.deploy(nftContract.address);

  // console.log("contract deployed to:", contract.address);

  // await hre.run("verify:verify", {
  //   address: contract.address,
  //   constructorArguments: contractConstuctorArgs
  // })

  console.log(' NFT contract address : ', nftContract.address)
  console.log(' marketplace contract address : ', marketPlacecontract.address)

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
