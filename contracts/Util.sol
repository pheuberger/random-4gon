// SPDX-License-Identifier: UNLICENSED

pragma solidity ^0.8.4;

library Util {
  // TODO: mention public/internal here in the article and get error message from hardhat
  function random(uint256 input) public pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }
  
  function random(string memory input) public pure returns (uint256) {
    return uint256(keccak256(abi.encodePacked(input)));
  }
}
