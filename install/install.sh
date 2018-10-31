#!/bin/bash


RELEASE_FILE=/etc/os-release

cloneDotfiles() {
    git clone --recursive https://github.com/hironeko/dotfiles.git $HOME/dotfiles
}

setUp () {
    . $HOME/dotfiles/install/functions/functions.sh
    setup
}

# set up for macOSX
if [[ `uname` == "Darwin" ]]; then
    # check directory
    if [[ -d $HOME/dotfiles ]]; then
        echo "already exits dir"
        echo "set up start"
        setUp
    else
        cat <<EOF
            git cloning.......
EOF
        cloneDotfiles
        cat <<EOF
            git clone done & set up start
EOF
        setUp
    fi
elif grep -e '^NAME="CentOS' $RELEASE_FILE >/dev/null; then
    echo "CentOs"
elif grep -e '^NAME="Ubuntu' $RELEASE_FILE >/dev/null; then
    echo "Ubuntu"
fi

exit 0
