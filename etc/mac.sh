#!/bin/bash

if test ! $(which brew); then
    echo "Installing Homebrew for your PC."
    xcode-select --install
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
else
    echo "done brew"
fi

brew upgrade
brew update

cat <<EOF

#############################################
#                                           #
#        brew install cellar                #
#                                           #
#############################################

EOF

CELLAR_NAME=(
    nvm
    git
    go
    tree
    composer
    vim
    tmux
    tig
    hub
    anyenv
    deno
    git-secret
    awscli
    peco
    bat
    lazygit
)

for cellar in ${CELLAR_NAME[@]}; do
  if brew list "$cellar" > /dev/null 2>&1; then
      echo "$cellar already installed.... skipping"
      echo ""
  else
      echo "$cellar installing.... "
      echo ""
      brew install $cellar
      echo ""
      echo "$cellar done"
  fi
done

anyenv install --init

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
  #emacs
  google-chrome
  dropbox
  iterm
  slack
  quip
  #vagrant
  #virtualbox
  visual-studio-code
  #boostnote
  #fork
  #jasper
  sequel-pro
  dicord
)

for cask in ${CASK_NAME[@]}; do
#   if brew cask list "$cask" > /dev/null 2>&1; then
    #   brew cask install $cask
  if brew list "$cask" > /dev/null 2>&1; then
      echo "$cask already installed.... skipping"
  else
      brew install $cask
  fi
done

brew cleanup
#brew cask cleanup

cat <<EOF

****************************

complete brew install
let's enjoy!!

****************************

EOF

return 0
