// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

interface IALPHARewards {
    function updateRewards() external returns (bool);
    function alphaRewards(uint256 _from, uint256 _to) external view returns(uint256);
    function parentRewards(uint256 _from, uint256 _to) external view returns(uint256);
    function LPRewards(uint256 _from, uint256 _to) external view returns(uint256);
    function lastRewardTime() external view returns(uint256);
}