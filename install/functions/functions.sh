#!/bin/bash

prezto_set () {
    cat <<EOF

    #############################################
    #                                           #
    #        prezto setup... satrt              #
    #                                           #
    #############################################

EOF

    . $HOME/dotfiles/bin/mac_set_up.sh
    # TODO: set up for prezto
    if [ $SHELL = "/bin/bash" ]; then
        . $HOME/dotfiles/bin/prezto_set_up.sh
    else
        echo "done changed zsh"
    fi
    cat <<EOF

    #############################################
    #                                           #
    #        prezto setup... done               #
    #                                           #
    #############################################

EOF

}

spacemacs_set () {
    cat <<EOF

    #############################################
    #                                           #
    #        spacemacs install ...satrt         #
    #                                           #
    #############################################

EOF
    # spacemacs clone
    if [ ! -e $HOME/.emacs.d/spacemacs.mk ]; then
        . $HOME/dotfiles/bin/spacemacs_set_up.sh
    fi
    cat <<EOF

    #############################################
    #                                           #
    #        spacemacs install ...done          #
    #                                           #
    #############################################

EOF

}

# git-flow set up for linux
gitflow () {
    curl -sL https://raw.githubusercontent.com/hironeko/setUpShells/develop/gitflow_set.sh | sh
}


hoge () {
    cat <<EOF
    test
    hoge
    +++++++
 EOF
}
