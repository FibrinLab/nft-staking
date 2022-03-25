// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/access/AccessControl.sol";


import "../interfaces/AlphaStaking.sol";
import "../interfaces/IALPHANFT.sol";
import "../interfaces/IBep20.sol";


/**
 * @title Alpha Rewards
 * @dev Calculates the rewards for staking on Alpha Shares
 * @author Akanimoh Osutuk (docakan)
 */

 contract alphaRewards is AccessControl {
     using SafeMath for uint256;

     AlphaStaking public alphaStaking;
     AlphaStaking public parentStaking;
    //  AlphaStaking public;

    uint256 public startTime;
    uint256 public lastRewardTime;

    constructor(
        IBEP20 _rewardsToken,
        AlphaStaking _alphaStaking,
        AlphaStaking _parentStaking
     )
        public
     {
        alphaStaking = _alphaStaking;
        parentStaking = _parentStaking;
     }

    /// @dev Contract config
    function setStartTime(
        uint256 _startTime,
        uint256 _lastRewardTime
    )
        external
    {
        require(
            require(hasRole(ADMIN_ROLE, msg.sender), "Caller must be admin");
        );
        startTime = _startTime;
        lastRewardTime = _lastRewardTime;
        
    }



 }