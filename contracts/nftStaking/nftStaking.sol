// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../interfaces/IALPHANFT.sol";
import "../interfaces/IALPHAReward.sol";

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
    IALPHARewards public rewardsContract;

    bool initialised;

    uint256 public lastUpdateTime;

    /**
    @notice Struct to track users and their tokens
    @dev tokenIds are all the tokens staked by the staker
    @dev balance is the current ether balance of the staker
    @dev rewardsEarned is the total reward for the staker till now
    @dev rewardsReleased is how much reward has been paid to the staker
    */
    struct Staker {
        uint256[] tokenIds;
        mapping (uint256 => uint256) tokenIndex;
        uint256 balance;
        uint256 lastRewardPoints;
        uint256 rewardsEarned;
        uint256 rewardsReleased;
    }

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


    function setRewardsContract(
        address _addr
    )
        external
    {
        require(hasRole(ADMIN_ROLE, msg.sender), "Caller must be admin");
        require(_addr != address(0));
        address oldddr = address(rewardsContract);
        rewardsContract = IALPHARewards(_addr);
        emit RewardTokenUpdated(oldddr, _addr);
    }
    

    // @dev Getter functions for the staking contract
    // @dev Gets the amount of tokens staked by the user
    function getStakedTokens(
        address _user
    )
        external
        view
        returns (uint256[] memory tokenIds)
    {
        return stakers[_user].tokenIds;
    }

}