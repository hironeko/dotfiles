#!/bin/bash


RELEASE_FILE=/etc/os-release

cloneDotfiles() {
    git clone --recursive https://github.com/hironeko/dotfiles.git $HOME/dotfiles
}

# set up for macOSX
if [[ `uname` == "Darwin" ]]; then
    # check directory
    if [[ -d $HOME/dotfiles ]]; then
        echo "done dotfiles"
        . $HOME/dotfiles/install/functions/functions.sh
        setup
    else
        echo ""
        echo "git cloning......."
        echo ""
        # git clone --recursive https://github.com/hironeko/dotfiles.git $HOME/dotfiles
        cloneDotfiles
        echo ""
        echo "git clone done"
        echo ""

        . $HOME/dotfiles/install/functions/functions.sh
        setup
    fi
elif grep -e '^NAME="CentOS' $RELEASE_FILE >/dev/null; then
    echo "CentOs"
elif grep -e '^NAME="Ubuntu' $RELEASE_FILE >/dev/null; then
    echo "Ubuntu"
fi

exit 0
