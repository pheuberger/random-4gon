// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

import "hardhat/console.sol";
import "@openzeppelin/contracts/utils/Strings.sol";
import 'base64-sol/base64.sol';

import "./Types.sol";
import "./Util.sol";
import "./SvgTools.sol";

library NFTBuilder {

  function generateTokenData(uint256 tokenId) public view returns (string memory, TokenData memory) {
    uint256 rand = Util.random(tokenId) % 100;
    (string memory startCol, string memory endCol) = SvgTools.getGradientColors();
    string memory json;
    TokenData memory data;  

    if (rand > 50) {
      console.log("building foreground NFT");
      json = buildForegroundNftJson(tokenId, startCol, endCol);
      data = TokenData(tokenId, 0, startCol, endCol, "", "", 0);
    } else {
      console.log("building background NFT");
      uint8 index = SvgTools.getRandomBGGradientIndex(tokenId);
      json = buildBackgroundNftJson(tokenId, startCol, endCol, index);
      data = TokenData(tokenId, 1, "", "", startCol, endCol, index);
    }

    string memory finalTokenUri = string(abi.encodePacked("data:application/json;base64,", json));
    console.log("\n--------------------");
    console.log(string(abi.encodePacked("https://nftpreview.0xdev.codes/?code=", finalTokenUri)));
    console.log("--------------------\n");
    return (finalTokenUri, data);
  }

  function generateCombinedTokenData(uint256 tokenId, TokenData memory bg, TokenData memory fg) public view returns (string memory, TokenData memory) {
    string memory json = buildCombinedNftJson(tokenId, bg, fg);
    TokenData memory resultData = TokenData(tokenId, 2, fg.fgStartColor, fg.fgEndColor, bg.bgStartColor, bg.bgEndColor, bg.bgGradientDirection);

    string memory finalTokenUri = string(abi.encodePacked("data:application/json;base64,", json));
    console.log("\n--------------------");
    console.log(string(abi.encodePacked("https://nftpreview.0xdev.codes/?code=", finalTokenUri)));
    console.log("--------------------\n");
    return (finalTokenUri, resultData);
  }

  function buildForegroundNftJson(uint256 tokenId, string memory startCol, string memory endCol) public pure returns (string memory) {
    string memory svgString = SvgTools.assembleForegroundSvgString(tokenId, startCol, endCol);

    return Base64.encode(bytes(string(abi.encodePacked(
      '{"name": "', 
      string(abi.encodePacked("4GON #", Strings.toString(tokenId))), 
      '", "description": "Randomly generated Foreground Four-Gon. Your wallet address influenced the shape\'s gradient colors.", "image": "data:image/svg+xml;base64,',
      Base64.encode(bytes(svgString)), 
      '", "type": "foreground", ',
      '"tokenId": ',
      Strings.toString(tokenId),
      '}'
    ))));
  }

  function buildBackgroundNftJson(uint256 tokenId, string memory startCol, string memory endCol, uint8 gradientDirectionIndex) public pure returns (string memory) {
    string memory svgString = SvgTools.assembleBackgroundSvgString(endCol, startCol, gradientDirectionIndex);

    return Base64.encode(bytes(string(abi.encodePacked(
      '{"name": "', 
      string(abi.encodePacked("4GON #", Strings.toString(tokenId))), 
      '", "description": "Randomly generated Background Four-Gon. Your wallet address influenced the background\'s gradient colors.", "image": "data:image/svg+xml;base64,',
      Base64.encode(bytes(svgString)), 
      '", "type": "background", ',
      '"tokenId": ',
      Strings.toString(tokenId),
      '}'
    ))));
  }


  function buildCombinedNftJson(uint256 tokenId, TokenData memory bg, TokenData memory fg) public pure returns (string memory) {
    string memory svgString = SvgTools.assembleCombinedSvgString(bg, fg);

    return Base64.encode(bytes(string(abi.encodePacked(
      '{"name": "', 
      string(abi.encodePacked("4GON #", Strings.toString(tokenId))), 
      '", "description": "A combination Four-Gon of background token id ',
      Strings.toString(bg.tokenId),
      ' and foreground token id ',
      Strings.toString(fg.tokenId),
      '.", "image": "data:image/svg+xml;base64,',
      Base64.encode(bytes(svgString)), 
      '", "type": "combined", ',
      '"tokenId": ',
      Strings.toString(tokenId),
      '}'
    ))));
  }

}
