// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';
import "solidity-bytes-utils/contracts/BytesLib.sol";


contract Random4Gon is ERC721URIStorage {

  using Counters for Counters.Counter;
  Counters.Counter private _tokenIds;

  struct TokenData {
    uint256 tokenId;
    uint8 tokenType;
    string fgStartColor;
    string fgEndColor;
    string bgStartColor;
    string bgEndColor;
    uint8 bgGradientDirection;
  }

  mapping (address => TokenData[]) fgTokensPerOwner;
  mapping (address => TokenData[]) bgTokensPerOwner;

  event NewNFTMinted(address sender, uint256 tokenId);

  string[] svgParts =[
    '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 100 100"><defs><linearGradient id="grad1" ',
    // insert background gradient directions here
    '><stop offset="0%" style="stop-color:#',
    // insert bg gradient start color here
    ';stop-opacity:1" /><stop offset="100%" style="stop-color:#',
    // insert bg gradient stop color here
    ';stop-opacity:1" /></linearGradient>',
    '<linearGradient id="grad2" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" style="stop-color:#', // optional fg gradient definition
    // insert fg gradient start color here
    ';stop-opacity:1"/><stop offset="100%" style="stop-color:#', 
    // insert fg gradient stop color here
    ';stop-opacity:1"/></linearGradient>', // only needed when adding fg gradient definition
    '</defs><rect width="100%" height="100%" fill="url(#grad1)" />', // close definitions and draw bg rect
    '<polygon fill="url(#grad2)" points="',
    // insert fg poly points here
    '"/>', // only needed if you added poly
    '</svg>'
  ];

  string[] fgSvgParts = [
    '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 100 100"><defs><linearGradient id="grad1" x1="0%" y1="0%" x2="100%" y2="100%"><stop offset="0%" style="stop-color:#ffffff;stop-opacity:1" /><stop offset="100%" style="stop-color:#fafafa;stop-opacity:1" /></linearGradient><linearGradient id="grad2" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" style="stop-color:#',
    ';stop-opacity:1"/><stop offset="100%" style="stop-color:#', 
    ';stop-opacity:1"/></linearGradient></defs><rect width="100%" height="100%" fill="url(#grad1)" /><polygon fill="url(#grad2)" points="',
     '"/></svg>'
  ];

  string[] bgSvgParts = [
    '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 100 100"><defs><linearGradient id="grad1" ',
    '><stop offset="0%" style="stop-color:#',
    ';stop-opacity:1" /><stop offset="100%" style="stop-color:#',
    ';stop-opacity:1" /></linearGradient></defs><rect width="100%" height="100%" fill="url(#grad1)"/></svg>'
  ];

  string[] combinedSvgParts = [
    '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 100 100"><defs><linearGradient id="grad1" ',
    '><stop offset="0%" style="stop-color:#',
    ';stop-opacity:1" /><stop offset="100%" style="stop-color:#',
    ';stop-opacity:1"/></linearGradient></defs><rect width="100%" height="100%" fill="url(#grad1)" /><polygon fill="url(#grad2)" points="',
     '"/></svg>'
  ];

  string[] bgGradientDirections = [
    'x1="0%" y1="0%" x2="100%" y2="100%"',
    'x1="0%" y1="0%" x2="0%" y2="100%"',
    'x1="0%" y1="0%" x2="100%" y2="0%"',
    'x1="0%" y1="100%" x2="0%" y2="0%"',
    'x1="100%" y1="100%" x2="0%" y2="0%"',
    'x1="100%" y1="0%" x2="0%" y2="0%"'
  ];

  constructor() ERC721("Random Four-Gons", "4GON") {
    console.log("heloooooo 4GON in da house!");
  }

  function mint() public {
    uint256 tokenId = _tokenIds.current();

    (string memory tokenUri, TokenData memory tokenData) = generateTokenData(tokenId);

    _safeMint(msg.sender, tokenId);
    _setTokenURI(tokenId, tokenUri);
    _tokenIds.increment();
    updateOwnersTokens(tokenData);
    emit NewNFTMinted(msg.sender, tokenId);
  }

  function combine() public view {
    TokenData[] memory fgTokens = fgTokensPerOwner[msg.sender];
    TokenData[] memory bgTokens = bgTokensPerOwner[msg.sender];

    require(fgTokens.length == 0 || bgTokens.length == 0, 
            'You need at least one foreground and background token to combine');
  }

  function generateTokenData(uint256 tokenId) private view returns (string memory, TokenData memory) {
    uint256 rand = random(Strings.toString(tokenId)) % 100;
    (string memory startCol, string memory endCol) = getGradientColors();
    string memory json;
    TokenData memory data;  

    if (rand > 10) {
      console.log("building foreground NFT");
      json = buildForegroundNftJson(tokenId, startCol, endCol);
      data = TokenData(tokenId, 0, startCol, endCol, "", "", 0);
    } else {
      console.log("building background NFT");
      uint8 index = uint8(random(string(abi.encodePacked("GRAD_DIRS", Strings.toString(tokenId)))) % bgGradientDirections.length);
      json = buildBackgroundNftJson(tokenId, startCol, endCol, index);
      data = TokenData(tokenId, 1, "", "", startCol, endCol, index);
    }

    string memory finalTokenUri = string(abi.encodePacked("data:application/json;base64,", json));
    console.log("\n--------------------");
    console.log(string(abi.encodePacked("https://nftpreview.0xdev.codes/?code=", finalTokenUri)));
    console.log("--------------------\n");
    return (finalTokenUri, data);
  }

  function updateOwnersTokens(TokenData memory tokenData) private {
    if (tokenData.tokenType == 0) {
      fgTokensPerOwner[msg.sender].push(tokenData);
    } else {
      bgTokensPerOwner[msg.sender].push(tokenData);
    }
  }

  function generateCoordinate(string memory seed, uint256 tokenId) public pure returns (uint8, uint8) {
    bytes memory hash = abi.encodePacked(keccak256(abi.encodePacked(seed, Strings.toString(tokenId))));
    uint8 resX = BytesLib.toUint8(BytesLib.slice(hash, 0, 4), 0) % 80;
    uint8 resY = BytesLib.toUint8(BytesLib.slice(hash, 5, 4), 0) % 80;
    return (resX, resY);
  }

  function random(uint256 input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }
  
  function random(string memory input) internal pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }

  function buildForegroundNftJson(uint256 tokenId, string memory startCol, string memory endCol) private view returns (string memory) {
    string memory svgString = generateForegroundSvgString(tokenId, startCol, endCol);

    return Base64.encode(bytes(string(abi.encodePacked(
      '{"name": "', 
      string(abi.encodePacked("4GON #", Strings.toString(tokenId))), 
      '", "description": "Randomly generated Foreground Four-Gon. Your wallet address influenced the shape\'s gradient colors.", "image": "data:image/svg+xml;base64,',
      Base64.encode(bytes(svgString)), 
      '", "type": "foreground", ',
      '"tokenId": ',
      Strings.toString(tokenId),
      ', "fgGradientStart": "#',
      startCol,
      '", ',
      '"fgGradientEnd": "#',
      endCol,
      '"}'
    ))));
  }

  function buildBackgroundNftJson(uint256 tokenId, string memory startCol, string memory endCol, uint8 gradientDirectionIndex) private view returns (string memory) {
    string memory svgString = generateBackgroundSvgString(endCol, startCol, tokenId, gradientDirectionIndex);

    return Base64.encode(bytes(string(abi.encodePacked(
      '{"name": "', 
      string(abi.encodePacked("4GON #", Strings.toString(tokenId))), 
      '", "description": "Randomly generated Background Four-Gon. Your wallet address influenced the background\'s gradient colors.", "image": "data:image/svg+xml;base64,',
      Base64.encode(bytes(svgString)), 
      '", "type": "background", ',
      '"tokenId": ',
      Strings.toString(tokenId),
      ', "bgGradientStart": "#',
      endCol,
      '", ',
      '"bgGradientEnd": "#',
      startCol,
      '"}'
    ))));
  }

  function generateBackgroundSvgString(string memory startCol, string memory endCol, uint8 gradientDirectionIndex) private view returns (string memory) {
    assert(gradientDirectionIndex < bgGradientDirections.length);
    string memory direction = bgGradientDirections[gradientDirectionIndex];

    return string(abi.encodePacked(bgSvgParts[0], direction, bgSvgParts[1], startCol, bgSvgParts[2], endCol, bgSvgParts[3]));
  }

  function generateForegroundSvgString(uint256 tokenId, string memory startCol, string memory endCol) private view returns (string memory) {
    (string memory p1, string memory p2, string memory p3, string memory p4) = generatePoints(tokenId);

    return string(abi.encodePacked(fgSvgParts[0], startCol, fgSvgParts[1], endCol, fgSvgParts[2], p1, ", ", p2, ", ", p3, ", ", p4, fgSvgParts[3]));
  }

  function generatePoints(uint256 tokenId) private pure returns (string memory, string memory, string memory, string memory) {
    (uint8 x1, uint8 y1) = generateCoordinate("first_seed", tokenId);
    (uint8 x2, uint8 y2) = generateCoordinate("second_seed", tokenId);
    (uint8 x3, uint8 y3) = generateCoordinate("third_seed", tokenId);
    (uint8 x4, uint8 y4) = generateCoordinate("fourth_seed", tokenId);

    string memory p1 = string(abi.encodePacked(Strings.toString(x1), " ", Strings.toString(y1)));
    string memory p2 = string(abi.encodePacked(Strings.toString(x2), " ", Strings.toString(y2)));
    string memory p3 = string(abi.encodePacked(Strings.toString(x3), " ", Strings.toString(y3)));
    string memory p4 = string(abi.encodePacked(Strings.toString(x4), " ", Strings.toString(y4)));
    return (p1, p2, p3, p4);
  }

  function getGradientColors() private view returns (string memory, string memory) {
    string memory addrString = addressToString(msg.sender);

    string memory startCol = substring(addrString, 2, 8);
    string memory endCol = substring(addrString, 8, 14);
    console.log("start %s, end %s", startCol, endCol);
    return (startCol, endCol);
  }

  function addressToString(address _addr) public pure returns(string memory) {
    bytes32 value = bytes32(uint256(uint160(_addr)));
    bytes memory alphabet = "0123456789abcdef";

    bytes memory str = new bytes(51);
    str[0] = "0";
    str[1] = "x";
    for (uint i = 0; i < 20; i++) {
        str[2+i*2] = alphabet[uint(uint8(value[i + 12] >> 4))];
        str[3+i*2] = alphabet[uint(uint8(value[i + 12] & 0x0f))];
    }
    return string(str);
  }

  function substring(string memory str, uint startIndex, uint endIndex) private pure returns (string memory) {
    bytes memory strBytes = bytes(str);
    bytes memory result = new bytes(endIndex-startIndex);
    for(uint i = startIndex; i < endIndex; i++) {
        result[i-startIndex] = strBytes[i];
    }
    return string(result);
  }

  function tokensOfOwner() public view returns (TokenData[] memory, TokenData[] memory) {
    return (fgTokensPerOwner[msg.sender], bgTokensPerOwner[msg.sender]);
  }
}
