#!/bin/bash


RELEASE_FILE=/etc/os-release

# set up for macOSX
if [[ `uname` == "Darwin" ]]; then
    # directoryの確認
    if [[ -d $HOME/dotfiles ]]; then
        echo "done dotfiles"
        . $HOME/dotfiles/install/functions/functions.sh
        hoge
    else
        echo "git cloning......."
        git clone --recursive https://github.com/hironeko/dotfiles.git $HOME/dotfiles
        . $HOME/dofiles/install/functions/functions.sh
        prezto_set
        spacemacs_set
    fi
elif grep -e '^NAME="CentOS' $RELEASE_FILE >/dev/null; then
    echo "CentOs"
elif grep -e '^NAME="Ubuntu' $RELEASE_FILE >/dev/null; then
    echo "Ubuntu"
fi

exit 0
