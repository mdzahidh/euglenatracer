#! /usr/bin/env bash
if [[ $1 == "--test-info" ]]; then
    echo "Directly Followed Arguments: Iteration"
    exit
fi
echo "../direct_follow -Uss"
../direct_follow -Uss

echo "../direct_follow --help"
../direct_follow --help

echo "../direct_follow -Ududu -Uim -V12 -URadio"
../direct_follow -Ududu -Uim -V12 -URadio

echo "../direct_follow -Ududu -Uim -V12 -URadio -V13"
../direct_follow -Ududu -Uim -V12 -URadio -V13

echo "../direct_follow -Ududu -Uim -V12 -URadio -V13 -N12"
../direct_follow -Ududu -Uim -V12 -URadio -V13 -N12

