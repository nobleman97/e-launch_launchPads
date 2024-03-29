const contractAbi = require("../artifacts/contracts/raven/ravenWallet.sol/RavenPay.json")
var contractAddress = "0xbcb01fdce3bbcce815f0bfb25309bf1a11b29541";

// /home/david/Documents/Projects/blockchain/elaunch_etal/artifacts/contracts/raven/ravenWallet.sol/RavenPay.json

const Web3 = require('web3');
const web3 = new Web3('https://data-seed-prebsc-1-s1.binance.org:8545/');
const web3_again = new Web3();

const contract= new web3.eth.Contract(contractAbi.abi, contractAddress);


async function getEvents() {
    let latest_block = await web3.eth.getBlockNumber();
    let historical_block = latest_block - 5000; // you can also change the value to 'latest' if you have a upgraded rpc
  

    const events = await contract.getPastEvents(
        'txDetails', // change if your looking for a different event
        { 
            // filter: { "2": "0x6394d40f98ae7a3e00b4725a12c719b0c227891dc4d984ecdce7b57accddbb8b" },
                  fromBlock: 	27717295,
                  toBlock: 	27717512,
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



getEvents()
    .then(() => process.exit(0))
    .catch((error) => {
        console.error(error);
        process.exit(1);
    });