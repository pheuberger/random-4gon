// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";

import "./NFTBuilder.sol";
import "./SvgTools.sol";
import "./Types.sol";

uint256 constant MAX_INT = 2**256 - 1;

contract Random4Gon is ERC721URIStorage {

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  mapping (address => TokenData[]) tokenOwnerMapping;

  event NewNFTMinted(address sender, uint256 tokenId);

  constructor() ERC721("Random Four-Gons", "4GON") {
    console.log("4GON constructor");
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId) public override {
    super.safeTransferFrom(_from, _to, _tokenId);
    updateTokenArrays(_from, _to, _tokenId);
  }

  function safeTransferFrom(address _from, address _to, uint256 _tokenId, bytes memory _data) public override {
    super.safeTransferFrom(_from, _to, _tokenId, _data);
    updateTokenArrays(_from, _to, _tokenId);
  }

  function updateTokenArrays(address _from, address _to, uint256 _tokenId) private {
    TokenData[] storage fromTokens = tokenOwnerMapping[_from];
    
    for (uint256 i = 0; i < fromTokens.length; i++) {
      if (fromTokens[i].tokenId != _tokenId) continue;
      tokenOwnerMapping[_to].push(fromTokens[i]);
      removeFromTokenArray(fromTokens, i);
      break;
    }
  }

  function mint() public {
    uint256 tokenId = _tokenIds.current();

    (string memory tokenUri, TokenData memory tokenData) = NFTBuilder.generateTokenData(tokenId);

    _safeMint(msg.sender, tokenId);
    _setTokenURI(tokenId, tokenUri);
    _tokenIds.increment();
    tokenOwnerMapping[msg.sender].push(tokenData);
    emit NewNFTMinted(msg.sender, tokenId);
  }

  function combine() public {
    TokenData[] storage ownersTokens = tokenOwnerMapping[msg.sender];
    uint256 fgTokenIndex = MAX_INT;
    uint256 bgTokenIndex = MAX_INT;

    for (uint256 i = 0; i < ownersTokens.length; i++) {
      if (ownersTokens[i].tokenType == 0) {
        fgTokenIndex = i;
      } else if (ownersTokens[i].tokenType == 1) {
        bgTokenIndex = i;
      }
      if (fgTokenIndex < MAX_INT && bgTokenIndex < MAX_INT) break; 
    }

    require(fgTokenIndex < MAX_INT && bgTokenIndex < MAX_INT, 
            'You need at least one foreground and background token to combine');

    uint256 tokenId = _tokenIds.current();
    
    (string memory tokenUri, TokenData memory newTokenData) = NFTBuilder.generateCombinedTokenData(tokenId, ownersTokens[bgTokenIndex], ownersTokens[fgTokenIndex]);
    _safeMint(msg.sender, tokenId);
    _setTokenURI(tokenId, tokenUri);
    _tokenIds.increment();
    _burn(ownersTokens[fgTokenIndex].tokenId);
    _burn(ownersTokens[bgTokenIndex].tokenId);
    removeFromTokenArray(ownersTokens, fgTokenIndex);
    removeFromTokenArray(ownersTokens, bgTokenIndex);

    tokenOwnerMapping[msg.sender].push(newTokenData);
    emit NewNFTMinted(msg.sender, tokenId);
  }

  function removeFromTokenArray(TokenData[] storage _arr, uint _index) private {
    if (_index >= _arr.length) return;

    _arr[_index] = _arr[_arr.length - 1];
    _arr.pop();
  }

  function getTokensForSender() public view returns (TokenData[] memory) {
    return tokenOwnerMapping[msg.sender];
  }
}
