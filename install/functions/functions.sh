#!/bin/bash

prezto_set () {

    . $HOME/dotfiles/etc/mac.sh

    cat <<EOF

    #############################################
    #                                           #
    #        prezto setup... check              #
    #                                           #
    #############################################

EOF

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
    else
        echo "done"
        exit 1
    fi

    cat <<EOF

    #############################################
    #                                           #
    #        spacemacs install ...done          #
    #                                           #
    #############################################

EOF
    emacs --insecure

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

}

# how to
# ! has some; then
has () {
  type "$1" &> /dev/null ;
}
