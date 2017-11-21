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

# spacemacs clone
if [ ! -e $HOME/.emacs.d/spacemacs.mk ]; then
    cat <<EOF

        #############################################
        #                                           #
        #        spacemacs install ...now           #
        #                                           #
        #############################################

    EOF
    . $HOME/dotfiles/bin/spacemacs_set_up.sh
fi

if emacs --version > /dev/null 2>&1; then
    emacs --insecure
fi

exit 0
