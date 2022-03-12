// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC1155/ERC1155.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

import "../helpers/AuthContract.sol";

contract ALPHANodeNFT is ERC1155,  AuthContract {
    using Counters for Counters.Counter;    
    Counters.Counter private _tokenIds;

    uint256 public constant ALPHA_NODE_NFT = 0;
    uint256 public constant ALPHA_100 = 1;
    uint256 public constant ALPHA_RONIN = 2;
    uint256 public constant ALPHA_APEX = 3;

    mapping(uint256 => string) private _uris;
    
    uint256 public total;    
    uint256 public _startingPower;
    uint256 public _ownerShipTransferCooldown;    
    
    address public contractOwner;
    address public _marketplaceAddress;

    address public powerManager;
    address public tokenMinter;
    address public attributeManager;
    address public superAdmin;

    string private baseTokenURI = 'https://myipfsserver.com/tokens/{id}';

    struct VanityAttribute {
        string attributeName;
        bool enabled;
        uint256 numericValue;
        string stringValue;
    }

    struct GameAttribute {
        string attributeName;
        bool enabled;
        uint256 numericValue;
        string stringValue;
    }

    struct Attributes {
        string name;
        uint256 currentPower;
        uint256 totalPaid;
        uint256 created;
        uint256 updated;
        uint256 lastOwnershipTransfer;
        uint256 ownerShipTransferCooldown;
        mapping(string => VanityAttribute) vanityAttributes;
        mapping(string => GameAttribute) gameAttributes;
        bool isEarning;        
    }

    struct PurchaseRequirements {
        address ALPHA;
        uint256 amountAlpha;
        bool requiresOg;
    }     

    mapping(address => bool) private ogHolders;

    mapping(uint256 => Attributes) public alphaNodes;

    event newTokenMinted(uint256 tokenId, uint256 timeStamp);

    event powerChanged(uint256 tokenId, uint256 prevPower, uint256 newPower, uint256 updatedAt);
    event stringAttributeChanged(uint256 tokenId, string attribute, string prevVal, string newVal);
    event uintAttributeChanged(uint256 tokenId, string attribute, uint256 prevVal, uint256 newVal);
    event boolAttributeChanged(uint256 tokenId, string attribute, bool prevVal, bool newVal);

    event tokenOwnershipChanged(uint256 tokenId, address prevOwner, address newOwner);
    event contractManagementChanged(string managementType, address prevAddress, address newAddress);
    event marketPlaceChanged(address prevAddress, address newAddress);
    event ownerShiptransferCooldownChanged(uint256 prevTime, uint256 newTime);

    constructor(
        address marketplaceAddress,
        uint256 startingPower,
        uint256 maxTokens,
        uint256 ownerShipTransferCooldown
    ) ERC1155("base uri") {
        
        _mint(msg.sender, ALPHA_NODE_NFT, 10000 - 157, "");
        _mint(msg.sender, ALPHA_100, 100, "");
        _mint(msg.sender, ALPHA_RONIN, 47, "");
        _mint(msg.sender, ALPHA_APEX, 10, "");
        
        powerManager = msg.sender;
        tokenMinter = msg.sender;
        _marketplaceAddress = marketplaceAddress;
        _startingPower = startingPower;
        attributeManager = msg.sender;
        superAdmin = msg.sender;
        total = maxTokens;
        _ownerShipTransferCooldown = ownerShipTransferCooldown * 1 minutes;

         // Set approval for all refers to transfer ownership capabilities
        setApprovalForAll(_marketplaceAddress, true);
    }

    

    /**
    * Token Minting.
     */
    function createToken(address nodeCreator) public minterOnly lessThanTotal returns (uint) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
       
        assignTokenStartingAttributes(newItemId);

        emit newTokenMinted(newItemId, block.timestamp);

        return newItemId;
    }

    /**
    *   create the token uri with the base uri and token id, return completed uri
     */
    function makeTokenURI(uint256 tokenId) private returns(string memory) {
        // string manipulation for replacement of the ID string literal identifier with the token id
        // return the completed uri
    }

    /**
    * Set starting attributes for newly minted token.
     */
    function assignTokenStartingAttributes(uint256 tokenId) private {
        alphaNodes[tokenId].name = "";
        alphaNodes[tokenId].currentPower = _startingPower;
        alphaNodes[tokenId].totalPaid = 0;
        alphaNodes[tokenId].created = block.timestamp;
        alphaNodes[tokenId].updated = block.timestamp;
        alphaNodes[tokenId].lastOwnershipTransfer = 0;
        alphaNodes[tokenId].isEarning = false;
    }

    /**
    * Called by Node NFT Power manager contract;
     */
    function increasePowerLevel(uint256 power, uint256 tokenId) public powerControlOnly {
        require(power > alphaNodes[tokenId].currentPower, "Power can only increase");

        uint256 previousPowerLevel = alphaNodes[tokenId].currentPower;
        alphaNodes[tokenId].currentPower = power;
        setLastUpdated(tokenId);

        emit powerChanged(tokenId, previousPowerLevel, power, block.timestamp);
    }

    function decreasePowerLevel(uint256 power, uint256 tokenId) public powerControlOnly {
        require(power < alphaNodes[tokenId].currentPower, "Power can only decrease");

        uint256 previousPowerLevel = alphaNodes[tokenId].currentPower;
        alphaNodes[tokenId].currentPower = power;
        setLastUpdated(tokenId);

        emit powerChanged(tokenId, previousPowerLevel, power, block.timestamp);
    }

    function resetPowerLevel(uint256 tokenId) public powerControlOnly {
        uint256 previousPowerLevel = alphaNodes[tokenId].currentPower;
        alphaNodes[tokenId].currentPower = _startingPower;
        setLastUpdated(tokenId);
        emit powerChanged(tokenId, previousPowerLevel, _startingPower, block.timestamp);
    }

    
    function updateName(string memory name, uint256 tokenId) public attributeManagerOnly {
        string memory previousName = alphaNodes[tokenId].name;

        alphaNodes[tokenId].name = name;
        setLastUpdated(tokenId);
        emit stringAttributeChanged(tokenId, "tokenName", previousName, name);
    }

    function updateTotalPaid(uint256 amount, uint256 tokenId) public attributeManagerOnly returns(uint256) {
        uint256 previousValue = alphaNodes[tokenId].totalPaid;

        alphaNodes[tokenId].totalPaid += amount; 
        setLastUpdated(tokenId);
        emit uintAttributeChanged(tokenId, "totalPaid", previousValue, alphaNodes[tokenId].totalPaid);

        return alphaNodes[tokenId].totalPaid;
    }

    function updateIsEarning(bool earningStatus, uint256 tokenId) public attributeManagerOnly {
        alphaNodes[tokenId].isEarning = earningStatus;
        setLastUpdated(tokenId);
        emit boolAttributeChanged(tokenId, "isEarning", !earningStatus, earningStatus);
    }

    /**
    *   Marketplace only function, auto sets to not earning if isForSale is true
     */
    function setIsForSale(bool isForSale, uint256 tokenId) public marketPlaceOnly {
        bool previousEarningStatus = alphaNodes[tokenId].isEarning;
        // set is earning to the inverse of isForSale
        alphaNodes[tokenId].isEarning = !isForSale;
        emit boolAttributeChanged(tokenId, "isEarning", previousEarningStatus, alphaNodes[tokenId].isEarning);
    }


    /**
    * Superadmin Only
     */
    function changeMinter(address newAddress) public superAdminOnly {
        address oldAddress = tokenMinter;

        tokenMinter = newAddress;

        emit contractManagementChanged("tokenMinter", oldAddress, newAddress);
    }

    function changeAttributeManager(address newAddress) public superAdminOnly {
        address oldAddress = attributeManager;

        attributeManager = newAddress;

        emit contractManagementChanged("attributeManager", oldAddress, newAddress);
    }

    function changePowerManager(address newAddress) public superAdminOnly {
        address oldAddress = powerManager;

        powerManager = newAddress;

        emit contractManagementChanged("powerManager", oldAddress, newAddress);
    }

    function changeMarketplaceAddress(address newAddress) public superAdminOnly {
        address oldAddress = _marketplaceAddress;

        setApprovalForAll(_marketplaceAddress, false);
        _marketplaceAddress = newAddress;

        setApprovalForAll(newAddress, true);

        emit marketPlaceChanged(oldAddress, newAddress);
    }

    /**
    *   Change global transfer cooldown
     */
    function setGlobalOwnerShipTransferCooldown(uint256 numMinutes) public superAdminOnly {
        require(numMinutes > 1, "Number of minutes must be greater than 1");
        _ownerShipTransferCooldown = numMinutes * 1 minutes;
    }

    /**
    *   Change transfer cooldown for single token by id
     */
    function setOwnerShipTransferCooldownByTokenId(uint256 numMinutes, uint256 tokenId) public superAdminOnly {
        require(numMinutes > 1, "Number of minutes must be greater than 1");
        alphaNodes[tokenId].ownerShipTransferCooldown = numMinutes * 1 minutes;
    }

    /**
    * Private Utils
     */
    function setLastUpdated(uint tokenId) private {
        alphaNodes[tokenId].updated = block.timestamp;
    }
    
    /**
    * Modifiers
     */
    modifier lessThanTotal() {
        require(_tokenIds.current() < total, "Can not mint any more of this series.");
        _;
    }

    modifier powerControlOnly() {
        require(msg.sender == powerManager, "Must be the power manager");
        _;
    }

    modifier attributeManagerOnly() {
        require(msg.sender == attributeManager, "Must be the power manager");
        _;
    }    

    modifier minterOnly() {
        require(msg.sender == tokenMinter, "Must be token minter");
        _;
    }

    modifier superAdminOnly() {
        require(msg.sender == superAdmin, "Must be super admin");
        _;
    }

    modifier marketPlaceOnly() {
        require(msg.sender == _marketplaceAddress, "Must be marketplace");
        _;
    }
}