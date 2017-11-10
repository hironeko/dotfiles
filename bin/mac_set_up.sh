#!/bin/bash

# change default shell
chsh -s /bin/zsh

/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

brew update

brew tap homebrew/php71

brew install nvm \
sqlite \
git \
pyenv \
go \
tree \
composer \
erlang \
elixir \
postgresql \
mysql \
vim


CASK_NAME=(
  clipy
  alfred
  docker
  emacs
  google-chrome
  dropbox
  iterm2
  slack
  quip
  vagrant
  virtualbox
)

for cask in ${CASK_NAME[@]}
do
  brew cask install $cask
done

echo << EOS
complete install
let's enjoy!!
EOS
