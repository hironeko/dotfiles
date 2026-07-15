#!/bin/bash
# Nerd Fonts installation

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

run_setup "Nerd Fonts インストール"

# Ensure Homebrew is installed
if ! command_exists brew; then
    log_error "Homebrew がインストールされていません。先に 00-homebrew.sh を実行してください"
    exit 1
fi

FONTS=(
    "font-hack-nerd-font"
    "font-fira-code-nerd-font"
    "font-meslo-lg-nerd-font"
)

log_info "Nerd Fonts をインストール中..."

# homebrew/cask-fonts tap is no longer needed in modern Homebrew
for font in "${FONTS[@]}"; do
    if brew_installed "$font"; then
        log_warning "$font は既にインストール済みです"
    else
        log_info "$font をインストール中..."
        brew install --cask "$font" || true
    fi
done

log_success "Nerd Fonts のインストールが完了しました"
log_info "フォント設定をターミナルで行ってください"
