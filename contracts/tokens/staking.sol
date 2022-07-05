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
        bool stakingIsPaused;
        bool poolIsInitialized;
        uint stakersCount;
    }

    address public feeReceiver; // address to send early unstaking fee

    mapping(uint => poolType) public pool;
    uint poolIndex;
    uint[] public poolIndexArray;

    uint public rewardIntervalInSeconds;

    // EVENTS
    event poolCreated(uint timeOfCreation, string poolName, uint poolID);
    event userStaked(address stakeHolder, uint timeOfStake, uint amountStaked);
    event rewardClaimed(address stakeHolder, uint timeOfClaim, uint amountUnstaked, uint rewardEarned);
    event poolState(uint timeOfChange, bool isPoolPaused);
    event messageEvent(string Reason);


    constructor(address _stakingToken, address _rewardsToken, address administratorAddress, address _feeReceiver) {
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);
        _transferOwnership(administratorAddress);
        feeReceiver = _feeReceiver;
        poolIndex = 0;

        rewardIntervalInSeconds = 365 days;
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

        emit poolCreated(block.timestamp, _poolName, (poolIndex - 1));

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

        pool[poolID].stakersCount += 1;

        pool[poolID].hasStaked[msg.sender] = true;
        pool[poolID].lastTimeUserStaked[msg.sender] = block.timestamp;

        emit userStaked(msg.sender, block.timestamp, _amount);
    }

    function calculateUserRewards(address userAddress, uint poolID) public view returns(uint){

        if(pool[poolID].hasStaked[userAddress] == true){
            uint lastTimeStaked = pool[poolID].lastTimeUserStaked[userAddress];
            uint periodSpentStaking = block.timestamp - lastTimeStaked;

            uint userStake_wei = pool[poolID].userStakedBalance[userAddress];
            uint userStake_notWei = userStake_wei / 1e6; //remove SIX zeroes.

            uint userReward_inWei = userStake_notWei * pool[poolID].APY * ((periodSpentStaking * 1e4) / rewardIntervalInSeconds);

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
            pool[_poolID].stakersCount -= 1;

            emit rewardClaimed(msg.sender, block.timestamp, claimerStakedBalance, 0);

        }else{

            uint reward = calculateUserRewards(msg.sender, _poolID);
            require(reward > 0, "Rewards is too small to be claimed");

            // Ensure claimer does not claim other stakeHolder's tokens as rewards
            uint amountOfTokenInContract = rewardsToken.balanceOf(address(this));
            uint totalStakedTokens = getTotalStaked();
            uint amountOfRewardsInContract = (amountOfTokenInContract - totalStakedTokens);

            // if the contract token balance is less than what the person desrves,
            // transfer what is left in the contract
            if(amountOfRewardsInContract < reward){
                reward = amountOfRewardsInContract;

                emit messageEvent("Sorry there is no more reward left in this Contract");
            }

            rewardsToken.transfer(msg.sender, reward);

            // decrease balance before transfer to prevent re-entrancy

            pool[_poolID].userStakedBalance[msg.sender] = 0;
            stakingToken.transfer(msg.sender, claimerStakedBalance);

            pool[_poolID].totalStaked -= claimerStakedBalance;
            pool[_poolID].hasStaked[msg.sender] = false;
            pool[_poolID].stakersCount -= 1;

            emit rewardClaimed(msg.sender, block.timestamp, claimerStakedBalance, reward);
        }

    }

    function setRewardInterval(uint _interval) public onlyOwner {
        rewardIntervalInSeconds = (_interval);
    }

    function togglePausePool(uint _poolID) external onlyOwner{
        pool[_poolID].stakingIsPaused = !pool[_poolID].stakingIsPaused;

        emit poolState(block.timestamp, pool[_poolID].stakingIsPaused);
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

    function getPoolStakeDuration(uint poolID) public view returns(uint){
        return pool[poolID].stakingDuration;
    }

    function getTotalStakeHolderCount() public view returns(uint){
        uint totalStakeHolderCount;

        for (uint256 i = 0; i < poolIndexArray.length; i++) {
            totalStakeHolderCount += pool[i].stakersCount;
        }

        return totalStakeHolderCount;
    }

    function getRewardLeftInContract() public view returns(uint rewardsAvailable){
        uint amountOfTokenInContract = rewardsToken.balanceOf(address(this));
        uint totalStakedTokens = getTotalStaked();
        uint amountOfRewardsInContract = (amountOfTokenInContract - totalStakedTokens);

        return amountOfRewardsInContract;
    }

    function setMinimumDeposit(uint _poolID, uint _minimumDepositInWei) public onlyOwner{
        pool[_poolID].minimumDeposit = _minimumDepositInWei;
    }

    function getMinimumDeposit(uint _poolID) public view returns(uint _minimumDeposit){
        return pool[_poolID].minimumDeposit;
    }
}
