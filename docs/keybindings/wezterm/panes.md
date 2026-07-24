# ペイン

定義箇所: [`chezmoi/dot_config/wezterm/keymaps.lua`](../../../chezmoi/dot_config/wezterm/keymaps.lua) の `key_tables` 配下 `pane_ops` / `resize_pane` / `activate_pane`

## `pane_ops` — `Alt+q` で起動

`one_shot = false` で 2 秒タイムアウト。タイムアウト前に同モード内のキーを押すと、再度 2 秒の猶予が与えられる。

| キー | 動作 |
| --- | --- |
| `d` | 垂直分割（縦に並べる） |
| `r` | 水平分割（横に並べる） |
| `x` | ペインを閉じる（確認あり） |
| `h` / `j` / `k` / `l` | ペイン移動（移動と同時に `pane_ops` を抜けてシェル入力に戻る） |
| `[` | ペイン選択モード（数字キーで対象を選択） |
| `z` | ペインズームのトグル |
| `s` | リサイズモード `resize_pane` へ遷移 |
| `a` | 移動モード `activate_pane` へ遷移（1 秒タイムアウト） |
| `Esc` | モード終了 |

## `resize_pane` — `pane_ops → s` で起動

`one_shot = false`。`Enter` で抜けるまで連続操作可。

| キー | 動作 |
| --- | --- |
| `h` | 左方向へ 1 単位リサイズ |
| `j` | 下方向へ 1 単位リサイズ |
| `k` | 上方向へ 1 単位リサイズ |
| `l` | 右方向へ 1 単位リサイズ |
| `Enter` | モード終了 |

## `activate_pane` — `pane_ops → a` で起動

1 秒タイムアウト。連続して別ペインへフォーカスを移すために使う。

| キー | 動作 |
| --- | --- |
| `h` / `j` / `k` / `l` | 上下左右のペインへフォーカス移動 |
