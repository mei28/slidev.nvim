# slidev.nvim

Neovim plugin for [Slidev](https://sli.dev/) - a presentation slides tool for developers.

このプラグインにより、NeovimからSlidevのCLI機能を直接利用できます。VSCodeなど別のエディタに切り替えることなく、Neovimでプレゼンテーション開発を完結できます。

## Features

- 開発サーバーの起動とライブプレビュー
- 複数形式でのエクスポート（PDF, PNG, PPTX, Markdown）
- 本番用ビルド（SPA）
- マークダウンフォーマット
- バッファクローズ時の自動クリーンアップ
- クロスプラットフォーム対応（macOS, Linux, Windows）

## Requirements

- Neovim 0.7+
- Node.js と npm（Slidev CLIのインストールに必要）
- Slidev CLI（推奨：グローバルインストール）

### Slidev CLIのインストール

```bash
# グローバルインストール（推奨）
npm install -g @slidev/cli

# または各プロジェクトでローカルインストール
npm install -D @slidev/cli

# npxで自動実行も可能（インストール不要）
```

プラグインは以下の優先順位でSlidev CLIを検出します：
1. 設定で指定されたコマンド
2. グローバルインストール（PATH から検出）
3. ローカルインストール（`node_modules/.bin/slidev`）
4. npx で自動実行（`@slidev/cli@latest`）

## Installation

### lazy.nvim

```lua
{
  'mei/slidev.nvim',
  config = function()
    require('slidev').setup({
      -- オプション設定（デフォルト値）
      port = 3030,
      auto_open_browser = true,
      debug = false,
    })
  end,
}
```

### packer.nvim

```lua
use {
  'mei/slidev.nvim',
  config = function()
    require('slidev').setup()
  end
}
```

### vim-plug

```vim
Plug 'mei/slidev.nvim'

lua << EOF
require('slidev').setup()
EOF
```

## Usage

### Commands

| コマンド | 説明 |
|---------|------|
| `:SlidevPreview` | 開発サーバーを起動してブラウザでプレビュー |
| `:SlidevWatch` | `SlidevPreview` のエイリアス |
| `:SlidevStop` | 現在のバッファのサーバーを停止 |
| `:SlidevStopAll` | すべてのサーバーを停止 |
| `:SlidevExport [format]` | エクスポート（デフォルト: pdf） |
| `:SlidevBuild` | 本番用にビルド |
| `:SlidevFormat` | マークダウンをフォーマット |
| `:SlidevStatus` | サーバーの状態を確認 |

### Basic Workflow

1. Slidevマークダウンファイルを開く：
   ```vim
   :e slides.md
   ```

2. プレビューを開始：
   ```vim
   :SlidevPreview
   ```

3. 編集しながらライブリロードで確認

4. エクスポート：
   ```vim
   :SlidevExport pdf
   ```

### Configuration

```lua
require('slidev').setup({
  -- Slidev CLIコマンドのパス（nilの場合は自動検出）
  slidev_command = nil,

  -- 開発サーバーのデフォルトポート
  port = 3030,

  -- ブラウザ自動起動の有効化
  auto_open_browser = true,

  -- 使用するブラウザ（nilの場合はシステムデフォルト）
  browser = nil,

  -- デバッグログの出力
  debug = false,

  -- リモートアクセスの設定
  remote = nil,  -- nilまたはパスワード文字列

  -- テーマの指定
  theme = nil,
})
```

### Lua API

```lua
local slidev = require('slidev')

-- プレビュー
slidev.preview()

-- カスタムポートでプレビュー
slidev.preview({ port = 8080 })

-- サーバー停止
slidev.stop()

-- すべてのサーバー停止
slidev.stop_all()

-- エクスポート
slidev.export('pdf')
slidev.export('png', { dark = true, range = '1-5' })

-- ビルド
slidev.build()
slidev.build({ out = 'build', download = true })

-- フォーマット
slidev.format()

-- サーバーの状態確認
if slidev.is_running() then
  print('Server is running')
end
```

## How It Works

slidev.nvimは、marp.nvimのアーキテクチャを参考に以下のアプローチで実装されています：

1. **CLI検出**: ローカルの `node_modules/.bin/slidev` を優先し、なければ `npx slidev@latest` にフォールバック
2. **プロセス管理**: `vim.fn.jobstart()` でSlidev CLIプロセスを起動
3. **自動クリーンアップ**: バッファクローズ時に自動的にサーバーを停止
4. **ブラウザ統合**: クロスプラットフォーム対応のブラウザ起動

## Comparison with marp.nvim

slidev.nvimは、marp.nvimと同様のコンセプトで、Slidevに特化した機能を提供します：

**共通点:**
- ライブプレビュー機能
- エクスポート機能
- バッファクローズ時の自動クリーンアップ

**slidev.nvim固有の機能:**
- Vueコンポーネントのサポート
- アニメーション・トランジション
- スライドノート機能
- リモートプレゼンテーション（`--remote`）
- より豊富なエクスポート形式（PPTX含む）

## Troubleshooting

### サーバーが起動しない

1. Slidev CLIがインストールされているか確認：
   ```bash
   npx slidev@latest --version
   ```

2. デバッグモードを有効化：
   ```lua
   require('slidev').setup({ debug = true })
   ```

3. Neovimのメッセージを確認：
   ```vim
   :messages
   ```

### ポートが既に使用されている

別のポート番号を指定：
```vim
:lua require('slidev').preview({ port = 8080 })
```

または設定でデフォルトポートを変更：
```lua
require('slidev').setup({ port = 8080 })
```

## Contributing

Issue報告やPull Requestを歓迎します。

## License

MIT

## Acknowledgments

このプラグインは、[marp.nvim](https://github.com/nwiizo/marp.nvim) を参考に実装されました。
