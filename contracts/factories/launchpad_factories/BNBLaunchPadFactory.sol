// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./LaunchpadFactoryBase.sol";
import "../../interfaces/IBNBLaunchPad.sol";


contract BNBLaunchPadFactory is LaunchpadFactoryBase {
  using Address for address payable;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

    IBNBLaunchPad.saleInfo compressedInfo;

    event presaleCreated(
    address indexed owner,
    address presaleAddress
    );

    constructor(address implementation_) LaunchpadFactoryBase( implementation_) {}

    // pulls tokens from creator's wallet and set allowance to zero
    function pullTokensFromWallet(
        address owner,
        address approvedToken,
        address presaleContract,
        uint tokensNeededForPresale
        ) internal {
        // from the allowed tokens, pull what is needed
        IERC20(approvedToken).safeTransferFrom(owner, presaleContract, tokensNeededForPresale);

        //for security reasons, decrease allowance back to zero
        // uint oldAllowance = IERC20(approvedToken).allowance(owner, address(this));
        // IERC20(approvedToken).safeDecreaseAllowance(address(this), oldAllowance); //will there be a problem here?
    }

    function totalTokensNeeded(
        uint _BNBFee,
        uint hardCap,
        uint presaleRate,
        uint listingRate,
        uint liquidityPercent
    )internal pure returns(uint tokensNeeded_wei, uint tokensCharged){
        require(_BNBFee == 2 || _BNBFee == 4, "BNBFee must either be 2 or 4");

        /**
        * @dev Doing all calculations in Wei
        *
        * NOTE: All figure entered are in wei by default.
        * Therefore raising them to ^18 converts figure to one ETHER (1 of your token)
        *
        * return tokensNeeded, _BNBFee
         */


        if(_BNBFee == 4){
            uint totalTokenBeingSold_wei = (hardCap * presaleRate) * 10**18;
            uint totalTokensForLiquidity_wei = ((hardCap * 96) * (listingRate * liquidityPercent)) * 10**14;

            uint totalTokensNeeded_wei = totalTokenBeingSold_wei + totalTokensForLiquidity_wei;

            return (totalTokensNeeded_wei, 0);
        }else if(_BNBFee == 2){
           uint totalTokenBeingSold_wei = (hardCap * presaleRate) * 10**18;
            uint totalTokensForLiquidity_wei = ((hardCap * 98) * (listingRate * liquidityPercent)) * 10**14;

            uint totalTokensNeeded_wei = totalTokenBeingSold_wei + totalTokensForLiquidity_wei;

            uint tokensFeeToCharge = (totalTokenBeingSold_wei * 15) / 1000;

            totalTokensNeeded_wei = (1015 * (hardCap * presaleRate))*1e15 + totalTokensForLiquidity_wei;

            return (totalTokensNeeded_wei, tokensFeeToCharge);
        }
    }



    function create(
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        uint256 _minBuyPerUser, // in wei
        uint256 _maxBuyPerUser, // in wei
        address tokenOnSale,
        uint hardCap, //enter value in ether (e.g 1, 2, 16 etc), not wei
        uint softCap, //enter value in ether (e.g 1, 2, 16 etc), not wei
        uint presaleRate,
        uint listingRate,
        uint liquidityPercent,
        uint _BNBFee, // either 2 or 5
        uint refundType // "0" for refund, "1" for burn
    ) external payable enoughFee nonReentrant{

        refundExcessiveFee();

        (uint tokensNeeded_wei,
        uint tokensBill) = totalTokensNeeded(
            _BNBFee,
            hardCap,
            presaleRate,
            listingRate,
            liquidityPercent
        );

        {
        compressedInfo._saleStartTime = _saleStartTime;
        compressedInfo._saleEndTime = _saleEndTime;
        compressedInfo._minBuyPerUser = _minBuyPerUser;
        compressedInfo._maxBuyPerUser = _maxBuyPerUser;
        compressedInfo.tokenOnSale = tokenOnSale;
        compressedInfo.hardCap = hardCap;
        compressedInfo.softCap = softCap;
        compressedInfo.presaleRate = presaleRate;
        compressedInfo.listingRate = listingRate;
        compressedInfo.liquidityPercent = liquidityPercent;
        compressedInfo._BNBFee = _BNBFee;
        compressedInfo.refundType = refundType;
        }

        payable(feeTo).sendValue(flatFee);
        address presale = Clones.clone(implementation);

        IBNBLaunchPad(presale).initialize(
            msg.sender,
            tokensNeeded_wei,
            compressedInfo,
            tokensBill,
            feeTo
        );

        // Pull tokensNeeded_wei from creator, and send to presale contract
        // ensure presale contract has a receive function
        pullTokensFromWallet(
            msg.sender,
            tokenOnSale,
            presale,
            tokensNeeded_wei
        );

        // Default Lockup is 5 days
        IBNBLaunchPad(presale).setDefaultLPTokenReleaseDate();

        emit presaleCreated(msg.sender, presale);

    }

}