// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/access/Ownable.sol";

interface IERC20 {
    function balanceOf(address account) external view returns (uint256);
    function _burn(address account, uint256 amount) external returns (bool);
    function transferFrom(address sender, address recipient, uint256 amount) external returns (bool);
    function transfer(address recipient, uint256 amount) external returns (bool);
}

contract VoipBridge is Ownable{
    IERC20 public voipToken;
    address public relayer;
    bool public contractIsPaused;

    mapping(address => uint256) public lockedBalances;
    mapping(string => bool) public solanaAddressIsUsed;
 
    event TokensBurned(address indexed user, uint256 amount, uint256 timestamp);
    event TokensLocked(uint256 amount, address indexed user, string solanaAddress, uint256 timestamp);

    constructor(address _voipToken, address _relayer) {
        voipToken = IERC20(_voipToken);
        relayer  = _relayer;
        _transferOwnership(_relayer);
        contractIsPaused = false;
    }

    function lockTokens(uint256 _amount, string memory _solanaAddress) external {
        require(contractIsPaused == false, "Contract is currently locked");
        require(_amount > 0, "Amount must be greater than zero");
        require(voipToken.balanceOf(msg.sender) >= _amount, "Insufficient balance");
        require(isValidSolanaAddress(_solanaAddress) == true, "Invalid Solana Address");
        require(solanaAddressIsUsed[_solanaAddress] == false, "The Specified Solana Address has been used");

        require(
            voipToken.transferFrom(msg.sender, address(this), _amount), "Token transfer failed"
        );

        lockedBalances[msg.sender] += _amount;
        solanaAddressIsUsed[_solanaAddress] = true;

        emit TokensLocked(_amount, msg.sender, _solanaAddress, block.timestamp);
    }

    function burnTokens(address _user) external onlyOwner {
        require(lockedBalances[_user] > 0, "Amount must be greater than zero");

        lockedBalances[_user] = 0;
        voipToken._burn(_user, lockedBalances[_user]);

        emit TokensBurned(_user, lockedBalances[_user], block.timestamp);
    }

    function unlockTokens (address _user) external onlyOwner {
        require(lockedBalances[_user] > 0, "Insufficient balance locked up in contract");

        lockedBalances[_user] = 0;
        voipToken.transfer(_user, lockedBalances[_user]);
    }

    function isValidSolanaAddress(string memory solanaAddress) public pure returns (bool) {
        bytes memory addrBytes = bytes(solanaAddress);
        
        if (addrBytes.length < 32 || addrBytes.length > 44) {
            return false;
        }

        bytes memory base58Chars = "123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz";

        for (uint256 i = 0; i < addrBytes.length; i++) {
            bool isValidChar = false;
            for (uint256 j = 0; j < base58Chars.length; j++) {
                if (addrBytes[i] == base58Chars[j]) {
                    isValidChar = true;
                    break;
                }
            }
            if (!isValidChar) {
                return false;
            }
        }
        return true;
    }

    function toggleContractPause() external onlyOwner {
        contractIsPaused = !contractIsPaused;
    }

    function changeRelayer(address _relayer) external onlyOwner {
        relayer = _relayer;
        transferOwnership(_relayer);
    }

}
