/*
*E-launch
*Decentralized Incubator
*A disruptive blockchain incubator program / decentralized seed stage fund, empowered through DAO based community-involvement mechanisms
*/
pragma solidity >=0.8.0;

// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/proxy/utils/Initializable.sol";
import "../interfaces/IUniswapV2Router02.sol";
import "../interfaces/IUniswapV2Factory.sol";
import "../interfaces/IBNBsoftLaunch.sol";

interface IERC20Extra is IERC20{
    function _burn(address account, uint256 amount) external;
}


//SeedifyFundsContract

contract BNBsoftLaunch is Ownable, Initializable {
    using SafeERC20 for IERC20;
    using SafeMath for uint256;

    //tokenSale attributes
    //address internal constant BUSD_TESTNET = 0xeD24FC36d5Ee211Ea25A80239Fb8C4Cfd80f12Ee;
    // uint256 public hardCap; // Max cap in BUSD
    // uint256 public hardCap_wei; 

    uint256 public softCap_wei;
    uint256 public saleStartTime; // start sale time
    uint256 public saleEndTime; // end sale time
    uint256 public totalBNBReceivedInAllTier; // total BUSD received (in wei)
    uint256 public totalparticipants; // total participants in ido
    uint256 public totalTokensBought; // (in wei)
    uint256 public totalTokensForFairLaunch_wei;
    uint256 public totalTokensBeingSold;
    uint256 public LPtokenReleaseDate;

    uint256 public _presaleRate;
    uint256 public _listingRate;
    uint256 public _liquidityPercent;
    uint256 public BNBFee_;
    uint256 public _tokensBill;
    uint256 public _refundType;
   
    
    address ELaunch;
    address public projectOwner; // project Owner
   
    uint256 public maxBuyPerUser; // max allocations per user in a tier
    uint256 public minBuyPerUser; // min allocation per user in a tier
    address[] private whitelist; // address array for tier one whitelist

    IERC20 public ERC20Interface;
    address public tokenAddress;
    IUniswapV2Router02 public uniswapV2Router;
    address public constant PancakeRouter_Test = 0xD99D1c33F9fC3444f8101754aBC46c52416550D1;
    address public constant PancakeRouter_Main = 0x05fF2B0DB69458A0750badebc4f9e13aDd608C7F;

    mapping(address => uint256) public amountBoughtInBNB; //mapping the user purchase 
    mapping(address => bool) internal userHasBought;

    //mapping to hold claimable balance for each user
    mapping(address => uint256) public claimableTokenBalance;

    bool public presaleFinalized;
    bool defaultReleaseDateSet;

    enum buyType{publicSale, whiteListOnly}
    buyType public saleState;

    // CONSTRUCTOR
     constructor(){
        // locks implementation to prevent it from being initialized in the future
        _disableInitializers();
    }

    function initialize(
        address _owner_,
        uint tokensNeeded_wei,
        IBNBsoftLaunch.saleInfo memory compressedInfo,
        uint tokensBill,
        address _ELaunch
    ) external initializer{

        softCap_wei = compressedInfo.softCap;
    
        saleStartTime = compressedInfo._saleStartTime;
        saleEndTime = compressedInfo._saleEndTime;
        projectOwner = _owner_;
        minBuyPerUser = compressedInfo.minBuyPerUser;
        maxBuyPerUser = compressedInfo.maxBuyPerUser;
        totalTokensBeingSold = compressedInfo.sumOfTokensOnSale;

       
        totalTokensForFairLaunch_wei = tokensNeeded_wei;
        ELaunch = _ELaunch;

        _tokensBill = tokensBill;

        //sale is public by default
        saleState = buyType.publicSale;

        
        
        _liquidityPercent = compressedInfo.liquidityPercent;
        BNBFee_ = compressedInfo._BNBFee;
        
        _refundType = compressedInfo.refundType;
    

        //set admin as the creator of the Sale (in Ownable)
        _transferOwnership(projectOwner);
    
        require(compressedInfo.tokenOnSale != address(0), "Token Address cannot be Zero");
        tokenAddress = compressedInfo.tokenOnSale;
        ERC20Interface = IERC20(tokenAddress);

        IUniswapV2Router02 _uniswapV2Router = IUniswapV2Router02(PancakeRouter_Test);
        uniswapV2Router = _uniswapV2Router;
    }

    /**
    *
    * ONLY NECESSARY IN BNB LAUNCHPAD!!!
    *
    *
    * */

    receive() external payable{
        buyTokens();
    }

    fallback() external payable{
        buyTokens();
    }


    //add the address in Whitelist to invest
    function addWhitelist(address _address) external onlyOwner {
        require(_address != address(0), "Invalid address");
        whitelist.push(_address);
    }

    
    // check the address in whitelist tier one
    function getWhitelist(address _address) public view returns (bool) {
        uint256 i;
        uint256 length = whitelist.length;
        for (i = 0; i < length; i++) {
            address _addressArr = whitelist[i];
            if (_addressArr == _address) {
                return true;
            }
        }
        return false;
    }

    //0 for publicSale & 1 for whiteListOnly
    function setSaleType(uint choice) public onlyOwner{
        require(choice == 0 || choice == 1, "choice can only be 0 or 1");
        if(choice == 0){
            saleState = buyType.publicSale;
        }else if(choice == 1){
            saleState = buyType.whiteListOnly;
        }

    }

    function calculateFairlaunchRate() public view returns(uint) {
        return ((totalTokensBeingSold * 1e18) / totalBNBReceivedInAllTier); //this will give the no. tokens per BUSD
    }

    function buyTokens() public payable{
        uint amount = msg.value;
        require(block.timestamp >= saleStartTime, "The sale has not started yet "); // solhint-disable
        require(block.timestamp <= saleEndTime, "The sale is closed"); // solhint-disable
        require(presaleFinalized == false, "buyTokens(): fairLaunch has been finalized");
       

        if(saleState == buyType.whiteListOnly){

            if (getWhitelist(msg.sender)) {
                amountBoughtInBNB[msg.sender] += amount;
                require(
                    amountBoughtInBNB[msg.sender] >= minBuyPerUser,
                    "buyTokens: "
                );
            
                require(
                    amountBoughtInBNB[msg.sender] <= maxBuyPerUser,
                    "buyTokens: You are investing more than your limit!"
                );

                // increase amount of total BUSD received
                totalBNBReceivedInAllTier += amount;

                // Get amount of tokens user can get for BNB paid
                // uint tokenAmount_wei = _amountOfTokens(amount);

                //for each time user buys tokens, add it to the amount he can claim
                // claimableTokenBalance[msg.sender] = claimableTokenBalance[msg.sender].add(tokenAmount_wei);
                // totalTokensBought += tokenAmount_wei; 
                
                if(userHasBought[msg.sender] == false){
                    userHasBought[msg.sender] = true;
                    totalparticipants += 1;
                }
                
            } else {
                revert("No a whitelisted address");
            }

        }else if (saleState == buyType.publicSale){
            
            amountBoughtInBNB[msg.sender] += amount;
            require(
                amountBoughtInBNB[msg.sender] >= minBuyPerUser,
                "your purchasing Power is so Low"
            );
        
            require(
                amountBoughtInBNB[msg.sender] <= maxBuyPerUser,
                "buyTokens:You are investing more than your tier-1 limit!"
            );

            // increase amount of total BUSD received
            totalBNBReceivedInAllTier += amount;

            // // Get amount of tokens user can get for money paid
            // uint tokenAmount_wei = _amountOfTokens(amount);

            // //for each time user buys tokens, add it to the amount he can claim
            // claimableTokenBalance[msg.sender] = claimableTokenBalance[msg.sender].add(tokenAmount_wei);
            // totalTokensBought += tokenAmount_wei; 

          if(userHasBought[msg.sender] == false){
                userHasBought[msg.sender] = true;
                totalparticipants += 1;
            }
        }
       
    }
    


    function amountsNeededForLiquidity() internal view returns(
            uint tokensForLiquidity,
            uint _BNBForLiquidity,
            uint _BNBforCreator,
            uint _presaleExecutionFee
        ){

        /**
        * @dev Doing all calculations in Wei
        *
        * NOTE: All figure entered are in wei by default.
        * Therefore raising them to ^18 converts figure to one ETHER (1 of your token)
        *
        * ...
         */

        if(BNBFee_ == 4){
            // remove all extra zeros from the "totalBNBReceivedInAllTier"
            // before using it for computing
            uint totalTokensBeingSold_notWei = (totalTokensBeingSold * 1e18) / 1e6;
            uint totalTokensForLiquidity_wei = ((totalTokensBeingSold_notWei * 96) * _liquidityPercent) * 1e2;

            // find the total amount of BUSD required to send Liquidity to PancakeSwap
            uint totalBNBReceivedInAllTier_notWei = totalBNBReceivedInAllTier / 1e6;
            uint totalBNBforLiquidity_wei = (totalBNBReceivedInAllTier_notWei * _liquidityPercent * 96) * 1e2;

            uint totalBNBforCreator_wei = (totalBNBReceivedInAllTier_notWei * (100 - _liquidityPercent) * 96) * 1e2;
            uint presaleExecutionFee_BNB =  totalBNBReceivedInAllTier - (totalBNBforCreator_wei + totalBNBforLiquidity_wei);

            return (totalTokensForLiquidity_wei, totalBNBforLiquidity_wei, totalBNBforCreator_wei, presaleExecutionFee_BNB);

        }else if(BNBFee_ == 2){
            // remove all extra zeros from the "totalBNBReceivedInAllTier"
            // before using it for computing
            uint totalTokensBeingSold_notWei = (totalTokensBeingSold * 1e18) / 1e6;
            uint totalTokensForLiquidity_wei = ((totalTokensBeingSold_notWei * 985) * _liquidityPercent) * 1e1; // send 98.5% and leave 1.5% for Elaunch

            // find the total amount of BUSD required to send Liquidity to PancakeSwap
            uint totalBNBReceivedInAllTier_notWei = totalBNBReceivedInAllTier / 1e6;
            uint totalBNBforLiquidity_wei = (totalBNBReceivedInAllTier_notWei * _liquidityPercent * 98) * 1e2;

            uint totalBNBforCreator_wei = (totalBNBReceivedInAllTier_notWei * (100 - _liquidityPercent) * 98) * 1e2;
            uint presaleExecutionFee_BNB =  totalBNBReceivedInAllTier - (totalBNBforCreator_wei + totalBNBforLiquidity_wei);

            return (totalTokensForLiquidity_wei, totalBNBforLiquidity_wei, totalBNBforCreator_wei, presaleExecutionFee_BNB);
        }
    }
    
    
    function handleUnsoldTokens(uint _tokensSentToPS) internal {
        uint256 unsoldTokens = totalTokensForFairLaunch_wei - ((totalTokensBeingSold * 1e18) + _tokensSentToPS + _tokensBill);

        if(_refundType == 0){
            // 0 = refund to creator
            ERC20Interface.transfer(projectOwner, unsoldTokens);
        }else if(_refundType == 1){
            // 1 = burn
            IERC20Extra(tokenAddress)._burn(address(this), unsoldTokens);
        }

    }

    function sendPresaleExecutionFees(uint presaleExecutionFee) internal {
        // send BNB fees to E-Launch
        payable(ELaunch).transfer(presaleExecutionFee);

        // if the fee model includes 2% of tokens, then transfer it to E-launch
        if(BNBFee_ == 2){
            ERC20Interface.transfer(ELaunch, _tokensBill);
        }
    }

    function ensureApprovalA() internal {
        uint entireBalance = IERC20(tokenAddress).balanceOf(address(this));

        // the token is being approved for the contract
        IERC20(tokenAddress).approve(PancakeRouter_Test, entireBalance);
    }

    function sendLiquidityToPancake(uint256 amountADesired, uint ethAmount)internal returns (uint _amountA) {
        // approve
        ensureApprovalA();
        
        // add the liquidity
        (uint amountA, , ) =
        uniswapV2Router.addLiquidityETH{value: ethAmount}(
            tokenAddress,
            amountADesired,
            0,
            0,
            address(this),
            (block.timestamp + 300)
        );

        return amountA;
    }

    function finalize() public onlyOwner{
        require(presaleFinalized == false, "finalize: presale already finalized");
        require(totalBNBReceivedInAllTier >= softCap_wei || block.timestamp >= saleEndTime,
        "finalize: SoftCap not reached or sale has not ended");
   
        (
            uint tokensForLiquidity,
            uint _BNBForLiquidity,
            uint _BNBforCreator,
            uint _presaleExecutionFee
        ) 
        = amountsNeededForLiquidity();

        sendPresaleExecutionFees(_presaleExecutionFee);

        uint tokensSentToPS = sendLiquidityToPancake(tokensForLiquidity, _BNBForLiquidity);

        // Send BNB that was not added liquidity pool to the creator
        payable(projectOwner).transfer(_BNBforCreator);

        // burn or refund unsold tokens
        handleUnsoldTokens(tokensSentToPS);

        presaleFinalized = true;
    }

    function calculateClaimableTokens() internal returns(uint){
        uint fairLaunchRate = calculateFairlaunchRate();

        uint claimableTokens = (amountBoughtInBNB[msg.sender] * fairLaunchRate);

        claimableTokenBalance[msg.sender] = claimableTokens;

        return claimableTokenBalance[msg.sender];
    }

    function claimTokens() external {
        require(presaleFinalized == true, "claimTokens: User cannot claim tokenss till sale is finalized");
        // Add boolean to ensure that liquidity pool has been created

        uint claimableTokens = calculateClaimableTokens();

        claimableTokenBalance[msg.sender] = 0;

        ERC20Interface.safeTransfer(msg.sender, claimableTokens);
    }

    function withdrawContribution() public {
        require(block.timestamp >= saleEndTime, "withdrawContribution: please wait till sale ends");
        require(totalBNBReceivedInAllTier < softCap_wei, "Cannot withdraw. Sale Exceeds softCap");

        uint withdrawableAmount = amountBoughtInBNB[msg.sender];

        payable(msg.sender).transfer(withdrawableAmount);
    }

    // // scrutinize this function for possible dangers.
    // function emergencyEndSale() public onlyOwner{
    //     saleEndTime = block.timestamp + 10;
    // }

    function checkBalancesOfContract() public view returns(uint contractBUSDBalance, uint contractTokenBalance) {
        // for BNB
        uint _contractBNBBalance = address(this).balance;
        // for the token
        uint _contractTokenBalance = ERC20Interface.balanceOf(address(this));

        return (_contractBNBBalance,  _contractTokenBalance);
    }

    function checkDetailsOfLPToken(address lpToken)public view returns(uint){
        return IERC20(lpToken).balanceOf(address(this));
    }

    // should Allow Owner redeem LP tokens after lockup period has passed
    function redeemLPToken(address lpToken) public onlyOwner{
        require(presaleFinalized == true, "redeemLPToken: User cannot redeemLPToken till sale is finalized");
        require(block.timestamp >= LPtokenReleaseDate, "redeemLPToken: Please wait till the release date");
        address theOwner = msg.sender;
        uint contractLPbalance = IERC20(lpToken).balanceOf(address(this));
        IERC20(lpToken).transfer(theOwner, contractLPbalance);
    }

    function postponeLPReleaseDate(uint extraTime)public onlyOwner{
        LPtokenReleaseDate += extraTime;
    }

    // function setDefaultLPTokenReleaseDate()external {
    //    require(defaultReleaseDateSet == false, "Default release date already set" );
    //    LPtokenReleaseDate = saleEndTime + 5 days;
    //    defaultReleaseDateSet = true;
    // }
}