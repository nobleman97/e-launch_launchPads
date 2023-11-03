// checkBalance.js

async function checkBalance() {
    const [account] = await ethers.getSigners();
    const balance = await account.getBalance();
  
    console.log(`Account Address: ${account.address}`);
    console.log(`Ether Balance: ${ethers.utils.formatEther(balance)} ETH`);
  }
  
  checkBalance()
    .then(() => process.exit(0))
    .catch(error => {
      console.error(error);
      process.exit(1);
    });
  