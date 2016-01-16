#! /usr/bin/env bash
if [[ $1 == "--test-info" ]]; then
    echo "Field Separator in Array Arguments"
    exit
fi
echo "../field_separator fs='.' test='129. 11. 32.  5'"
../field_separator fs='.' test='129. 11. 32.  5'

echo "../field_separator fs='. ' test='129. 11. 32.  5'"
../field_separator fs='. ' test='129. 11. 32.  5'

