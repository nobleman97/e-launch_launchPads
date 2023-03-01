pragma solidity ^0.8.0;

// SPDX-License-Identifier: UNLICENSED

import "@openzeppelin/contracts/access/Ownable.sol";

contract vestinginfo  is Ownable{
    bool public vestingIsActivated;

    uint public numberOfCliffs;
    uint public cliff; // the time that must pass before user can claim token per

    mapping (address => mapping (uint => uint)) public userPockets;
    mapping (uint => uint ) public percentPerCliff;
    mapping (address => mapping (uint => bool)) public hasClaimedFromPocket;
    mapping (address => uint) public totalClaimed;

    // Lock / Unlock logic

    function initiateVesting  (
        bool _status, 
        uint _cliffs, 
        uint[] memory _percentPerCliff, // must amount to 100%,
        uint _cliffPeriod
    ) public {

        vestingIsActivated = _status;
        numberOfCliffs = _cliffs;
        cliff = _cliffPeriod;

        uint totalPercentage;

        for (uint x; x < numberOfCliffs; x++){
            percentPerCliff[x] = _percentPerCliff[x];

            totalPercentage += _percentPerCliff[x];
        }

        require(totalPercentage == 100, "total vesting percentage must amount to 100%");

    }



}