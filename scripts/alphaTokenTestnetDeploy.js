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

  const ALPHAToken = await hre.ethers.getContractFactory('ALPHA');

  const alphaTokenContract = await ALPHAToken.deploy();

  await alphaTokenContract.deployed();
  
  console.log("contract deployed to:", alphaTokenContract.address);

  await hre.run("verify:verify", {
    address: alphaTokenContract.address,
    constructorArguments: contractConstuctorArgs
  })

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

//  npx hardhat run --network fuji scripts/alphaTokenTestnetDeploy.js