# Neovim Configuration

VSCodeライクな使い心地を実現したNeovim設定です。

## 特徴

- **プラグインマネージャー**: lazy.nvim
- **ファイルエクスプローラー**: nvim-tree (VSCodeのサイドバー的な)
- **ファジーファインダー**: telescope (Cmd+P的な)
- **LSP**: mason + nvim-lspconfig (自動補完、定義ジャンプ、エラー表示など)
- **補完**: nvim-cmp (IntelliSense的な)
- **シンタックスハイライト**: treesitter
- **Git統合**: gitsigns
- **UI改善**: lualine, bufferline, indent-blankline
- **その他**: autopairs, comment, formatting

## インストール

### 1. Neovimのインストール

```bash
# Homebrew (macOS)
brew install neovim

# またはバージョン0.9.0以上を使用
nvim --version
```

### 2. 設定のシンボリックリンクを作成

```bash
# ~/.config/nvim へシンボリックリンクを作成
ln -sf ~/dotfiles/nvim ~/.config/nvim
```

### 3. Neovimを起動

初回起動時に自動的にlazy.nvimとプラグインがインストールされます：

```bash
nvim
```

プラグインのインストールが完了するまで待ちます。エラーが出た場合は`:Lazy sync`を実行してください。

### 4. LSPサーバーのインストール

`:Mason`を実行してLSPサーバー、フォーマッター、リンターをインストールします。

または、設定に含まれているサーバーは自動的にインストールされます。

## 主要なキーバインド

### 基本操作

- `Space` - リーダーキー
- `jk` - Escapeキー (Insertモードから抜ける)
- `Ctrl+s` - ファイル保存（VSCode風）
- `<leader>w` - ファイル保存
- `<leader>q` - 終了
- `Ctrl+q` - バッファを閉じる（VSCode風）
- `<leader>x` - バッファを閉じる

### ファイルエクスプローラー (nvim-tree)

- `<leader>e` - ファイルツリーのトグル
- `<leader>ef` - 現在のファイルでツリーを開く

**ツリー内での操作:**
- `Enter` または `o` - ファイルを開く（ツリーは維持）
- `s` - 垂直分割で開く
- `i` - 水平分割で開く
- `t` - 新しいタブで開く
- `a` - 新規ファイル/ディレクトリ作成
- `d` - 削除
- `r` - リネーム
- `?` - ヘルプ表示

### ファジーファインダー (Telescope)

- `Ctrl+p` - ファイル検索（VSCode風、**超便利！**）
- `Ctrl+f` - テキスト検索（VSCode風、全文検索）
- `<leader>ff` - ファイル検索
- `<leader>fg` - テキスト検索 (grep)
- `<leader>fb` - バッファ検索
- `<leader>fr` - 最近開いたファイル

**検索の特徴:**
- 大文字小文字を区別しない（smart-case）
- 隠しファイルも検索
- サブディレクトリも自動検索
- `.git/`ディレクトリは除外

### LSP機能

- `gd` - 定義へジャンプ
- `gD` - 宣言へジャンプ
- `gR` - 参照を表示
- `gi` - 実装へジャンプ
- `K` - ホバー情報を表示
- `<leader>ca` - コードアクション
- `<leader>rn` - リネーム
- `[d` - 前の診断へ
- `]d` - 次の診断へ

### ウィンドウ管理

- `<C-h>` - 左のウィンドウへ
- `<C-l>` - 右のウィンドウへ
- `<C-j>` - 下のウィンドウへ
- `<C-k>` - 上のウィンドウへ
- `<leader>sv` - 垂直分割
- `<leader>sh` - 水平分割
- `<leader>sx` - 分割を閉じる
- `<leader>se` - 分割サイズを均等に
- `<C-Up/Down/Left/Right>` - ウィンドウサイズ変更

### バッファ管理

- `<S-l>` - 次のバッファ
- `<S-h>` - 前のバッファ
- `<leader>x` - バッファを閉じる（短縮版）
- `<leader>bd` - バッファを閉じる
- `<leader>bx` - バッファを強制的に閉じる

### Git

- `]c` - 次の変更へ
- `[c` - 前の変更へ
- `<leader>hs` - 変更をステージ
- `<leader>hr` - 変更をリセット
- `<leader>hp` - 変更をプレビュー

### コメント

- `gcc` - 行コメントのトグル
- `gc` (ビジュアルモード) - 選択範囲のコメントトグル

### フォーマット

- `<leader>mp` - コードフォーマット

## ディレクトリ構造

```
nvim/
├── init.lua                 # エントリーポイント
├── lua/
│   ├── config/
│   │   ├── options.lua      # 基本設定
│   │   ├── keymaps.lua      # キーマップ
│   │   └── lazy.lua         # lazy.nvim設定
│   └── plugins/
│       ├── colorscheme.lua  # カラースキーム
│       ├── nvim-tree.lua    # ファイルツリー
│       ├── telescope.lua    # ファジーファインダー
│       ├── treesitter.lua   # シンタックスハイライト
│       ├── lsp.lua          # LSP設定
│       ├── mason.lua        # LSPインストーラー
│       ├── nvim-cmp.lua     # 補完
│       ├── lualine.lua      # ステータスライン
│       ├── bufferline.lua   # タブライン
│       ├── gitsigns.lua     # Git統合
│       ├── autopairs.lua    # 自動括弧閉じ
│       ├── comment.lua      # コメント
│       ├── formatting.lua   # フォーマット
│       └── indent-blankline.lua  # インデントガイド
└── README.md
```

## カスタマイズ

各プラグインの設定は`lua/plugins/`ディレクトリ内の対応するファイルで変更できます。

基本設定（行番号、インデント、検索など）は`lua/config/options.lua`で変更できます。

キーバインドは`lua/config/keymaps.lua`と各プラグインファイルで変更できます。

## tmuxとの併用

tmuxのprefixキーは`Ctrl+t`に設定されており、Neovimのキーバインドと競合しません。

**tmux内でNeovimを使う場合:**
- `Ctrl+t` → tmux操作
- `Ctrl+h/j/k/l` → Neovimウィンドウ移動
- `Ctrl+p` → Neovimファイル検索
- `Ctrl+s` → Neovim保存

問題なく併用できます！

## トラブルシューティング

### プラグインがインストールされない

```vim
:Lazy sync
```

### LSPサーバーが動作しない

```vim
:Mason
```

でサーバーを手動インストールしてください。

### エラーが出る

```vim
:checkhealth
```

で問題を診断できます。

## 参考

このNeovim設定は以下の記事を参考にしています：
- [Neovimでコーディングのレベルを落とさないための最低限の設定](https://zenn.dev/forcia_tech/articles/202411_deguchi_neovim)
