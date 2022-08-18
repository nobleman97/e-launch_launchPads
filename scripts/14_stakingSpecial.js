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
  const _specialStaking = await hre.ethers.getContractFactory("SpecialStaking");
  const _specialStaking_ = await _specialStaking.deploy('0xb282A53ff6c79AAb63e57Dea7ab7d5f2E2ee76Ae', '0xb282A53ff6c79AAb63e57Dea7ab7d5f2E2ee76Ae', '0xDBD06E7690F2c575129abD5552DaEB0055367305', '0xd8764B01dD3A77211a4437d1768F598Cb249E33B');

  await _specialStaking_.deployed();

  console.log("_specialStaking_ deployed to:", _specialStaking_.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
