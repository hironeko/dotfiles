#!/bin/bash

if test ! $(which brew); then
  echo "Installing Homebrew for your PC."
  xcode-select --install
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
elif brew doctor > /dev/null 2>&1; then
    echo "done brew"
fi

brew upgrade
brew update

# tap
brew tap homebrew/php
brew tap Goles/battery

cat <<EOF

#############################################
#                                           #
#        brew install cellar                #
#                                           #
#############################################

EOF

CELLAR_NAME=(
    nvm
    sqlite
    git
    pyenv
    go
    tree
    php71
    composer
    erlang
    elixir
    postgresql
    mysql
    vim
    rbenv
    git-flow
    battery
    tmux
)

for cellar in ${CELLAR_NAME[@]}; do
  if brew list "$cellar" > /dev/null 2>&1; then
      echo "$cellar already installed.... skipping"
  else
      echo "$cellar installing.... now"
      brew install $cellar
      echo "$cellar installing.... done"
  fi
done

cat <<EOF

############################################
#                                          #
#        brew cask install                 #
#                                          #
############################################

EOF

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
  visual-studio-code
)

for cask in ${CASK_NAME[@]}; do
  if brew cask list "$cask" > /dev/null 2>&1; then
      echo "$cask already installed.... skipping"
  else
      brew cask install $cask
  fi
done

brew cleanup
brew cask cleanup

xcode-select --install

cat <<EOF

****************************
complete brew install
let's enjoy!!
****************************

EOF

return 0
