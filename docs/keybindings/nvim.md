# Neovim キーバインド

設定ファイル: [`.config/nvim/lua/config/keymaps.lua`](../../.config/nvim/lua/config/keymaps.lua)

> LazyVim の既定キーマップ (<https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua>) に加え、以下のカスタムを設定しています。
> `<leader>` は Neovim のリーダーキー (デフォルト `<Space>`) です。

## 編集

| キー | モード | 動作 |
| --- | --- | --- |
| `p` / `P` | Normal / Visual | システムクリップボード (`"+`) から貼り付け |
| `Ctrl+a` | Insert | 行頭へ移動 (Emacs 風) |
| `Ctrl+e` | Insert | 行末へ移動 (Emacs 風) |
| `Ctrl+i` | Normal / Insert | デフォルトの `<C-i>` (jump list forward) を維持 |
| `+` | Normal | インクリメント (旧 `<C-a>`) |
| `-` | Normal | デクリメント (旧 `<C-x>`) |
| `#` | Normal | カーソル下の単語を `:%s/word//g` に流し込む |

## ウィンドウ / タブ

| キー | 動作 |
| --- | --- |
| `Tab` | 次のタブ |
| `Shift+Tab` | 前のタブ |
| `ss` | 水平分割 (`:split`) |
| `sv` | 垂直分割 (`:vsplit`) |
| `sh` / `sj` / `sk` / `sl` | 分割ウィンドウ間の移動 (左/下/上/右) |
| `Ctrl+w` + 矢印 | 分割ウィンドウのサイズ変更 |

## 診断 / ターミナル / Lazy 系

| キー | 動作 |
| --- | --- |
| `Ctrl+j` | 次の診断へジャンプ |
| `Ctrl+/` | Snacks ターミナル (Root) |
| `Ctrl+_` | Snacks ターミナル (cwd) |
| `<leader>d` | lazydocker (インストール時のみ有効) |
| `<leader>gg` | LazyGit (cwd) |
| `<leader>gG` | LazyGit (Git プロジェクトルート) |
| `<leader><leader>` | ファイル検索 (Git プロジェクトルート。dotfiles では hidden 有効) |
| `<leader>/` | grep (Git プロジェクトルート。dotfiles では hidden 有効) |
| `<leader>nn` | 通知履歴を表示 |

> ※ `<leader>ft`, `<leader>fT`, `<leader>n` (デフォルトの通知履歴) は無効化済み

## リンク / ブラウザ連携

| キー | 動作 |
| --- | --- |
| `gh` | カーソル下の URL / ファイルを開く |
| `gx` | URL か `arn:aws:...` を判定し、ARN なら AWS コンソールへ |
| `<leader>gR` | カーソル下の `org/repo` を GitHub で開く |

## スクロール (独自 `zz` サイクル)

| キー | 動作 |
| --- | --- |
| `zz` | 画面中央へ (サイクル開始) |
| `zz` 後の `z` (1 秒以内) | 中央 → 上 → 下 → 中央 … とサイクル |
| それ以外の `z` + 任意キー | 通常の `z{char}` として動作 |
