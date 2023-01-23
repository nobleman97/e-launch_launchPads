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

    // Mappings
    mapping (address => uint256) public userBalance;

    // Events
    event depositMade(uint time, address sender, address receiver, uint amount);
    event withdrawalMade(uint time, address receiver, uint amount);

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


    // "Approve" a reasonable amount of USDT before calling this function
    function receiveFunds( uint256 amount) public {
        require(amount > 0, "amount must be greater than zero");

        userTokens.transferFrom(msg.sender, treasuryWallet, amount);
        userBalance[msg.sender] += amount;

        emit depositMade(block.timestamp, msg.sender, treasuryWallet, amount);
    }

    // "Approve" a reasonable amount of USDT for this contract before
    function withdrawFunds ( uint256 amount, address userWallet ) public onlyOwner {
        require ( amount > 0, "amount must be greater than zero");
        require(userBalance[userWallet] >= amount, "User's Balance is lower than requested amount");
        // uint treasuryBalance = userTokens.balanceOf(treasuryWallet);

        userBalance[userWallet] -= amount;
        userTokens.transferFrom(treasuryWallet, userWallet, amount);

        emit withdrawalMade(block.timestamp, userWallet, amount);        
    }

    function reduceUserBalance (address _user, uint _amount) public onlyOwner{
        // this function should be called when user spends money from his in-app wallet
        require ( _amount > 0, "amount must be greater than zero");

        userBalance[_user] -= _amount;        
    }

    function getBalanceByAddress(address user) public view returns (uint256) {
        return userTokens.balanceOf(user);
    }

    function getContractBalance() public view returns (uint256) {
        return userTokens.balanceOf(address(this));
    }

    function setTreasury (address _treasuryAddress) external onlyOwner{
        treasuryWallet = _treasuryAddress;
    }



}