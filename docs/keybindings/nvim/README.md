# Neovim キーバインド & チュートリアル

Vim 初心者向けに、本リポジトリの Neovim 設定 ([LazyVim](https://www.lazyvim.org/) ベース) で使えるキーをモード別にまとめたチュートリアル集です。

設定ファイル:

- [`.config/shared/nvim/lua/config/options.lua`](../../../.config/shared/nvim/lua/config/options.lua) — オプションとリーダーキー
- [`.config/shared/nvim/lua/config/keymaps.lua`](../../../.config/shared/nvim/lua/config/keymaps.lua) — カスタムキーマップ
- [`.config/shared/nvim/lua/config/autocmds.lua`](../../../.config/shared/nvim/lua/config/autocmds.lua) — autocmd とユーザーコマンド
- [`.config/shared/nvim/lua/plugins/`](../../../.config/shared/nvim/lua/plugins/) — 各プラグインの設定

## 大事な前提

| 用語 | 値 |
| --- | --- |
| `<leader>` (リーダーキー) | **`,` カンマ** (LazyVim デフォルトの `<Space>` から変更済) |
| `<localleader>` | `\` バックスラッシュ |
| 主要テーマ | Catppuccin Mocha |

> 失われた `,` (`f/F/t/T` の逆方向リピート) は **`;,`** に再割当しています。

## 読む順番

1. [modes.md](modes.md) — Vim の **モード** の考え方。これが Vim を理解する第一歩
2. [normal.md](normal.md) — 移動・編集・コピペの基本 (Vim 操作の 8 割はここ)
3. [insert.md](insert.md) — 文字を打つモード。AI 補完 (Supermaven) のキーもここ
4. [visual.md](visual.md) — 範囲選択
5. [command.md](command.md) — `:` で始めるコマンド (`:w`, `:q`, など)
6. [leader-keys.md](leader-keys.md) — `,` で始まる強力なショートカット集
7. [plugins.md](plugins.md) — プラグイン別の便利キー一覧

## まず触ってみるべき5つ

| キー | 何をする |
| --- | --- |
| `,` を押す | 1秒待つと WhichKey が起動して使えるリーダーキーの一覧が出る (迷子防止) |
| `i` → 文字入力 → `Esc` | インサートモード ↔ ノーマルモード |
| `:w` → Enter | 保存 |
| `:q` → Enter | 終了 |
| `:help` | 公式ヘルプ。`:H foo` なら **右に縦分割で日本語ヘルプ** が開く |

## トラブったら

- **入力を受け付けない** → Esc を 2 回押す。多分インサートじゃないモードに迷い込んでる
- **キーを忘れた** → `,` を押してから 1 秒待つ (WhichKey が表示)
- **プラグインがおかしい** → `:Lazy` → `r` で reload、`:checkhealth` で診断
- **このドキュメントに無い** → `:Telescope keymaps` か `:WhichKey` で全キー検索可能
