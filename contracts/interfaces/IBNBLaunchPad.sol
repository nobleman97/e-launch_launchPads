// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;


interface IBNBLaunchPad {
     struct saleInfo{
        uint256 _saleStartTime;
        uint256 _saleEndTime;
        uint256 _minBuyPerUser;
        uint256 _maxBuyPerUser;
        address tokenOnSale;
        uint hardCap;
        uint softCap;
        uint presaleRate;
        uint listingRate;
        uint liquidityPercent;
        uint _BNBFee;
        uint refundType; // "0" for refund, "1" for burn
    }

    function initialize(
        address _owner_,
        uint tokensNeeded_wei,
        saleInfo memory compressedInfo,
        uint tokensBill,
        address _ELaunch
    ) external;

    function setDefaultLPTokenReleaseDate()external;
}