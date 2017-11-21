#!/bin/bash

# change default shell
chsh -s /bin/zsh

git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"

zsh -c 'setopt EXTENDED_GLOB; for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/* ; do ; ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}" ; done'

DOT_FILES=(
    .zshrc
    .bash_profile
    .spacemacs
    .tmux.conf
    .vimrc
    package.json
)

for file in ${DOT_FILES[@]}; do
    #echo $file
    ln -sf $HOME/dotfiles/$file $HOME/$file
done

ln -nfr $HOME/dotfiles/.emacs.d $HOME/.emacs.d

exec $SHELL -l

return 0
