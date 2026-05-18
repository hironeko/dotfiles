#!/bin/bash
# dotfiles インストールスクリプト
# 新規セットアップ時に実行

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 dotfiles をセットアップ開始"
echo "=========================================="
echo ""

# 1. Stow セットアップ
echo "📦 ステップ 1: GNU Stow によるシンボリックリンク設定"
if [ -f "$DOTFILES_DIR/stow-setup.sh" ]; then
    bash "$DOTFILES_DIR/stow-setup.sh"
else
    echo "❌ stow-setup.sh が見つかりません"
    exit 1
fi

echo ""
echo "=========================================="
echo "📱 ステップ 2: Claude Code desktop app をインストール"

# 2. Claude Code desktop app をインストール
if command -v brew &> /dev/null; then
    if brew list --cask claude-code &> /dev/null; then
        echo "✅ Claude Code は既にインストール済みです"
    else
        echo "🔽 Claude Code desktop app をインストール中..."
        if brew install --cask claude-code; then
            echo "✅ Claude Code をインストールしました"
        else
            echo "⚠️  Claude Code のインストールに失敗しました（スキップ可能）"
        fi
    fi
else
    echo "⚠️  Homebrew がインストールされていません"
    echo "   手動で Claude Code をインストールしてください:"
    echo "   brew install --cask claude-code"
fi

echo ""
echo "=========================================="
echo "✅ セットアップが完了しました！"
echo ""
echo "📝 次のステップ:"
echo "  1. シェルをリロード: source ~/.zshrc"
echo "  2. Claude Code アプリを起動: claude code"
echo "  3. または Claude Code desktop app を起動"
echo ""
echo "🔗 リセット方法:"
echo "  ./stow-reset.sh"
