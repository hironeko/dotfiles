#!/bin/bash

#ZSHRC=~/.zshrc

# ログインシェルの変更
#chsh -s /bin/zsh
echo " install shell prototype "

if test ! $(which brew)
then
  if test ! "$(uname)" = "Darwin"
  then
    echo "  I nstalling Homebrew for your PC."
    #/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi
fi

#        brew install cellar

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

#        brew cask install

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
  gyazo
)

for cask in ${CASK_NAME[@]}
 do
  echo $cask
  #brew cask install $cask
done
