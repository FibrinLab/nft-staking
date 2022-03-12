
pragma solidity ^0.8.0;


import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";

contract AlphaNFT is ERC1155, Ownable {

  uint256 public constant ARTWORK = 0;
  uint256 public constant PHOTO = 1;

  constructor() ERC1155("") {
    _mint(msg.sender, ARTWORK, 1, "");
    _mint(msg.sender, PHOTO, 2, "");
  }

  function mint(address account, uint256 id, uint256 amount) public onlyOwner {
    _mint(account, id, amount, "");
  }

  function burn(address account, uint256 id, uint256 amount) public {
    require(msg.sender == account);
    _burn(account, id, amount);
  }

}

