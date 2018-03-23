#!/bin/bash


CELLAR_NAME=(
    nvm
    sqlite
    git
    pyenv
    go
    tree
    php72
    composer
    postgresql
    mysql
    vim
    rbenv
    git-flow
    tmux
)

for cellar in ${CELLAR_NAME[@]}; do
    if brew list "$cellar" > /dev/null 2>&1; then
        echo ""
        echo "$cellar installed.... start unisntall"
        echo ""
        brew uninstall $cellar
        echo ""
        echo ""
        echo "done"
        echo ""
        echo ""
    else
        echo ""
        echo "$cellar not install"
        echo ""
    fi
done


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
        echo ""
        echo ""
        echo "$cask installed.... start uninstall"
        brew cask uninstall $cask
        echo ""
    else
        echo ""
        echo ""
        echo "$cask not installed !!"
        echo ""
        echo ""
    fi
done

brew cleanup
brew cask cleanup


rm -rf $HOME/.zprezto

DOT_FILES=(
  .zshrc
  .spacemacs
  .tmux.conf
  .vimrc
  .gemrc
  package.json
)

for file in ${DOT_FILES[@]}; do
  unlink $HOME/$file
done

unlink $HOME/.emacs.d

echo ""
cat <<EOF

****************************

complete uninstall
Good Bye!!!

****************************

EOF


