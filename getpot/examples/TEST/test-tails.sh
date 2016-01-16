#! /usr/bin/env bash
if [[ $1 == "--test-info" ]]; then
    echo "Directly Followed Arguments: Easy, Using '*_tails()'"
    exit
fi
echo "../tails -U -Udu -Uschoene -Uwelt -V -V -V"
../tails -U -Udu -Uschoene -Uwelt -V -V -V

echo "../tails -Uhallo -Udu -Uschoene -Uwelt -V1 -V2 -V3"
../tails -Uhallo -Udu -Uschoene -Uwelt -V1 -V2 -V3

echo "../tails -Uhallo -Udu -Uschoene -Uwelt"
../tails -Uhallo -Udu -Uschoene -Uwelt

echo "../tails -U -Udu -Uschoene -Uwelt -V -V -V -NUM3.14 -NUM1.41 -NUM"
../tails -U -Udu -Uschoene -Uwelt -V -V -V -NUM3.14 -NUM1.41 -NUM

