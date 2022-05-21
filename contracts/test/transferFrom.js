const fs = require('fs');
const Web3 = require('web3');
const web3 =
  new Web3(new Web3.providers.WebsocketProvider("ws://localhost:8545"));

const MYGASPRICE = '' + 2 * 1e9

function getERC20ABI() {
  return JSON.parse(
    fs.readFileSync('./build/TestERC20_sol_TestERC20.abi').toString() );
}

function getERC20Contract(sca) {
  return new web3.eth.Contract( getERC20ABI(), sca );
}

function getNFTABI() {
  return JSON.parse(
    fs.readFileSync('./build/TestERC721_sol_TestERC721.abi').toString() );
}

function getNFTContract(sca) {
  return new web3.eth.Contract( getNFTABI(), sca );
}

var ebi = process.argv[2] // from account index
var is20 = JSON.parse( process.argv[3] )
var sca = process.argv[4]
var fromAddr = process.argv[5]
var val = parseInt(process.argv[6])

web3.eth.getAccounts()
.then( res => {

  let eb = res[ebi]
  let con = (is20) ? getERC20Contract(sca) : getNFTContract(sca)

  con.methods.transferFrom( fromAddr, eb, val )
  .send( {from:eb, gas: 500000, gasPrice: MYGASPRICE} )
  .then( res => {
    process.exit(0)
  } )
  .catch( e => {
    console.log(e);
    process.exit(1)
  } )
} )
.catch( e => {
  console.log(e.toString());
  process.exit(1);
} )
