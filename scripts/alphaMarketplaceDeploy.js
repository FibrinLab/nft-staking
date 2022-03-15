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
    '0x608fc138642be366dfa77b13d68c29fd6dc636a1',// nft token address
    '0x618711478689a68aa547480c2d9ba72fbfc31774',// royalty distributor address
    10000,// total supply of nfts
    '0x325a98f258a5732c7b06555603f6af5bc1c17f0a'// alpha erc20 token
  ]

  // const AlphaMarketplace = await hre.ethers.getContractFactory('AlphaNodesNFTMarketPlace');

  // const AlphaMarketplaceContract = await AlphaMarketplace.deploy(
  //   '0x608fc138642be366dfa77b13d68c29fd6dc636a1',// nft token address
  //   '0x618711478689a68aa547480c2d9ba72fbfc31774',// royalty distributor address
  //   10000,// total supply of nfts
  //   '0x325a98f258a5732c7b06555603f6af5bc1c17f0a'// alpha erc20 token
  // );

  // await AlphaMarketplaceContract.deployed();
  
  // console.log("contract deployed to:", AlphaMarketplaceContract.address);

  await hre.run("verify:verify", {
    address: '0xA5FB76f49F86A3FE799574D129690f76be182E7a',
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

//  npx hardhat run --network fuji scripts/alphaMarketplaceDeploy.js