// // SPDX-License-Identifier: MIT

// pragma solidity ^0.8.7;

// import "../interfaces/IALPHANFT.sol";
// import "./NFT.sol";
// import "../interfaces/IALPHARewards.sol";

// import "@openzeppelin/contracts/access/AccessControl.sol";
// import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// // import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
// import "@openzeppelin/contracts/utils/math/SafeMath.sol";
// // To be implemented for security purposes
// import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

// /**
// * @title Alpha NFT Staking Contract
// * @dev
// * @author Akanimoh Osutuk (DocAkan) 
// */

// contract nftStaking is AccessControl {
//     using SafeMath for uint256;

//     // IERC20 public rewardsToken;
//     // IALPHANFT public parentNFT;

//     address public rewardsToken;
//     NFT public parentNFT;

//     // Adopting the OpenZeppelin Implementation
//     // IERC721 public parentNFT;
//     IALPHARewards public rewardsContract;

//     bool initialised;
//     bool public tokensClaimable;

//     uint256 public stakedEthTotal;
//     uint256 public lastUpdateTime;
//     uint256 public powerLevel;

//     uint256 public rewardsPerTokenPoints;

//     uint256 constant pointMultiplier = 10e18;


//     /**
//     @notice Struct to track users and their tokens
//     @dev tokenIds are all the tokens staked by the staker
//     @dev balance is the current ether balance of the staker
//     @dev rewardsEarned is the total reward for the staker till now
//     @dev rewardsReleased is how much reward has been paid to the staker
//     */
//     struct Staker {
//         uint256[] tokenIds;
//         mapping (uint256 => uint256) tokenIndex;
//         uint256 balance;
//         uint256 lastRewardPoints;
//         uint256 rewardsEarned;
//         uint256 rewardsReleased;
//     }

//     /// @notice Mapping of a staker to its properties
//     mapping(address => Staker) public stakers;

//     /// @notice Mapping from token ID to the owner
//     mapping(uint256 => address) public tokenOwner;

//     // Role identifier for the Admin Role
//     bytes32 public constant ADMIN_ROLE = keccak256("ADMIN_ROLE");

//     /// @notice Admin update of rewards contract
//     event RewardsTokenUpdated(address indexed oldRewardsToken, address newRewardsToken );

//     /// @notice event emitted when a user has staked a token
//     event Staked(address owner, uint256 amount);

//     /// @notice event emitted when a user has unstaked a token
//     event Unstaked(address owner, uint256 amount);

//     /// @notice event emitted when a user claims reward
//     event RewardPaid(address user, uint256 amount);

//     /// @notice Emergency unstake tokens without rewards
//     event EmergencyUnstake(address indexed user, uint256 tokenId);

//     constructor(
//         address _rewardsToken,
//         address _parentNFT
//     ) {
//         require(rewardsToken != address(0), "MerchNStaking: stake token address is 0");
//         rewardsToken = _rewardsToken;
//         parentNFT = NFT(_parentNFT);
//         // grantRole(ADMIN_ROLE, msg.sender);
//         // parentNFT = IERC721(0x);
//     }

//     /**
//     * @dev sets the admin role
//     */
//     function setAdmin(bytes32, address) external {
//         grantRole(ADMIN_ROLE, msg.sender);
//     }
    
//     function isAdmin(bytes32, address) external view returns(bool) {
//         hasRole(ADMIN_ROLE, msg.sender);
//     }

//     /**
//     * @dev Init the staking contract
//     */

//     function initStaking(
//         IERC20 _rewardsToken,
//         IALPHANFT _parentNFT
//     ) external {
//         require(!initialised, "Already Initialised");
//         require(hasRole(ADMIN_ROLE, msg.sender), "Caller not an admin");
//         // rewardsToken = _rewardsToken;
//         // parentNFT = _parentNFT;
//         lastUpdateTime = block.timestamp;
//         initialised = true;
//     }


//     function setRewardsContract(
//         address _addr
//     )
//         external
//     {
//         require(hasRole(ADMIN_ROLE, msg.sender), "Caller must be admin");
//         require(_addr != address(0));
//         address oldaddr = address(rewardsContract);
//         rewardsContract = IALPHARewards(_addr);
//         emit RewardsTokenUpdated(oldaddr, _addr);
//     }


//     // @dev Getter functions for the staking contract
//     // @dev Gets the amount of tokens staked by the user
//     function getStakedTokens(
//         address _user
//     )
//         external
//         view
//         returns (uint256[] memory tokenIds)
//     {
//         return stakers[_user].tokenIds;
//     }


//     /// @notice Stake ALPHA NFTS and earn reward tokens
//     function stake(
//         uint256 tokenId
//     )
//         external
//     {
//         _stake(msg.sender, tokenId);
//     }

//     function _stake(
//         address _user,
//         uint256 _tokenId
//     )
//         internal
//     {
//         Staker storage staker = stakers[_user];

//         if (staker.balance == 0 && staker.lastRewardPoints == 0 ) {
//             staker.lastRewardPoints = rewardsPerTokenPoints;
//         }

