// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../interfaces/IERC20.sol";
import "../interfaces/IALPHANFT.sol";
import "./AlphaAccessControls.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";

/**
* @title Alpha NFT Staking Contract
* @dev
* @author Akanimoh Osutuk (DocAkan) 
*/

contract nftStaking {

    IERC20 public rewardToken;
    IALPHANFT public parentNFT;
    AlphaAccessControls public accessControls;

    uint256 public lastUpdateTime;

    constructor() {
    }

    /**
    * @dev Init the staking contract
    */

    function initStaking(
        IERC20 _rewardToken,
        IALPHANFT _parentNFT,
        AlphaAccessControls _accessControls
    ) external {
        require(!initialised, "Already Initialised");
        rewardToken = _rewardToken;
        parentNFT = _parentNFT;
        lastUpdateTime = block.timestamp;
        initialised = true;
    }

}