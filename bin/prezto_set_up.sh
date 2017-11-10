
git clone --recursive https://github.com/sorin-ionescu/prezto.git "${ZDOTDIR:-$HOME}/.zprezto"

zsh -c 'setopt EXTENDED_GLOB; for rcfile in "${ZDOTDIR:-$HOME}"/.zprezto/runcoms/* ; do ; ln -s "$rcfile" "${ZDOTDIR:-$HOME}/.${rcfile:t}" ; done'

DOT_FILES=(
    .zshrc
    .bash_profile
    .emacs.d
    .spacemacs
    .tmux.conf
    .vimrc
    package.json
)

for file in ${DOT_FILES[@]}
do
    #echo $file
    ln -sf $HOME/dotfiles/$file $HOME/$file
done

#source $HOME/$ZSHRC
exec $SHELL -l
