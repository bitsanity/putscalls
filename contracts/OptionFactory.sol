// SPDX-License-Identifier: MIT

pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721.sol";
import "@openzeppelin/contracts/token/ERC721/IERC721Receiver.sol";

import "./OptionNFT.sol";

contract Ownable {
  address payable public owner_;

  modifier isOwner {
    if (msg.sender != owner_) { revert("must be owner"); }
    _;
  }

  constructor() {
    owner_ = payable(msg.sender);
  }

  function setOwner( address payable newowner ) public isOwner {
    owner_ = newowner;
  }
}

//
// Decentralized Exchange to create Options for Ethereum-based assets including
// Ether (amounts in wei), ERC20 tokens and stablecoins (amounts in units),
// and ERC721 NFTs (amount n/a)
//
// The maker places collateral when creating the option. The maker receives an
// OptionNFT holding the details as part of the creation process. The maker
// can sell the NFT anywhere NFTs are exchanges without involving this smart
// contract.
//
// The eventual owner of the OptionNFT can take any time before expiry. The
// OptionNFT must be approved for this smart contract and will be burned as
// part of the process when the option is taken.
//
// Call Option AAABBB
// . conveys right of a buyer to buy AAA for a price of BBB
//
// . maker provides AAA as collateral to be held by this contract
//
// . taker provides BBB at time of take
// . smart contract sends AAA to taker
// . smart contract sends BBB to maker
//
// Put Option AAABBB
// . conveys right of a buyer to sell a given amount of AAA for price BBB
//   on or before it expires.
//
// . maker provides BBB to smart contract as collateral
//
// . taker provides AAA at time of take
// . smart contract sends AAA to maker
// . smart contract sends BBB to taker
//
// WARNING: Scams abound. Users MUST verify SCAs before making deals
//

