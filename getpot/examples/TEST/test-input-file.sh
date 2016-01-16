#! /usr/bin/env bash
if [[ $1 == "--test-info" ]]; then
    echo "Input File Parsing: Simple Example"
    exit
fi
echo "../input-file --directory ../"
../input-file --directory ../

echo "../input-file -c GetPot"
../input-file -c GetPot

echo "../input-file -c Punk"
../input-file -c Punk

echo "../input-file -c BASIC"
../input-file -c BASIC

echo "../input-file -c C"
../input-file -c C

