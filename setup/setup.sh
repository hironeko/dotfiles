#!/bin/bash
# Master setup script for dotfiles

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

# Parse arguments
SKIP_HOMEBREW=false
SKIP_FONTS=false
SKIP_VOLTA=false
SKIP_ANYENV=false

while [[ $# -gt 0 ]]; do
    case $1 in
        --skip-homebrew)
            SKIP_HOMEBREW=true
            shift
            ;;
        --skip-fonts)
            SKIP_FONTS=true
            shift
            ;;
        --skip-volta)
            SKIP_VOLTA=true
            shift
            ;;
        --skip-anyenv)
            SKIP_ANYENV=true
            shift
            ;;
        --help)
            echo "Usage: $0 [OPTIONS]"
            echo ""
            echo "Options:"
            echo "  --skip-homebrew   Skip Homebrew setup"
            echo "  --skip-fonts      Skip Nerd Fonts installation"
            echo "  --skip-volta      Skip Volta setup"
            echo "  --skip-anyenv     Skip anyenv setup"
            echo "  --help           Show this help message"
            exit 0
            ;;
        *)
            log_error "Unknown option: $1"
            exit 1
            ;;
    esac
done

print_header "macOS dotfiles 完全セットアップ"

echo ""
log_info "セットアップ内容:"
echo "  1. Homebrew インストール"
echo "  2. 開発ツール インストール"
echo "  3. Nerd Fonts インストール"
echo "  4. Volta (Node.js) セットアップ"
echo "  5. anyenv (マルチ言語) セットアップ"
echo "  6. Herdr インストール"
echo "  7. dotfiles リンク設定 (GNU Stow)"
echo "  8. Claude Code desktop app インストール"
echo ""

# Step 1: Homebrew
if [ "$SKIP_HOMEBREW" = false ]; then
    bash "$SCRIPT_DIR/00-homebrew.sh" || exit 1
else
    log_warning "Homebrew セットアップをスキップしました"
fi

# Step 2: Development tools
bash "$SCRIPT_DIR/01-dev-tools.sh" || exit 1

# Step 3: Fonts
if [ "$SKIP_FONTS" = false ]; then
    bash "$SCRIPT_DIR/02-fonts.sh" || exit 1
else
    log_warning "Nerd Fonts インストールをスキップしました"
fi

# Step 4: Volta
if [ "$SKIP_VOLTA" = false ]; then
    bash "$SCRIPT_DIR/03-volta.sh" || exit 1
else
    log_warning "Volta セットアップをスキップしました"
fi

# Step 5: anyenv
if [ "$SKIP_ANYENV" = false ]; then
    bash "$SCRIPT_DIR/04-anyenv.sh" || exit 1
else
    log_warning "anyenv セットアップをスキップしました"
fi

# Step 6: Herdr
bash "$SCRIPT_DIR/05-herdr.sh" || exit 1

# Step 7: Stow dotfiles
print_header "GNU Stow によるシンボリックリンク設定"
if [ -f "$SCRIPT_DIR/stow-setup.sh" ]; then
    bash "$SCRIPT_DIR/stow-setup.sh" || exit 1
else
    log_error "stow-setup.sh が見つかりません"
    exit 1
fi

# Final summary
echo ""
print_header "セットアップ完了！"
echo ""
log_success "すべてのセットアップが完了しました"
echo ""
log_info "次のステップ:"
echo "  1. シェルをリロード:"
echo "     source ~/.zshrc"
echo ""
echo "  2. Claude Code デスクトップアプリを起動:"
echo "     claude code  (CLI)"
echo "     または Spotlight 検索で 'Claude Code' を起動"
echo ""
echo "  3. Python などが必要な場合:"
echo "     anyenv install pyenv"
echo "     pyenv install 3.12.0"
echo ""
echo "📝 セットアップをやり直す場合:"
echo "  ./setup.sh --skip-fonts --skip-volta"
echo ""
