#!/bin/bash

if [[ `uname` -eq "Darwin" ]]; then
  /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
fi

brew upgrade
brew update

# tap
brew tap homebrew/php71 \
caskroom/cask

echo <<EOF

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
)

for cellar in ${CELLAR_NAME[@]}; do
  brew install $cellar
done

echo <<EOF

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
)

for cask in ${CASK_NAME[@]}; do
  brew cask install $cask
done

brew cleanup
brew cask cleanup

echo <<EOF

****************************
complete brew install
let's enjoy!!
****************************

EOF
