#! /usr/bin/env bash
if [[ $1 == "--test-info" ]]; then
    echo "UFO-Detection: Easy"
    exit
fi
echo "../ez-ufo yes no -i source.cpp --arguments"
../ez-ufo yes no -i source.cpp --arguments

echo "../ez-ufo zfd x=12 y=234 loength=21 height=21 n=2 --variable"
../ez-ufo zfd x=12 y=234 loength=21 height=21 n=2 --variable

echo "../ez-ufo yes no -i source.cpp --nominuses -o out.o gogo"
../ez-ufo yes no -i source.cpp --nominuses -o out.o gogo

echo "../ez-ufo n=21 -i in.dat -o out.dat /etc/fstab force --nominuses"
../ez-ufo n=21 -i in.dat -o out.dat /etc/fstab force --nominuses

