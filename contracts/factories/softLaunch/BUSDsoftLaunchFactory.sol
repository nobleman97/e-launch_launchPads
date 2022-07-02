// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/proxy/Clones.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "./softLaunchFactoryBase.sol";
import "../../interfaces/IBUSDsoftLaunch.sol";

contract BUSDsoftLaunchFactory is softLaunchFactoryBase {
  using Address for address payable;
  using SafeMath for uint256;
  using SafeERC20 for IERC20;

    IBUSDsoftLaunch.saleInfo compressedInfo;

    event presaleCreated(
    address indexed owner,
    address presaleAddress
    );

    constructor(address implementation_) softLaunchFactoryBase( implementation_) {}

    // pulls tokens from creator's wallet and set allowance to zero
    function pullTokensFromWallet(
        address owner,
        address approvedToken,
        address presaleContract,
        uint tokensNeededForPresale
    ) internal {
        // from the allowed tokens, pull what is needed
        IERC20(approvedToken).safeTransferFrom(owner, presaleContract, tokensNeededForPresale);

    }

    function totalTokensNeeded(
        uint _BUSDFee,
        uint _liquidityPercent,
        uint _totalTokensForSale
    )internal pure returns(uint _tokensNeeded_wei, uint tokensCharged){
        require(_BUSDFee == 2 || _BUSDFee == 4, "_BUSDFee must either be 2 or 4");

        /**
        * @dev Doing all calculations in Wei
        *
        * NOTE: All figure entered are in wei by default.
        * Therefore raising them to ^18 converts figure to one ETHER (1 of your token)
        *
        * return tokensNeeded, _BNBFee
         */


        if(_BUSDFee == 4){
            uint totalTokensForLiquidity = ((_totalTokensForSale * 96) * _liquidityPercent) * 1e14;

            uint tokensNeeded_wei = totalTokensForLiquidity + (_totalTokensForSale * 1e18);

            return (tokensNeeded_wei, 0);
        }else if(_BUSDFee == 2){
            uint totalTokensForLiquidity = ((_totalTokensForSale * 98) * _liquidityPercent) * 1e14;

            uint tokensNeeded_wei = totalTokensForLiquidity + (_totalTokensForSale * 1e18);

            uint tokensCharge_wei = (tokensNeeded_wei * 15) / 1000;

            tokensNeeded_wei = tokensNeeded_wei + tokensCharge_wei;

            return (tokensNeeded_wei, tokensCharge_wei);
        }
    }



    function create(
        uint256 _saleStartTime,
        uint256 _saleEndTime,
        address tokenOnSale,
        uint softCap, //enter value in ether (e.g 1, 2, 16 etc), not wei
        uint liquidityPercent,
        uint _BUSDFee, // either 2 or 5
        uint refundType, // "0" for refund, "1" for burn
        uint totalTokensForSale, // entered as normal value (ethers)
        uint liquidityReleaseDate,
        uint minBuyPerUser,
        uint maxBuyPerUser
    ) external payable enoughFee nonReentrant{

        refundExcessiveFee();

        (uint tokensNeeded_wei,
        uint tokensBill) = totalTokensNeeded(
            _BUSDFee,
            liquidityPercent,
            totalTokensForSale
        );

        {
        compressedInfo._saleStartTime = _saleStartTime;
        compressedInfo._saleEndTime = _saleEndTime;
        compressedInfo.tokenOnSale = tokenOnSale;
        compressedInfo.softCap = softCap;
        compressedInfo.liquidityPercent = liquidityPercent;
        compressedInfo._BUSDFee = _BUSDFee;
        compressedInfo.refundType = refundType;
        compressedInfo.liquidityReleaseDate = liquidityReleaseDate;
        compressedInfo.minBuyPerUser = minBuyPerUser;
        compressedInfo.maxBuyPerUser = maxBuyPerUser;
        compressedInfo.sumOfTokensOnSale = totalTokensForSale;
        }

        payable(feeTo).sendValue(flatFee);
        address presale = Clones.clone(implementation);

        IBUSDsoftLaunch(presale).initialize(
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
        // IBNBsoftLaunch(presale).setDefaultLPTokenReleaseDate();

        emit presaleCreated(msg.sender, presale);

    }

}