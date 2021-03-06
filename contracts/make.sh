#!/bin/bash

commd=$1

if [ -z $commd ]
then
  echo compiling ...
  solcjs --bin --abi --optimize \
    --base-path . \
    --include-path /home/skull/node_modules \
    -o ./build *.sol
fi

if [ "$commd" = "clean" ]
then
  echo cleaning ...
  rm -rf build
fi
