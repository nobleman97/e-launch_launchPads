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
  const tateStaking2 = await hre.ethers.getContractFactory("tateStaking2");
  const _tateStaking2 = await tateStaking2.deploy("0x09924d7C4f6aA63baedd23b04BdD3211eb761D35", "0x09924d7C4f6aA63baedd23b04BdD3211eb761D35", 
                                "0xDBD06E7690F2c575129abD5552DaEB0055367305", "0xDBD06E7690F2c575129abD5552DaEB0055367305");

  await _tateStaking2.deployed();

  console.log("tateStaking2 deployed to:", _tateStaking2.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
});
