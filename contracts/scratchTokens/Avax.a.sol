
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract AVAXA is ERC20 {

  /** Token constants */
  string constant _name = "AVAXa";
  string constant _symbol = "AVAXa";
  
  mapping(address => uint256) _balances;

  constructor() ERC20("AVAX.a", "AVAX.a") {
      _mint(msg.sender, 265000000 * 10 ** decimals());      
  }

}
