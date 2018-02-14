#!/bin/bash

RELEASE_FILE=/etc/os-release

# set up for macOSX
if [[ `uname` == "Darwin" ]]; then
    # directoryの確認
    if [[ -d $HOME/dotfiles ]]; then
        echo "done dotfiles"
    else
        echo "git cloning......."
        git clone --recursive https://github.com/hironeko/dotfiles.git
        echo "done git clone , start shell"
        . $HOME/dotfiles/bin/mac_set_up.sh
    fi
elif grep -e '^NAME="CentOS' $RELEASE_FILE >/dev/null; then
  echo "CentOs"
elif grep -e '^NAME="Ubuntu' $RELEASE_FILE >/dev/null; then
  echo "Ubuntu"
fi


# TODO: set up for prezto
if [ $SHELL = "/bin/bash" ]; then
    . $HOME/dotfiles/bin/prezto_set_up.sh
else
    echo "done changed zsh"
fi

cat <<EOF

    #############################################
    #                                           #
    #        spacemacs install ...now           #
    #                                           #
    #############################################

EOF

# spacemacs clone
if [ ! -e $HOME/.emacs.d/spacemacs.mk ]; then
    . $HOME/dotfiles/bin/spacemacs_set_up.sh
fi

exit 0
