#!/bin/bash
# Teardown script - reverse of setup.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"

# shellcheck source=/dev/null
source "$SCRIPT_DIR/common.sh"

print_header "macOS dotfiles Teardown"

echo ""
log_warning "⚠️  警告: このスクリプトは以下を削除します:"
echo "  1. GNU Stow によるシンボリックリンク"
echo "  2. Herdr"
echo "  3. anyenv とインストールした言語環境"
echo "  4. Volta"
echo "  5. Homebrew パッケージ (neovim, tmux, stow など)"
echo "  6. Nerd Fonts"
echo ""
read -p "続行しますか? (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    log_info "キャンセルしました"
    exit 0
fi

# Step 1: Unlink stow packages
print_header "GNU Stow シンボリックリンク削除"
if [ -f "$SCRIPT_DIR/stow-reset.sh" ]; then
    bash "$SCRIPT_DIR/stow-reset.sh" || log_warning "stow-reset.sh 実行に失敗"
else
    log_warning "stow-reset.sh が見つかりません"
fi

# Step 2: Remove Herdr
print_header "Herdr 削除"
if command -v herdr &> /dev/null; then
    log_info "Herdr をアンインストール中..."
    rm -rf ~/.local/bin/herdr ~/.config/herdr
    log_success "Herdr を削除しました"
else
    log_warning "Herdr はインストールされていません"
fi

# Step 3: Remove anyenv
print_header "anyenv 削除"
if [ -d "$HOME/.anyenv" ]; then
    log_info "anyenv をアンインストール中..."
    rm -rf "$HOME/.anyenv"
    log_success "anyenv を削除しました"
else
    log_warning "anyenv はインストールされていません"
fi

# Step 4: Remove Volta
print_header "Volta 削除"
if [ -d "$HOME/.volta" ]; then
    log_info "Volta をアンインストール中..."
    rm -rf "$HOME/.volta"
    log_success "Volta を削除しました"
else
    log_warning "Volta はインストールされていません"
fi

# Step 5: Remove Nerd Fonts
print_header "Nerd Fonts 削除"
if brew list --cask | grep -q "font-hack-nerd-font\|font-fira-code-nerd-font\|font-meslo-lg-nerd-font"; then
    log_info "Nerd Fonts をアンインストール中..."
    brew uninstall --cask font-hack-nerd-font font-fira-code-nerd-font font-meslo-lg-nerd-font 2>/dev/null || true
    log_success "Nerd Fonts を削除しました"
else
    log_warning "Nerd Fonts はインストールされていません"
fi

# Step 6: Remove dev tools
print_header "開発ツール削除"
log_info "Homebrew パッケージをアンインストール中..."
brew uninstall neovim tmux stow peco lazygit tig ghq fzf ripgrep fd bat exa tree-sitter 2>/dev/null || true
log_success "開発ツールを削除しました"

# Step 7: Clean up caches
print_header "キャッシュ削除"
log_info "Neovim キャッシュを削除中..."
rm -rf ~/.local/share/nvim ~/.local/state/nvim ~/.cache/nvim
log_success "キャッシュを削除しました"

# Final summary
echo ""
print_header "Teardown 完了！"
echo ""
log_success "アンインストールが完了しました"
echo ""
log_info "残っているもの:"
echo "  - Homebrew 本体 (brew uninstall で削除可能)"
echo "  - dotfiles リポジトリ (~/dotfiles)"
echo "  - バックアップファイル (~/.zshrc.backup.* など)"
echo ""
log_info "完全に削除する場合:"
echo "  rm -rf ~/dotfiles"
echo "  /bin/bash -c \"\$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/uninstall.sh)\""
echo ""
