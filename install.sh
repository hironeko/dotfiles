#!/bin/bash

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
  . $HOME/dotfiles/bin/mac_set_up.sh
fi

# TODO: set up for prezto
if [ $SHELL = "/bin/bash" ]; then
    . $HOME/dotfiles/bin/prezto_set_up.sh
else
    echo "done change zsh"
fi

cat <<EOF

    #############################################
    #                                           #
    #        spacemacs install ...now           #
    #                                           #
    #############################################

EOF

# spacemacs clone
if [ ! -e $HOME/.emacs.d/spacemacs.mk ]; then
    . $HOME/dotfiles/bin/spacemacs_set_up.sh
fi

exit 0
