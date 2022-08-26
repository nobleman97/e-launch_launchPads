const { InfuraProvider } = require("@ethersproject/providers");
const hre = require("hardhat");

const factoryAddress = '0xB3Ef27eCc72b8c027DB9e2CD81849fA4be567C86';

async function handleApproval(){
    const tokenContract = await hre.ethers.getContractFactory("testToken");

    const token = await tokenContract.attach(
        "0xb83448589263925e321977E0cE5B10835A81A6b5" // $TCC
    )

    const theResult = await token.approve(factoryAddress, "2000000000000000000000")
    console.log(theResult);
}

async function main() {
    const myContract = await hre.ethers.getContractFactory("BNBLaunchPadFactory");

    const contract = await myContract.attach(
        factoryAddress
    )

    const theResponse = await contract.setFlatFee('2000000000000');

        console.log(theResponse);

    await handleApproval();

    const ourResponse = await contract.create(
        1660916101,
        1660919701,
        '1000000000000000000',
        '2000000000000000000',
        '0xb83448589263925e321977E0cE5B10835A81A6b5',
        '200000000000000000',
        '100000000000000000',
        100,
        100,
        60,
        2,
        1,
        {value: ethers.utils.parseUnits("0.05"),
        gasLimit: 900000}
    );

    console.log(ourResponse);

    // const theResponse = await contract.setFlatFee('2000000000000');

    //     console.log(theResponse);
}

const { infuraProjectId } = require('../secrets.json');

async function checkFunc(){

    const network = await ethers.providers.getNetwork(4);

    const provider =  hre.ethers.getDefaultProvider(network, infuraProjectId)
    

    const myContract = await hre.ethers.getContractFactory("Privacy");

    const contract = await myContract.attach(
        '0xCE172FE7FD8a2FEE9fb4D7a9b1Fa553b14A51805'
    )

    let ourAnswer = await provider.getStorageAt('0xCE172FE7FD8a2FEE9fb4D7a9b1Fa553b14A51805', 5)

    // console.log(ourAnswer);

    // ourAnswer = ourAnswer.slice(0, 34);

    // console.log(ourAnswer);

    // await contract.unlock(ourAnswer);

    // console.log(" Contract lock state has been change to: ", await contract.locked());
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