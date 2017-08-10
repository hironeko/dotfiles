#!/bin/bash

#ZSHRC=~/.zshrc

# ログインシェルの変更
#chsh -s /bin/zsh
#echo " install shell prototype "

if test ! $(which brew)
then
  if test ! "$(uname)" = "Darwin"
  then
    echo "  I nstalling Homebrew for your PC."
   # /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
fi


DOT_FILES=(
  .zshrc
  .bash_profile
  .emacs.d
  .spacemacs
  .tmux.conf
  .vimrc
  package.json
)

for file in ${DOT_FILES[@]}
 do
  echo $file
  #ln -sf $HOME/dotfiles/$file $HOME/$file
done

#############################################
#                                           #
#        brew install cellar                #
#                                           #
#############################################

#brew update

CELLAR_NAME=(
  nvm
  sqlite
  yarn
  php70
  git
  pyenv
  go
  heroku
  tree
  composer
  erlang
  elixir
  postgresql
  mysql
  vim
  exa
)

for cellar in ${CELLAR_NAME[@]}
 do
  echo $cellar
  #brew install $cellar
done

############################################
#                                          #
#        brew cask install                 #
#                                          #
############################################

CASK_NAME=(
  clipy
  alfred
  docker
  emacs
  google-chrome
  visual-studio-code
  dropbox
  iterm2
  slack
  quip
)

for cask in ${CASK_NAME[@]}
 do
  echo $cask
  #brew cask install $cask
done

git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"

setopt EXTENDED_GLOB
for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/^README.md(.N); do
  ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}"
done

#source $HOME/$ZSHRC
