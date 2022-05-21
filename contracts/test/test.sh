#!/bin/bash

TESTACCTA="0x8c34f41f1cf2dfe2c28b1ce7808031c40ce26d38"
TESTACCTB="0x147b61187f3f16583ac77060cbc4f711ae6c9349"
TESTACCTC="0x940855d6894bc2045fbd4d7d768623521948b904"
TESTPVTA="0x0bce878dba9cce506e81da71bb00558d1684979711cf2833bab06388f715c01a"
TESTPVTB="0xff7da9b82a2bd5d76352b9c385295a430d2ea8f9f6f405a7ced42a5b0e73aad7"
TESTPVTC="0x7451ce18c54780b24b4962aee05b26778ca4e3f42678bf589c608a3ad2c634c2"

ETHER="0x0000000000000000000000000000000000000000"
ERC20="0xF68580C3263FB98C6EAeE7164afD45Ecf6189EbB"
ERC721="0x4Ebf4321A360533AC2D48A713B8f18D341210078"
FACTORY="0x9E8bFcBC56a63ca595C262e1921D3B7a00BB9cF0"

MAKEFEE="1"
CANCELFEE="2"
TAKEFEE="3"

echo CONFIRM is ganache running from a fresh start?:
read -p '[N/y]: ' ans
if [[ $ans != "y" && $ans != "Y" ]]; then
  echo ""
  echo Please run the following before this:
  echo ""
  echo -n ganache-cli ""
  echo -n --account=\"$TESTPVTA,100000000000000000000\" ""
  echo -n --account=\"$TESTPVTB,100000000000000000000\" ""
  echo  --account=\"$TESTPVTC,100000000000000000000\"
  echo ""
  exit
fi

echo
echo =================
echo DEPLOY TEST ERCs
echo =================
echo
node ./deploy.js
echo

echo
echo ==================================
echo DEPLOY OptionFactory AND OptionNFT
echo ==================================
echo
pushd ..

node ./cli.js 0 0 deploy $MAKEFEE $CANCELFEE $TAKEFEE
node ./cli.js 0 $FACTORY variables

echo
echo ===========================
echo ONLY OWNER CAN CHANGE OWNER
echo ===========================
echo

node ./cli.js 0 $FACTORY setOwner $TESTACCTB
node ./cli.js 0 $FACTORY variables

echo BEGIN SHOULDFAIL ---------------------------------------------------------
node ./cli.js 0 $FACTORY setOwner $TESTACCTB
echo END SHOULDFAIL------------------------------------------------------------

node ./cli.js 1 $FACTORY setOwner $TESTACCTC
node ./cli.js 0 $FACTORY variables

echo
echo ==========================
echo ONLY OWNER CAN ADJUST FEES
echo ==========================
echo

node ./cli.js 2 $FACTORY setFee 0 1000
node ./cli.js 2 $FACTORY setFee 1 2000
node ./cli.js 2 $FACTORY setFee 2 3000
node ./cli.js 0 $FACTORY variables

echo BEGIN SHOULDFAIL ---------------------------------------------------------
node ./cli.js 2 $FACTORY setFee 3 1000 # invalid which
node ./cli.js 1 $FACTORY setFee 0 1000 # invalid owner
echo END SHOULDFAIL------------------------------------------------------------

node ./cli.js 0 $FACTORY variables

echo
echo ===============================
echo RECEIVING ETH FORWARDS TO OWNER
echo ===============================
echo

# back to test subdirectory for testpay script
popd
node ./testpay.js 2 $FACTORY 10000
pushd ..
node ./cli.js 0 $FACTORY variables

echo
echo ===============
echo MAKE AND CANCEL
echo ===============
echo
# $EPOCHSECONDS is a magic shell variable, since bash 5.0
# $(()) forces bash to do arithmetic instead of string addition

HOURINSECONDS=3600
HOURFROMNOW=$(($EPOCHSECONDS+$HOURINSECONDS))

echo make...
node ./cli.js 0 $FACTORY make "true" $ETHER 1000000 0 $ERC20 100000 0 $HOURFROMNOW "zero"
node ./cli.js 0 $FACTORY balance $TESTACCTA

echo --- ensure token owner CAN cancel before expiry
node ./cli.js 0 $FACTORY approve $FACTORY 0
echo token owner balance before canceling
node ./cli.js 0 $FACTORY balance $TESTACCTA
node ./cli.js 0 $FACTORY cancel 0
echo token owner balance after canceling
node ./cli.js 0 $FACTORY balance $TESTACCTA
echo

