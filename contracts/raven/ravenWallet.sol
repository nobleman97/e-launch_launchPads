// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
 * - Receive tokens
 * - Update records
 * - Forward funds to TW
 * 
 */

contract RavenPay is Ownable {


    // Global Vars
    string Name;
    IERC20 public userTokens;
    address treasuryWallet;
    uint testValue;

    // Mappings
    mapping (address => mapping (uint256 => uint256)) public transactionPerTime;

    // Events
    event depositMade(uint time, address sender, address receiver, uint amount);
    // event withdrawalMade(uint time, address receiver, uint amount);
    // event balanceReduced(address _user_, uint amount);
    // event balanceIncreased(address _user_,  uint amount);
    event inAppTransfer(address from, address to, uint amount);
    event  txDetails(address indexed _sender, uint _amountSent, string RefString);

    // Constructor
    constructor(
            address _userTokens,
            string memory _name,
            address administratorAddress,
            address _treasury) 
    {
        userTokens = IERC20(_userTokens);
        Name = _name;
        _transferOwnership(administratorAddress);
        treasuryWallet = _treasury;

    }

    // Function
    fallback() external payable{
        revert();
    }

    receive() external payable{
        revert();
    }


    // "Approve" a reasonable amount of USDT before calling this function
    function receiveFunds( uint256 amount, string memory _refString) public returns(string memory sucessMessage) {
        require(amount > 0, "amount must be greater than zero");

        userTokens.transferFrom(msg.sender, treasuryWallet, amount);
        transactionPerTime[msg.sender][block.timestamp] += amount;

        
        emit txDetails(msg.sender, amount, _refString);
        return("success"); 
    }


    function getContractBalance() public view returns (uint256) {
        return userTokens.balanceOf(address(this));
    }

    function removeTokensFromContract (address _token) external onlyOwner {
        // to salvage any tokens that may be stuck in smart contract
        uint contractBalance = IERC20(_token).balanceOf(address(this));

        IERC20(_token).transfer(treasuryWallet, contractBalance);
    }

    function setTreasury (address _treasuryAddress) external onlyOwner{
        treasuryWallet = _treasuryAddress;
    }


    function setUserTokens (address _tokenAddress) public onlyOwner {
        userTokens = IERC20(_tokenAddress);
    }


}