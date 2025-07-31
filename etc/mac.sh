#!/bin/bash

if test ! $(which brew); then
    echo "Installing Homebrew for your PC."
#    xcode-select --install
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    exec $SHELL -l
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
    git
    go
    tree
    vim
    tmux
    tig
    anyenv
    awscli
    peco
    gh
    bat
    git-secret
    lazygit
    powerlevel10k
    powerline-go
    font-hack-nerd-font
    font-fira-code-nerd-font
    font-meslo-lg-nerd-font
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
  docker
  google-chrome
  slack
  visual-studio-code
  raycast
  arc
  protonvpn
  zed
)

for cask in ${CASK_NAME[@]}; do
#   if brew cask list "$cask" > /dev/null 2>&1; then
    #   brew cask install $cask
  if brew list "$cask" > /dev/null 2>&1; then
      echo "$cask already installed.... skipping"
  else
      brew install --cask  $cask
  fi
done

brew cleanup
#brew cask cleanup

# install volta
curl https://get.volta.sh | bash
volta setup

cat <<EOF

****************************

complete brew install
let's enjoy!!

****************************

EOF

return 0
