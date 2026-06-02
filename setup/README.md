# Setup Scripts for macOS Dotfiles

このディレクトリには、macOS 環境の自動セットアップスクリプトが含まれています。

## 🚀 クイックスタート

### 新規マシンでの完全セットアップ

```bash
cd ~/dotfiles
bash setup/setup.sh
```

これにより以下がインストール・設定されます：
1. ✅ Homebrew
2. ✅ 開発ツール (neovim, tmux, git, awscli など)
3. ✅ Nerd Fonts (Hack, FiraCode, MesloLG)
4. ✅ Volta (Node.js バージョン管理)
5. ✅ anyenv (Python/Ruby/PHP などのバージョン管理)
6. ✅ dotfiles リンク設定 (GNU Stow)
7. ✅ Claude Code desktop app

### 既存環境への dotfiles 適用

```bash
bash stow-setup.sh
```

## 📦 スクリプト構成

| ファイル | 説明 |
|---------|------|
| `setup.sh` | マスタースクリプト（全て制御）|
| `common.sh` | 共通関数（ロギング、インストール関数）|
| `00-homebrew.sh` | Homebrew インストール・アップデート |
| `01-dev-tools.sh` | 開発ツール一括インストール |
| `02-fonts.sh` | Nerd Fonts インストール |
| `03-volta.sh` | Volta (Node.js) セットアップ |
| `04-anyenv.sh` | anyenv (マルチ言語) セットアップ |

## 🎯 各スクリプトの単独実行

各スクリプトは独立して実行可能です：

```bash
# Homebrew のみセットアップ
bash setup/00-homebrew.sh

# 開発ツールをインストール
bash setup/01-dev-tools.sh

# Volta をセットアップ
bash setup/03-volta.sh

# anyenv をセットアップ
bash setup/04-anyenv.sh
```

## ⚙️ オプション

`setup.sh` はスキップオプションをサポート：

```bash
# Homebrew セットアップをスキップ
bash setup/setup.sh --skip-homebrew

# 複数スキップ
bash setup/setup.sh --skip-fonts --skip-volta

# 使用可能なオプション
bash setup/setup.sh --help
```

## 📋 インストール対象

### Homebrew パッケージ
- **VCS**: git, gh (GitHub CLI), git-secret, tig, lazygit
- **Editors**: neovim, vim
- **Terminal**: tmux, peco, bat, fd, tree, jq
- **Tools**: awscli, ripgrep, tree-sitter, stow
- **Utils**: gnu-sed, gnu-tar

### Nerd Fonts
- Hack Nerd Font
- FiraCode Nerd Font
- MesloLG Nerd Font

### バージョン管理ツール
- **Volta**: Node.js のバージョン管理
- **anyenv**: Python, Ruby, PHP, Go などの統一管理

## 🔧 トラブルシューティング

### Homebrew のインストール失敗
```bash
# 手動でインストール
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

### M1/M2/M3 Mac 特有の問題
Homebrew は `/opt/homebrew` にインストールされ、自動的に PATH が設定されます。

### Volta が認識されない
シェルをリロードしてください：
```bash
source ~/.zshrc
```

### Volta で "latest" エラーが出る
**Volta は `latest` バージョンをサポートしていません。** 具体的なバージョン番号を指定してください：
```bash
# ❌ これは動きません
volta install node@latest

# ✅ こう指定します
volta install node@22.18.0

# package.json の volta セクションも具体的なバージョンが必須
# "volta": { "node": "22.18.0", "npm": "10.9.3" }
```

### anyenv 言語環境が必要な場合
```bash
# 使用可能な環境を確認
anyenv envs

# Python をインストール
anyenv install pyenv
pyenv install 3.12.0

# Ruby をインストール
anyenv install rbenv
rbenv install 3.3.0
```

## 🔄 何度でも実行可能

すべてのスクリプトは冪等性を持つため、何度実行しても安全です：
- 既にインストール済みのツールはスキップ
- 依存関係を自動チェック
- エラー時は明確なメッセージを表示

## 📝 使用例

### シナリオ1: 新規 M3 Mac のセットアップ
```bash
git clone https://github.com/hironeko/dotfiles.git
cd dotfiles
bash setup/setup.sh
```

### シナリオ2: 既存環境に dotfiles だけ追加
```bash
cd ~/dotfiles
bash stow-setup.sh
```

### シナリオ3: Volta と anyenv なしでセットアップ
```bash
bash setup/setup.sh --skip-volta --skip-anyenv
```

## 🤝 カスタマイズ

各スクリプトは sh で記述されており、簡単にカスタマイズできます：

- `common.sh` の関数を利用して新しいセットアップスクリプトを追加
- `setup.sh` に新しいステップを追加
- 不要なツールは `01-dev-tools.sh` の `DEV_TOOLS` 配列から削除

## 📄 ログ出力

スクリプトは以下の色分けされたメッセージを出力します：
- 🔵 **INFO** (blue): 情報メッセージ
- ✅ **SUCCESS** (green): 成功メッセージ
- ⚠️  **WARNING** (yellow): 警告メッセージ
- ❌ **ERROR** (red): エラーメッセージ
