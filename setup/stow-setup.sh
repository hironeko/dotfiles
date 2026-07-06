#!/bin/bash
# GNU Stow セットアップスクリプト

set -e

DOTFILES_DIR="$HOME/dotfiles"
PACKAGES=(zsh tmux nvim peco bin functions zed root herdr)

echo "🔗 GNU Stow を使用した dotfiles リンク設定を開始します"
echo "=========================================="

# Stow が インストール済みか確認
if ! command -v stow &> /dev/null; then
    echo "❌ GNU Stow がインストールされていません"
    echo "インストール: brew install stow"
    exit 1
fi

# 既存のシンボリックリンクをバックアップ
echo ""
echo "📦 既存の設定をバックアップ..."
BACKUP_DIR="$HOME/.dotfiles-backup-$(date +%Y%m%d%H%M%S)"
for package in "${PACKAGES[@]}"; do
    case "$package" in
        zsh)
            [ -L "$HOME/.zshrc" ] && mkdir -p "$BACKUP_DIR" && mv "$HOME/.zshrc" "$BACKUP_DIR/" || true
            ;;
        tmux)
            [ -L "$HOME/.tmux.conf" ] && mkdir -p "$BACKUP_DIR" && mv "$HOME/.tmux.conf" "$BACKUP_DIR/" || true
            ;;
        nvim)
            [ -L "$HOME/.config/nvim" ] && mkdir -p "$BACKUP_DIR" && mv "$HOME/.config/nvim" "$BACKUP_DIR/" || true
            ;;
        peco)
            [ -L "$HOME/.config/peco" ] && mkdir -p "$BACKUP_DIR" && mv "$HOME/.config/peco" "$BACKUP_DIR/" || true
            ;;
    esac
done

[ -d "$BACKUP_DIR" ] && echo "✅ バックアップ: $BACKUP_DIR"

# Stow で各パッケージをリンク
echo ""
echo "🔗 dotfiles をリンク中..."
cd "$DOTFILES_DIR"

for package in "${PACKAGES[@]}"; do
    if [ -d "$DOTFILES_DIR/$package" ]; then
        if stow "$package"; then
            echo "✅ $package をリンクしました"
        else
            echo "⚠️  $package のリンクに失敗しました"
        fi
    else
        echo "⏭️  $package は存在しません（スキップ）"
    fi
done

echo ""
echo "=========================================="
echo "✅ セットアップが完了しました！"
echo ""
echo "📝 リセット方法:"
echo "  ./stow-reset.sh"
echo ""
echo "🔗 リンク状態確認:"
echo "  ls -la ~/.zshrc ~/.tmux.conf ~/.config/nvim"
