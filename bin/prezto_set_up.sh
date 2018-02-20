#!/bin/bash

# change default shell
chsh -s /bin/zsh

git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"

zsh -c 'setopt EXTENDED_GLOB; for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/* ; do ; ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}" ; done'

exec $SHELL -l

return 0
