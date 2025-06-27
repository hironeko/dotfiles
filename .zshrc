# Enable Powerlevel10k instant prompt. Should stay close to the top of ~/.zshrc.
# Initialization code that may require console input (password prompts, [y/n]
# confirmations, etc.) must go above this block; everything else may go below.
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi


# M1
eval $(/opt/homebrew/bin/brew shellenv)

# starshipコメントアウト
#eval "$(starship init zsh)"


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


#
# エディタ
export EDITOR=vim
export VISUAL=vim
# ページャ

# -------------------------------------
# zshのオプション
# -------------------------------------

## 補完機能の強化
autoload -Uz compinit
compinit
setopt auto_list
setopt auto_menu
zstyle ":completion:*" menu select

# 大文字小文字を区別しない補完
zstyle ":completion:*" matcher-list 'm:{a-z}={A-Z}' 'm:{A-Z}={a-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'

## 入力しているコマンド名が間違っている場合にもしかして：を出す。
setopt correct

# ビープを鳴らさない
setopt no_beep

## 色を使う

## ^Dでログアウトしない。
setopt ignoreeof

setopt complete_in_word

## バックグラウンドジョブが終了したらすぐに知らせる。
setopt notify

# 補完

# cd -[tab]で過去のディレクトリにひとっ飛びできるようにする
setopt auto_pushd

# ディレクトリ名を入力するだけでcdできるようにする
setopt auto_cd


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

# RPROMPT=\$vcs_info_msg_0_  # 新しいプロンプトを使用するためコメントアウト

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


# -------------------------------------
# その他
# -------------------------------------

# cdしたあとで、自動的に ls する
function chpwd() { 
  ls -a1
  # Git Worktree関数がロードされている場合のみ実行
  if typeset -f __git_worktree_chpwd > /dev/null; then
    __git_worktree_chpwd
  fi
}

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


export VOLTA_HOME="$HOME/.volta"
export PATH="$VOLTA_HOME/bin:$PATH"

# [ -f ~/.inshellisense/key-bindings.zsh ] && source ~/.inshellisense/key-bindings.zsh



# Powerlevel10k theme
source /opt/homebrew/share/powerlevel10k/powerlevel10k.zsh-theme

# gitでbranchを grep して削除
gb-d() {
  if [ -z "$1" ]; then
    echo "Usage: gbd <pattern>"
    return 1
  fi
  git branch | grep "$1" | xargs git branch -D
}


. "$HOME/.local/bin/env"

# AWS関連の関数を遅延読み込み
autoload -Uz aws_functions
function aws_functions() {
  if [ -f "$HOME/dotfiles/functions/aws_functions.sh" ]; then
    source "$HOME/dotfiles/functions/aws_functions.sh"
  fi
}

# Git Worktree関連の関数を遅延読み込み
autoload -Uz git_worktree_functions
function git_worktree_functions() {
  if [ -f "$HOME/dotfiles/functions/git_worktree.sh" ]; then
    source "$HOME/dotfiles/functions/git_worktree.sh"
  fi
}

readonly COLOR_SUCCESS='\033[0;32m'
readonly COLOR_WARNING='\033[0;33m'
readonly COLOR_ERROR='\033[0;31m'
readonly COLOR_INFO='\033[0;34m'
readonly COLOR_RESET='\033[0m'

# To customize prompt, run `p10k configure` or edit ~/.p10k.zsh.
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
