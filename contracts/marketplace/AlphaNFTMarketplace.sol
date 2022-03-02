// SPDX-License-Identifier: MIT

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/interfaces/IERC165.sol";
import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/utils/Context.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/math/SafeMath.sol";
import "@openzeppelin/contracts/security/ReentrancyGuard.sol";

pragma solidity ^0.8.7;

interface IAlphaNodeNFT {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function totalSupply() external view returns (uint256);
}

contract AlphaNodesNFTMarketPlace is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct Offer {
        bool isForSale;
        uint256 alphaNodeNFTIndex;
        address payable seller;
        uint256 minValue;       // min starting price
        address onlySellTo;     // Specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint256 alphaNodeNFTIndex;
        address payable bidder;
        uint256 value;
    }

    address public MEDIUM_OF_EXCHANGE;

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

    // A record of the highest alphaNodeNFT bid
    mapping (uint256 => Bid) public alphaNodeNFTBids;

    // This creates an array of all pending withdrawals
    mapping (address => uint256) public pendingWithdrawals;

    // Events
    event alphaNodeNFTTransfer(address indexed _fromAddress, address indexed _toAddress, uint256 indexed _alphaNodeNFTIndex);
    event alphaNodeNFTOffered(uint256 indexed _alphaNodeNFTIndex, uint256 indexed _value, address indexed _toAddress);
    event alphaNodeNFTBidEntered(uint256 indexed _alphaNodeNFTIndex, uint256 indexed _value, address indexed _fromAddress);
    event alphaNodeNFTBidWithdrawn(uint256 indexed _alphaNodeNFTIndex, uint256 indexed _value, address indexed _fromAddress);
    event alphaNodeNFTBought(uint256 indexed _alphaNodeNFTIndex, uint256 _value, address indexed _fromAddress, address indexed _toAddress);
    event alphaNodeNFTRemovedFromMarketplace(uint256 indexed _alphaNodeNFTIndex);

    /**
     * @dev Contract constructor
     */
    constructor(
        address nftToken, 
        address payable royaltyDistributorAddress,
        uint256 nftSupply
        ) {
        devAddr = payable(msg.sender);
        nftContract = nftToken;
        MAX_NFT_SUPPLY = nftSupply;
        ROYALTY_DISTRIBUTOR = royaltyDistributorAddress;
    }

    /**
     * @dev Withdraw FTM from this contract (callable by owner only)
    */
    function withdrawDevFunds() public onlyOwner nonReentrant {
        _safeTransferMediumOfExchange(devAddr, address(this).balance);
    }

    /**
     * @dev Update dev address by the previous dev
     */
    function setDev(address payable _devAddr) external onlyOwner {
        devAddr = _devAddr;
    }
    /**
    * @dev Transfer FTM safely between users
     */
    function _safeTransferMediumOfExchange(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "TransferHelper: FTM_TRANSFER_FAILED");
    }

    /**
     * @dev Transfer ownership of a alphaNodeNFT to another user without requiring payment
     */
    function transferAlphaNodeNFTWithoutPayment(address payable _to, uint256 _alphaNodeNFTIndex) public {
        requireChecks(_alphaNodeNFTIndex);

        if (alphaNodeNFTsOfferedForSale[_alphaNodeNFTIndex].isForSale) {
            alphaNodeNFTNoLongerForSale(_alphaNodeNFTIndex);
        }

        IAlphaNodeNFT(nftContract).safeTransferFrom(msg.sender, _to, _alphaNodeNFTIndex);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = alphaNodeNFTBids[_alphaNodeNFTIndex];

        if (bid.bidder == _to) {
            // Kill bid and refund value
            _safeTransferMediumOfExchange(_to, bid.value);
            alphaNodeNFTBids[_alphaNodeNFTIndex] = Bid(false, _alphaNodeNFTIndex, payable(address(0)), 0);
        }

        emit alphaNodeNFTTransfer(msg.sender, _to, _alphaNodeNFTIndex);
    }

    /**
     * @dev Set a alphaNodeNFT's for sale offer to false
     */
    function alphaNodeNFTNoLongerForSale(uint256 _alphaNodeNFTIndex) public {
        requireChecks(_alphaNodeNFTIndex);

        alphaNodeNFTsOfferedForSale[_alphaNodeNFTIndex] = Offer(false, _alphaNodeNFTIndex, payable(msg.sender), 0, address(0));
        emit alphaNodeNFTRemovedFromMarketplace(_alphaNodeNFTIndex);
    }

    /**
     * @dev Offer a alphaNodeNFT for sale with a minimum price
     */
    function offerAlphaNodeNFTForSale(uint256 _alphaNodeNFTIndex, uint256 _minSalePriceInWei) public {
        requireChecks(_alphaNodeNFTIndex);

        alphaNodeNFTsOfferedForSale[_alphaNodeNFTIndex] = Offer(true, _alphaNodeNFTIndex, payable(msg.sender), _minSalePriceInWei, address(0));
        emit alphaNodeNFTOffered(_alphaNodeNFTIndex, _minSalePriceInWei, address(0));
    }

    /**
     * @dev Offer to sell a alphaNodeNFT to a specific address
     */
    function offerAlphaNodeNFTForSaleToAddress(uint256 _alphaNodeNFTIndex, uint256 _minSalePriceInWei, address _toAddress) public {
        requireChecks(_alphaNodeNFTIndex);

        alphaNodeNFTsOfferedForSale[_alphaNodeNFTIndex] = Offer(true, _alphaNodeNFTIndex, payable(msg.sender), _minSalePriceInWei, _toAddress);
        emit alphaNodeNFTOffered(_alphaNodeNFTIndex, _minSalePriceInWei, _toAddress);
    }

    /**
     * @dev The alphaNodeNFT buying function
     */
    function buyalphaNodeNFT(uint256 _alphaNodeNFTIndex) payable public nonReentrant {
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
        _safeTransferMediumOfExchange(devAddr, royaltyFee);
        IAlphaNodeNFT(nftContract).safeTransferFrom(seller, msg.sender, _alphaNodeNFTIndex);
        alphaNodeNFTNoLongerForSale(_alphaNodeNFTIndex);
        
        emit alphaNodeNFTBought(_alphaNodeNFTIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = alphaNodeNFTBids[_alphaNodeNFTIndex];

        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            _safeTransferMediumOfExchange(msg.sender, bid.value);
            alphaNodeNFTBids[_alphaNodeNFTIndex] = Bid(false, _alphaNodeNFTIndex, payable(address(0)), 0);
        }
    }

    /**
     * @dev Allows marketplace users to withdraw their funds
     */
    function userWithdrawal() public nonReentrant {
        uint256 amount = pendingWithdrawals[msg.sender];
        // Remember to zero the pending refund before
        // sending to prevent re-entrancy attacks
        pendingWithdrawals[msg.sender] = 0;
        _safeTransferMediumOfExchange(msg.sender, amount);
    }

    /**
     * @dev Enter a bid for a alphaNodeNFT
     */
    function enterBidForalphaNodeNFT(uint256 _alphaNodeNFTIndex) payable public nonReentrant {
        require(_alphaNodeNFTIndex <= MAX_NFT_SUPPLY, "No alphaNodeNFT");
        require(IERC721(nftContract).ownerOf(_alphaNodeNFTIndex) != address(0), "No owner");
        require(msg.value != 0, "0 bid");

        Bid memory existing = alphaNodeNFTBids[_alphaNodeNFTIndex];

        require(msg.value > existing.value, "Low bid");

        if (existing.value > 0) {
            // Refund the failing bid
            _safeTransferMediumOfExchange(existing.bidder, existing.value);
        }

        alphaNodeNFTBids[_alphaNodeNFTIndex] = Bid(true, _alphaNodeNFTIndex, payable(msg.sender), msg.value);
        emit alphaNodeNFTBidEntered(_alphaNodeNFTIndex, msg.value, msg.sender);
    }

    /**
     * @dev Allows alphaNodeNFT owner to accept a bid
     */
    function acceptBidForalphaNodeNFT(uint256 _alphaNodeNFTIndex) public nonReentrant {
        requireChecks(_alphaNodeNFTIndex);

        address seller = msg.sender;
        Bid memory bid = alphaNodeNFTBids[_alphaNodeNFTIndex];

        require(bid.value > 0, "0 bid");

        IAlphaNodeNFT(nftContract).safeTransferFrom(seller, bid.bidder, _alphaNodeNFTIndex);

        alphaNodeNFTsOfferedForSale[_alphaNodeNFTIndex] = Offer(false, _alphaNodeNFTIndex, bid.bidder, 0, address(0));
        alphaNodeNFTBids[_alphaNodeNFTIndex] = Bid(false, _alphaNodeNFTIndex, payable(address(0)), 0);

        uint256 bidAmount = bid.value;

        uint256 royaltyFee = bidAmount.mul(royaltyTransactionFee).div(10000);
        uint256 paymentAfterFeeRemoved = bidAmount.sub(royaltyFee);
        
        pendingWithdrawals[seller] += paymentAfterFeeRemoved;
        _safeTransferMediumOfExchange(devAddr, royaltyFee);
        

        emit alphaNodeNFTBought(_alphaNodeNFTIndex, bid.value, seller, bid.bidder);
    }

    /**
     * @dev Withdraw a bid for a alphaNodeNFT
     */
    function withdrawBidForalphaNodeNFT(uint256 _alphaNodeNFTIndex) public nonReentrant {
        require(_alphaNodeNFTIndex <= MAX_NFT_SUPPLY, "No alphaNodeNFT");
        require(IERC721(nftContract).ownerOf(_alphaNodeNFTIndex) != address(0), "No owner");

        Bid memory bid = alphaNodeNFTBids[_alphaNodeNFTIndex];

        require(bid.bidder == msg.sender, "Not bidder");

        emit alphaNodeNFTBidWithdrawn(_alphaNodeNFTIndex, bid.value, msg.sender);
        alphaNodeNFTBids[_alphaNodeNFTIndex] = Bid(false, _alphaNodeNFTIndex, payable(address(0)), 0);

        // Refund the bid money
        _safeTransferMediumOfExchange(msg.sender, bid.value);
    }

    /**
     * @dev Require checks to cut down on redundancy
     */
    function requireChecks(uint256 _alphaNodeNFTIndex) internal view {
        require(IERC721(nftContract).ownerOf(_alphaNodeNFTIndex) == msg.sender, "Not owner");
        require(_alphaNodeNFTIndex <= MAX_NFT_SUPPLY, "No alphaNodeNFT");
    }

    /**
    *  @dev Set Royalty Distributor Address
     */
    function setRoyaltyDistributorAddress(address payable newAddress) public onlyOwner nonReentrant {
        ROYALTY_DISTRIBUTOR = newAddress;
    }
}