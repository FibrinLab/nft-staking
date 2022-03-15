// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "../helpers/AuthContract.sol";

contract NodeRewardsPool is ReentrancyGuard, AuthContract {

  constructor() {

  }

  function receive() public {
    // receive ALPHA
  }

  function withdraw() public authorized {
    // withdraw alpha
  }

  function balance() public view returns(uint256) {
    // show current balance of alpha
  }

}