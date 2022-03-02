// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../helpers/AuthContract.sol";

contract AlphaNodeCreator is ReentrancyGuard, AuthContract {
    using Counters for Counters.Counter;    
    Counters.Counter private bondIds;

    address payable public NODE_REWARDS_POOL_ADDRESS;
    
    address public LP_PAIR;
    
    address public BURN_ADDRESS;    
    address public DEX_ADDRESS;
    address public TREASURY_ADDRESS;
    address public LP_RECEIVER_ADDRESS;

    address public NODE_NFT_CONTRACT;

    event rewardsPoolAddressChanged(address prevAddress, address newAddress);

    struct Bond {
        uint256 disount;
        address currency;
    }
    
    struct NodeTier {
        string name;
        uint256 price;        
    }

    struct FeeStructure {
        uint256 rewardsPool;
        uint256 liquidity;
        uint256 treasury;
        uint256 burn;
    }
  
    mapping(uint256 => NodeTier) public nodeTiers;
    mapping(uint256 => Bond) private bonds;
  
    FeeStructure public nodeCreationFees;

    constructor(
        address payable nodeRewardsPoolAddress,
        address treasuryReceiver,
        address lpReceiver,
        address lpPair,
        address dexAddress,
        address nodeNftContract
    ) {
        NODE_REWARDS_POOL_ADDRESS = nodeRewardsPoolAddress;
        DEX_ADDRESS = dexAddress;
        TREASURY_ADDRESS = treasuryReceiver;
        LP_RECEIVER_ADDRESS = lpReceiver;
        LP_PAIR = lpPair;
        NODE_NFT_CONTRACT = nodeNftContract;
    }

    function purchaseNodeFullPrice(uint256 level) payable public returns(bool) {
        require(nodeTiers[level].price > 0, "node tier does not exist");
        require(msg.value >= nodeTiers[level].price, "insufficient funds");
        
        takeFees(msg.sender, msg.value);
        createNode(msg.sender, level);
        
        return true;  
    }

    function purchaseNodeAtDiscountByBondId(uint256 level, uint256 bondId) public authorized {
        // requires auth, purhase the node at a discount, require a bond id that has been previously registered
    }

    function takeFees(address creator, uint256 amount) private {
        // split the amount
        // send to receivers 
    }

    function createNode(address creator, uint256 level) private {
        // call the nft contract mint
        // register node with rewards distributor
    }

    function setFeeStructure(uint256 rewardsPool, uint256 liquidity, uint256 treasury, uint256 burn) public authorized {
        // require all 4 add up to 100%
        // require()
        nodeCreationFees = FeeStructure(rewardsPool, liquidity, treasury, burn);
    }

    function defineBond(uint256 discount, address currency) public authorized {
        // use counter to increment id and save the bond to the bonds mapping
    }

    function defineNodeTier(uint256 level, string calldata name, uint256 price) public authorized {
        require(level >= 1, "Node tier must be at least 1");
        nodeTiers[level] = NodeTier(name, price);
    }

    function setRewardsPoolAddress(address payable newAddress) public authorized {
        address prevAddress = NODE_REWARDS_POOL_ADDRESS;
        NODE_REWARDS_POOL_ADDRESS = newAddress;
        emit rewardsPoolAddressChanged(prevAddress, newAddress);
    }

    function setTreasuryAddress(address payable newAddress) public authorized {
        address prevAddress = TREASURY_ADDRESS;
        TREASURY_ADDRESS = newAddress;
        emit rewardsPoolAddressChanged(prevAddress, newAddress);
    }

    function setLPReceiverAddress(address payable newAddress) public authorized {
        address prevAddress = LP_RECEIVER_ADDRESS;
        LP_RECEIVER_ADDRESS = newAddress;
        emit rewardsPoolAddressChanged(prevAddress, newAddress);
    }

    function setLPPairAddress(address payable newAddress) public authorized {
        address prevAddress = LP_PAIR;
        LP_PAIR = newAddress;
        emit rewardsPoolAddressChanged(prevAddress, newAddress);
    }

    function setDEXAddress(address payable newAddress) public authorized {
        address prevAddress = DEX_ADDRESS;
        DEX_ADDRESS = newAddress;
        emit rewardsPoolAddressChanged(prevAddress, newAddress);
    }

}