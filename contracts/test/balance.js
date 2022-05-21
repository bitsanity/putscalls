const fs = require('fs');
const Web3 = require('web3');
const web3 =
  new Web3(new Web3.providers.WebsocketProvider("ws://localhost:8545"));

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

var is20 = JSON.parse( process.argv[2] )
var sca = process.argv[3]
var acct = process.argv[4]

let con = (is20) ? getERC20Contract(sca) : getNFTContract(sca)

con.methods.balanceOf( acct ).call()
.then( res => {
  console.log( 'balance: ' + res )
  process.exit( 0 )
} )
.catch( e => {
  console.log(e);
  process.exit(1)
} );

