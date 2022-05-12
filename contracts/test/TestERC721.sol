// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/ERC721.sol";

contract TestERC721 is ERC721 {

  uint256 public _count;

  constructor() ERC721("Test NFT", "TNFT") {}

  function mint( address to ) external returns (uint256 tokenId) {
    _mint( to, tokenId = _count++ );
  }
}

