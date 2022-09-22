const { InfuraProvider } = require("@ethersproject/providers");
const hre = require("hardhat");

const factoryAddress = '0xa2371DDc9C47c885FFC5A470F02bfaf60de3d7DB';

async function handleApproval(){
    const tokenContract = await hre.ethers.getContractFactory("testToken");

    const token = await tokenContract.attach(
        "0xb83448589263925e321977E0cE5B10835A81A6b5" // $TCC
    )

    const theResult = await token.approve(factoryAddress, "8000000000000000000000")
    console.log(theResult);
}

async function main() {
    const myContract = await hre.ethers.getContractFactory("BNBsoftLaunchFactory");

    const contract = await myContract.attach(
        factoryAddress
    )

    //const theResponse = await contract.setFlatFee('2000000000000');

        // console.log(theResponse);

    await handleApproval();

    const ourResponse = await contract.create(
        1663851494,
        1663852634,
        '0xb83448589263925e321977E0cE5B10835A81A6b5',
        '50000000000000000',
        56,
        2,
        0,
        4000,
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
        "0x24efe8f4e762ea20fB2D152b598FC835a8763Bf8"
    )

    // let ourAnswer = await contract.buyTokens(
    //     {value: '90000000000000000',
    //     gasLimit: 900000});

    let ourAnswer = await contract.finalize();

    console.log(ourAnswer);
}

async function investigate(){
    const myContract = await hre.ethers.getContractFactory("BNBsoftLaunch");

    const contract = await myContract.attach(
        "0xf8eb527dfb3ea480ee0ef286446a48ceac56dcf8"
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

    
}

checkFunc()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });

    /**
     *  NewBUSDfactory: 0xB3Ef27eCc72b8c027DB9e2CD81849fA4be567C86
     *  newBNBLaunchPadFactory: 0x5F59bb6BdA0e64B0A453317B75F6749C0A988D0a
     */