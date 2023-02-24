#!/bin/bash

DOTPATH=$HOME/dotfiles

prezto_set () {

    cat <<EOF

    #############################################
    #                                           #
    #        prezto setup... check              #
    #                                           #
    #############################################

EOF

    if [ $SHELL = "/bin/bash" ]; then
        . $DOTPATH/etc/prezto.sh
    else
        echo "alredy changed zsh"
    fi
    cat <<EOF

    #############################################
    #                                           #
    #        prezto setup... done               #
    #                                           #
    #############################################

EOF
    return 0
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
    # if [ ! -e $HOME/.emacs.d/spacemacs.mk ]; then
    . $DOTPATH/etc/spacemacs.sh
    # else
        # echo "done"
    # fi

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
        # .spacemacs
        .tmux.conf
        .vimrc
        .gemrc
        package.json
    )

    for file in ${DOT_FILES[@]}; do
        ln -sf $DOTPATH/$file $HOME/$file
    done

    ln -nfs $DOTPATH/.emacs.d $HOME/.emacs.d
    cat <<EOF
    ########################
    #                      #
    #     done symlink     #
    #                      #
    ########################
EOF
    return 0
}

# how to
# ! has some; then
has () {
  type "$1" &> /dev/null ;
}

starship_set() {
    curl -fsSL https://starship.rs/install.sh | bash
    exec $SHELL -l
}

setup () {
    
    . $DOTPATH/etc/mac.sh

    # prezto_set

    #starship_set

    symlink_set
    
    #if [ ! -e $HOME/.emacs.d/spacemacs.mk ]; then
    #    spacemacs_set
    #fi

}
