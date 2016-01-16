#! /usr/bin/env bash
if [[ $1 == "--test-info" ]]; then
    echo "UFO-Detection: User Specified Arguments"
    exit
fi

echo "../ufo yes no -i source.cpp --arguments"
../ufo yes no -i source.cpp --arguments

echo "../ufo -i source.cpp --force n=13 -xzt --options"
../ufo -i source.cpp --force n=13 -xzt --options

echo "../ufo zfd if=source.cpp force n=13 -l -zrt -olp --flags"
../ufo zfd if=source.cpp force n=13 -l -zrt -olp --flags

echo "../ufo zfd x=12 y=234 loength=21 height=21 n=2 --variables"
../ufo zfd x=12 y=234 loength=21 height=21 n=2 --variables

echo "../ufo --sections # (edit file section labels in example.pot)"
../ufo --sections # (edit file section labels in example.pot)

echo "../ufo n=21 -i in.dat -o out.dat /etc/fstab force --nominuses "
../ufo n=21 -i in.dat -o out.dat /etc/fstab force --nominuses 


