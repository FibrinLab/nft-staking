// SPDX-License-Identifier: MIT
pragma solidity ^0.8.7;

import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "../helpers/AuthContract.sol";

interface IALPHANFT {
    function createToken (address creator, string memory level) external returns(uint256);
}

interface IAlphaRewardsDistributor {
    function addShare (address creator, uint256 newShareId, string memory level) external;
}

contract AlphaShareCreator is ReentrancyGuard, AuthContract {
    using Counters for Counters.Counter;

    address public _mediumOfExchange; // ERC20
    
    address public _alphaNftContract; // ERC721
    
    address payable public _alphaShareNativePaymentSplitter;
    address payable public _alphaShareERC20PaymentSplitter;

    address payable public _alphaShareERC20BondPaymentSplitter;
    
    
    uint256 public _maxSharesPerTransaction;
    uint256 public _baseShareCostERC20;
    uint256 public _baseShareCostNative;
    uint256 public _maxNFTShares;
    uint256 public _nftSharesRemaining;

    event rewardsPoolAddressChanged(address prevAddress, address newAddress);

    struct Bond {
        uint256 price;
        address currency;
    }
    
    Counters.Counter public bondIds;
    mapping(uint256 => Bond) public bonds;
    mapping(uint256 => bool) private bondExists;
  
    constructor(
        address alphaNftContract,
        address payable alphaShareNativePaymentSplitter,
        address payable alphaShareERC20PaymentSplitter,
        address payable alphaShareERC20BondPaymentSplitter,
        uint256 maxNFTShares,
        uint256 maxSharesPerTransaction,
        uint256 baseShareCostERC20,
        uint256 baseShareCostNative
    ) {
        _alphaNftContract = alphaNftContract;
        _alphaShareNativePaymentSplitter = payable(alphaShareNativePaymentSplitter);
        _alphaShareERC20PaymentSplitter = payable(alphaShareERC20PaymentSplitter);
        _alphaShareERC20BondPaymentSplitter = payable(alphaShareERC20BondPaymentSplitter);
        
        _maxNFTShares = maxNFTShares;
        _nftSharesRemaining = maxNFTShares;

        _maxSharesPerTransaction = maxSharesPerTransaction;
        _baseShareCostERC20 = baseShareCostERC20;
        _baseShareCostNative = baseShareCostNative;
    }

    /**
    * @dev Transfer payment safely between users
     */
    function _safeTransferNative(
        address to, 
        uint256 value
        ) 
        internal 
    {
        (bool success, ) = to.call{value: value}("");
        require(success, "TransferHelper: TRANSFER_FAILED");
    }

    function approveMediumOfExchange(address holder, uint256 _tokenamount) internal returns(bool) {
       IERC20(_mediumOfExchange).approve(address(holder), _tokenamount);
       return true;
    }

    function unapproveMediumOfExchange(address holder) internal returns(bool) {
        IERC20(_mediumOfExchange).approve(address(holder), 0);
        return true;
    } 

    function purchaseSharesFullPrice(
        uint256 number, 
        string memory level
        ) 
        payable 
        public
        nonReentrant 
    {
        uint256 totalCostERC20 = number * _baseShareCostERC20;
        uint256 totalCostNative = number * _baseShareCostNative;

        require(number > 0, "Must purchase at least one.");
        require(_nftSharesRemaining >= _nftSharesRemaining - number, "Can not purchase more than available.");
        require(number <= _maxSharesPerTransaction, "Unable to purchase this quantity");
        require(msg.value == totalCostNative, "Insufficient payment amount");
        require(IERC20(_mediumOfExchange).balanceOf(msg.sender) >= totalCostERC20, "Insufficient balance");
        
        _nftSharesRemaining = _nftSharesRemaining - number;

        // TODO:: change payment address to payment receiver / splitter
        _safeTransferNative(payable(address(_alphaShareNativePaymentSplitter)), totalCostNative);
        
        approveMediumOfExchange(msg.sender, totalCostERC20);
        
        IERC20(_mediumOfExchange)
            .transfer(payable(address(_alphaShareERC20PaymentSplitter)), totalCostERC20);
        
        unapproveMediumOfExchange(msg.sender);
        
        for (uint256 i = 0; i < number; i++) {
            createShare(msg.sender, level);
        }
    }

    function purchaseSharesAtBondDiscount(
        uint256 bondId,
        uint256 number, 
        string memory level
        ) 
        payable 
        public
        nonReentrant 
    {
        require(bondExists[bondId] == true, "No Bond available at this index.");
        
        uint256 totalCostERC20 = number * bonds[bondId].price;
        
        require(number > 0, "Must purchase at least one.");
        require(_nftSharesRemaining >= _nftSharesRemaining - number, "Can not purchase more than available.");
        require(number <= _maxSharesPerTransaction, "Unable to purchase this quantity");
        
        // ERC20 purchase only with bonds
        require(IERC20(bonds[bondId].currency).balanceOf(msg.sender) >= totalCostERC20, "Insufficient balance");
        
        _nftSharesRemaining = _nftSharesRemaining - number;

        IERC20(_mediumOfExchange)
            .transfer(payable(address(_alphaShareERC20PaymentSplitter)), totalCostERC20);
        
        for (uint256 i = 0; i < number; i++) {
            createShare(msg.sender, level);
        }

    }

    function createShare(
        address creator, 
        string memory level
        ) 
        private 
    {
        // Mint the Token
        IALPHANFT(_alphaNftContract)
            .createToken(creator, level);
    }

    function registerBondERC20(
        uint256 price, 
        address currency
        ) 
        public
        authorized
        nonReentrant 
    {
        require(price > 1e9, "Price too low.");
        
        uint256 bondId = bondIds.current();
        Bond memory newBond = Bond(price, currency);

        bonds[bondId] = newBond;
        bondExists[bondId] = true;
        
        bondIds.increment();        
    }

    function removeBond(
        uint256 bondId
        ) 
        public 
        authorized
        nonReentrant 
    {
        require(bondExists[bondId] == true, "No Bond at this index.");

        delete bonds[bondId];
        bondExists[bondId] = false;
    }

    function setBaseShareCostERC20(
        uint256 newCost
        ) 
        public 
        authorized 
        nonReentrant 
    {
        require(newCost > 1e9, "New cost too low");
        _baseShareCostERC20 = newCost;
    }

    function setBaseShareCostNative(
        uint256 newCost
        ) 
        public 
        authorized 
        nonReentrant 
    {
        require(newCost > 1e18, "New cost too low");
        _baseShareCostNative = newCost;
    }

    function setAlphaNftContractAddress(
        address alphaNftContract
        )
        public
        authorized
    {
        _alphaNftContract = alphaNftContract;
    }

    function setAlphaShareNativePaymentSplitter(
        address payable alphaShareNativePaymentSplitter
        )
        public
        authorized
        nonReentrant
    {
        _alphaShareNativePaymentSplitter = payable(alphaShareNativePaymentSplitter);
    }

    function setAlphaShareERC20PaymentSplitter(
        address payable alphaShareERC20PaymentSplitter
        )
        public
        authorized
        nonReentrant
    {
        _alphaShareERC20PaymentSplitter = payable(alphaShareERC20PaymentSplitter);
    }

    function setMaxSharesPerTransaction(
        uint256 maxSharesPerTransaction
        )
        public
        authorized
        nonReentrant
    {
        _maxSharesPerTransaction = maxSharesPerTransaction;
    }    

}