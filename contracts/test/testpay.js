const fs = require('fs');
const Web3 = require('web3');
const web3 =
  new Web3(new Web3.providers.WebsocketProvider("ws://localhost:8545"));

const MYGASPRICE = '' + 2 * 1e9;

function getABI() {
  return JSON.parse(
    fs.readFileSync('../build/OptionFactory_sol_OptionFactory.abi')
    .toString() );
}

function getContract(sca) {
  return new web3.eth.Contract( getABI(), sca );
}

var ebi = process.argv[2]
var toaddr = process.argv[3]
var amtwei = process.argv[4]

web3.eth.getAccounts().then( (res) => {
  var eb = res[ebi];

  // send eth with calldata blank
  // fallback - send eth with calldata that doesn't match any function

  web3.eth.sendTransaction( {
          from: eb,
            to: toaddr,
         value: amtwei,
           gas: 50000,
      gasPrice: MYGASPRICE } )
    .then( () => {

      // invoke nonexistent foo(uint) function with useless parameter 42 to
      // trigger contract fallback
      let calldata = web3.eth.abi.encodeFunctionCall({
        name: 'foo',
        type: 'function',
        inputs: [ {
          type: 'uint256',
          name: 'alice'
        } ]
      }, [42] )

      // send wei along to confirm it gets swept to owner address
      let valuetosend = 10000;

      web3.eth.sendTransaction( {
        from: eb,
        to: toaddr,
        value:amtwei,
        gas: 100000,
        gasPrice: MYGASPRICE,
        data: calldata } )
      .then( () => { process.exit(0) } )
      .catch( e => { console.log(e) } )
    } )
    .catch( (err) => {console.log(err);} );
} )

