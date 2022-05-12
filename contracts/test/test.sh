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

#node ./cli.js 0 $FACTORY setOwner $TESTACCTB
#node ./cli.js 0 $FACTORY variables

echo BEGIN SHOULDFAIL ---------------------------------------------------------
#node ./cli.js 0 $FACTORY setOwner $TESTACCTB
echo END SHOULDFAIL------------------------------------------------------------

#node ./cli.js 1 $FACTORY setOwner $TESTACCTC
#node ./cli.js 0 $FACTORY variables

echo
echo ==========================
echo ONLY OWNER CAN ADJUST FEES
echo ==========================
echo

#node ./cli.js 0 $FACTORY setFee 0 1000
#node ./cli.js 0 $FACTORY setFee 1 2000
#node ./cli.js 0 $FACTORY setFee 2 3000
#node ./cli.js 0 $FACTORY variables

echo BEGIN SHOULDFAIL ---------------------------------------------------------
#node ./cli.js 2 $FACTORY setFee 3 1000 # invalid which
#node ./cli.js 1 $FACTORY setFee 0 1000 # invalid owner
echo END SHOULDFAIL------------------------------------------------------------

#node ./cli.js 0 $FACTORY variables

echo
echo ===============================
echo RECEIVING ETH FORWARDS TO OWNER
echo ===============================
echo

# back to test subdirectory for testpay script
popd
#node ./testpay.js 2 $FACTORY 10000
pushd ..
#node ./cli.js 0 $FACTORY variables

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
node ./cli.js 0 $FACTORY make "true" $ETHER 1000000 0 $ERC20 100000 0 $HOURFROMNOW "mydata"

#node ./cli.js 0 $FACTORY balance $TESTACCTA

echo BEGIN SHOULDFAIL ---------------------------------------------------------
echo ensure someone other than token owner cannot cancel
node ./cli.js 1 $FACTORY cancel 0
echo END SHOULDFAIL -----------------------------------------------------------

echo --- ensure token owner CAN cancel before expiry
node ./cli.js 0 $FACTORY approve $FACTORY 0
node ./cli.js 0 $FACTORY balance $TESTACCTA
node ./cli.js 0 $FACTORY cancel 0
node ./cli.js 0 $FACTORY balance $TESTACCTA
echo

echo =================================================================
echo make an option that expires NOW so next block it will be expired
echo =================================================================
node ./cli.js 0 $FACTORY balance $TESTACCTA
node ./cli.js 0 $FACTORY make "true" $ETHER 500000 0 $ERC20 100000 0 $EPOCHSECONDS "mydata"
sleep 1

echo --- maker 0 sells nft to address 1 on some nft marketplace
node ./cli.js 0 $FACTORY approve $TESTACCTB 1
node ./cli.js 1 $FACTORY transferFrom $TESTACCTA 1
sleep 1

echo
echo --- anyone taking the already-expired option returns collateral to maker
echo
node ./cli.js 1 $FACTORY approve $FACTORY 1
node ./cli.js 1 $FACTORY take 1
#node ./cli.js 0 $FACTORY balance $TESTACCTA

echo OptionNFT events:
node ./cli.js 0 $FACTORY events

popd
#node ./events.js $ERC20 $ERC721

