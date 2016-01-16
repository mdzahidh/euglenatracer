#! /usr/bin/env bash
if [[ $1 == "--test-info" ]]; then
    echo "Options (Arguments Starting with '-')"
    exit
fi
echo "../options --nice beep neep --slice --senal-acustica"
../options --nice beep neep --slice --senal-acustica

echo "../options --nice beep neep --slice --senal-acustica --do-nothing"
../options --nice beep neep --slice --senal-acustica --do-nothing

