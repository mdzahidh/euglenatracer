#! /usr/bin/env bash
if [[ $1 == "--test-info" ]]; then
    echo "GetPot 'get' - function group"
    exit
fi

echo "../get"
../get
echo "../get 1"
../get 1
echo "../get 1 2"
../get 1 2
echo "../get 1 2 5"
../get 1 2 5
echo "../get 1 2 5 6"
../get 1 2 5 6
echo "../get 1 2 5 6 2"
../get 1 2 5 6 2
echo "../get hallo liebe Leute hallo guten tag 2 3 4"
../get hallo liebe Leute hallo guten tag 2 3 4
