const fs = require('fs');
const Web3 = require('web3');
const web3 =
  new Web3(new Web3.providers.WebsocketProvider("ws://localhost:8545"));

const MYGASPRICE = '' + 2 * 1e9

function getERC721ABI() {
  return JSON.parse(
    fs.readFileSync('./build/TestERC721_sol_TestERC721.abi').toString() );
}

function getERC721Contract(sca) {
  return new web3.eth.Contract( getERC721ABI(), sca );
}

var ebi = process.argv[2] // from account index
var erc721sca = process.argv[3]
var toaddr = process.argv[4]

web3.eth.getAccounts().then( res => {

  let eb = res[ebi]
  let erc721con = getERC721Contract( erc721sca )

  erc721con.methods.mint( toaddr )
  .send( {from:eb, gas: 1000000, gasPrice: MYGASPRICE} )
  .then( res => {
    process.exit(0)
  } )
  .catch( e => {
    console.log(e.toString());
    process.exit(1)
  } )

} )
.catch( e => {
  console.log(e.toString());
  process.exit(1);
} )
