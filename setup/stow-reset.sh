#!/bin/bash
# GNU Stow リセットスクリプト - すべてのシンボリックリンクを削除

set -e

DOTFILES_DIR="$HOME/dotfiles"
PACKAGES=(zsh tmux nvim peco bin functions docker zed)

echo "🗑️  GNU Stow リンクをアンリンク中..."
echo "=========================================="

# Stow で各パッケージをアンリンク
cd "$DOTFILES_DIR"

for package in "${PACKAGES[@]}"; do
    if [ -d "$DOTFILES_DIR/$package" ]; then
        if stow -D "$package" 2>/dev/null; then
            echo "✅ $package をアンリンクしました"
        else
            echo "⏭️  $package はリンクされていません（スキップ）"
        fi
    fi
done

echo ""
echo "=========================================="
echo "✅ アンリンク完了！"
echo ""
echo "🔗 セットアップ方法:"
echo "  ./stow-setup.sh"
