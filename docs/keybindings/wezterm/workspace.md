# ワークスペース

定義箇所: [`chezmoi/dot_config/wezterm/workspace.lua`](../../../chezmoi/dot_config/wezterm/workspace.lua)

`scratch` ワークスペースは一時的な作業領域として扱われ、`Ctrl+Cmd+n` / `Ctrl+Cmd+p` の巡回からは除外される。`Ctrl+Cmd+s` のトグルで `scratch` へ移動した際は、移動前のワークスペースを記憶しており、再度同キーで元に戻る。

## グローバル

| キー | 動作 |
| --- | --- |
| `Ctrl+Cmd+s` | `scratch` ワークスペースをトグル（戻り先を記憶） |
| `Ctrl+Cmd+n` | 次のワークスペース（`scratch` を除外して巡回） |
| `Ctrl+Cmd+p` | 前のワークスペース（`scratch` を除外して巡回） |
| `Leader → w` | fuzzy 選択メニューを開き、同時に `workspace_mode` を有効化 |

## `workspace_mode` key table

`Leader → w` で fuzzy 選択メニューと同時に起動する。メニュー操作中も新規作成キーは受け取れる。

| キー | 動作 |
| --- | --- |
| `Shift+c` | 新規ワークスペースを作成（プロンプトで名前入力 → 即座に移動） |
| `Esc` | モード終了 |
