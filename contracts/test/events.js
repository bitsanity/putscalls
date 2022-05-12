const fs = require('fs');
const Web3 = require('web3');
const web3 =
  new Web3(new Web3.providers.WebsocketProvider("ws://localhost:8545"));

function getERC20ABI() {
  return JSON.parse(
    fs.readFileSync('./build/TestERC20_sol_TestERC20.abi').toString() );
}

function getNFTABI() {
  return JSON.parse(
    fs.readFileSync('./build/TestERC721_sol_TestERC721.abi').toString() );
}

function getERC20Contract(sca) {
  return new web3.eth.Contract( getERC20ABI(), sca );
}

function getNFTContract(sca) {
  return new web3.eth.Contract( getNFTABI(), sca );
}

var erc20sca = process.argv[2]
var nftsca = process.argv[3]

let erc20con = getERC20Contract( erc20sca )
let nftcon = getNFTContract( nftsca )

erc20con.getPastEvents('allEvents', {fromBlock:0,toBlock:'latest'})
.then( events => {

  for (var ii = 0; ii < events.length; ii++)
    printEvent( events[ii] );

  nftcon.getPastEvents('allEvents', {fromBlock:0,toBlock:'latest'})
  .then( evts => {

    for (var ii = 0; ii < evts.length; ii++)
      printEvent( evts[ii] );

    process.exit(0);
  } )
  .catch( err => {
    console.log(err.toString());
    process.exit(1);
  } )
} )
.catch( err => {
  console.log(err.toString());
  process.exit(1);
} )
