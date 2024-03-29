
const { InfuraProvider } = require("@ethersproject/providers");
const hre = require("hardhat");
const contractAbi = require("../artifacts/contracts/raven/ravenWallet.sol/RavenPay.json")
                                
// const contractAbi = require("../artifacts/contracts/tokens/Token.sol/testToken.json")
var contractAddress = "0xbcB01fdce3BBccE815F0BFB25309bf1a11B29541";

const Web3 = require('web3');
const web3 = new Web3('https://data-seed-prebsc-2-s1.binance.org:8545/');


const contract= new web3.eth.Contract(contractAbi.abi, contractAddress);


async function getEvents() {
    let latest_block = await web3.eth.getBlockNumber();
    let historical_block = latest_block - 5000; // you can also change the value to 'latest' if you have a upgraded rpc
    console.log("latest: ", latest_block, "historical block: ", historical_block);

    const events = await contract.getPastEvents(
        'txDetails', // change if your looking for a different event
        { 
            // filter: { "2": "0x6394d40f98ae7a3e00b4725a12c719b0c227891dc4d984ecdce7b57accddbb8b" },
                  fromBlock: 27717145,
                  toBlock: 27717296,
         }
    );latest_block

    // console.log(events);
    await getTransferDetails(events);
};

async function getTransferDetails(data_events) {
    for (i = 0; i < data_events.length; i++) {
        let _sender = data_events[i]['returnValues']['0'];
        let refString = data_events[i]['returnValues']['2'];

        console.log("sender:", _sender, "refString:", refString);

    };
};



getEvents()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });