# 透明度 — `setting_mode` key table

定義箇所: [`chezmoi/dot_config/wezterm/modules/opacity.lua`](../../../chezmoi/dot_config/wezterm/modules/opacity.lua)

背景の不透明度をリアルタイム調整するモード。キーを押すたびに `setting_mode` が再アクティブ化されるため、連続操作が可能。

## 起動

`setting_mode` を起動するキーは現在割り当てなし。コマンドパレット (`Ctrl+j`) から `ActivateKeyTable` を選んで起動するか、必要に応じて [`keymaps.lua`](../../../chezmoi/dot_config/wezterm/keymaps.lua) にエントリを追加する。

## キー一覧

| キー | 動作 |
| --- | --- |
| `;` | 不透明度を `+0.1`（上限 `1.0`） |
| `-` | 不透明度を `-0.1`（下限 `0.1`） |
| `0` | [`wezterm.lua`](../../../chezmoi/dot_config/wezterm/wezterm.lua) の `window_background_opacity` 初期値（現在 `0.7`）へリセット |

## 補足

調整値は `window:set_config_overrides` でセッション内に保持される。WezTerm 再起動時には設定ファイルの初期値に戻る。
