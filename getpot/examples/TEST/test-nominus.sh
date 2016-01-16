#! /usr/bin/env bash
if [[ $1 == "--test-info" ]]; then
    echo "Nominus Arguments"
    exit
fi
echo "../nominus sss ddd fff"
../nominus sss ddd fff

echo "../nominus -v sss -a ddd variable=12 fff"
../nominus -v sss -a ddd variable=12 fff

