// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../helpers/AuthContract.sol";
import "./AlphaNFTAuthorizations.sol";

contract ALPHANFT is
    ERC721,
    AlphaNFTAuthorizations, 
    AuthContract,
    ReentrancyGuard 
{
    using Strings for uint256;
    using Counters for Counters.Counter;    
    Counters.Counter private _tokenIds;

    uint256 public total;    
    uint256 public _startingPower;
    uint256 public _ownerShipTransferCooldown; 

    string public baseURI;

    struct AlphaNFTAttributes {
        string name;
        string nftType;
        uint256 currentPower;
        uint256 totalPaid;
        uint256 created;
        uint256 updated;
        uint256 lastOwnershipTransfer;
        uint256 ownerShipTransferCooldown;
        bool isEarning;        
    }
    
    mapping(uint256 => AlphaNFTAttributes) public alphaNodes;
    mapping(uint256 => bool) private tokenExists;
    
    struct VanityAttributeStringType {
        string attributeName;
        bool enabled;
        string attributeValue;
    }

    struct GameAttributeStringType {
        string attributeName;
        bool enabled;
        string attributeValue;
    }

    struct VanityAttributeNumericType {
        string attributeName;
        bool enabled;
        uint256 attributeValue;
    }

    struct GameAttributeNumericType {
        string attributeName;
        bool enabled;
        uint256 attributeValue;
    }
    
    mapping(uint256 => VanityAttributeStringType[]) public vanityStringAttributes;
    mapping(uint256 => GameAttributeStringType[]) public gameStringAttributes;
    mapping(uint256 => VanityAttributeNumericType[]) public vanityNumericAttributes;
    mapping(uint256 => GameAttributeNumericType[]) public gameNumericAttributes;

    mapping (uint256 => string) private _tokenURIs;

    event baseURISet(string baseURI);
    event tokeURISet(uint256 tokenId, string tokenURI);

    event newTokenMinted(uint256 tokenId, AlphaNFTAttributes nftAttributes, uint256 timeStamp);

    event powerChanged(uint256 tokenId, uint256 prevPower, uint256 newPower, uint256 updatedAt);
    
    event stringAttributeChanged(uint256 tokenId, string attribute, string prevVal, string newVal);
    event uintAttributeChanged(uint256 tokenId, string attribute, uint256 prevVal, uint256 newVal);
    event boolAttributeChanged(uint256 tokenId, string attribute, bool prevVal, bool newVal);

    event vanityNumericAttributeAdded(uint256 tokenId, string _attributeName, uint256 attributeIndex, uint256 _attributeValue);
    event vanityStringAttributeAdded(uint256 tokenId, string _attributeName, uint256 attributeIndex, string _attributeValue);
    
    event vanityStringAttributeUpdated(uint256 tokenId, string _attributeName, uint256 attributeIndex, string previousValue, string _attributeValue);
    event vanityNumericAttributeUpdated(uint256 tokenId, string _attributeName, uint256 attributeIndex, uint256 previousValue, uint256 _attributeValue);
    
    event gameNumericAttributeAdded(uint256 tokenId, string _attributeName, uint256 attributeIndex, uint256 _attributeValue);
    event gameStringAttributeAdded(uint256 tokenId, string _attributeName, uint256 attributeIndex, string _attributeValue);
    
    event gameStringAttributeUpdated(uint256 tokenId, string _attributeName, uint256 attributeIndex, string previousValue, string _attributeValue);
    event gameNumericAttributeUpdated(uint256 tokenId, string _attributeName, uint256 attributeIndex, uint256 previousValue, uint256 _attributeValue);
    
    event attributeDeleted(uint256 tokenId, string attributeName, uint256 attributeIndex);

    event tokenOwnershipChanged(uint256 tokenId, address prevOwner, address newOwner);
    event contractManagementChanged(string managementType, address prevAddress, address newAddress);
    event marketPlaceChanged(address prevAddress, address newAddress);
    event ownerShiptransferCooldownChanged(uint256 prevTime, uint256 newTime);
   
    // TODO:: pass token minter address as argument
    // TODO:: add new contracet addresses as we created them to be passed in as arguments

    constructor(

    ) ERC721("Alpha Shares", "AlphaShares") {
        powerManager = msg.sender; // to be set after deployment
        tokenMinter = msg.sender; // to be set after deployment
        _marketplaceAddress = msg.sender; // marketplaceAddress, to be set after deployment
        _startingPower = 10000; //startingPower;
        attributeManager = msg.sender;
        superAdmin = msg.sender;
        total = 10000; // maxTokens;
        _ownerShipTransferCooldown = 1 days;
        
        init();
    }

    function init() internal {
        // Set approval for all refers to transfer ownership capabilities
        setApprovalForAll(_marketplaceAddress, true);
    }

    /**
    * @dev createToken is called by minter
     */
    function createToken(
        address _to,
        string memory _nftType    
        ) 
        public 
        minterOnly 
        lessThanTotal 
        returns (uint) 
    {
        // begin by incrementing
        _tokenIds.increment();
        
        uint256 newItemId = _tokenIds.current();        
        
        // set mapping for exists on this token id to true
        tokenExists[newItemId] = true;

        // _to is passed in from the node creation contract
        _safeMint(_to, newItemId);
        
        alphaNodes[newItemId] = AlphaNFTAttributes({
            name: "",
            nftType: _nftType,
            currentPower: _startingPower,
            totalPaid: 0,
            created: block.timestamp,
            updated: block.timestamp,
            lastOwnershipTransfer: block.timestamp,
            ownerShipTransferCooldown: 1 days,
            isEarning: false
        });
        
        emit newTokenMinted(newItemId, alphaNodes[newItemId], block.timestamp);

        return newItemId;
    }

    /**
    * @dev setBaseURI - to be set after contract is deployed and metadata is ready
     */
    function setBaseURI(
        string memory baseURI_
        ) 
        external 
        superAdminOnly 
    {
        require(bytes(baseURI_).length != 0, "Base URI must not be empty string.");
        baseURI = baseURI_;
        emit baseURISet(baseURI);
    }

    function tokenURI(
        uint256 tokenId
        ) 
        public 
        view 
        override 
        _tokenExists(tokenId) 
        returns (string memory)  
    {
        string memory _tokenURI = _tokenURIs[tokenId];
        string memory base = baseURI;
        
        // If there is no base URI, return the token URI.
        if (bytes(base).length == 0) {
            return _tokenURI;
        }
        // If both are set, concatenate the baseURI and tokenURI (via abi.encodePacked).
        if (bytes(_tokenURI).length > 0) {
            return string(abi.encodePacked(base, _tokenURI));
        }
        // If there is a baseURI but no tokenURI, concatenate the tokenID to the baseURI.
        return string(abi.encodePacked(base, tokenId.toString()));
    }    

    /**
    * @dev Economic Control Functions:
    *
    *   toggle profit earning
    *
    *   set power level - increase, decrease, or reset
    *   used for managing and recording economic earnings potential of a token
    *   can be upgraded via compounding rewards, called by the power controller contract
     */


    /**
    * @dev toggle earning profit - will be toggled off during auction
     */
    function updateIsEarning(
        bool earningStatus, 
        uint256 tokenId
        ) 
        public 
        powerControlOnly 
        nonReentrant 
        _tokenExists(tokenId) 
    {
        alphaNodes[tokenId].isEarning = earningStatus;
        
        setLastUpdated(tokenId);
        
        emit boolAttributeChanged(tokenId, "isEarning", !earningStatus, earningStatus);
    }   

    /**
    * Called by Node NFT Power manager contract;
     */
    function increasePowerLevel(
        uint256 power, 
        uint256 tokenId
        ) 
        public 
        powerControlOnly 
        nonReentrant 
        _tokenExists(tokenId) 
    {
        require(power > alphaNodes[tokenId].currentPower, "Power can only increase with this function");

        uint256 previousPowerLevel = alphaNodes[tokenId].currentPower;

        alphaNodes[tokenId].currentPower = power;
        setLastUpdated(tokenId);

        emit powerChanged(tokenId, previousPowerLevel, power, block.timestamp);
    }

    function decreasePowerLevel(
        uint256 power, 
        uint256 tokenId
        ) 
        public 
        powerControlOnly 
        nonReentrant
        _tokenExists(tokenId) 
    {
        require(power < alphaNodes[tokenId].currentPower, "Power can only decrease with this function");
        require(power > 0, "Power must be greater than 0");

        uint256 previousPowerLevel = alphaNodes[tokenId].currentPower;

        alphaNodes[tokenId].currentPower = power;
        setLastUpdated(tokenId);

        emit powerChanged(tokenId, previousPowerLevel, power, block.timestamp);
    }

    function resetPowerLevel(
        uint256 tokenId
        ) 
        public 
        powerControlOnly 
        nonReentrant 
        _tokenExists(tokenId) 
    {
        uint256 previousPowerLevel = alphaNodes[tokenId].currentPower;
        
        alphaNodes[tokenId].currentPower = _startingPower;
        setLastUpdated(tokenId);
        
        emit powerChanged(tokenId, previousPowerLevel, _startingPower, block.timestamp);
    }
    

    /**
    *   @dev Marketplace only function, auto sets to not earning if isForSale is true
     */
    function setIsForSale(
        bool isForSale, 
        uint256 tokenId
        ) 
        public 
        marketPlaceOnly 
        nonReentrant 
        _tokenExists(tokenId) 
    {
        bool previousEarningStatus = alphaNodes[tokenId].isEarning;
        // set is earning to the inverse of isForSale
        alphaNodes[tokenId].isEarning = !isForSale;
        emit boolAttributeChanged(tokenId, "isEarning", previousEarningStatus, alphaNodes[tokenId].isEarning);
    }
    

    /**
    * @dev superadmin only - address updates to enable modularity of system
     */
    function changeMinter(
        address newAddress
        ) 
        public 
        superAdminOnly 
        nonReentrant 
    {
        require(newAddress == address(newAddress), "Invalid address");

        address oldAddress = tokenMinter;

        tokenMinter = newAddress;

        emit contractManagementChanged("tokenMinter", oldAddress, newAddress);
    }

    function changeAttributeManager(
        address newAddress
        ) 
        public 
        superAdminOnly 
        nonReentrant 
    {
        address oldAddress = attributeManager;

        attributeManager = newAddress;

        emit contractManagementChanged("attributeManager", oldAddress, newAddress);
    }

    function changePowerManager(
        address newAddress
        ) 
        public 
        superAdminOnly 
        nonReentrant 
    {
        address oldAddress = powerManager;

        powerManager = newAddress;

        emit contractManagementChanged("powerManager", oldAddress, newAddress);
    }

    function changeMarketplaceAddress(
        address newAddress
        ) 
        public 
        superAdminOnly 
        nonReentrant 
    {
        address oldAddress = _marketplaceAddress;

        setApprovalForAll(_marketplaceAddress, false);
        _marketplaceAddress = newAddress;

        setApprovalForAll(newAddress, true);

        emit marketPlaceChanged(oldAddress, newAddress);
    }

    /**
    * @dev Change global transfer cooldown
     */
    function setGlobalOwnerShipTransferCooldown(
        uint256 numMinutes
        ) 
        public 
        superAdminOnly
        nonReentrant 
    {
        require(numMinutes > 1, "Number of minutes must be greater than 1");
        _ownerShipTransferCooldown = numMinutes * 1 minutes;
    }

    /**
    * @dev  Change transfer cooldown for single token by id
     */
    function setOwnerShipTransferCooldownByTokenId(
        uint256 numMinutes, 
        uint256 tokenId
        ) 
        public 
        nonReentrant 
        superAdminOnly 
        tokenIDInRange(tokenId) 
    {
        require(numMinutes > 1, "Number of minutes must be greater than 1");
        alphaNodes[tokenId].ownerShipTransferCooldown = numMinutes * 1 minutes;
    }

    /**
    * @dev Private Utils
    */
    
    function setLastUpdated(
        uint tokenId
        ) 
        private 
    {
        alphaNodes[tokenId].updated = block.timestamp;
    }

    /**
    *  @dev On Chain Attribute Management, Name, Total Earned, Vanity String, Vanity Numeric, Game String, Game Numeric
    */
    function updateName(
        string memory name, 
        uint256 tokenId
        ) 
        public 
        attributeManagerOnly 
        nonReentrant 
        _tokenExists(tokenId) 
    {
        string memory previousName = alphaNodes[tokenId].name;

        alphaNodes[tokenId].name = name;
        setLastUpdated(tokenId);
        
        emit stringAttributeChanged(tokenId, "tokenName", previousName, name);
    }

    function updateTotalPaid(
        uint256 amount, 
        uint256 tokenId
        ) 
        public 
        attributeManagerOnly 
        nonReentrant 
        _tokenExists(tokenId) 
        returns(uint256) 
    {
        uint256 previousValue = alphaNodes[tokenId].totalPaid;

        alphaNodes[tokenId].totalPaid += amount; 
        setLastUpdated(tokenId);
        
        emit uintAttributeChanged(tokenId, "totalPaid", previousValue, alphaNodes[tokenId].totalPaid);

        return alphaNodes[tokenId].totalPaid;
    }

    function addVanityStringAttribute(
        uint256 tokenId, 
        string memory _attributeName, 
        string memory _attributeValue
        ) 
        public 
        attributeManagerOnly 
        _tokenExists(tokenId) 
    {
        VanityAttributeStringType memory stringAttribute;

        stringAttribute = VanityAttributeStringType({
            attributeName: _attributeName,
            attributeValue: _attributeValue,
            enabled: true
        });
        
        vanityStringAttributes[tokenId].push(stringAttribute);
        
        // get index of attribute
        uint256 attributeIndex = vanityStringAttributes[tokenId].length - 1;
        
        emit vanityStringAttributeAdded(
            tokenId, 
            _attributeName,
            attributeIndex, 
            _attributeValue
        );
    }

    function updateVanityStringAttribute(
        uint256 tokenId,
        uint256 attributeIndex,
        bool isEnabled, 
        string memory _attributeName, 
        string memory _attributeValue
        ) 
        public 
        attributeManagerOnly 
        _tokenExists(tokenId) 
    {
        string memory previousValue = vanityStringAttributes[tokenId][attributeIndex].attributeValue;
        
        vanityStringAttributes[tokenId][attributeIndex] = VanityAttributeStringType({
            attributeName: _attributeName,
            attributeValue: _attributeValue,
            enabled: isEnabled
        });

        emit vanityStringAttributeUpdated(
            tokenId, 
            _attributeName,
            attributeIndex,
            previousValue, 
            _attributeValue
        );
    }

    function removeVanityStringAttribute(
        uint256 tokenId, 
        uint256 attributeIndex
        ) 
        public 
        attributeManagerOnly 
        _tokenExists(tokenId) 
    {
        string memory attrName = vanityStringAttributes[tokenId][attributeIndex].attributeName;
        
        delete vanityStringAttributes[tokenId][attributeIndex];
        
        emit attributeDeleted(tokenId, attrName, attributeIndex);
    }

    function getVanityStringAttributesByTokenId (
        uint256 tokenId
        ) 
        public
        view 
        _tokenExists(tokenId) 
        returns (VanityAttributeStringType[] memory) 
    {
        return vanityStringAttributes[tokenId];
    }

    /**
    * Vanity Numeric Attributes Management
     */    

    function addVanityNumericAttribute(
        uint256 tokenId, 
        string memory _attributeName, 
        uint256 _attributeValue
        ) 
        public 
        attributeManagerOnly 
        _tokenExists(tokenId) 
    {
        VanityAttributeNumericType memory numericAttribute;

        numericAttribute = VanityAttributeNumericType({
            attributeName: _attributeName,
            attributeValue: _attributeValue,
            enabled: true
        });
        
        vanityNumericAttributes[tokenId].push(numericAttribute);

        uint256 attributeIndex = vanityNumericAttributes[tokenId].length - 1;

        emit vanityNumericAttributeAdded(
            tokenId, 
            _attributeName,
            attributeIndex, 
            _attributeValue
        );
    }

    function updateVanityNumericAttribute(
        uint256 tokenId, 
        string memory _attributeName, 
        uint256 _attributeValue,
        uint256 attributeIndex,
        bool isEnabled
        ) 
        public 
        attributeManagerOnly 
        _tokenExists(tokenId) 
    {
        uint previousValue = vanityNumericAttributes[tokenId][attributeIndex].attributeValue;

        vanityNumericAttributes[tokenId][attributeIndex] = VanityAttributeNumericType({
            attributeName: _attributeName,
            attributeValue: _attributeValue,
            enabled: isEnabled
        });

        emit vanityNumericAttributeUpdated(
            tokenId, 
            _attributeName,
            attributeIndex,
            previousValue, 
            _attributeValue
        );
    }

    function removeVanityNumericAttribute(
        uint256 tokenId, 
        uint256 attributeIndex
        ) 
        public 
        attributeManagerOnly 
        _tokenExists(tokenId) 
    {
        string memory attributeName = vanityNumericAttributes[tokenId][attributeIndex].attributeName;

        delete vanityNumericAttributes[tokenId][attributeIndex];

        emit attributeDeleted(tokenId,  attributeName, attributeIndex);
    }

    function getVanityNumericAttributesByTokenId (
        uint256 tokenId
        ) 
        public
        view 
        _tokenExists(tokenId) 
        returns (VanityAttributeNumericType[] memory) 
    {
        return vanityNumericAttributes[tokenId];
    }

    /**
    *  Add, edit, remove Game attributes by token id
     */
    function addGameStringAttribute(
        uint256 tokenId, 
        string memory _attributeName, 
        string memory _attributeValue
        ) 
        public 
        attributeManagerOnly 
        _tokenExists(tokenId) 
    {
        GameAttributeStringType memory stringAttribute;

        stringAttribute = GameAttributeStringType({
            attributeName: _attributeName,
            attributeValue: _attributeValue,
            enabled: true
        });
        
        gameStringAttributes[tokenId].push(stringAttribute);
        uint attributeIndex = gameStringAttributes[tokenId].length - 1;

        emit gameStringAttributeAdded(tokenId, _attributeName, attributeIndex, _attributeValue);
    }

    function updateGameStringAttribute(
        uint256 tokenId, 
        string memory _attributeName, 
        string memory _attributeValue,
        bool isEnabled,
        uint256 attributeIndex
        ) 
        public 
        attributeManagerOnly 
        _tokenExists(tokenId) 
    {   
        string memory previousValue = gameStringAttributes[tokenId][attributeIndex].attributeValue;

        gameStringAttributes[tokenId][attributeIndex] = GameAttributeStringType({
            attributeName: _attributeName,
            attributeValue: _attributeValue,
            enabled: isEnabled
        });

        emit gameStringAttributeUpdated(tokenId, _attributeName, attributeIndex, previousValue, _attributeValue);
    }

    function removeGameStringAttribute(
        uint256 tokenId, 
        uint256 attributeIndex
        ) 
        public 
        attributeManagerOnly  
        _tokenExists(tokenId) 
    {
        string memory attributeName = gameStringAttributes[tokenId][attributeIndex].attributeName;
        
        delete gameStringAttributes[tokenId][attributeIndex];
        
        emit attributeDeleted(tokenId, attributeName, attributeIndex);
    }

    function getGameStringAttributesByTokenId (
        uint256 tokenId
        ) 
        public
        view 
        _tokenExists(tokenId) 
        returns (GameAttributeStringType[] memory) 
    {
        return gameStringAttributes[tokenId];
    }

    /**
    * Game Numeric Attributes Management
     */
    function addGameNumericAttribute(
        uint256 tokenId, 
        string memory _attributeName, 
        uint256 _attributeValue
        ) 
        public 
        attributeManagerOnly 
        _tokenExists(tokenId) 
    {   
        GameAttributeNumericType memory numericAttribute;

        numericAttribute = GameAttributeNumericType({
            attributeName: _attributeName,
            attributeValue: _attributeValue,
            enabled: true
        });
        
        gameNumericAttributes[tokenId].push(numericAttribute);
        uint256 attributeIndex = gameNumericAttributes[tokenId].length - 1;

        emit gameNumericAttributeAdded(tokenId, _attributeName, _attributeValue, attributeIndex);
    }

    function updateGameNumericAttribute(
        uint256 tokenId, 
        string memory _attributeName, 
        uint256 _attributeValue,
        uint256 attributeIndex,
        bool isEnabled
        ) 
        public 
        attributeManagerOnly 
        _tokenExists(tokenId) 
    {
        uint256 previousValue = gameNumericAttributes[tokenId][attributeIndex].attributeValue;

        gameNumericAttributes[tokenId][attributeIndex] = GameAttributeNumericType({
            attributeName: _attributeName,
            attributeValue: _attributeValue,
            enabled: isEnabled
        });

        emit gameNumericAttributeUpdated(tokenId, _attributeName, attributeIndex, previousValue, _attributeValue);
    }

    function removeGameNumericAttribute(
        uint256 tokenId, 
        uint256 attributeIndex
        ) 
        public 
        attributeManagerOnly 
        _tokenExists(tokenId) 
    {
        string memory attributeName = gameNumericAttributes[tokenId][attributeIndex].attributeName;

        delete gameNumericAttributes[tokenId][attributeIndex];

        emit attributeDeleted(tokenId, attributeName, attributeIndex);
    }

    function getGameNumericAttributesByTokenId (
        uint256 tokenId
        ) 
        public
        view 
        _tokenExists(tokenId) 
        returns (GameAttributeNumericType[] memory) 
    {
        return gameNumericAttributes[tokenId];
    }

    function setSuperAdmin(address newSuperAdmin) public onlyOwner {
        superAdmin = newSuperAdmin;
    }

    /**
    * @dev Modifiers
     */
    modifier lessThanTotal() {
        require(_tokenIds.current() < total, "Can not mint any more of this series.");
        _;
    }

    modifier tokenIDInRange(uint256 tokenId) {
        require(tokenId <= _tokenIds.current(), "TokenId index is out of range.");
        _;
    }

    modifier _tokenExists(uint256 tokenId) {
        require(_exists(tokenId), "TokenId does not exist.");
        _;
    }

    modifier validAddress(address _address) {
        require(_address != address(0), "Invalid address");
        require(_address != address(0x0), "Invalid address");
        _;
    }    
    
}