contract OptionFactory is Ownable, IERC721Receiver {

  OptionNFT public nft;

  uint256 public makefee;
  uint256 public cancelfee;
  uint256 public takefee;

  // isCall : make a call option if true, otherwise a put
  // xxxType : any erc20 token sca, nft sca, or use 0x0 for ETH
  // xxxAmount : units of xxxType, eth or erc20, 0x0 for nft
  // expires : seconds since Unix epoch when option expires
  // tokenId : non-zero indicates collateral is an nft
  // data : passed along to the ERC721 OptionNFT constructor and ultimately
  //        to a receiver's onERC721Received() callback, iff the receiver is
  //        another smartcontract.

  function make( bool isCall,
                 address aaaType,
                 uint256 aaaAmount,
                 uint256 aaaTokenId,
                 address bbbType,
                 uint256 bbbAmount,
                 uint256 bbbTokenId,
                 uint256 expires,
                 bytes memory data )
                 external payable returns (uint256 tokenId) {

    if (isCall) {
      if (aaaType == address(0x0)) { // eth
        require( msg.value == aaaAmount + makefee, "incorrect value" );
      } else { // token
        _retrieve( aaaType, aaaAmount, aaaTokenId );
      }

      tokenId = nft.mint( msg.sender,
                          OptionNFT.OptionType.CALL,
                          aaaType,
                          aaaAmount,
                          aaaTokenId,
                          bbbType,
                          bbbAmount,
                          bbbTokenId,
                          expires,
                          data );
    }
    else {
      if (bbbType == address(0x0)) { // eth
        require( msg.value == bbbAmount + makefee, "incorrect value" );
      } else { // token
        _retrieve( bbbType, bbbAmount, bbbTokenId );
      }

      tokenId = nft.mint( msg.sender,
                          OptionNFT.OptionType.PUT,
                          bbbType,
                          bbbAmount,
                          bbbTokenId,
                          aaaType,
                          aaaAmount,
                          aaaTokenId,
                          expires,
                          data );
    }

    owner_.transfer( makefee );
  }

  function take( uint256 tokenId ) external payable {

    nft.burn( tokenId ); // reverts if this contract is not owner/authorized
                         // changes token owner to the null address

    owner_.transfer( takefee );

    // if option has expired, just return collateral to maker
    if ( block.timestamp >= nft._expirations(tokenId) ) {
      _dispatch( nft._makers(tokenId),
                 nft._collatTypes(tokenId),
                 nft._collatAmounts(tokenId),
                 nft._collatTokenIds(tokenId) );
      return;
    }

    // collateral to taker
    _dispatch( msg.sender,
               nft._collatTypes(tokenId),
               nft._collatAmounts(tokenId),
               nft._collatTokenIds(tokenId) );

    // settlement to maker
    _dispatch( nft._makers(tokenId),
               nft._settleTypes(tokenId),
               nft._settleAmounts(tokenId),
               nft._settleTokenIds(tokenId) );
  }

  // maker may cancel to retrieve collateral after expiry

  function cancel( uint256 tokenId ) external payable {

    owner_.transfer( cancelfee );

    if (nft.isSinged(tokenId)) return;

    if (    nft.ownerOf(tokenId) == address(this)
         || nft.getApproved(tokenId) == address(this)
         || nft.isApprovedForAll(nft.ownerOf(tokenId), address(this) )) {
      nft.burn( tokenId );
    }
    else {
      if ( block.timestamp < nft._expirations(tokenId) ) return;
      nft.singe( tokenId );
    }

    _dispatch( nft._makers(tokenId),
               nft._collatTypes(tokenId),
               nft._collatAmounts(tokenId),
               nft._collatTokenIds(tokenId) );

  }

  //
  // Admin and internal functions ...
  //
  function _retrieve( address xxxType, uint256 xxxAmt, uint256 xxxTokenId )
  internal {

    if (xxxTokenId == 0x0) { // erc20
      require( IERC20(xxxType).transferFrom(msg.sender, address(this), xxxAmt),
               "failed to transfer erc20 to this" );
    } else { // erc721
      IERC721(xxxType).transferFrom( msg.sender, address(this), xxxTokenId );
    }
  }

  // if the maker of the token is zero that means dispatch already happened
  function _dispatch( address to,
                      address xxxType,
                      uint256 xxxAmt,
                      uint256 xxxTokenId ) internal {

    if (xxxType == address(0x0)) {
      payable(to).transfer( xxxAmt );
    } else if (xxxTokenId == 0x0) { // erc20
      require( IERC20(xxxType).approve(to, xxxAmt), "failed to approve erc20" );
    } else { // erc721
      IERC721(xxxType).approve( msg.sender, xxxTokenId );
    }
  }

  constructor( uint256 mf, uint256 cf, uint256 tf ) {
    makefee = mf;
    cancelfee = cf;
    takefee = tf;
    nft = new OptionNFT();
  }

  function setFee( uint8 which, uint256 amtwei ) public isOwner {
    if (which == uint8(0)) makefee = amtwei;
    else if (which == uint8(1)) cancelfee = amtwei;
    else if (which == uint8(2)) takefee = amtwei;
    else revert( "invalid fee specified" );
  }

  // forward to admin if caller sends ether and leaves calldata blank
  receive() external payable {
    owner_.transfer( msg.value );
  }

  // calldata does not match a function
  fallback() external payable {
    owner_.transfer( msg.value );
  }

  // IERC721.safeTransferFrom() to a smart contract requires this function
  // be present and return the function selector to confirm
  function onERC721Received( address _operator,
                             address _from,
                             uint256 _tokenId,
                             bytes calldata _data) external pure
                             returns(bytes4) {

    if (    _operator == address(0x0)
         && _from == address(0x0)
         && _tokenId == 0x0
         && _data.length > 0 ) {
      // do nothing but suppress compiler warnings about unused params
    }
    return IERC721Receiver.onERC721Received.selector;
  }
}
