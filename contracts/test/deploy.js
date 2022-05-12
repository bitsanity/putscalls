const fs = require('fs');
const Web3 = require('web3');
const web3 =
  new Web3(new Web3.providers.WebsocketProvider("ws://localhost:8545"));

const MYGASPRICE = '' + 2 * 1e9;

var ebi = (process.argv[2]) ? process.argv[2] : "0"; // account index
var eb;

var erc20abi = JSON.parse(
  fs.readFileSync('./build/TestERC20_sol_TestERC20.abi').toString() );

var erc20bin =
  fs.readFileSync('./build/TestERC20_sol_TestERC20.bin').toString();

if (!erc20bin.startsWith('0x')) erc20bin = '0x' + erc20bin;

var nftabi = JSON.parse(
  fs.readFileSync('./build/TestERC721_sol_TestERC721.abi').toString() );

var nftbin =
  fs.readFileSync('./build/TestERC721_sol_TestERC721.bin').toString();

if (!nftbin.startsWith('0x')) nftbin = '0x' + nftbin;

web3.eth.getAccounts().then( (res) => {
  eb = res[ebi];

  let con = new web3.eth.Contract( erc20abi );
  con.deploy({data:erc20bin} )
  .send({from: eb, gas: 3000000, gasPrice: MYGASPRICE}, (err, hash) => {
    if (err) console.log( err );
  } )
  .on('error', (err) => { console.log("err: ", err); })
  .on('transactionHash', (h) => { console.log( "tx: ", h ); } )
  .on('receipt', (r) => { console.log( 'rcpt: ' + r.contractAddress); } )
  .on('confirmation', (cn, rcpt) => { console.log( 'cn: ', cn ); } )
  .then( (nin) => {
    console.log( "TestERC20 SCA: ", nin.options.address );
  } );

  con = new web3.eth.Contract( nftabi );
  con.deploy({data:nftbin} )
  .send({from: eb, gas: 3000000, gasPrice: MYGASPRICE}, (err, hash) => {
    if (err) console.log( err );
  } )
  .on('error', (err) => { console.log("err: ", err); })
  .on('transactionHash', (h) => { console.log( "tx: ", h ); } )
  .on('receipt', (r) => { console.log( 'rcpt: ' + r.contractAddress); } )
  .on('confirmation', (cn, rcpt) => { console.log( 'cn: ', cn ); } )
  .then( (nin) => {
    console.log( "TestERC721 SCA: ", nin.options.address );
  } );
} )

setTimeout( () => { process.exit(0)}, 5000 );

