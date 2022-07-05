// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract FusionStaking is Ownable{
    IERC20 public rewardsToken;// Contract address of reward token
    IERC20 public stakingToken;// Contract address of staking token

    struct poolType{
        string poolName;
        uint stakingDuration;
        uint APY; // is in % (e.g 40%)
        uint minimumDeposit; // passed in as wei
        uint totalStaked;
        mapping(address => uint256) userStakedBalance;
        mapping(address => bool) hasStaked;
        mapping(address => uint) lastTimeUserStaked;
        address[] stakers;
        bool stakingIsPaused;
        bool poolIsInitialized;
    }

    address public feeReceiver; // address to send early unstaking fee

    mapping(uint => poolType) public pool;
    uint poolIndex;
    uint[] public poolIndexArray;

    uint public rewardIntervalInDays;

    constructor(address _stakingToken, address _rewardsToken, address administratorAddress, address _feeReceiver) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
        _transferOwnership(administratorAddress);
        feeReceiver = _feeReceiver;
        poolIndex = 0;

        rewardIntervalInDays = 365 days;
    }

    function createPool(
        string memory _poolName,
        uint _stakingDuration,
        uint _APY,
        uint _minimumDeposit
    ) external onlyOwner returns(uint _createdPoolIndex){
        require(_APY > 0 && _APY < 1000, "APY can only be between 1% and 1000%");

        pool[poolIndex].poolName = _poolName;
        pool[poolIndex].stakingDuration = _stakingDuration;
        pool[poolIndex].APY = _APY;
        pool[poolIndex].minimumDeposit = _minimumDeposit;
        pool[poolIndex].poolIsInitialized = true;

        poolIndexArray.push(poolIndex);
        poolIndex += 1;

        return (poolIndex - 1);
    }


    /**
    *   Function to stake the token
    *
    *   @dev Approval should first be granted to this contract to pull
    *   "_amount" of Fusion tokens from the caller's wallet, before the
    *   aller can call this function
    *
    *   "_amount" should be passed in as wei
    *
     */
    function stake(uint _amount, uint poolID) public {
        require(pool[poolID].poolIsInitialized == true, "Pool does not exist");
        require(pool[poolID].stakingIsPaused == false, "Staking in this pool is currently Paused. Please contact admin");
        require(pool[poolID].hasStaked[msg.sender] == false, "You currently have a stake in this pool. You have to Unstake.");
        require(_amount >= pool[poolID].minimumDeposit, "stake(): You are trying to stake below the minimum for this pool");

        pool[poolID].totalStaked += _amount;

        pool[poolID].userStakedBalance[msg.sender] += _amount;

        stakingToken.transferFrom(msg.sender, address(this), _amount);

        pool[poolID].stakers.push(msg.sender);
        pool[poolID].hasStaked[msg.sender] = true;
        pool[poolID].lastTimeUserStaked[msg.sender] = block.timestamp;


    }

    function calculateUserRewards(address userAddress, uint poolID) public view returns(uint){

        if(pool[poolID].hasStaked[userAddress] == true){
            uint lastTimeStaked = pool[poolID].lastTimeUserStaked[userAddress];
            uint periodSpentStaking = block.timestamp - lastTimeStaked;

            uint userStake_wei = pool[poolID].userStakedBalance[userAddress];
            uint userStake_notWei = userStake_wei / 1e6; //remove SIX zeroes.

            uint userReward_inWei; //= userStake_notWei * pool[poolID].APY * ((periodSpentStaking * 1e4) / 365 days); // reward period is yearly

            if(pool[poolID].APY > 0 && pool[poolID].APY <= 9){
                userReward_inWei = userStake_notWei * pool[poolID].APY * ((periodSpentStaking * 1e5) / rewardIntervalInDays);
            }
            else if(pool[poolID].APY >= 10 && pool[poolID].APY <= 99){
                userReward_inWei = userStake_notWei * pool[poolID].APY * ((periodSpentStaking * 1e4) / rewardIntervalInDays);
            }
            else if(pool[poolID].APY >= 100 && pool[poolID].APY <= 999){
                userReward_inWei = userStake_notWei * pool[poolID].APY * ((periodSpentStaking * 1e3) / rewardIntervalInDays);
            }

            return userReward_inWei;
        }else{
            return 0;
        }
    }

    // Function to claim rewards & unstake tokens
    function claimReward(uint _poolID) external {
        require(pool[_poolID].hasStaked[msg.sender] == true, "You currently have no stake in this pool.");

        uint stakeTime = pool[_poolID].lastTimeUserStaked[msg.sender];

        uint claimerStakedBalance = pool[_poolID].userStakedBalance[msg.sender];

        /**
        * If claiming before duration, deduct 20% and send to projectOwner
        *
        * */
        if((block.timestamp - stakeTime) < pool[_poolID].stakingDuration){

            uint stakedBalance_notWei = claimerStakedBalance / 1e6;
            uint twentyPercentFee_wei = (stakedBalance_notWei * 20) * 1e4;

            // deduct 20% from stake balance
            claimerStakedBalance -= twentyPercentFee_wei;
            pool[_poolID].userStakedBalance[msg.sender] -= twentyPercentFee_wei;

            // send 20% to receiver
            stakingToken.transfer(feeReceiver, twentyPercentFee_wei);

            // send claimer his remaining 80%
            pool[_poolID].userStakedBalance[msg.sender] = 0;
            stakingToken.transfer(msg.sender, claimerStakedBalance);

            pool[_poolID].totalStaked -= (claimerStakedBalance + twentyPercentFee_wei);
            pool[_poolID].hasStaked[msg.sender] = false;

        }else{

            uint reward = calculateUserRewards(msg.sender, _poolID);
            require(reward > 0, "Rewards is too small to be claimed");

            rewardsToken.transfer(msg.sender, reward);

            // decrease balance before transfer to prevent re-entrancy

            pool[_poolID].userStakedBalance[msg.sender] = 0;
            stakingToken.transfer(msg.sender, claimerStakedBalance);

            pool[_poolID].totalStaked -= claimerStakedBalance;
            pool[_poolID].hasStaked[msg.sender] = false;

        }
    }

    function setRewardInterval(uint _interval) public onlyOwner {
        rewardIntervalInDays = (_interval * 1 days);
    }

    function togglePausePool(uint _poolID) external onlyOwner{
        pool[_poolID].stakingIsPaused = !pool[_poolID].stakingIsPaused;

        getPoolState(_poolID);
    }

    function getPoolState(uint _poolID) public view returns(bool _stakingIsPaused){
        return pool[_poolID].stakingIsPaused;
    }

    function adjustAPY(uint _poolID, uint _newAPY) public onlyOwner{

        pool[_poolID].APY = _newAPY;
    }

    function getAPY(uint _poolID) public view returns (uint){
        return pool[_poolID].APY;
    }

    function getTotalStaked() public view returns(uint){
        uint totalStakedInAllPools;
        for (uint256 i = 0; i < poolIndexArray.length; i++) {
            totalStakedInAllPools += pool[i].totalStaked;
        }

        return totalStakedInAllPools;
    }

    function getUserStakingBalance(uint poolID, address userAddress) public view returns (uint){
        return pool[poolID].userStakedBalance[userAddress];
    }

    function getLastStakeDate(uint poolID, address userAddress) public view returns (uint){
        return pool[poolID].lastTimeUserStaked[userAddress];
    }
}
