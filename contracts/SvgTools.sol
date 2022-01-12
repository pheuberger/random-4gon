// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "@openzeppelin/contracts/utils/Strings.sol";
import "solidity-bytes-utils/contracts/BytesLib.sol";
import "./Util.sol";
import "./Types.sol";

library SvgTools {

  string constant svgPart0 = '<svg xmlns="http://www.w3.org/2000/svg" preserveAspectRatio="xMinYMin meet" viewBox="0 0 100 100"><defs><linearGradient id="grad1" ';
  // insert background gradient directions here
  string constant svgPart1 = '><stop offset="0%" style="stop-color:#';
  // insert bg gradient start color here
  string constant svgPart2 = ';stop-opacity:1" /><stop offset="100%" style="stop-color:#';
  // insert bg gradient stop color here
  string constant svgPart3 = ';stop-opacity:1" /></linearGradient>';
  string constant svgPart4 = '<linearGradient id="grad2" x1="0%" y1="0%" x2="0%" y2="100%"><stop offset="0%" style="stop-color:#'; // optional fg gradient definitio
  // insert fg gradient start color here
  string constant svgPart5 = ';stop-opacity:1"/><stop offset="100%" style="stop-color:#';
  // insert fg gradient stop color here
  string constant svgPart6 = ';stop-opacity:1"/></linearGradient>'; // only needed when adding fg gradient definitio
  string constant svgPart7 = '</defs><rect width="100%" height="100%" fill="url(#grad1)" />'; // close definitions and draw bg rec
  string constant svgPart8 = '<polygon fill="url(#grad2)" points="';
  // insert fg poly points here
  string constant svgPart9 = '"/>'; // only needed if you added pol
  string constant svgPart10 = '</svg>';

  function getGradientDirectionVariant(uint8 index) private pure returns (string memory) {
    return [
      'x1="0%" y1="0%" x2="100%" y2="100%"',
      'x1="0%" y1="0%" x2="0%" y2="100%"',
      'x1="0%" y1="0%" x2="100%" y2="0%"',
      'x1="0%" y1="100%" x2="0%" y2="0%"',
      'x1="100%" y1="100%" x2="0%" y2="0%"',
      'x1="100%" y1="0%" x2="0%" y2="0%"'
    ][index];
  }

  function getRandomBGGradientIndex(uint256 tokenId) public pure returns (uint8) {
    return uint8(Util.random(string(abi.encodePacked("GRAD_DIRS", Strings.toString(tokenId)))) % 6);
  }

  function assembleBackgroundSvgString(string memory startCol, string memory endCol, uint8 gradientDirectionIndex) public pure returns (string memory) {
    assert(gradientDirectionIndex < 6);
    return string(abi.encodePacked(
      generateSvgHeader(gradientDirectionIndex, startCol, endCol),
      svgPart7,
      svgPart10
    ));
  }

  function assembleCombinedSvgString(TokenData memory bg, TokenData memory fg) public pure returns (string memory) {
    return string(abi.encodePacked(
      generateSvgHeader(bg.bgGradientDirection, bg.bgStartColor, bg.bgEndColor),
      svgPart4,
      fg.fgStartColor,
      svgPart5,
      fg.fgEndColor,
      assemblePolyPointsString(fg.tokenId),
      svgPart9,
      svgPart10
    ));
  }


  function assembleForegroundSvgString(uint256 tokenId, string memory startCol, string memory endCol) public pure returns (string memory) {
    return string(abi.encodePacked(
      generateSvgHeader(0, "ffffff", "fafafa"),
      svgPart4,
      startCol,
      svgPart5,
      endCol,
      assemblePolyPointsString(tokenId),
      svgPart9,
      svgPart10
    ));
  }

  function generateSvgHeader(uint8 gradientDirection, string memory startCol, string memory endCol) private pure returns (string memory) {
    return string(abi.encodePacked(
      svgPart0, 
      getGradientDirectionVariant(gradientDirection),
      svgPart1,
      startCol, 
      svgPart2, 
      endCol, 
      svgPart3
    ));
  }

  function assemblePolyPointsString(uint256 tokenId) private pure returns (string memory) {
    (string memory p1, string memory p2, string memory p3, string memory p4) = generatePoints(tokenId);

    return string(abi.encodePacked(
      svgPart6,
      svgPart7,
      svgPart8,
      p1, 
      ", ", 
      p2, 
      ", ", 
      p3, 
      ", ", 
      p4
    ));
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

  function generateCoordinate(string memory seed, uint256 tokenId) public pure returns (uint8, uint8) {
    bytes memory hash = abi.encodePacked(keccak256(abi.encodePacked(seed, Strings.toString(tokenId))));
    uint8 resX = BytesLib.toUint8(BytesLib.slice(hash, 0, 4), 0) % 60 + 20;
    uint8 resY = BytesLib.toUint8(BytesLib.slice(hash, 5, 4), 0) % 60 + 20;
    return (resX, resY);
  }

  function getGradientColors() public view returns (string memory, string memory) {
    string memory addrString = addressToString(msg.sender);

    string memory startCol = substring(addrString, 2, 8);
    string memory endCol = substring(addrString, 8, 14);
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

}
