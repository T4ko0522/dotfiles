# グローバル

key table に入っていない通常状態で常時有効なキーバインド。

定義箇所: [`nix-configs/home/modules/apps/wezterm/files/keymaps.lua`](../../../nix-configs/home/modules/apps/wezterm/files/keymaps.lua) の `keys` テーブル

## コマンドパレット / 設定

| キー | 動作 |
| --- | --- |
| `Ctrl+j` | コマンドパレットを開く |
| `Ctrl+Shift+Alt+r` | 設定の再読込 |
| `Alt+Enter` | フルスクリーン切替 |

## クリップボード

| キー | 動作 |
| --- | --- |
| `Ctrl+c` | 選択範囲をクリップボードへコピー |
| `Ctrl+v` / `Ctrl+Shift+v` | クリップボードから貼り付け |
| `Ctrl+Shift+Space` | QuickSelect 起動（URL / git hash / IP / path 等を 1 文字キーで選択） |

QuickSelect の追加パターンは [`nix-configs/home/modules/apps/wezterm/files/wezterm.lua`](../../../nix-configs/home/modules/apps/wezterm/files/wezterm.lua) の `config.quick_select_patterns` で定義可能（現在は未設定で WezTerm 既定パターンのみ）。

## フォントサイズ

| キー | 動作 |
| --- | --- |
| `Alt+;` / `Ctrl+Shift+;` | 10% 拡大 |
| `Alt+-` / `Ctrl+Shift+-` | 10% 縮小 |
| `Ctrl+;` | 0.5pt 拡大 |
| `Ctrl+-` | 0.5pt 縮小 |
| `Alt+0` / `Ctrl+Shift+0` | リセット |

## モード起動 (Leader 経由)

| キー | 起動するモード | 詳細 |
| --- | --- | --- |
| `Leader → v` | `copy_mode` | [copy-mode.md](./copy-mode.md) |
| `Leader → s` | `resize_pane` | [panes.md](./panes.md) |
| `Leader → w` | `workspace_mode`（fuzzy 選択メニュー併発） | [workspace.md](./workspace.md) |

## モード起動 (直接)

| キー | 起動するモード | 詳細 |
| --- | --- | --- |
| `Alt+a` | `tab_ops`（トグル、`Esc` または `Alt+a` で終了） | [tabs.md](./tabs.md) |
| `Alt+q` | `pane_ops`（2 秒タイムアウト） | [panes.md](./panes.md) |
