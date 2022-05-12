const fs = require('fs');
const Web3 = require('web3');
const web3 =
  new Web3(new Web3.providers.WebsocketProvider("ws://localhost:8545"));

const MYGASPRICE = '' + 2 * 1e9;

function getABI() {
  return JSON.parse(
    fs.readFileSync('./build/OptionFactory_sol_OptionFactory.abi')
    .toString() );
}

function getBinary() {
  var binary =
    fs.readFileSync('./build/OptionFactory_sol_OptionFactory.bin').toString();
  if (!binary.startsWith('0x')) binary = '0x' + binary;
  return binary;
}

function getContract(sca) {
  return new web3.eth.Contract( getABI(), sca );
}

function printEvent(evt) {
  console.log( evt.event + ': ' + JSON.stringify(evt.returnValues) + '\n' );
}

function nftABI() {
  return JSON.parse(
    fs.readFileSync('./build/OptionNFT_sol_OptionNFT.abi').toString() );
}

const cmds =
  [
   'approve',
   'transferFrom',
   'balance',
   'deploy',
   'events',
   'variables',
   'setOwner',
   'make',
   'take',
   'cancel',
   'setFee'
  ];

function usage() {
  console.log(
    '\nUsage:\n$ node cli.js <acctindex> <SCA> <command> [arg]*\n',
     'Commands:\n',
     '\tapprove <foraddress> <tokenid> |\n',
     '\ttransferFrom <fromapproveraddress> <tokenid> |\n',
     '\tbalance [address] |\n',
     '\tdeploy <makefee> <cancelfee> <takefee> |\n',
     '\tevents |\n',
     '\tvariables |\n',
     '\tsetOwner <newadmin> |\n',
     '\tmake <isCall> <atype> <aamount> <atokenid> <btype> <bamount> <btokenid> <expires> <data> |\n',
     '\ttake <nfttokenid> |\n',
     '\tcancel <nfttokenid> |\n',
     '\tsetFee <whichone> <amountinwei> |\n'
  );
}

var cmd = process.argv[4];

let found = false;
for (let ii = 0; ii < cmds.length; ii++)
  if (cmds[ii] == cmd) found = true;

if (!found) {
  usage();
  process.exit(1);
}

var ebi = process.argv[2]; // local account index
var sca = process.argv[3];

