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

interface IMagicGameNFT {
    function safeTransferFrom(address _from, address _to, uint256 _tokenId) external;
    function totalSupply() external view returns (uint256);
}

contract MagicGameMarketplace is Ownable, ReentrancyGuard {
    using SafeMath for uint256;

    struct Offer {
        bool isForSale;
        uint256 magicGameNFTIndex;
        address payable seller;
        uint256 minValue;       // FTM value
        address onlySellTo;     // Specify to sell only to a specific person
    }

    struct Bid {
        bool hasBid;
        uint256 magicGameNFTIndex;
        address payable bidder;
        uint256 value;
    }

    // Max supply of MagicGameNFTs
    uint256 public constant MAX_MagicGameNFT_SUPPLY = 10000000000000000000;

    // The magicgames contract address
    address public magicGameNFTContract;

    // Dev address
    address payable public devAddr;

    // Royalty fee for devs, 10 === 0.1% fee
    uint256 public royaltyTransactionFee = 500;

    // A record of magicGameNFTs that are offered for sale at a specific price, and optionally to a specific address
    mapping (uint256 => Offer) public magicGameNFTsOfferedForSale;

    // A record of the highest magicGameNFT bid
    mapping (uint256 => Bid) public magicGameNFTBids;

    // This creates an array of all pending withdrawals
    mapping (address => uint256) public pendingWithdrawals;

    // Events
    event MagicGameNFTTransfer(address indexed _fromAddress, address indexed _toAddress, uint256 indexed _magicGameNFTIndex);
    event MagicGameNFTOffered(uint256 indexed _magicGameNFTIndex, uint256 indexed _value, address indexed _toAddress);
    event MagicGameNFTBidEntered(uint256 indexed _magicGameNFTIndex, uint256 indexed _value, address indexed _fromAddress);
    event MagicGameNFTBidWithdrawn(uint256 indexed _magicGameNFTIndex, uint256 indexed _value, address indexed _fromAddress);
    event MagicGameNFTBought(uint256 indexed _magicGameNFTIndex, uint256 _value, address indexed _fromAddress, address indexed _toAddress);
    event MagicGameNFTRemovedFromMarketplace(uint256 indexed _magicGameNFTIndex);

    /**
     * @dev Contract constructor
     */
    constructor(address nftToken) {
        devAddr = payable(msg.sender);
        magicGameNFTContract = nftToken;
    }

    /**
     * @dev Withdraw FTM from this contract (callable by owner only)
    */
    function withdrawDevFunds() public onlyOwner nonReentrant {
        _safeTransferFTM(devAddr, address(this).balance);
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
    function _safeTransferFTM(address to, uint256 value) internal {
        (bool success, ) = to.call{value: value}("");
        require(success, "TransferHelper: FTM_TRANSFER_FAILED");
    }

    /**
     * @dev Transfer ownership of a magicGameNFT to another user without requiring payment
     */
    function transferMagicGameNFTWithoutPayment(address payable _to, uint256 _magicGameNFTIndex) public {
        requireChecks(_magicGameNFTIndex);

        if (magicGameNFTsOfferedForSale[_magicGameNFTIndex].isForSale) {
            magicGameNFTNoLongerForSale(_magicGameNFTIndex);
        }

        IMagicGameNFT(magicGameNFTContract).safeTransferFrom(msg.sender, _to, _magicGameNFTIndex);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = magicGameNFTBids[_magicGameNFTIndex];

        if (bid.bidder == _to) {
            // Kill bid and refund value
            _safeTransferFTM(_to, bid.value);
            magicGameNFTBids[_magicGameNFTIndex] = Bid(false, _magicGameNFTIndex, payable(address(0)), 0);
        }

        emit MagicGameNFTTransfer(msg.sender, _to, _magicGameNFTIndex);
    }

    /**
     * @dev Set a magicGameNFT's for sale offer to false
     */
    function magicGameNFTNoLongerForSale(uint256 _magicGameNFTIndex) public {
        requireChecks(_magicGameNFTIndex);

        magicGameNFTsOfferedForSale[_magicGameNFTIndex] = Offer(false, _magicGameNFTIndex, payable(msg.sender), 0, address(0));
        emit MagicGameNFTRemovedFromMarketplace(_magicGameNFTIndex);
    }

    /**
     * @dev Offer a magicGameNFT for sale with a minimum price
     */
    function offerMagicGameNFTForSale(uint256 _magicGameNFTIndex, uint256 _minSalePriceInWei) public {
        requireChecks(_magicGameNFTIndex);

        magicGameNFTsOfferedForSale[_magicGameNFTIndex] = Offer(true, _magicGameNFTIndex, payable(msg.sender), _minSalePriceInWei, address(0));
        emit MagicGameNFTOffered(_magicGameNFTIndex, _minSalePriceInWei, address(0));
    }

    /**
     * @dev Offer to sell a magicGameNFT to a specific address
     */
    function offerMagicGameNFTForSaleToAddress(uint256 _magicGameNFTIndex, uint256 _minSalePriceInWei, address _toAddress) public {
        requireChecks(_magicGameNFTIndex);

        magicGameNFTsOfferedForSale[_magicGameNFTIndex] = Offer(true, _magicGameNFTIndex, payable(msg.sender), _minSalePriceInWei, _toAddress);
        emit MagicGameNFTOffered(_magicGameNFTIndex, _minSalePriceInWei, _toAddress);
    }

    /**
     * @dev The magicGameNFT buying function
     */
    function buyMagicGameNFT(uint256 _magicGameNFTIndex) payable public nonReentrant {
        Offer memory offer = magicGameNFTsOfferedForSale[_magicGameNFTIndex];

        require(_magicGameNFTIndex <= MAX_MagicGameNFT_SUPPLY, "No magicGameNFT");
        require(offer.isForSale, "Not for sale");
        require(msg.value >= offer.minValue, "Not enough FTM");
        require(offer.seller == IERC721(magicGameNFTContract).ownerOf(_magicGameNFTIndex), "Seller not owner");

        if (offer.onlySellTo != address(0)) {
            require(offer.onlySellTo == msg.sender, "Invalid buyer");
        }

        uint256 paymentReceived = msg.value;
        address seller = offer.seller;

        uint256 royaltyFee = paymentReceived.mul(royaltyTransactionFee).div(10000);
        uint256 paymentAfterFeeRemoved = paymentReceived.sub(royaltyFee);
        pendingWithdrawals[seller] += paymentAfterFeeRemoved;
        _safeTransferFTM(devAddr, royaltyFee);
        IMagicGameNFT(magicGameNFTContract).safeTransferFrom(seller, msg.sender, _magicGameNFTIndex);
        magicGameNFTNoLongerForSale(_magicGameNFTIndex);
        
        emit MagicGameNFTBought(_magicGameNFTIndex, msg.value, seller, msg.sender);

        // Check for the case where there is a bid from the new owner and refund it.
        // Any other bid can stay in place.
        Bid memory bid = magicGameNFTBids[_magicGameNFTIndex];

        if (bid.bidder == msg.sender) {
            // Kill bid and refund value
            _safeTransferFTM(msg.sender, bid.value);
            magicGameNFTBids[_magicGameNFTIndex] = Bid(false, _magicGameNFTIndex, payable(address(0)), 0);
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
        _safeTransferFTM(msg.sender, amount);
    }

    /**
     * @dev Enter a bid for a magicGameNFT
     */
    function enterBidForMagicGameNFT(uint256 _magicGameNFTIndex) payable public nonReentrant {
        require(_magicGameNFTIndex <= MAX_MagicGameNFT_SUPPLY, "No magicGameNFT");
        require(IERC721(magicGameNFTContract).ownerOf(_magicGameNFTIndex) != address(0), "No owner");
        require(msg.value != 0, "0 bid");

        Bid memory existing = magicGameNFTBids[_magicGameNFTIndex];

        require(msg.value > existing.value, "Low bid");

        if (existing.value > 0) {
            // Refund the failing bid
            _safeTransferFTM(existing.bidder, existing.value);
        }

        magicGameNFTBids[_magicGameNFTIndex] = Bid(true, _magicGameNFTIndex, payable(msg.sender), msg.value);
        emit MagicGameNFTBidEntered(_magicGameNFTIndex, msg.value, msg.sender);
    }

    /**
     * @dev Allows magicGameNFT owner to accept a bid
     */
    function acceptBidForMagicGameNFT(uint256 _magicGameNFTIndex) public nonReentrant {
        requireChecks(_magicGameNFTIndex);

        address seller = msg.sender;
        Bid memory bid = magicGameNFTBids[_magicGameNFTIndex];

        require(bid.value > 0, "0 bid");

        IMagicGameNFT(magicGameNFTContract).safeTransferFrom(seller, bid.bidder, _magicGameNFTIndex);

        magicGameNFTsOfferedForSale[_magicGameNFTIndex] = Offer(false, _magicGameNFTIndex, bid.bidder, 0, address(0));
        magicGameNFTBids[_magicGameNFTIndex] = Bid(false, _magicGameNFTIndex, payable(address(0)), 0);

        uint256 bidAmount = bid.value;

        uint256 royaltyFee = bidAmount.mul(royaltyTransactionFee).div(10000);
        uint256 paymentAfterFeeRemoved = bidAmount.sub(royaltyFee);
        
        pendingWithdrawals[seller] += paymentAfterFeeRemoved;
        _safeTransferFTM(devAddr, royaltyFee);
        

        emit MagicGameNFTBought(_magicGameNFTIndex, bid.value, seller, bid.bidder);
    }

    /**
     * @dev Withdraw a bid for a magicGameNFT
     */
    function withdrawBidForMagicGameNFT(uint256 _magicGameNFTIndex) public nonReentrant {
        require(_magicGameNFTIndex <= MAX_MagicGameNFT_SUPPLY, "No magicGameNFT");
        require(IERC721(magicGameNFTContract).ownerOf(_magicGameNFTIndex) != address(0), "No owner");

        Bid memory bid = magicGameNFTBids[_magicGameNFTIndex];

        require(bid.bidder == msg.sender, "Not bidder");

        emit MagicGameNFTBidWithdrawn(_magicGameNFTIndex, bid.value, msg.sender);
        magicGameNFTBids[_magicGameNFTIndex] = Bid(false, _magicGameNFTIndex, payable(address(0)), 0);

        // Refund the bid money
        _safeTransferFTM(msg.sender, bid.value);
    }

    /**
     * @dev Require checks to cut down on redundancy
     */
    function requireChecks(uint256 _magicGameNFTIndex) internal view {
        require(IERC721(magicGameNFTContract).ownerOf(_magicGameNFTIndex) == msg.sender, "Not owner");
        require(_magicGameNFTIndex <= MAX_MagicGameNFT_SUPPLY, "No magicGameNFT");
    }
}