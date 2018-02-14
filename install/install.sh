#!/bin/bash

. ./functions/functions.sh

RELEASE_FILE=/etc/os-release

# set up for macOSX
if [[ `uname` == "Darwin" ]]; then
    # directoryの確認
    if [[ -d $HOME/dotfiles ]]; then
        echo "done dotfiles"
        hoge
    else
        dotfiles
    fi
elif grep -e '^NAME="CentOS' $RELEASE_FILE >/dev/null; then
    echo "CentOs"
elif grep -e '^NAME="Ubuntu' $RELEASE_FILE >/dev/null; then
    echo "Ubuntu"
fi

exit 0
