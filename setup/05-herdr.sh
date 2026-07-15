#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

run_setup "Herdr インストール"

# Check if Herdr is already installed
if command -v herdr &> /dev/null; then
    log_warning "Herdr は既にインストール済みです"
else
    log_info "Herdr をダウンロードしてインストール中..."
    curl -fsSL https://herdr.dev/install.sh | sh

    if command -v herdr &> /dev/null; then
        log_success "Herdr を正常にインストールしました"
    else
        log_error "Herdr のインストールに失敗しました"
        exit 1
    fi
fi

log_success "Herdr のセットアップが完了しました"
