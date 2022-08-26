 // We require the Hardhat Runtime Environment explicitly here. This is optional
// but useful for running the script in a standalone fashion through `node <script>`.
//
// When running the script with `npx hardhat run <script>` you'll find the Hardhat
// Runtime Environment's members available in the global scope.
const hre = require("hardhat");

// const { ethers } = require('ethers');

async function main() {
  
    const MyContract = await hre.ethers.getContractFactory("MyBuilding");
    const contract = await MyContract.attach(
    "0xb913E21a0a6373c5E6A3Fd487F92ccE242D3d8b7" // The deployed contract address
    );



    const theResult = await contract.goToTop(
      '0xF67e39bF6C3c7eD8B63c5218Fc184Ff45c9B2e2C',
      {gasLimit: "900000"});

    console.log(theResult);

    
}

// We recommend this pattern to be able to use async/await everywhere
// and properly handle errors.
main()
  .then(() => process.exit(0))
  .catch((error) => {
    console.error(error);
    process.exit(1);
  });




/** Implementations:
* - BNBLaunchPad:   0x61177276bb92b277ef968c38dc4f5b8560ec47aa
* - BUSDlaunchPad:  0x1e87035ec026aaa4e71a4735cc7835419f0c09e3
* - BNBfairLaunch:  0xb9b076c6d741131f106b0ec210d5a643ffbcfee0
* - BUSDfairLaunch: 0x8bdec19498e46297506975c31c484b8dbf46ea8a
*/

