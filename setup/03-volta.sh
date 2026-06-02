#!/bin/bash
# Volta (Node.js version manager) installation and global tools setup

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/common.sh"

run_setup "Volta セットアップ"

VOLTA_INSTALLED=false

# Check if Volta is already installed
if command_exists volta; then
    log_success "Volta は既にインストール済みです"
    volta --version
    VOLTA_INSTALLED=true
else
    # Install Volta
    log_info "Volta をインストール中..."
    if curl https://get.volta.sh | bash; then
        log_success "Volta をインストールしました"
    else
        log_error "Volta のインストールに失敗しました"
        exit 1
    fi

    # Set up PATH for Volta
    export VOLTA_HOME="$HOME/.volta"
    export PATH="$VOLTA_HOME/bin:$PATH"

    # Verify installation
    if command_exists volta; then
        log_success "Volta をセットアップしました"
        volta --version
        VOLTA_INSTALLED=true
    else
        log_warning "Volta は PATH に認識されていません。シェルをリロードしてください"
        exit 1
    fi
fi

# Install Node.js (use LTS version)
# Note: Volta requires explicit version numbers, not "latest"
NODE_VERSION="22.18.0"
log_info "Node.js v${NODE_VERSION} をインストール中..."
if volta install "node@${NODE_VERSION}"; then
    log_success "Node.js をインストールしました"
    node --version
    npm --version
else
    log_error "Node.js のインストールに失敗しました"
    exit 1
fi

# Install global CLI tools
log_info "グローバルツールをインストール中..."

GLOBAL_TOOLS=(
    "claude-cli"
    "codex"
    "@anthropic-ai/sdk"
)

for tool in "${GLOBAL_TOOLS[@]}"; do
    log_info "$tool をインストール中..."
    if npm install -g "$tool"; then
        log_success "$tool をインストールしました"
    else
        log_warning "$tool のインストールに失敗しました（スキップ）"
    fi
done

log_success "Volta セットアップとグローバルツール インストールが完了しました"
log_info "インストール済みグローバルツール:"
npm list -g --depth=0 | grep -E "claude|codex|anthropic" || true
