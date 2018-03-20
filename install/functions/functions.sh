#!/bin/bash

prezto_set () {
    cat <<EOF

    #############################################
    #                                           #
    #        prezto setup... start              #
    #                                           #
    #############################################

EOF

    . $HOME/dotfiles/etc/mac.sh

    if [ $SHELL = "/bin/bash" ]; then
        . $HOME/dotfiles/etc/prezto.sh
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

    exit 1

}

spacemacs_set () {
    cat <<EOF

    #############################################
    #                                           #
    #        spacemacs install ...start         #
    #                                           #
    #############################################

EOF
    # spacemacs clone
    if [ ! -e $HOME/.emacs.d/spacemacs.mk ]; then
        . $HOME/dotfiles/etc/spacemacs.sh
    fi
    cat <<EOF

    #############################################
    #                                           #
    #        spacemacs install ...done          #
    #                                           #
    #############################################

EOF
    emacs --insecure

    exit 1
}

# git-flow set up for linux
gitflow () {
    curl -sL https://raw.githubusercontent.com/hironeko/setUpShells/develop/gitflow_set.sh | sh
}

symlink_set () {
    DOT_FILES=(
        .zshrc
        .spacemacs
        .tmux.conf
        .vimrc
        .gemrc
        package.json
    )

    for file in ${DOT_FILES[@]}; do
        ln -sf $HOME/dotfiles/$file $HOME/$file
    done

    ln -nfs $HOME/dotfiles/.emacs.d $HOME/.emacs.d
    cat <<EOF
    ########################
    #                      #
    #     done symlink     #
    #                      #
    ########################
EOF

    exit 1
}

# how to
# ! has some; then
has () {
  type "$1" &> /dev/null ;
}
