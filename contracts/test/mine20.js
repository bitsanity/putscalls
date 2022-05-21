const fs = require('fs');
const Web3 = require('web3');
const web3 =
  new Web3(new Web3.providers.WebsocketProvider("ws://localhost:8545"));

const MYGASPRICE = 2 * 1e9

function getERC20ABI() {
  return JSON.parse(
    fs.readFileSync('./build/TestERC20_sol_TestERC20.abi').toString() );
}

function getERC20Contract(sca) {
  return new web3.eth.Contract( getERC20ABI(), sca );
}

var ebi = process.argv[2] // from account index
var erc20sca = process.argv[3]
var toaddr = process.argv[4]
var amount = parseInt(process.argv[5])

web3.eth.getAccounts().then( res => {

  let eb = res[ebi]
  let erc20con = getERC20Contract( erc20sca )

  erc20con.methods.mint( toaddr, amount )
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
