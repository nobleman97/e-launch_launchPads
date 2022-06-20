// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.0;


interface IBNBsoftLaunch {
     struct saleInfo{
        uint256 _saleStartTime;
        uint256 _saleEndTime;
        address tokenOnSale;
        uint softCap;
        uint liquidityPercent;
        uint _BNBFee;
        uint refundType; // "0" for refund, "1" for burn
        uint liquidityReleaseDate;
        uint maxOwnerReceiveableBNB;
        uint minBuyPerUser;
        uint maxBuyPerUser;
        uint sumOfTokensOnSale;
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