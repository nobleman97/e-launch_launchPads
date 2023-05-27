// SPDX-License-Identifier: MIT

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract tateStaking2 is Ownable{
    IERC20 public rewardsToken;// Contract address of reward token
    IERC20 public stakingToken;// Contract address of staking token
    // pool[_poolID].userStakedBalance
    struct poolType{
        string poolName;
        uint APY; // is in % (e.g 40%) for ease of calculation
        uint lockDuration;  // in days
        // uint minimumDeposit; // passed in as wei
        uint totalStaked;
        uint earlyPenalty; // is in percentages


        mapping(address => uint256) userStakedBalance;
        mapping(address => bool) hasStaked;
        mapping(address => uint) lastTimeUserStaked;
        mapping(address => uint) lastTimeUserUnstaked;

        bool stakingIsPaused;
        bool poolIsInitialized;
        uint stakersCount;
        uint withdrawalFee;
        
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


    constructor(
        address _stakingToken, 
        address _rewardsToken,
        address administratorAddress,
        address _feeReceiver
        
    ){
        stakingToken = IERC20(_stakingToken);
        rewardsToken = IERC20(_rewardsToken);

        _transferOwnership(administratorAddress);
        feeReceiver = _feeReceiver;
        poolIndex = 0;

        rewardIntervalInSeconds = 365 days;
    }

    receive() external payable {
        revert("Cannot send BNB to this address");
    }

    function createPool(
        string memory _poolName,
        uint _APY, // enter as % (e.g 40)
        uint _earlyPenalty, // enter as % (e.g 40)
        uint _withdrawalFee, // enter as % (e.g 10)
        uint _lockDuration

    ) external onlyOwner returns(uint _createdPoolIndex){
        require(_APY > 0 && _APY < 1000, "APY can only be between 1% and 1000%");

        pool[poolIndex].poolName = _poolName;
        pool[poolIndex].APY = _APY;
        pool[poolIndex].lockDuration = _lockDuration* 1 days;
        pool[poolIndex].earlyPenalty = _earlyPenalty;
        pool[poolIndex].withdrawalFee = _withdrawalFee;

        // pool[poolIndex].minimumDeposit = _minimumDeposit;

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
    *    n"_amount" of Fusion tokens from the caller's wallet, before the
    *   aller can call this function
    *
    *   "_amount" should be passed in as wei
    *
     */
    function stake(uint _amount, uint poolID) public {
        require(pool[poolID].poolIsInitialized == true, "Pool does not exist");
        require(pool[poolID].stakingIsPaused == false, "Staking in this pool is currently Paused. Please contact admin");
        require(pool[poolID].hasStaked[msg.sender] == false, "You currently have a stake in this pool. You have to Unstake.");
        // require(_amount >= pool[poolID].minimumDeposit, "stake(): You are trying to stake below the minimum for this pool");

    
        pool[poolID].totalStaked += _amount;
        pool[poolID].userStakedBalance[msg.sender] += _amount;

        
            

        stakingToken.transferFrom(msg.sender, address(this), _amount);

        pool[poolID].stakersCount += 1;

        pool[poolID].hasStaked[msg.sender] = true;
        pool[poolID].lastTimeUserStaked[msg.sender] = block.timestamp;
        pool[poolID].lastTimeUserUnstaked[msg.sender] = 0;

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

    // Determine how much will be lost due to early withdrawal
    function determineLoss(uint _poolID) public  view returns(uint _loss, uint _balance){
        
        uint stakeTime = pool[_poolID].lastTimeUserStaked[msg.sender];
        uint _elapsedTime = block.timestamp - stakeTime;

        if (_elapsedTime < pool[_poolID].lockDuration){


            uint theLoss = ((pool[_poolID].userStakedBalance[msg.sender] * (pool[_poolID].earlyPenalty ) )) / 100 ;


            
            return (theLoss, (pool[_poolID].userStakedBalance[msg.sender] - theLoss) );

        
        } else {
            return (0, pool[_poolID].userStakedBalance[msg.sender]);
        }

        
    }




    // Function to claim rewards & unstake tokens
    function claimReward(uint _poolID) external {
        require(pool[_poolID].hasStaked[msg.sender] == true, "You currently have no stake in this pool.");

        uint stakeTime = pool[_poolID].lastTimeUserStaked[msg.sender];
        uint _elapsedTime = block.timestamp - stakeTime;

        
        if ( _elapsedTime > pool[_poolID].lockDuration){
            //if user is withdrawing after lockDuration has elapsed

            uint claimerStakedBalance = pool[_poolID].userStakedBalance[msg.sender];

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

                emit messageEvent("Sorry. There is no more reward left in this Contract");
            }

            // Send reward
            if (pool[_poolID].withdrawalFee == 0){
                rewardsToken.transfer(msg.sender, reward);
            }else{
                //subtract withdrawal fee
                uint reward_loss = ((reward * (pool[_poolID].withdrawalFee ) )) / 100 ;

                //send the loss to admin
                rewardsToken.transfer(msg.sender, (reward_loss));  

                // send the difference to investor
                rewardsToken.transfer(msg.sender, (reward - reward_loss));                 
            }

            // Decrease balance before transfer to prevent re-entrancy
            pool[_poolID].userStakedBalance[msg.sender] = 0;

            // Unstake tokens
            stakingToken.transfer(msg.sender, claimerStakedBalance);

            pool[_poolID].totalStaked -= claimerStakedBalance;
            pool[_poolID].hasStaked[msg.sender] = false;
            pool[_poolID].stakersCount -= 1;

            // upon unstaking, keep record of time of unstaking
            pool[_poolID].lastTimeUserUnstaked[msg.sender] = block.timestamp;

            emit rewardClaimed(msg.sender, block.timestamp, claimerStakedBalance, reward);

        }else if(_elapsedTime < pool[_poolID].lockDuration){
            // if user is withdrawing before lockduration has elapsed

            (uint lossIncurred, uint claimableBalance) = determineLoss(_poolID);

            // uint claimerStakedBalance = pool[_poolID].userStakedBalance[msg.sender];

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

            // Send reward
            if (pool[_poolID].withdrawalFee == 0){
                rewardsToken.transfer(msg.sender, reward);
            }else{
                //subtract withdrawal fee
                uint reward_loss = ((reward * (pool[_poolID].withdrawalFee ) )) / 100 ;

                //send the loss to admin
                rewardsToken.transfer(msg.sender, (reward_loss));  

                // send the difference to investor
                rewardsToken.transfer(msg.sender, (reward - reward_loss));                 
            }
            
            // Decrease balance before transfer to prevent re-entrancy
            pool[_poolID].userStakedBalance[msg.sender] = 0;


            // Unstake tokens

            // send loss to admin
            stakingToken.transfer(feeReceiver, lossIncurred);
            // send remainder to user
            require(claimableBalance > 0, "claimable balance must be greater than 0.");

            stakingToken.transfer(msg.sender, claimableBalance);


            pool[_poolID].totalStaked -= (lossIncurred + claimableBalance);
            pool[_poolID].hasStaked[msg.sender] = false;
            pool[_poolID].stakersCount -= 1;

            // upon unstaking, keep record of time of unstaking
            pool[_poolID].lastTimeUserUnstaked[msg.sender] = block.timestamp;

            emit rewardClaimed(msg.sender, block.timestamp, (lossIncurred + claimableBalance), reward);

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

    function getTotalStakeHolderCount() public view returns(uint){
        uint totalStakeHolderCount;

        for (uint256 i = 0; i < poolIndexArray.length; i++) {
            totalStakeHolderCount += pool[i].stakersCount;
        }

        return totalStakeHolderCount;
    }

    function getStakerCountPerPool(uint _poolID) public view returns(uint){
        return pool[_poolID].stakersCount;
    }

    function getRewardLeftInContract() public view returns(uint rewardsAvailable){
        uint amountOfTokenInContract = rewardsToken.balanceOf(address(this));
        uint totalStakedTokens = getTotalStaked();
        uint amountOfRewardsInContract = (amountOfTokenInContract - totalStakedTokens);

        return amountOfRewardsInContract;
    }

    // function setMinimumDeposit(uint _poolID, uint _minimumDepositInWei) public onlyOwner{
    //     pool[_poolID].minimumDeposit = _minimumDepositInWei;
    // }

    // function getMinimumDeposit(uint _poolID) public view returns(uint _minimumDeposit){
    //     return pool[_poolID].minimumDeposit;
    // }

    function setStakingToken(address _contractAddress) public onlyOwner{
        stakingToken = IERC20(_contractAddress);
    }

    function setRewardToken(address _contractAddress) public onlyOwner{
        rewardsToken = IERC20(_contractAddress);

    }

    function transferTheOwnership(address _newOwner) external onlyOwner{
        transferOwnership(_newOwner);
    }

    function setFeeReceiver(address _newAddress) external onlyOwner{
        feeReceiver = _newAddress;
    }

}
