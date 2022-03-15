// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/finance/paymentSplitter.sol";

/**
* @dev Reusable Royalty Distributor for Alpha Marketplace
 */

contract AlphaRoyaltyDistributor is PaymentSplitter
{
    constructor (
      address[] memory _payees, 
      uint256[] memory _shares
    ) PaymentSplitter(_payees, _shares) payable {}
}