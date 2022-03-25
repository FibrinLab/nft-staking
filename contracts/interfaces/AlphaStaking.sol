// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

interface AlphaStaking {
    function stakedEthTotal() external view returns (uint256);
    function lpToken() external view returns (address);
    function WETH() external view returns (address);
}