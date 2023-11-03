// SPDX-License-Identifier: MIT


/**
$$$$$$$\                                    $$\           $$$$$$$\  $$\                     
$$  __$$\                                   \__|          $$  __$$\ $$ |                    
$$ |  $$ | $$$$$$\  $$$$$$\$$$$\   $$$$$$\  $$\ $$$$$$$\  $$ |  $$ |$$ |$$\   $$\  $$$$$$\  
$$ |  $$ |$$  __$$\ $$  _$$  _$$\  \____$$\ $$ |$$  __$$\ $$$$$$$  |$$ |$$ |  $$ |$$  __$$\ 
$$ |  $$ |$$ /  $$ |$$ / $$ / $$ | $$$$$$$ |$$ |$$ |  $$ |$$  ____/ $$ |$$ |  $$ |$$ /  $$ |
$$ |  $$ |$$ |  $$ |$$ | $$ | $$ |$$  __$$ |$$ |$$ |  $$ |$$ |      $$ |$$ |  $$ |$$ |  $$ |
$$$$$$$  |\$$$$$$  |$$ | $$ | $$ |\$$$$$$$ |$$ |$$ |  $$ |$$ |      $$ |\$$$$$$  |\$$$$$$$ |
\_______/  \______/ \__| \__| \__| \_______|\__|\__|  \__|\__|      \__| \______/  \____$$ |
                                                                                  $$\   $$ |
                                                                                  \$$$$$$  |
                                                                                   \______/  
 */
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

/// @author no-op.eth (nft-lab.xyz)
/// @title DomainPlug Membership Pass
contract DomainPlugPass is ERC1155, Ownable {

  string public constant name = "DomainPlug Membership Pass";
  string public constant symbol = "DMP";
  uint256 public constant MAX_SUPPLY = 1000;
  uint256 public constant MAX_TX = 4;

  uint256 public cost;
  /** URI for the contract metadata */
  string public contractURI;
  /** Funds recipient */
  address public recipient;

  uint256 private _supply;
  bool public saleActive;

  mapping(uint => string) public tokenURI;

  event SaleStateChanged(bool _val);
  event TotalSupplyChanged(uint256 _val);

  /** For URI conversions */
  using Strings for uint256;

  constructor(string memory _uri, address _recepient) ERC1155(_uri) {
    recipient = _recepient;
    saleActive = false;
    cost = 0.25 ether;
    _supply = 0;
    
  }

  /// @notice Sets public sale state
  /// @param _val The new value
  function setSaleState(bool _val) external onlyOwner {
    saleActive = _val;
    emit SaleStateChanged(_val);
  }

  /// @notice Sets cost per mint
  /// @param _val New price
  /// @dev Send in WEI
  function setCost(uint256 _val) external onlyOwner {
    cost = _val;
  }

  /// @notice Sets a new funds recipient
  /// @param _val New address
  function setRecipient(address _val) external onlyOwner {
    recipient = _val;
  }

  /// @notice Sets the base metadata URI
  /// @param _val The new URI
  function setBaseURI(string memory _val) external onlyOwner {
    _setURI(_val);
  }

  /// @notice Sets the contract metadata URI
  /// @param _val The new URI
  function setContractURI(string memory _val) external onlyOwner {
    contractURI = _val;
  }

  /// @notice Returns the amount of tokens sold
  /// @return supply The number of tokens sold
  function totalSupply() public view returns (uint256) {
    return _supply;
  }

  /// @notice Returns the URI for a given token ID
  /// @param _id The ID to return URI for
  /// @return Token URI
  function uri(uint256 _id) public view override returns (string memory) {
    return string(abi.encodePacked(super.uri(_id), _id.toString()));
  }

  /// @notice Withdraws contract funds
  function withdraw() public payable onlyOwner {
    payable(recipient).transfer(address(this).balance);
  }

  /// @notice Reserves a set of NFTs for collection owner (giveaways, etc)
  /// @param _amt The amount to reserve
  function reserve(uint256 _amt) external onlyOwner {
    require(_supply + _amt <= MAX_SUPPLY, "Amount exceeds supply.");

    _supply += _amt;
    _mint(msg.sender, 0, _amt, "0x0000");

    emit TotalSupplyChanged(totalSupply());
  }

  /// @notice Mints a new token in public sale
  /// @param _quantity Amount to be minted
  /// @dev Must send COST * amt in wei
  function mint(uint _id, uint256 _quantity) external payable {
    require(saleActive, "Sale is not yet active.");
    require(_quantity <= MAX_TX, "Amount of tokens exceeds transaction limit.");
    require(_supply + _quantity <= MAX_SUPPLY, "Amount exceeds supply.");
    require(cost * _quantity == msg.value, "ETH sent not equal to cost.");

    _supply += _quantity;
    _mint(msg.sender, _id, _quantity, "");

    emit TotalSupplyChanged(totalSupply());
  }

  function mintBatch(address _to, uint[] memory _ids, uint[] memory _amounts) external onlyOwner {
    _mintBatch(_to, _ids, _amounts, "");
  }

  function setURI(uint _id, string memory _uri) external onlyOwner {
    tokenURI[_id] = _uri;
    emit URI(_uri, _id);
  }

  function burn(uint _id, uint _amount) external {
    _burn(msg.sender, _id, _amount);
  }

  function burnBatch(uint[] memory _ids, uint[] memory _amounts) external {
    _burnBatch(msg.sender, _ids, _amounts);
  }
}