echo
echo --- make an option that expires NOW so next block it will be expired
echo
node ./cli.js 0 $FACTORY balance $TESTACCTA
node ./cli.js 0 $FACTORY make "true" $ETHER 500000 0 $ERC20 100000 0 $EPOCHSECONDS "one"
sleep 1

echo --- maker 0 sells nft to address 1 on some nft marketplace
node ./cli.js 0 $FACTORY approve $TESTACCTB 1
node ./cli.js 1 $FACTORY transferFrom $TESTACCTA 1
sleep 1

echo
echo --- anyone taking the already-expired option returns collateral to maker
echo
node ./cli.js 1 $FACTORY approve $FACTORY 1
echo balance before taking ...
node ./cli.js 0 $FACTORY balance $TESTACCTA
node ./cli.js 1 $FACTORY take 1 0
echo balance after taking ...
node ./cli.js 0 $FACTORY balance $TESTACCTA

echo
echo --- maker canceling the expired option returns collateral
echo
node ./cli.js 0 $FACTORY make "true" $ETHER 500000 0 $ERC20 100000 0 $EPOCHSECONDS "two"
sleep 1

node ./cli.js 0 $FACTORY balance $TESTACCTA
node ./cli.js 1 $FACTORY cancel 2
node ./cli.js 0 $FACTORY balance $TESTACCTA

echo
echo ===========================================
echo MAKE A PUT WHERE THE COLLATERAL IS AN ERC20
echo ===========================================
echo
echo --- give 1M units of erc20 to acct 2
echo

popd
node ./mine20.js 2 $ERC20 $TESTACCTC 1000000
echo
echo --- approve the erc20s for OptionFactory
echo
node ./approve.js 2 "true" $ERC20 $FACTORY 1000000
pushd ..

echo
echo -- make the put
node ./cli.js 2 $FACTORY make "false" $ETHER 100000000 0 $ERC20 1000000 0 $HOURFROMNOW "three"

echo -- verify the smart contract holds the erc20s
popd
node ./balance.js "true" $ERC20 $FACTORY
pushd ..

echo -- sell the nft to TESTACCTB
node ./cli.js 2 $FACTORY approve $TESTACCTB 3
node ./cli.js 1 $FACTORY transferFrom $TESTACCTC 3

echo -- TESTACCTB approves OptionNFT tokenId=3 for OptionFactory
node ./cli.js 1 $FACTORY approve $FACTORY 3
echo -- TESTACCTB then takes the put and receives the erc20s
node ./cli.js 1 $FACTORY take 3 100000000
popd
echo -- TESTACCTB balance of the erc20
node ./transferFrom.js 1 "true" $ERC20 $FACTORY 1000000
node ./balance.js "true" $ERC20 $TESTACCTB

echo
echo ==================================================
echo MAKE PUT WHERE COLLATERAL IS SOME OTHER ERC721/NFT
echo ==================================================
echo
echo -- mint some random nft assume tokenId=0 and give it to TESTACCTC
node ./mine721.js 2 $ERC721 $TESTACCTC
echo -- approve the nft as collateral for the OptionFactory put
node ./approve.js 2 "false" $ERC721 $FACTORY 0
echo
pushd ..

echo -- TESTACCTC creates and owns OptionNFT tokenId=4
node ./cli.js 2 $FACTORY make "false" $ETHER 100000000 0 $ERC721 0 0 $HOURFROMNOW "four"
echo

echo -- verify the smart contract now owns the nft
popd
node ./balance.js "false" $ERC721 $FACTORY
pushd ..

echo -- TESTACCTC sells option 4 to TESTACCTB
node ./cli.js 2 $FACTORY approve $TESTACCTB 4
node ./cli.js 1 $FACTORY transferFrom $TESTACCTC 4

echo -- TESTACCTB/1 approves OptionNFT tokenId=4 for OptionFactory
node ./cli.js 1 $FACTORY approve $FACTORY 4
echo -- TESTACCTB/1 takes the put and receives the 721
node ./cli.js 1 $FACTORY take 4 100000000
echo
popd

echo -- B/1 takes the 721
node ./transferFrom.js 1 "false" $ERC721 $FACTORY 0
node ./balance.js "false" $ERC721 $TESTACCTB
echo

echo ==================
echo FACTORY NFT EVENTS
echo ==================
echo
pushd ..
node ./cli.js 0 $FACTORY events
popd

echo ===================================
echo EVENTS ON OUR MISC ERC20 AND ERC721
echo ===================================
echo
node ./events.js $ERC20 $ERC721

