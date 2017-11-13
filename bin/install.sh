#!/bin/bash

# mac_set_up.sh の読み込み
#MAC_SET_UP=`./mac_set_up.sh`

# ログインシェルの変更
#chsh -s /bin/zsh
## コマンドの有無
has() {
    type "$1" > /dev/null 2>&1
}

if has "brew"; then
    echo "yes"
fi

if [[ `uname` -eq "Darwin" ]]; then
    echo "Installing Homebrew for your PC."
fi
