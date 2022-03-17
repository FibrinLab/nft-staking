// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../interfaces/IALPHANFT.sol";
import "./AlphaAccessControls.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
* @title Alpha NFT Staking Contract
* @dev
* @author Akanimoh Osutuk (DocAkan) 
*/

contract nftStaking is IERC20, AccessControl {

    IERC20 public rewardToken;
    IALPHANFT public parentNFT;

    bool initialised;

    uint256 public lastUpdateTime;

    // Role identifier for the Admin Role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    constructor(address minter) {
        _setupRole(ADMIN_ROLE, minter);
    }

    /**
    * @dev Init the staking contract
    */

    function initStaking(
        IERC20 _rewardToken,
        IALPHANFT _parentNFT
    ) external {
        require(!initialised, "Already Initialised");
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller not an admin");
        rewardToken = _rewardToken;
        parentNFT = _parentNFT;
        lastUpdateTime = block.timestamp;
        initialised = true;
    }

}