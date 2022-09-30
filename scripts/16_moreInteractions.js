const { InfuraProvider } = require("@ethersproject/providers");
const hre = require("hardhat");

const factoryAddress = '0xB38b5957C6FE6aDAF74C94Cd16EB9D538bbd6f8F';

async function handleApproval(){
    const tokenContract = await hre.ethers.getContractFactory("testToken");

    const token = await tokenContract.attach(
        '0x56394D3E4F1B3f9b69AA336533BeB10D225844A1'
       // "0xb83448589263925e321977E0cE5B10835A81A6b5" // $TCC
    )

    const theResult = await token.approve(factoryAddress, "8000000000000000000000")
    console.log(theResult);
}

async function main() {
    const myContract = await hre.ethers.getContractFactory("BNBsoftLaunchFactory");

    const contract = await myContract.attach(
        factoryAddress
    )

    // await contract.setFlatFee('2000000000000');


    await handleApproval();

    const ourResponse = await contract.create(
        1664516260,
        1664517520,
        '0x56394D3E4F1B3f9b69AA336533BeB10D225844A1',
        '50000000000000000',
        60,
        2,
        0,
        300,
        1660919701,
        '2000000000000000',
        '100000000000000000',
        {value: ethers.utils.parseUnits("0.05"),
        gasLimit: 900000}
    );

    console.log(ourResponse);

    // const theResponse = await contract.setFlatFee('2000000000000');

    //     console.log(theResponse);
}

const { infuraProjectId } = require('../secrets.json');

async function checkFunc(){

    // const network = await ethers.providers.getNetwork(97);
    // const provider =  hre.ethers.getDefaultProvider(network, infuraProjectId)
    

    const myContract = await hre.ethers.getContractFactory("BNBsoftLaunch");

    const contract = await myContract.attach(
        "0x0D1b59AD14Dd75a0909Ed4d81210F972b68f8b3e"
    )

    // let ourAnswer = await contract.buyTokens(
    //     {value: '60000000000000000',
    //     gasLimit: 900000});

    let ourAnswer = await contract.claimTokens();

    console.log(ourAnswer);
}

async function investigate(){
    const myContract = await hre.ethers.getContractFactory("BNBsoftLaunch");

    const contract = await myContract.attach(
        "0x4c2941DFE7829b40d88AE7f63940d76dB2Ba075b"
    )

    console.log("David's FairLaunch")

    const softCap = await contract.softCap_wei()
    console.log(`the softcap is: ${softCap.toString()}` )

    const totalContribution = await contract.totalBNBReceivedInAllTier()
    console.log(`the totalContribution is: ${totalContribution.toString()}` )

    const presalRate = await contract._presaleRate()
    console.log(`the presalRate is: ${presalRate.toString()}` )

    const _listingRate = await contract._listingRate()
    console.log(`the _listingRate is: ${_listingRate.toString()}` )

    const _liquidityPercent = await contract._liquidityPercent()
    console.log(`the _liquidityPercent is: ${_liquidityPercent.toString()}` )

    const BNBFee_ = await contract.BNBFee_()
    console.log(`the BNBFee_ is: ${BNBFee_.toString()}` )

    const totalTokensBeingSold = await contract.totalTokensBeingSold()
    console.log(`the totalTokensBeingSold is: ${totalTokensBeingSold.toString()}` )


    // tokenAddress

    const tokenAddress = await contract.tokenAddress()
    console.log(`the tokenAddress is: ${tokenAddress.toString()}` )

}

async function changeImplementation(){
    const myContract = await hre.ethers.getContractFactory("BUSDsoftLaunchFactory");

    const contract = await myContract.attach(
        "0x81B1559D208518AA36382E325738BDB21c104669"
    )

    const response = await contract.setImplementation('0x5610561CC9D5E87Edb9d7Fcb71140Da4796BDAB7')
    // const response = await contract.implementation();

    console.log(response)
}

main()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

    /**
     *  
     */