# WezTerm キーバインド

設定ファイル:

- [`.config/wezterm/keymaps.lua`](../../.config/wezterm/keymaps.lua)
- [`.config/wezterm/workspace.lua`](../../.config/wezterm/workspace.lua)
- [`.config/wezterm/modules/opacity.lua`](../../.config/wezterm/modules/opacity.lua)
- [`.config/wezterm/modules/aws_profile.lua`](../../.config/wezterm/modules/aws_profile.lua)

前提:

- Leader キー: `Ctrl+q`（タイムアウト 2000 ms）
- デフォルトキー: 無効化 (`disable_default_key_bindings = true`)
- 現在有効な key table 名は、右ステータスバーに赤背景で表示されます

## グローバル

| キー | 動作 |
| --- | --- |
| `Ctrl+j` | コマンドパレットを開く |
| `Ctrl+Shift+Alt+p` | コマンドパレット (予備) |
| `Ctrl+Shift+Alt+r` | 設定の再読込 |
| `Alt+Enter` | フルスクリーン切替 |
| `Ctrl+c` / `Ctrl+v` | クリップボードへコピー / 貼り付け |
| `Alt+;` / `Ctrl+Shift+;` | フォントサイズ拡大 |
| `Alt+-` / `Ctrl+Shift+-` | フォントサイズ縮小 |
| `Alt+0` / `Ctrl+Shift+0` | フォントサイズリセット |
| `Super+Space` | クイックセレクト (AWS ARN パターン対応) |

## Leader からのアクション

| キー | 動作 |
| --- | --- |
| `LEADER` → `[` | コピーモードに入る |
| `LEADER` → `p` | AWS プロファイル選択 (fuzzy、`export AWS_PROFILE=...` を挿入) |
| `LEADER` → `w` | ワークスペース選択 (fuzzy、scratch は除外) |

## ワークスペース

| キー | 動作 |
| --- | --- |
| `Ctrl+Cmd+s` | scratch ワークスペースをトグル (戻り先を記憶) |
| `Ctrl+Cmd+n` | 次のワークスペース (scratch 除外) |
| `Ctrl+Cmd+p` | 前のワークスペース (scratch 除外) |

### `workspace_mode` (`LEADER` → `w` 中)

| キー | 動作 |
| --- | --- |
| `Shift+c` | 新規ワークスペースを作成 (名前を入力) |
| `Esc` | モード終了 |

## タブ操作 — `tab_ops` key table

`Alt+a` で有効化 (トグル。`Alt+a` または `Esc` で終了)

| キー | 動作 |
| --- | --- |
| `Tab` / `Shift+Tab` | 次 / 前のタブへ |
| `t` | 新しいタブ |
| `w` | タブを閉じる (確認あり) |
| `[` / `]` | タブを左 / 右へ移動 |
| `1`〜`8` | 指定番号のタブへ |
| `9` | 末尾のタブへ |

## ペイン操作 — `pane_ops` key table

`Alt+q` または `Ctrl+q` で有効化 (2 秒タイムアウト)

| キー | 動作 |
| --- | --- |
| `d` | 垂直分割 |
| `r` | 水平分割 |
| `x` | ペインを閉じる (確認あり) |
| `h` / `j` / `k` / `l` | ペイン移動 |
| `[` | ペイン選択モード |
| `z` | ペインズームのトグル |
| `s` | リサイズモードへ (`resize_pane`) |
| `a` | 移動モードへ (`activate_pane`、1 秒タイムアウト) |
| `Esc` | モード終了 |

### `resize_pane`

| キー | 動作 |
| --- | --- |
| `h` / `j` / `k` / `l` | ペインサイズを 1 単位調整 |
| `Enter` | モード終了 |

### `activate_pane`

| キー | 動作 |
| --- | --- |
| `h` / `j` / `k` / `l` | ペイン移動 (連続操作可) |

## コピーモード — `copy_mode` key table

`LEADER` → `[` で有効化

| キー | 動作 |
| --- | --- |
| `h` / `j` / `k` / `l` | カーソル移動 |
| `w` / `b` / `e` | 単語単位で前後移動 |
| `^` / `$` | 行頭 (コンテンツ) / 行末へ |
| `0` | 行頭 (カラム 0) へ |
| `o` / `O` | 選択の反対側へ (縦 / 横) |
| `f` / `F` / `t` / `T` | 文字ジャンプ (前方 / 後方 / 手前 / 後方手前) |
| `;` | 直前のジャンプを再実行 |
| `g` / `G` | スクロールバック先頭 / 末尾 |
| `H` / `M` / `L` | ビューポートの上 / 中央 / 下 |
| `Alt+b` / `Alt+f` | ページ上 / 下 |
| `Alt+u` / `Alt+d` | 半ページ上 / 下 |
| `v` | セル選択モード |
| `Alt+v` | ブロック選択モード |
| `V` | 行選択モード |
| `y` | Clipboard へコピー |
| `Enter` | Clipboard+PrimarySelection にコピーして終了 |
| `Esc` / `q` / `Alt+c` | コピーモード終了 |

## `setting_mode` (透明度調整)

`setting_mode` 中で以下のキーが利用できます (モジュール: `modules/opacity.lua`)

| キー | 動作 |
| --- | --- |
| `;` | 背景の不透明度を +0.1 |
| `-` | 背景の不透明度を -0.1 |
| `0` | 初期値 (`0.65`) へリセット |
