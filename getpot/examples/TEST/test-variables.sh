#! /usr/bin/env bash
if [[ $1 == "--test-info" ]]; then
    echo "Variables"
    exit
fi
echo "../variables float=1e37 integer=38 string='frank-rene schaefer' vector='08.15 sourceforge 42' string=bonjorno"
../variables float=1e37 integer=38 string='frank-rene schaefer' vector='08.15 sourceforge 42' string=bonjorno

echo "../variables float=3.14 integer=1970 string='frank-rene schaefer' vector='08.15 sourceforge 42'"
../variables float=3.14 integer=1970 string='frank-rene schaefer' vector='08.15 sourceforge 42'

echo "../variables float=1e37 integer=1968 string='sonderbar' vector='08.15 sourceforge 42'"
../variables float=1e37 integer=1968 string='sonderbar' vector='08.15 sourceforge 42'

