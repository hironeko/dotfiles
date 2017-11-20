#!/bin/bash

# mac_set_up.sh の読み込み
#MAC_SET_UP=`./mac_set_up.sh`

# ログインシェルの変更
#chsh -s /bin/zsh

# コマンドの有無
# directoryの確認
if [[ -d $HOME/dotfiles ]]; then
  echo "done dotfiles"
  #exit 0
else
  echo "git cloning......."
  #git clone https://github.com/hironeko/dotfiles.git
  echo "done git clone"
fi

# set up for macOSX
if [[ `uname` -eq "Darwin" ]]; then
  source $HOME/dotfiles/bin/mac_set_up.sh
fi

# TODO: set up for prezto
if [ $SHELL = "/bin/bash" ]; then
    source $HOME/dotfiles/bin/prezto_set_up.sh
else
    echo "done change zsh"
fi

# spacemacs clone
if [ ! -f $HOME/.emacs.d/spacemacs.mk ]; then
    git clone git clone https://github.com/syl20bnr/spacemacs $HOME/.emacs.d
    emacs --insecure
fi

exit 0
