#!/bin/bash
# Homebrew installation and basic package setup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

run_setup "Homebrew セットアップ"

# Check if Homebrew is already installed
if command_exists brew; then
    log_success "Homebrew は既にインストール済みです"
    log_info "Homebrew をアップデート中..."
    brew update
    brew upgrade
    log_success "Homebrew をアップデートしました"
    exit 0
fi

# Install Homebrew
log_info "Homebrew をインストール中..."
if /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"; then
    log_success "Homebrew をインストールしました"
else
    log_error "Homebrew のインストールに失敗しました"
    exit 1
fi

# M1/M2/M3 Macs での PATH 設定
if [[ -f /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
    log_info "Apple Silicon (M1/M2/M3) 用の PATH を設定しました"
fi

# Update Homebrew
log_info "Homebrew をアップデート中..."
brew update
brew upgrade

log_success "Homebrew セットアップが完了しました"
