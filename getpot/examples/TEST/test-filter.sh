#! /usr/bin/env bash
if [[ $1 == "--test-info" ]]; then
    echo "Filter Prefixes"
    exit
fi
echo "../filter --nice"
../filter --nice

