// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

import "../interfaces/IALPHANFT.sol";

pragma solidity ^0.8.7;

contract AlphaNodesNFTMarketPlace is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct Offer {
        bool isForSale;
        uint256 auctionLength;
        uint256 alphaNodeNFTIndex;
        address payable seller;
        uint256 minValue;       // min starting price
        address onlySellTo;     // Specify to sell only to a specific person       
    }

    struct SaleType {
        bool nativeCurrencyAuction;
    }

    struct Bid {
        bool hasBid;
        uint256 alphaNodeNFTIndex;
        address payable bidder;
        uint256 value;
    }

    address public ERC20_MEDIUM_OF_EXCHANGE;

    // Max supply of alphaNodeNFTs
    uint256 public MAX_NFT_SUPPLY; // set in constructor 

    // The alphaNodes contract address
    address public nftContract;

    // Dev address
    address payable public devAddr;

    // Royalty Distributor
    address payable public ROYALTY_DISTRIBUTOR;

    // Royalty fee for devs, 10 === 0.1% fee
    uint256 public royaltyTransactionFee = 250;

    // A record of alphaNodeNFTs that are offered for sale at a specific price, and optionally to a specific address
    mapping (uint256 => Offer) public alphaNodeNFTsOfferedForSale;
    mapping (uint256 => bool) public isNativeCurrencySaleType;

    // A record of the highest alphaNodeNFT bid
    mapping (uint256 => Bid) public alphaNodeNFTBids;

   
    // This creates an array of all pending withdrawals
    mapping (address => uint256) public pendingWithdrawals;

    // Events
    event alphaNodeNFTTransfer(address indexed _fromAddress, address indexed _toAddress, uint256 indexed _alphaNodeNFTIndex);
    event alphaNodeNFTOffered(uint256 indexed _alphaNodeNFTIndex, uint256 indexed _value, address indexed _toAddress);
    event alphaNodeNativeNFTBidEntered(uint256 indexed _alphaNodeNFTIndex, uint256 indexed _value, address indexed _fromAddress);
    event alphaNodeERC20NFTBidEntered(uint256 indexed _alphaNodeNFTIndex, uint256 indexed _value, address indexed _fromAddress);
    event alphaNodeNFTBidWithdrawn(uint256 indexed _alphaNodeNFTIndex, uint256 indexed _value, address indexed _fromAddress);
    event alphaNodeNFTBought(uint256 indexed _alphaNodeNFTIndex, uint256 _value, address indexed _fromAddress, address indexed _toAddress);
    event alphaNodeNFTRemovedFromMarketplace(uint256 indexed _alphaNodeNFTIndex);

    event royaltyTransferred(uint256 indexed amount, uint256 indexed _alphaNodeNFTIndex);

    /**
     * @dev Contract constructor
     */
    constructor(
        address nftToken, 
        address payable royaltyDistributorAddress,
        uint256 nftSupply,
        address _ERC20_MEDIUM_OF_EXCHANGE
        ) {
        devAddr = payable(msg.sender);
        nftContract = nftToken;
        MAX_NFT_SUPPLY = nftSupply;
        ROYALTY_DISTRIBUTOR = payable(royaltyDistributorAddress);
        ERC20_MEDIUM_OF_EXCHANGE = _ERC20_MEDIUM_OF_EXCHANGE;
    }

    /**
     * @dev Update dev address by the previous dev
     */
    function setDev(
        address payable _devAddr
        ) 
        external 
        onlyOwner 
    {
        devAddr = _devAddr;
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

    function transferERC20PaymentToken(
        address to, 
        uint256 amount
        ) 
        internal 
    {
        IERC20(ERC20_MEDIUM_OF_EXCHANGE).transfer(to, amount);
    }

    /**
     * @dev Transfer ownership of a alphaNodeNFT to another user without requiring payment
     */
    function transferAlphaNodeNFTWithoutPayment(
        address payable _to, 
        uint256 _alphaNodeNFTIndex
        ) 
        public 
    {
        requireChecks(_alphaNodeNFTIndex);

        if (alphaNodeNFTsOfferedForSale[_alphaNodeNFTIndex].isForSale) {
            alphaNodeNFTNoLongerForSale(_alphaNodeNFTIndex);
            IALPHANFT(nftContract).setIsForSale(false, _alphaNodeNFTIndex);
        }

        IALPHANFT(nftContract).safeTransferFrom(msg.sender, _to, _alphaNodeNFTIndex);        

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = alphaNodeNFTBids[_alphaNodeNFTIndex];

        if (bid.bidder == _to) {
            // Kill bid and refund value
            _safeTransferNative(_to, bid.value);
            alphaNodeNFTBids[_alphaNodeNFTIndex] = Bid(false, _alphaNodeNFTIndex, payable(address(0)), 0);
        }

        emit alphaNodeNFTTransfer(msg.sender, _to, _alphaNodeNFTIndex);
    }

    /**
     * @dev Set a alphaNodeNFT's for sale offer to false
     */
    function alphaNodeNFTNoLongerForSale(
        uint256 _alphaNodeNFTIndex
        ) 
        public 
    {
        requireChecks(_alphaNodeNFTIndex);

        alphaNodeNFTsOfferedForSale[_alphaNodeNFTIndex] = Offer(
            false,
            0,
            _alphaNodeNFTIndex, 
            payable(msg.sender), 
            0, 
            address(0)
        );

        IALPHANFT(nftContract).setIsForSale(false, _alphaNodeNFTIndex);

        emit alphaNodeNFTRemovedFromMarketplace(_alphaNodeNFTIndex);
    }

    /**
     * @dev Offer a alphaNodeNFT for sale with a minimum price
     */
    function offerAlphaNodeNFTForSaleNative(
        uint256 _alphaNodeNFTIndex, 
        uint256 _minSalePriceInWei,
        uint256 auctionLength
        ) 
        public 
    {
        requireChecks(_alphaNodeNFTIndex);

        uint256 time = auctionLength * 1 days;

        alphaNodeNFTsOfferedForSale[_alphaNodeNFTIndex] = Offer(
            true, 
            time,
            _alphaNodeNFTIndex, 
            payable(msg.sender), 
            _minSalePriceInWei, 
            address(0)
        );
        emit alphaNodeNFTOffered(_alphaNodeNFTIndex, _minSalePriceInWei, address(0));
    }

    function offerAlphaNodeNFTForSaleERC20(
        uint256 _alphaNodeNFTIndex, 
        uint256 _minSalePriceInWei,
        uint256 auctionLength
        ) 
        public 
    {
        requireChecks(_alphaNodeNFTIndex);
        
        uint256 time = auctionLength * 1 days;
        
        alphaNodeNFTsOfferedForSale[_alphaNodeNFTIndex] = Offer(
            true, 
            time,
            _alphaNodeNFTIndex, 
            payable(msg.sender), 
            _minSalePriceInWei, 
            address(0)
        );

        IALPHANFT(nftContract).setIsForSale(true, _alphaNodeNFTIndex);
        
        emit alphaNodeNFTOffered(_alphaNodeNFTIndex, _minSalePriceInWei, address(0));        
    }

    /**
     * @dev Offer to sell a alphaNodeNFT to a specific address
     */
    function offerAlphaNodeNFTForSaleToAddressNative(
        uint256 _alphaNodeNFTIndex, 
        uint256 _minSalePriceInWei, 
        address _toAddress,
        uint256 auctionLength
        ) 
        public 
    {
        requireChecks(_alphaNodeNFTIndex);

        uint256 time = auctionLength * 1 days;

        isNativeCurrencySaleType[_alphaNodeNFTIndex] = true;
        alphaNodeNFTsOfferedForSale[_alphaNodeNFTIndex] = Offer(
            true,
            time,
            _alphaNodeNFTIndex, 
            payable(msg.sender), 
            _minSalePriceInWei, 
            _toAddress
        );
        
        emit alphaNodeNFTOffered(_alphaNodeNFTIndex, _minSalePriceInWei, _toAddress);
    }
    
    function offerAlphaNodeNFTForSaleToAddressERC20(
        uint256 _alphaNodeNFTIndex, 
        uint256 _minSalePriceInWei, 
        address _toAddress,
        uint256 auctionLength
        ) 
        public 
    {
        requireChecks(_alphaNodeNFTIndex);

        uint256 time = auctionLength * 1 days;

        isNativeCurrencySaleType[_alphaNodeNFTIndex] = false;
        alphaNodeNFTsOfferedForSale[_alphaNodeNFTIndex] = Offer(
            true,
            time,
            _alphaNodeNFTIndex, 
            payable(msg.sender), 
            _minSalePriceInWei, 
            _toAddress
        );
        
        emit alphaNodeNFTOffered(_alphaNodeNFTIndex, _minSalePriceInWei, _toAddress);
    }

    /**
     * @dev The alphaNodeNFT buying function
     */
    function buyalphaNodeNFT(
        uint256 _alphaNodeNFTIndex
        ) 
        payable 
        public 
        nonReentrant 
    {
        Offer memory offer = alphaNodeNFTsOfferedForSale[_alphaNodeNFTIndex];

        require(_alphaNodeNFTIndex <= MAX_NFT_SUPPLY, "No alphaNodeNFT");
        require(offer.isForSale, "Not for sale");
        require(msg.value >= offer.minValue, "Offer not high enough.");
        require(offer.seller == IERC721(nftContract).ownerOf(_alphaNodeNFTIndex), "Seller not owner");

        if (offer.onlySellTo != address(0)) {
            require(offer.onlySellTo == msg.sender, "Invalid buyer");
        }

        uint256 paymentReceived = msg.value;
        address seller = offer.seller;

        uint256 royaltyFee = paymentReceived.mul(royaltyTransactionFee).div(10000);
        uint256 paymentAfterFeeRemoved = paymentReceived.sub(royaltyFee);
        pendingWithdrawals[seller] += paymentAfterFeeRemoved;
        
        IALPHANFT(nftContract).safeTransferFrom(seller, msg.sender, _alphaNodeNFTIndex);
        alphaNodeNFTNoLongerForSale(_alphaNodeNFTIndex);
        
        _safeTransferNative(ROYALTY_DISTRIBUTOR, royaltyFee);

        emit alphaNodeNFTBought(_alphaNodeNFTIndex, msg.value, seller, msg.sender);        
        emit royaltyTransferred(paymentReceived, _alphaNodeNFTIndex);
        
        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = alphaNodeNFTBids[_alphaNodeNFTIndex];

        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            _safeTransferNative(msg.sender, bid.value);
            alphaNodeNFTBids[_alphaNodeNFTIndex] = Bid(false, _alphaNodeNFTIndex, payable(address(0)), 0);
        }
    }

    /**
     * @dev Allows marketplace users to withdraw their funds
     */
    function userWithdrawal() 
        public 
        nonReentrant 
    {
        uint256 amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        _safeTransferNative(msg.sender, amount);
    }

    /**
     * @dev Enter a bid for a alphaNodeNFT
     */
    function enterNativeBidForalphaNodeNFT(
        uint256 _alphaNodeNFTIndex
        ) 
        payable 
        public 
        nonReentrant 
    {
        require(_alphaNodeNFTIndex <= MAX_NFT_SUPPLY, "No alphaNodeNFT");
        
        // require that this token sale to be one that only accepts bids in native currency
        require(isNativeCurrencySaleType[_alphaNodeNFTIndex] == true, "Must use different form of payment");
        
        require(IERC721(nftContract).ownerOf(_alphaNodeNFTIndex) != address(0), "No owner");
        require(msg.value != 0, "0 bid");

        Bid memory existing = alphaNodeNFTBids[_alphaNodeNFTIndex];

        require(msg.value > existing.value, "Low bid");

        if (existing.value > 0) {
            // Refund the failing bid
            _safeTransferNative(existing.bidder, existing.value);
        }

        alphaNodeNFTBids[_alphaNodeNFTIndex] = Bid(true, _alphaNodeNFTIndex, payable(msg.sender), msg.value);
        emit alphaNodeNativeNFTBidEntered(_alphaNodeNFTIndex, msg.value, msg.sender);
    }

    function enterERC20BidForalphaNodeNFT(
        uint256 _alphaNodeNFTIndex, 
        uint256 amountERC20
        ) 
        payable 
        public 
        nonReentrant 
    {
        require(_alphaNodeNFTIndex <= MAX_NFT_SUPPLY, "No alphaNodeNFT");
        
        // require this token sale to require bids in non native currency
        require(isNativeCurrencySaleType[_alphaNodeNFTIndex] == false, "Must use different form of payment");
        
        require(IERC721(nftContract).ownerOf(_alphaNodeNFTIndex) != address(0), "No owner");
        require(amountERC20 != 0, "0 bid");
        require(IERC20(ERC20_MEDIUM_OF_EXCHANGE).balanceOf(msg.sender) >= amountERC20, "Insufficient Balance");

        Bid memory existing = alphaNodeNFTBids[_alphaNodeNFTIndex];

        require(amountERC20 > existing.value, "Low bid");

        if (existing.value > 0) {
            // Refund the failing bid
            _safeTransferNative(existing.bidder, existing.value);
        }

        alphaNodeNFTBids[_alphaNodeNFTIndex] = Bid(true, _alphaNodeNFTIndex, payable(msg.sender), msg.value);
        emit alphaNodeERC20NFTBidEntered(_alphaNodeNFTIndex, amountERC20, msg.sender);
    }

    /**
     * @dev Allows alphaNodeNFT owner to accept a bid
     */
    function acceptBidForalphaNodeNFT(
        uint256 _alphaNodeNFTIndex
        ) 
        public 
        nonReentrant 
    {
        requireChecks(_alphaNodeNFTIndex);

        address seller = msg.sender;
        Bid memory bid = alphaNodeNFTBids[_alphaNodeNFTIndex];

        require(bid.value > 0, "0 bid");

        IALPHANFT(nftContract).safeTransferFrom(seller, bid.bidder, _alphaNodeNFTIndex);

        alphaNodeNFTsOfferedForSale[_alphaNodeNFTIndex] = Offer(
            false,
            0, 
            _alphaNodeNFTIndex, 
            bid.bidder, 
            0, 
            address(0)
        );

        alphaNodeNFTBids[_alphaNodeNFTIndex] = Bid(false, _alphaNodeNFTIndex, payable(address(0)), 0);

        uint256 bidAmount = bid.value;

        uint256 royaltyFee = bidAmount.mul(royaltyTransactionFee).div(10000);
        uint256 paymentAfterFeeRemoved = bidAmount.sub(royaltyFee);
        
        pendingWithdrawals[seller] += paymentAfterFeeRemoved;
        
        _safeTransferNative(ROYALTY_DISTRIBUTOR, royaltyFee);
        
        emit alphaNodeNFTBought(_alphaNodeNFTIndex, bid.value, seller, bid.bidder);
        emit royaltyTransferred(bid.value, _alphaNodeNFTIndex);
    }

    /**
     * @dev Withdraw a bid for a alphaNodeNFT
     */
    function withdrawBidForalphaNodeNFT(
        uint256 _alphaNodeNFTIndex
        ) 
        public 
        nonReentrant 
    {
        require(_alphaNodeNFTIndex <= MAX_NFT_SUPPLY, "No alphaNodeNFT");
        require(IERC721(nftContract).ownerOf(_alphaNodeNFTIndex) != address(0), "No owner");

        Bid memory bid = alphaNodeNFTBids[_alphaNodeNFTIndex];

        require(bid.bidder == msg.sender, "Not bidder");

        emit alphaNodeNFTBidWithdrawn(_alphaNodeNFTIndex, bid.value, msg.sender);
        alphaNodeNFTBids[_alphaNodeNFTIndex] = Bid(false, _alphaNodeNFTIndex, payable(address(0)), 0);

        // Refund the bid money
        _safeTransferNative(msg.sender, bid.value);
    }

    /**
     * @dev Require checks to cut down on redundancy
     */
    function requireChecks(
        uint256 _alphaNodeNFTIndex
        ) 
        internal 
        view 
    {
        require(IERC721(nftContract).ownerOf(_alphaNodeNFTIndex) == msg.sender, "Not owner");
        require(_alphaNodeNFTIndex <= MAX_NFT_SUPPLY, "No alphaNodeNFT");
    }

    /**
    *  @dev Set Royalty Distributor Address
     */
    function setRoyaltyDistributorAddress(
        address payable newAddress
        ) 
        public 
        onlyOwner 
        nonReentrant 
    {
        ROYALTY_DISTRIBUTOR = newAddress;
    }
}