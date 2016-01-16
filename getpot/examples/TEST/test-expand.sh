#! /usr/bin/env bash
if [[ $1 == "--test-info" ]]; then
    echo "Input File Parsing: Macro Expansion (Dollar Brackets)"
    exit
fi
echo "../expand --directory ../"
../expand --directory ../

