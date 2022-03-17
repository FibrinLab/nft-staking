// SPDX-License-Identifier: MIT

pragma solidity ^0.8.7;

import "../interfaces/IALPHANFT.sol";
import "../interfaces/IALPHAReward.sol";

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";

/**
* @title Alpha NFT Staking Contract
* @dev
* @author Akanimoh Osutuk (DocAkan) 
*/

contract nftStaking is AccessControl {

    IERC20 public rewardToken;
    IALPHANFT public parentNFT;
    address public rewardsContract;
    // IALPHARewards public rewardsContract;

    bool initialised;

    uint256 public lastUpdateTime;
    uint256 public powerLevel;

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

    /// @notice Mapping of a staker to its properties
    mapping(address => Staker) public stakers;

    // Role identifier for the Admin Role
    bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

    /// @notice Admin update of rewards contract
    event RewardsTokenUpdated(address indexed oldRewardsToken, address newRewardsToken );

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
        address oldaddr = address(rewardsContract);
        // rewardsContract = IALPHARewards(_addr);
        emit RewardsTokenUpdated(oldaddr, _addr);
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


    /// @notice Stake ALPHA NFTS and earn reward tokens
    function stake(
        uint256 tokenId
    )
        external
    {
        _stake(msg.sender, tokenId);
    }

    function _stake(
        address _user,
        uint256 tokenId
    )
        internal
    {
        Staker storage staker = stakers[_user];

    }

}