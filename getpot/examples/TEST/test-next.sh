#! /usr/bin/env bash
if [[ $1 == "--test-info" ]]; then
    echo "Next Argument"
    exit
fi
echo "../next 0.1 123.4 'hallo welt' 21"
../next 0.1 123.4 'hallo welt' 21

echo "../next 'hallo welt' gugu 47.1 logo"
../next 'hallo welt' gugu 47.1 logo

echo "../next 0.000009 0.000009 12 65535 df aee ff 123 000d '\n'"
../next 0.000009 0.000009 12 65535 df aee ff 123 000d '\n'

