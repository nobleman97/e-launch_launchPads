const { InfuraProvider } = require("@ethersproject/providers");
// const hre = require("hardhat");
const contractAbi = require("../artifacts/contracts/raven/ravenWallet.sol/RavenPay.json")
var contractAddress = "0xAE800648F95c7C9071fd896F198fAaC49aae6437";

// /home/david/Documents/Projects/blockchain/elaunch_etal/artifacts/contracts/raven/ravenWallet.sol/RavenPay.json

const Web3 = require('web3');
const web3 = new Web3('https://data-seed-prebsc-1-s1.binance.org:8545/');
const web3_again = new Web3();

const contract= new web3.eth.Contract(contractAbi.abi, contractAddress);


async function getEvents() {
    let latest_block = await web3.eth.getBlockNumber();
    let historical_block = latest_block - 5000; // you can also change the value to 'latest' if you have a upgraded rpc
    // console.log("latest: ", latest_block, "historical block: ", historical_block);

    const events = await contract.getPastEvents(
        'txDetails', // change if your looking for a different event
        { 
            // filter: { "2": "0x6394d40f98ae7a3e00b4725a12c719b0c227891dc4d984ecdce7b57accddbb8b" },
                  fromBlock: 	27617336,
                  toBlock: 	27618216,
         }
    );
    await getTransferDetails(events);
};

async function getTransferDetails(data_events) {
    for (i = 0; i < data_events.length; i++) {
        let _sender = data_events[i]['returnValues']['0'];
        let refString = data_events[i]['returnValues']['2'];

        console.log("sender:", _sender, "refString:", refString);

    };
};


// const Web3 = require('web3');
// const web3 = new Web3('HTTPS_ENDPOINT');
// const contractAddress = 'CONTRACT_ADDRESS';
// const contractAbi = require('./ABI_JSON');
// const contract = new web3.eth.Contract(contractAbi, contractAddress);

// const PAST_EVENT = async () => {
//     let latest_block = await web3.eth.getBlockNumber();
//     let historical_block = latest_block - 5000;

//   await contract.getPastEvents('txDetails',
//     {
//     //   filter: { RefString: "TX-85ED2D2F51954216B26B2F54A1DFC530" },
//       fromBlock: 	historical_block,
//       toBlock: 	latest_block,
//     },
//     (err, events) => {
//       console.log(events);
//     });
// };

// PAST_EVENT();


getEvents()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });