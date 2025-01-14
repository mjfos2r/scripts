#!/bin/zsh

if [[ $# != 1 ]]; then
    echo "please specify a single file to return the path for!"
    exit 1
fi

FILE=$1
PATH=$(readlink -f $FILE)
/usr/bin/pbcopy <<< "$PATH"
echo $PATH
exit 0