//         updateReward(_user);
//         uint256 amount = getContribution(_tokenId);
//         staker.balance = staker.balance.add(amount);
//         stakedEthTotal = stakedEthTotal.add(amount);
//         staker.tokenIds.push(_tokenId);
//         staker.tokenIndex[staker.tokenIds.length - 1];
//         tokenOwner[_tokenId] = _user;
//         parentNFT.safeTransferFrom(
//             _user,
//             address(this),
//             _tokenId
//         );

//         emit Staked(_user, _tokenId);
//     }

//     /// @notice Unstake ALPHA NFTs
//     function unstake(
//         uint256 _tokenId
//     )
//         external
//     {
//         require(tokenOwner[_tokenId] == msg.sender, "Sender must have staked tokenIDs");
//         claimReward(msg.sender);
//         _unstake(msg.sender, _tokenId);
//     }


//     /**
//      * @dev All the unstaking goes through this function
//      * @dev Rewards to be given out is calculated
//      * @dev Balance of stakers are updated as they unstake the nfts based on ether price
//      */
//     function _unstake(
//         address _user, 
//         uint256 _tokenId
//     )
//         internal
//     {
//         Staker storage staker = stakers[_user];
//         uint256 amount = getContribution(_tokenId);
//         staker.balance = staker.balance.sub(amount);
//         stakedEthTotal = stakedEthTotal.sub(amount);

//         uint256 lastIndex = staker.tokenIds.length - 1;
//         uint256 lastIndexKey = staker.tokenIds[lastIndex];
//         uint256 tokenIdIndex = staker.tokenIndex[_tokenId];

//         staker.tokenIds[tokenIdIndex] = lastIndexKey;
//         staker.tokenIndex[lastIndexKey] = tokenIdIndex;
//         if (staker.tokenIds.length > 0) {
//             staker.tokenIds.pop();
//             delete staker.tokenIndex[_tokenId];
//         }

//         if (staker.balance == 0) {
//             delete stakers[_user];
//         }
//         delete tokenOwner[_tokenId];

//         parentNFT.safeTransferFrom(
//             address(this), 
//             _user, 
//             _tokenId
//         );

//         emit Unstaked(_user, _tokenId);
//     }

//     /// @dev Updates the amount of rewards owed for each user before any tokens are moved
//     function updateReward(
//         address _user
//     )
//         public
//     {
//         rewardsContract.updateRewards();
//         /// Review and update the interface contract
//         uint256 parentRewards = rewardsContract.parentRewards(lastUpdateTime, block.timestamp);

//         if (stakedEthTotal > 0) {
//             rewardsPerTokenPoints = rewardsPerTokenPoints.add(parentRewards
//             .mul(1e18)
//             .mul(pointMultiplier)
//             .div(stakedEthTotal));
//         }

//         lastUpdateTime = block.timestamp;
//         uint256 rewards = rewardsDue(_user);

//         Staker storage staker = stakers[_user];
//         if (_user != address(0)) {
//             staker.rewardsEarned = staker.rewardsEarned.add(rewards);
//             staker.lastRewardPoints = rewardsPerTokenPoints; 
//         }
//     }


//     /// @notice Returns the rewards due for a user
//     /// @dev This gets the rewards from each of the periods as one multiplier
//     function rewardsDue(
//         address _user
//     )
//         public
//         view
//         returns(uint256)
//     {
//         uint256 newRewardPerToken = rewardsPerTokenPoints.sub(stakers[_user].lastRewardPoints);
//         uint256 rewards = stakers[_user].balance.mul(newRewardPerToken)
//             .div(1e18)
//             .div(pointMultiplier);
//     }

//     /// @dev gets the value of a staked NFT
//     function getContribution(
//         uint256 _tokenId
//     )
//         public
//         view
//         returns (uint256)
//     {
//         // return parentNFT.basicSalePrice(_tokenId);
//     }


//     function claimReward(
//         address _user
//     )
//         public
//     {
//         require(tokensClaimable == true, "Cannot be claimed yet");
//         updateReward(_user);

//         Staker storage staker = stakers[_user];

//         uint256 payableAmount = staker.rewardsEarned.sub(staker.rewardsReleased);
//         staker.rewardsReleased = staker.rewardsReleased.add(payableAmount);

//         /// @dev 
//         uint256 rewardBal = rewardsToken.balanceOf(address(this));
//         if (payableAmount > rewardBal) {
//             payableAmount = rewardBal;
//         }

//         rewardsToken.transfer(_user, payableAmount);
//         emit RewardPaid(_user, payableAmount);
//     }


//     // Unstake without caring about rewards. EMERGENCY ONLY.
//     function emergencyUnstake(uint256 _tokenId) public {
//         require(
//             tokenOwner[_tokenId] == msg.sender,
//             "Sender must have staked tokenID"
//         );
//         _unstake(msg.sender, _tokenId);
//         emit EmergencyUnstake(msg.sender, _tokenId);

//     }

// }