var eb;
web3.eth.getAccounts().then( (res) => {
  eb = res[ebi];

  if (cmd == 'balance')
  {
    let addr = process.argv[5];

    web3.eth.getBalance( addr )
    .then( (bal) => {
      console.log( "bal: " + bal );
      process.exit(0);
    } )
    .catch( err => {
      console.log(err.toString());
      process.exit(1);
    } );
  }
  if (cmd == 'deploy')
  {
    let mf = process.argv[5];
    let cf = process.argv[6];
    let tf = process.argv[7];

    let con = new web3.eth.Contract( getABI() );
    con.deploy({data:getBinary(), arguments: [mf,cf,tf]} )
      .send({from: eb, gas: 4000000, gasPrice: MYGASPRICE}, (err, hash) => {
        if (err) console.log( 'deploy: ' + err );
      } )
      .on('error', (err) => { console.log("err: ", err); })
      .on('transactionHash', (h) => { console.log( "hash: ", h ); } )
      .on('receipt', (r) => { console.log( 'rcpt: ' + r.contractAddress); } )
      .on('confirmation', (cn, rcpt) => { console.log( 'cn: ', cn ); } )
      .then( (nin) => {
        console.log( "SCA: ", nin.options.address );
        process.exit(0);
      } );
  }
  else
  {
    let con = new web3.eth.Contract( getABI(), sca );

    if (cmd == 'approve') {
      let foraddr = process.argv[5]
      let tokenId = parseInt( process.argv[6] )

      con.methods.nft().call().then( (nft) => {
        let nftcon = new web3.eth.Contract( nftABI(), nft )

        nftcon.methods.ownerOf( tokenId ).call()
        .then( own => {
          console.log( 'caller is ' + eb )
          console.log( 'owner of ' + tokenId + ' is ' + own )
        } )
        .catch( e => {console.log(e)} )

        nftcon.methods.approve( foraddr, tokenId )
        .send( {from: eb, gas: 1000000, gasPrice: MYGASPRICE} )
        .then( (res) => {
          process.exit(0);
        } )
        .catch( err => {
          process.exit(1);
        } );
      } )
      .catch( e => { console.log(e); process.exit(1) } )
    }

    if (cmd == 'transferFrom') {
      let fromaddr = process.argv[5]
      let tokenId = parseInt( process.argv[6] )

      con.methods.nft().call().then( (nft) => {
        let nftcon = new web3.eth.Contract( nftABI(), nft )

        nftcon.methods.transferFrom( fromaddr, eb, tokenId )
        .send( {from: eb, gas: 1000000, gasPrice: MYGASPRICE} )
        .then( (res) => {
          process.exit(0);
        } )
        .catch( err => {
          process.exit(1);
        } );
      } )
    }

    if (cmd == 'events')
    {
      con.methods.nft().call().then( (res) => {
        console.log( "OptionNFT: " + res + ' events: ' )

        let nftcon = new web3.eth.Contract( nftABI(), res )

        nftcon.getPastEvents('allEvents', {fromBlock:0,toBlock:'latest'})
        .then( evs => {

          for (let ii = 0; ii < evs.length; ii++) {
            printEvent( evs[ii] );

            if (evs[ii].returnValues.tokenId) {
              let tok = evs[ii].returnValues.tokenId
continue;
              try {
                console.log( 'tokenId: ' + tok )

                nftcon.methods._optionTypes(tok).call().then( ot => {
                  console.log( 'optionType: ' + ot )
                } )
                nftcon.methods._makers(tok).call().then( mk => {
                  console.log( 'maker: ' + mk )
                } )
                nftcon.methods._collatTypes(tok).call().then( ct => {
                  console.log( 'collatType: ' + ct )
                } )
                nftcon.methods._collatAmounts(tok).call().then( ca => {
                  console.log( 'collatAmount: ' + ca )
                } )
                nftcon.methods._collatTokenIds(tok).call().then( cti => {
                  console.log( 'collatTokenId: ' + cti )
                } )
                nftcon.methods._settleTypes(tok).call().then( st => {
                  console.log( 'settleType: ' + st )
                } )
                nftcon.methods._settleAmounts(tok).call().then( sa => {
                  console.log( 'settleAmount: ' + sa )
                } )
                nftcon.methods._settleTokenIds(tok).call().then( sti => {
                  console.log( 'settleTokenId: ' + sti )
                } )
                nftcon.methods._expirations(tok).call().then( ex => {
                  console.log( 'expiration: ' + ex )
                } )
              }
              catch( e ) {
                console.log(e);
                process.exit(1);
              }
            }
          }
          setTimeout( () => { process.exit(0)}, 3000 );
        } )
        .catch( e => { console.log(e); process.exit(1) } )
        } )
    }

    if (cmd == 'variables')
    {
      try {
        web3.eth.getBalance( sca ).then( (bal) => {
          console.log( "balance (wei): " + bal )
        } )

        con.methods.owner_().call().then( (res) => {
          console.log( "owner: " + res )

          web3.eth.getBalance( res ).then( bal => {
            console.log( "owner balance: " + bal )
          } )
        } )

        con.methods.nft().call().then( (res) => {
          console.log( "nft: " + res )
        } )

        con.methods.makefee().call().then( (res) => {
          console.log( "makefee: " + res )
        } )

        con.methods.cancelfee().call().then( (res) => {
          console.log( "cancelfee: " + res )
        } )

        con.methods.takefee().call().then( (res) => {
          console.log( "takefee: " + res )
        } )
      }
      catch( err ) {
        console.log(err.toString());
        process.exit(1);
      }
    }

    if (cmd == 'make')
    {
      let isCall = JSON.parse(process.argv[5].toLowerCase());
      let atype = process.argv[6]
      let aamount = parseInt( process.argv[7] )
      let atokenid = process.argv[8]
      let btype = process.argv[9]
      let bamount = parseInt( process.argv[10] )
      let btokenid = process.argv[11]
      let expires = parseInt( process.argv[12] )
      let data = Buffer.from( process.argv[13], 'utf-8' )

      con.methods.makefee().call()
      .then( (makefee) => {
        let val = parseInt( makefee );

        if (isCall && /^0x0+$/.test(atype)) val += aamount;
        else if (/^0x0+$/.test(btype)) val += bamount;

        con.methods.make(
          isCall,atype,aamount,atokenid,btype,bamount,btokenid,expires,data )
        .send( {from: eb, gas: 2000000, gasPrice: MYGASPRICE, value:val} )
        .then( (res) => {
          process.exit(0);
        } )
        .catch( err => {
          process.exit(1);
        } );
      } )
      .catch( err => {
        console.log( 'makefee: ' + err );
        process.exit(1);
      } );

    }

    if (cmd == 'take')
    {
      let tokenId = process.argv[5];

      con.methods.takefee().call().then( (tf) => {
        con.methods.take( tokenId )
        .send( {from: eb, gas: 100000, gasPrice: MYGASPRICE, value: tf} )
        .then( () => {
          console.log( 'took: ' + tokenId );
          process.exit(0);
        } )
        .catch( err => {
          console.log( err.toString() );
          process.exit( 1 );
        } );
      } )
      .catch( e => { console.log(e) } )
    }

    if (cmd == 'cancel')
    {
      let tokenId = parseInt( process.argv[5] )

      con.methods.cancelfee().call().then( (cf) => {

        con.methods.cancel( tokenId )
        .send( {from: eb, gas: 100000, gasPrice: MYGASPRICE, value: cf} )
        .then( () => {
          console.log( 'canceled ' + tokenId );
          process.exit(0);
        } )
        .catch( err => {
          console.log( err.toString() );
          process.exit( 1 );
        } );
      } )
    }

    if (cmd == 'setFee')
    {
      let which = process.argv[5];
      let newfeewei = process.argv[6];

      con.methods.setFee( which, newfeewei )
      .send( {from: eb, gas: 100000, gasPrice: MYGASPRICE} )
      .then( () => { process.exit(0); } )
      .catch( err => { console.log(err.toString()); process.exit(1); } );
    }

    if (cmd == 'setOwner')
    {
      let newguy = process.argv[5];

      con.methods.setOwner( newguy )
      .send( {from: eb, gas: 100000, gasPrice: MYGASPRICE} )
      .then( () => { process.exit(0); } )
      .catch( err => { console.log(err.toString()); process.exit(1); } );
    }
  }

  setTimeout( () => { process.exit(0)}, 1000 );
} );

