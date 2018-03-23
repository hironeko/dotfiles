#!/bin/bash

. $HOME/dotfiles/install/functions/functions.sh

CELLAR_NAME=$(brew list)
CASK_NAME=$(brew cask list)

for cellar in ${CELLAR_NAME[@]}; do
    if brew list "$cellar" > /dev/null 2>&1; then
        echo ""
        echo ""
        echo "$cellar installed.... start unisntall"
        brew uninstall $cellar
        echo "done"
        echo ""
        echo ""
    else
        echo ""
        echo "$cellar not install"
        echo ""
    fi
done


for cask in ${CASK_NAME[@]}; do
    if brew cask list "$cask" > /dev/null 2>&1; then
        echo ""
        echo ""
        echo "$cask installed.... start uninstall"
        brew cask uninstall $cask
        echo "done"
        echo ""
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

echo ""
cat <<EOF

***************************

symlink unlink

***************************

EOF

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

chsh -s /bin/bash

echo ""
cat <<EOF

***************************

change shell done

***************************

EOF

chsh -s /bin/bash

echo "done"
echo ""

cat <<EOF

***************************

uninstall brew

***************************

EOF

if has $(which brew); then
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/uninstall)"
fi


echo ""
cat <<EOF

****************************

complete uninstall
Good Bye!!!

****************************

EOF


