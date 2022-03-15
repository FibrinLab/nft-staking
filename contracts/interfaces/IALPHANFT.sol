
pragma solidity ^0.8.7;

interface IALPHANFT {
  function _marketplaceAddress (  ) external view returns ( address );
  function _ownerShipTransferCooldown (  ) external view returns ( uint256 );
  function _startingPower (  ) external view returns ( uint256 );
  function addGameNumericAttribute ( uint256 tokenId, string memory _attributeName, uint256 _attributeValue ) external;
  function addGameStringAttribute ( uint256 tokenId, string memory _attributeName, string memory _attributeValue ) external;
  function addVanityNumericAttribute ( uint256 tokenId, string memory _attributeName, string memory _attributeValue ) external;
  function addVanityStringAttribute ( uint256 tokenId, string memory _attributeName, string memory _attributeValue ) external;
  function alphaNodes ( uint256 ) external view returns ( string memory name, string memory nftType, uint256 currentPower, uint256 totalPaid, uint256 created, uint256 updated, uint256 lastOwnershipTransfer, uint256 ownerShipTransferCooldown, bool isEarning );
  function approve ( address to, uint256 tokenId ) external;
  function attributeManager (  ) external view returns ( address );
  function authorize ( address adr ) external;
  function balanceOf ( address owner ) external view returns ( uint256 );
  function baseURI (  ) external view returns ( string memory );
  function changeAttributeManager ( address newAddress ) external;
  function changeMarketplaceAddress ( address newAddress ) external;
  function changeMinter ( address newAddress ) external;
  function changePowerManager ( address newAddress ) external;
  function createToken ( address _to, string memory _nftType ) external returns ( uint256 );
  function decreasePowerLevel ( uint256 power, uint256 tokenId ) external;
  function gameNumericAttributes ( uint256, uint256 ) external view returns ( string memory attributeName, bool enabled, uint256 attributeValue );
  function gameStringAttributes ( uint256, uint256 ) external view returns ( string memory attributeName, bool enabled, string memory attributeValue );
  function getApproved ( uint256 tokenId ) external view returns ( address );
  function increasePowerLevel ( uint256 power, uint256 tokenId ) external;
  function isApprovedForAll ( address owner, address operator ) external view returns ( bool );
  function isAuthorized ( address adr ) external view returns ( bool );
  function name (  ) external view returns ( string memory );
  function owner (  ) external view returns ( address );
  function ownerOf ( uint256 tokenId ) external view returns ( address );
  function powerManager (  ) external view returns ( address );
  function removeGameNumericAttribute ( uint256 tokenId, uint256 attributeIndex ) external;
  function removeGameStringAttribute ( uint256 tokenId, uint256 attributeIndex ) external;
  function removeVanityNumericAttribute ( uint256 tokenId, uint256 attributeIndex ) external;
  function removeVanityStringAttribute ( uint256 tokenId, uint256 attributeIndex ) external;
  function renounceOwnership (  ) external;
  function resetPowerLevel ( uint256 tokenId ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId ) external;
  function safeTransferFrom ( address from, address to, uint256 tokenId, bytes calldata _data ) external;
  function setApprovalForAll ( address operator, bool approved ) external;
  function setBaseURI ( string memory baseURI_ ) external;
  function setGlobalOwnerShipTransferCooldown ( uint256 numMinutes ) external;
  function setIsForSale ( bool isForSale, uint256 tokenId ) external;
  function setOwnerShipTransferCooldownByTokenId ( uint256 numMinutes, uint256 tokenId ) external;
  function superAdmin (  ) external view returns ( address );
  function supportsInterface ( bytes4 interfaceId ) external view returns ( bool );
  function symbol (  ) external view returns ( string memory );
  function tokenMinter (  ) external view returns ( address );
  function tokenURI ( uint256 tokenId ) external view returns ( string memory );
  function total (  ) external view returns ( uint256 );
  function transferFrom ( address from, address to, uint256 tokenId ) external;
  function transferOwnership ( address newOwner ) external;
  function unauthorize ( address adr ) external;
  function updateGameNumericAttribute ( uint256 tokenId, string memory _attributeName, uint256 _attributeValue, uint256 attributeIndex, bool isEnabled ) external;
  function updateGameStringAttribute ( uint256 tokenId, string memory _attributeName, string memory _attributeValue, bool isEnabled, uint256 attributeIndex ) external;
  function updateIsEarning ( bool earningStatus, uint256 tokenId ) external;
  function updateName ( string memory name, uint256 tokenId ) external;
  function updateTotalPaid ( uint256 amount, uint256 tokenId ) external returns ( uint256 );
  function updateVanityNumericAttribute ( uint256 tokenId, string memory _attributeName, uint256 _attributeValue, uint256 attributeIndex, bool isEnabled ) external;
  function updateVanityStringAttribute ( uint256 tokenId, uint256 attributeIndex, bool isEnabled, string memory _attributeName, string memory _attributeValue ) external;
  function vanityNumericAttributes ( uint256, uint256 ) external view returns ( string memory attributeName, bool enabled, uint256 attributeValue );
  function vanityStringAttributes ( uint256, uint256 ) external view returns ( string memory attributeName, bool enabled, string memory attributeValue );

  // TODO:: set up typing for the return values, the autogenerated tuple[] is not correct
  
  // function getGameNumericAttributesByTokenId ( uint256 tokenId ) external view returns ( tuple[] );
  // function getGameStringAttributesByTokenId ( uint256 tokenId ) external view returns ( tuple[] );
  // function getVanityNumericAttributesByTokenId ( uint256 tokenId ) external view returns ( tuple[] );
  // function getVanityStringAttributesByTokenId ( uint256 tokenId ) external view returns ( tuple[] );
  
}
