#! /usr/bin/env bash
if [[ $1 == "--test-info" ]]; then
    echo "Follow Arguments: Any"
    exit
fi
echo "../follow --alpha 3.14 --beta 0.815 --size -1 1 --user arnold.nyme 32141 --user ruth.chelle"
../follow --alpha 3.14 --beta 0.815 --size -1 1 --user arnold.nyme 32141 --user ruth.chelle

echo "../follow --alpha 3.14 --beta 0.815 --size -1 1 --user arnold.nyme -32141 --user ruth.chelle 3"
../follow --alpha 3.14 --beta 0.815 --size -1 1 --user arnold.nyme -32141 --user ruth.chelle 3

