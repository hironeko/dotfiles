#!/bin/bash
# anyenv (multi-language version manager) installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

run_setup "anyenv セットアップ"

# Ensure Homebrew is installed
if ! command_exists brew; then
    log_error "Homebrew がインストールされていません。先に 00-homebrew.sh を実行してください"
    exit 1
fi

# Install anyenv
if command_exists anyenv; then
    log_success "anyenv は既にインストール済みです"
    anyenv versions
else
    log_info "anyenv をインストール中..."
    brew_install "anyenv" || exit 1
fi

# Initialize anyenv
if [ ! -d "$HOME/.anyenv/bin" ]; then
    log_info "anyenv を初期化中..."
    anyenv init || true
fi

# Add anyenv to PATH
export PATH="$HOME/.anyenv/bin:$PATH"
eval "$(anyenv init -)" 2>/dev/null || true

log_success "anyenv セットアップが完了しました"
log_info "使用可能な環境マネージャー:"
anyenv envs

log_warning "任意の言語環境が必要な場合は、以下のコマンドでインストールしてください:"
echo "  anyenv install rbenv      # Ruby"
echo "  anyenv install pyenv      # Python"
echo "  anyenv install phpenv     # PHP"
echo "  anyenv install goenv      # Go"
