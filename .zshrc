# if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
#   source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
# fi

# # Ensure that a non-login, non-interactive shell has a defined environment.
# if [[ "$SHLVL" -eq 1 && ! -o LOGIN && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
#     source "${ZDOTDIR:-$HOME}/.zprofile"
# fi

# M1
eval $(/opt/homebrew/bin/brew shellenv)

# starshipコメントアウト
#eval "$(starship init zsh)"
eval "$(anyenv init - --no-rehash)"

# eval "$(rbenv init -)"

# -------------------------------------
# alias の読み込み
# -------------------------------------

. $HOME/dotfiles/bin/alias

# -------------------------------------
# path の読み込み
# -------------------------------------

. $HOME/dotfiles/bin/path

#--------------------------------------
# phpenv のため
#--------------------------------------

# . $HOME/dotfiles/bin/phpenv_build_path

#
# エディタ
export EDITOR=vim
export VISUAL=vim
# ページャ
#export PAGER=/usr/local/bin/vimpager
#export MANPAGER=/usr/local/bin/vimpager

# -------------------------------------
# zshのオプション
# -------------------------------------

## 補完機能の強化
autoload -Uz compinit
compinit
setopt auto_list
setopt auto_menu
zstyle ":completion:*" menu select

## 入力しているコマンド名が間違っている場合にもしかして：を出す。
setopt correct

# ビープを鳴らさない
setopt no_beep

## 色を使う
setopt prompt_subst

## ^Dでログアウトしない。
setopt ignoreeof

setopt complete_in_word

## バックグラウンドジョブが終了したらすぐに知らせる。
setopt no_tify

# 補完

# cd -[tab]で過去のディレクトリにひとっ飛びできるようにする
setopt auto_pushd

# ディレクトリ名を入力するだけでcdできるようにする
setopt auto_cd

# -------------------------------------
# パス
# -------------------------------------

# 重複する要素を自動的に削除
typeset -U path cdpath fpath manpath

path=(
    $HOME/bin(N-/)
    /usr/local/bin(N-/)
    /usr/local/sbin(N-/)
    $path
)

# -------------------------------------
# プロンプト
# -------------------------------------

autoload -U promptinit; promptinit
autoload -Uz colors; colors
autoload -Uz vcs_info
autoload -Uz is-at-least
autoload -Uz add-zsh-hook

setopt prompt_subst

# begin VCS
zstyle ":vcs_info:*" enable git svn hg bzr
zstyle ":vcs_info:*" formats "(%s)-[%b]"
zstyle ":vcs_info:*" actionformats "(%s)-[%b|%a]"
zstyle ":vcs_info:(svn|bzr):*" branchformat "%b:r%r"
zstyle ":vcs_info:bzr:*" use-simple true

zstyle ":vcs_info:*" max-exports 6

# %b カレントブランチ
# %u not add  %c add only  %n yourname
if is-at-least 4.3.10; then
    zstyle ":vcs_info:git:*" check-for-changes true # commitしていないのをチェック
    zstyle ":vcs_info:git:*" stagedstr "%F{yellow} ✚"
    zstyle ":vcs_info:git:*" unstagedstr "%F{magenta} ✖"
    zstyle ":vcs_info:git:*" formats "%F{cyan}(%b)%c%u%f"
    zstyle ":vcs_info:git:*" actionformats "(%s)-[%b|%a]%c%u"
fi

precmd(){ vcs_info }

function vcs_prompt_info() {
    psvar=()
    LANG=en_US.UTF-8 vcs_info
    [[ -n "$vcs_info_msg_0_" ]] && echo -n " %{$fg[yellow]%}$vcs_info_msg_0_%f"
}
# end VCS

#PROMPT+="%(?.%F{green}$OK%f.%F{red}$NG%f) "
#PROMPT+="%F{blue}%~%f\$(vcs_prompt_info)"
#PROMPT+="%% "
#RPROMPT="[%*]"

RPROMPT=\$vcs_info_msg_0_

# -------------------------------------
# キーバインド
# -------------------------------------

bindkey -e

function cdup() {
   echo
   cd ..
   zle reset-prompt
}
zle -N cdup
bindkey '^K' cdup

bindkey "^R" history-incremental-search-backward

# -------------------------------------
# その他
# -------------------------------------

# cdしたあとで、自動的に ls する
function chpwd() { ls -a1 }

# change tab name(title)
function title {
    echo -ne "\033]0;"$*"\007"
}

#ヒストリーサイズ設定
# history size setting
HISTFILE=$HOME/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
setopt share_history

#pecoでhistory検索
function peco-select-history() {
  BUFFER=$(\history -n -r 1 | peco --query "$LBUFFER")
  CURSOR=$#BUFFER
  zle clear-screen
}
zle -N peco-select-history
bindkey '^r' peco-select-history


# eval "$(ssh-agent -s)"
# ssh-add --apple-use-keychain
export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

[ -f ~/.inshellisense/key-bindings.zsh ] && source ~/.inshellisense/key-bindings.zsh


export PS1="%~ "$'\n'""
