# -------------------------------------
# zpreztoの設定を読み込む
# bashに記載ある環境変数を使用する
# -------------------------------------

if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Ensure that a non-login, non-interactive shell has a defined environment.
if [[ "$SHLVL" -eq 1 && ! -o LOGIN && -s "${ZDOTDIR:-$HOME}/.zprofile" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprofile"
fi

# path
eval "$(rbenv init -)"
export PATH="/usr/local/sbin:$PATH"
[[ -s "$HOME/.gvm/scripts/gvm" ]] && source "$HOME/.gvm/scripts/gvm"
export PATH="$HOME/.cargo/bin:$PATH"
export PATH="$PATH:$HOME/.composer/vendor/bin"
PATH="$HOME/.cask/bin:$PATH"
export PYENV_ROOT="/usr/local/var/pyenv"
if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi
export NVM_DIR=$HOME/.nvm
source $(brew --prefix nvm)/nvm.sh


# -------------------------------------
# 環境変数
# -------------------------------------

# SSHで接続した先で日本語が使えるようにする
export LC_CTYPE=en_US.UTF-8
export LC_ALL=en_US.UTF-8

# エディタ
export EDITOR=/usr/local/bin/vim
export VISUAL=/usr/local/bin/vim
# ページャ
#export PAGER=/usr/local/bin/vimpager
#export MANPAGER=/usr/local/bin/vimpager


# -------------------------------------
# zshのオプション
# -------------------------------------

## 補完機能の強化
autoload -U compinit
compinit

## 入力しているコマンド名が間違っている場合にもしかして：を出す。
setopt correct

# ビープを鳴らさない
setopt nobeep

## 色を使う
setopt prompt_subst

## ^Dでログアウトしない。
setopt ignoreeof

## バックグラウンドジョブが終了したらすぐに知らせる。
setopt no_tify

# 補完
## タブによるファイルの順番切り替えをしない
unsetopt auto_menu

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
    zstyle ":vcs_info:git:*" stagedstr "%F{yellow}<Stage>"
    zstyle ":vcs_info:git:*" unstagedstr "%F{magenta}<Unstage>"
    zstyle ":vcs_info:git:*" formats "%F{cyan}(%b) %c%u%f"
    zstyle ":vcs_info:git:*" actionformats "(%s)-[%b|%a] %c%u"
fi

precmd(){ vcs_info }

function vcs_prompt_info() {
    psvar=()
    LANG=en_US.UTF-8 vcs_info
    [[ -n "$vcs_info_msg_0_" ]] && echo -n " %{$fg[yellow]%}$vcs_info_msg_0_%f"
    #[[ -n "$vcs_info_msg_0_" ]] && psvar[1]="$vcs_info_msg_0_"
}
# end VCS

#PROMPT+="%(?.%F{green}$OK%f.%F{red}$NG%f) "
#PROMPT+="%F{blue}%~%f\$(vcs_prompt_info)"
#PROMPT+="%% "
#RPROMPT="[%*]"

RPROMPT=\$vcs_info_msg_0_

# -------------------------------------
# エイリアス
# -------------------------------------

# -n 行数表示, -I バイナリファイル無視, svn関係のファイルを無視
#alias grep="grep --color -n -I --exclude='*.svn-*' --exclude='entries' --exclude='*/cache/*'"

# ls
#alias ls="ls -G" # color for darwin
alias l="ls -la"
#alias la="ls -la"
#alias l1="ls -1"

# tree
#alias tree="tree -NC" # N: 文字化け対策, C:色をつける

# open mac only
alias op='open -a'
alias ops="open -a 'sublime text'"
alias opv="open -a 'visual studio code'"
# Git command
alias gs="git status"
alias gd="git diff"
# Rails command
alias be="bundle exec"
# emacs command
alias ei="emacs -nw"
# tmux
alias ts='tmux new -s'
alias tks='tmux kill-session'
alias tl='tmux ls'
alias ta='tmux a'
# exa command
alias le="exa -l" # file view
alias leg="exa -l --git" #git state view 
alias et="exa -T" #Tree view 
#docker-compose
alias dc="docker-compose"

# 2つ上、3つ上にも移動できるようにする
alias ...='cd ../..'
#alias ....='cd ../../..'

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

### リンゴマーク出すための関数
# function toon {
#   echo -n ""
# }

# histroy
#ヒストリーサイズ設定
# history size setting
HISTFILE=$HOME/.zsh_history
HISTSIZE=1000000
SAVEHIST=1000000
# 直前のコマンドは追加しない
setopt hist_ignore_dups
# コマンド履歴の呼び出し
autoload -Uz history-search-end
# other tab history saher
setopt share_history
##

#if (which zprof > /dev/null 2>&1) ;then
#  zprof
#fi
