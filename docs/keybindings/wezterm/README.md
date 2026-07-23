# WezTerm キーバインド

設定ファイル:

- [`dot_config/shared/wezterm/wezterm.lua`](../../../dot_config/shared/wezterm/wezterm.lua) — エントリポイント
- [`dot_config/shared/wezterm/keymaps.lua`](../../../dot_config/shared/wezterm/keymaps.lua) — グローバル / `tab_ops` / `pane_ops` / `resize_pane` / `activate_pane` / `copy_mode`
- [`dot_config/shared/wezterm/workspace.lua`](../../../dot_config/shared/wezterm/workspace.lua) — ワークスペース / `workspace_mode`
- [`dot_config/shared/wezterm/modules/opacity.lua`](../../../dot_config/shared/wezterm/modules/opacity.lua) — `setting_mode`

## 前提

- **Leader キー**: `Ctrl+q`（タイムアウト 2000 ms）
- **デフォルトキー**: 無効化 (`disable_default_key_bindings = true`)
- 現在有効な key table 名は、右ステータスバーに赤背景で表示されます
- `setting_mode` を起動するキーは現状未割当のため、コマンドパレット (`Ctrl+j`) から `ActivateKeyTable` で起動する想定

## カテゴリ別ドキュメント

| カテゴリ | リンク | 概要 |
| --- | --- | --- |
| グローバル | [`global.md`](./global.md) | コマンドパレット / コピペ / フォント / フルスクリーン / QuickSelect |
| ワークスペース | [`workspace.md`](./workspace.md) | scratch トグル / ワークスペース選択 / `workspace_mode` |
| タブ | [`tabs.md`](./tabs.md) | `tab_ops` モード |
| ペイン | [`panes.md`](./panes.md) | `pane_ops` / `resize_pane` / `activate_pane` モード |
| コピーモード | [`copy-mode.md`](./copy-mode.md) | `copy_mode` の移動 / 選択 / 検索 / ジャンプ |
| 透明度 | [`setting-mode.md`](./setting-mode.md) | `setting_mode`（背景不透明度の調整） |
