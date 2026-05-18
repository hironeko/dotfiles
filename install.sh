#!/bin/bash
# dotfiles インストールスクリプト（簡易版）
# 完全なセットアップは setup/setup.sh を使用してください

set -e

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "🚀 dotfiles セットアップスクリプト"
echo "=========================================="
echo ""
echo "このスクリプトは以下の2つのセットアップを提供します:"
echo ""
echo "1. 完全セットアップ（推奨・新規マシン向け）"
echo "   Homebrew, 開発ツール, Nerd Fonts, Volta, anyenv, dotfiles をインストール"
echo "   実行: bash setup/setup.sh"
echo ""
echo "2. dotfiles のみリンク（既存環境向け）"
echo "   dotfiles 構成を既存のマシンに適用"
echo "   実行: bash stow-setup.sh"
echo ""
echo "どちらを実行しますか？"
echo "  [1] 完全セットアップを実行 (setup/setup.sh)"
echo "  [2] dotfiles のみリンク (stow-setup.sh)"
echo "  [3] キャンセル"
echo ""
read -p "選択 (1/2/3): " choice

case $choice in
    1)
        echo ""
        exec bash "$DOTFILES_DIR/setup/setup.sh" "$@"
        ;;
    2)
        echo ""
        exec bash "$DOTFILES_DIR/setup/stow-setup.sh"
        ;;
    3)
        echo "キャンセルしました"
        exit 0
        ;;
    *)
        echo "❌ 無効な選択です"
        exit 1
        ;;
esac
