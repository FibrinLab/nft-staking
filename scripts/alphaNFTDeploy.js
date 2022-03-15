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
  const contractConstuctorArgs = []

  const ALPHANFT = await hre.ethers.getContractFactory('ALPHANFT');

  const ALPHANFTContract = await ALPHANFT.deploy();

  await ALPHANFTContract.deployed();
  
  console.log("contract deployed to:", ALPHANFTContract.address);

  // await hre.run("verify:verify", {
  //   address: ALPHANFTContract.address,
  //   constructorArguments: contractConstuctorArgs
  // })

}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });

// npx hardhat run --network fuji scripts/alphaNFTDeploy.js
// npx hardhat run --network http://127.0.0.1:8545 scripts/alphaNFTDeploy.js
// npx hardhat run --network localhost scripts/alphaNFTDeploy.js