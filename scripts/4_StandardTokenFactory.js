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
  const StandardTokenFactory = await hre.ethers.getContractFactory("StandardTokenFactory");
  const _standardTokenFactory = await StandardTokenFactory.deploy("0xe4fa27bBb1C0Be0E686231254FF0c3437329d89B", "0x1A9e40Fb76aA44d4aE9575E4738B1d3E443D7C05");

  await _standardTokenFactory.deployed();

  console.log("_standardTokenFactory deployed to:", _standardTokenFactory.address);
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });
