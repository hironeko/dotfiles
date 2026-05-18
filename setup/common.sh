#!/bin/bash
# Common functions for setup scripts

set -o pipefail

# Color codes
readonly COLOR_SUCCESS='\033[0;32m'
readonly COLOR_WARNING='\033[0;33m'
readonly COLOR_ERROR='\033[0;31m'
readonly COLOR_INFO='\033[0;34m'
readonly COLOR_RESET='\033[0m'

# Logging functions
log_info() {
    echo -e "${COLOR_INFO}ℹ️  $*${COLOR_RESET}"
}

log_success() {
    echo -e "${COLOR_SUCCESS}✅ $*${COLOR_RESET}"
}

log_warning() {
    echo -e "${COLOR_WARNING}⚠️  $*${COLOR_RESET}"
}

log_error() {
    echo -e "${COLOR_ERROR}❌ $*${COLOR_RESET}" >&2
}

# Section headers
print_header() {
    echo ""
    echo "=========================================="
    echo "📦 $*"
    echo "=========================================="
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Check if brew package is installed
brew_installed() {
    brew list "$1" &> /dev/null 2>&1
}

# Install brew package
brew_install() {
    local package=$1

    if brew_installed "$package"; then
        log_warning "$package は既にインストール済みです"
        return 0
    fi

    log_info "$package をインストール中..."
    if brew install "$package"; then
        log_success "$package をインストールしました"
        return 0
    else
        log_error "$package のインストールに失敗しました"
        return 1
    fi
}

# Install brew cask
brew_cask_install() {
    local cask=$1

    if brew list --cask "$cask" &> /dev/null 2>&1; then
        log_warning "$cask は既にインストール済みです"
        return 0
    fi

    log_info "$cask をインストール中..."
    if brew install --cask "$cask"; then
        log_success "$cask をインストールしました"
        return 0
    else
        log_error "$cask のインストールに失敗しました"
        return 1
    fi
}

# Check if running on macOS
is_macos() {
    [[ "$OSTYPE" == "darwin"* ]]
}

# Main function wrapper with error handling
run_setup() {
    local setup_name=$1

    if ! is_macos; then
        log_error "このスクリプトは macOS でのみ動作します"
        exit 1
    fi

    print_header "$setup_name"
}

# Cleanup on error
trap 'log_error "エラーが発生しました"; exit 1' ERR
