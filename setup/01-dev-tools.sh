#!/bin/bash
# Development tools installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

run_setup "開発ツール インストール"

# Ensure Homebrew is installed
if ! command_exists brew; then
    log_error "Homebrew がインストールされていません。先に 00-homebrew.sh を実行してください"
    exit 1
fi

# Essential development tools
DEV_TOOLS=(
    git
    tree
    neovim
    tmux
    tig
    awscli
    peco
    gh
    bat
    git-secret
    lazygit
    jq
    fd
    tree-sitter
    ripgrep
    stow
)

log_info "開発ツールをインストール中..."
for tool in "${DEV_TOOLS[@]}"; do
    brew_install "$tool" || true
done

# Additional tools for macOS
log_info "macOS 用追加ツールをインストール中..."
brew_install "gnu-sed" || true
brew_install "gnu-tar" || true

# Claude Code desktop app
log_info "Claude Code をインストール中..."
brew_cask_install "claude-code" || true

log_success "開発ツールのインストールが完了しました"
