#! /usr/bin/env bash
if [[ $1 == "--test-info" ]]; then
    echo "Combining GetPot Objects - Absorbtion"
    exit
fi
echo "../absorb --directory ../"
../absorb --directory ../
echo "../absorb --directory ../ bubu=6711 --I12"
../absorb --directory ../ bubu=6711 --I12

