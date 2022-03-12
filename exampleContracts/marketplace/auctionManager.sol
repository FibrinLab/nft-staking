pragma solidity ^0.8.7;

import "./Auction.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";

contract AuctionManager {
    uint _auctionIdCounter; // auction Id counter
    mapping(uint => Auction) public auctions; // auctions

    function createAuction(uint _endTime, uint _minIncrement, uint _directBuyPrice,uint _startPrice,address _nftAddress,uint _tokenId) external returns (bool) {} // create an auction
    function getAuctions() external view returns(address[] memory _auctions) {} // Return a list of all auctions
    function getAuctionInfo(address[] calldata _auctionsList) external view
      returns (
            uint256[] memory directBuy,
            address[] memory owner,
            uint256[] memory highestBid,
            uint256[] memory tokenIds,
            uint256[] memory endTime,
            uint256[] memory startPrice,
            uint256[] memory auctionState
      ) {} // Return the information of each auction address
}