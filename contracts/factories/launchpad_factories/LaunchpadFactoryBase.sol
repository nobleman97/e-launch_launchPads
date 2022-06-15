// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.4;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/utils/Address.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";



contract LaunchpadFactoryBase is Ownable, ReentrancyGuard {
  using SafeMath for uint256;
  using Address for address payable;

 
  address public implementation;
  address public feeTo;
  uint256 public flatFee;

  modifier enoughFee() {
    require(msg.value >= flatFee, "Flat fee");
    _;
  }

  constructor(address implementation_) {
    implementation = implementation_;
    feeTo = msg.sender;
    flatFee = 500_000_000 gwei;
  }

  function setImplementation(address implementation_) external onlyOwner {
    implementation = implementation_;
  }

  function setFeeTo(address feeReceivingAddress) external onlyOwner {
    feeTo = feeReceivingAddress;
  }

  function setFlatFee(uint256 fee) external onlyOwner {
    flatFee = fee;
  }

  function refundExcessiveFee() internal {
    uint256 refund = msg.value.sub(flatFee);
    if (refund > 0) {
      payable(msg.sender).sendValue(refund);
    }
  }
}
