// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/access/AccessControl.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";

contract ALPHANodeNFT is ERC721URIStorage {
    using Counters for Counters.Counter;    
    Counters.Counter private _tokenIds;
    
    uint256 public total;    
    uint256 public _startingPower;    
    
    address public contractOwner;
    address public _marketplaceAddress;

    address public powerManager;
    address public tokenMinter;
    address public attributeManager;
    address public superAdmin;

    struct Attributes {
        string name;
        uint256 currentPower;
        uint256 totalPaid;
        uint256 created;
        uint256 updated;
        uint256 lastOwnershipTransfer;
        bool isEarning;        
    }

    mapping(uint256 => Attributes) public alphaNodes;

    event newTokenMinted(uint256 tokenId, Attributes, uint256 timeStamp);

    event powerChanged(uint256 tokenId, uint256 prevPower, uint256 newPower, uint256 updatedAt);
    event stringAttributeChanged(uint256 tokenId, string attribute, string prevVal, string newVal);
    event uintAttributeChanged(uint256 tokenId, string attribute, uint256 prevVal, uint256 newVal);
    event boolAttributeChanged(uint256 tokenId, string attribute, bool prevVal, bool newVal);

    event tokenOwnershipChanged(uint256 tokenId, address prevOwner, address newOwner);
    event contractManagementChanged(string managementType, address prevAddress, address newAddress);
    event marketPlaceChanged(address prevAddress, address newAddress);

    constructor(
        address marketplaceAddress,
        uint256 startingPower,
        uint256 maxTokens
    ) ERC721("ALPHA Node NFT", "ALPHANodeNFT") {
        powerManager = msg.sender;
        tokenMinter = msg.sender;
        _marketplaceAddress = marketplaceAddress;
        _startingPower = startingPower;
        attributeManager = msg.sender;
        superAdmin = msg.sender;
        total = maxTokens;
    }

    /**
    * Token Minting.
     */
    function createToken(string memory tokenURI) public minterOnly lessThanTotal returns (uint) {
        _tokenIds.increment();
        uint256 newItemId = _tokenIds.current();
        _mint(msg.sender, newItemId);
        _setTokenURI(newItemId, tokenURI);
        setApprovalForAll(_marketplaceAddress, true);
        assignTokenStartingAttributes(newItemId);

        emit newTokenMinted(newItemId, alphaNodes[newItemId], block.timestamp);

        return newItemId;
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

    /**
    * Called by NFT Attribute Manager Contract
     */
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
}