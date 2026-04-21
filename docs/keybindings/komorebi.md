# komorebi + whkd キーバインド

設定ファイル: [`.config/whkdrc`](../../.config/whkdrc)

前提:
- シェルは `powershell`
- `Win` = Windows キー

## 基本

| キー | 動作 |
| --- | --- |
| `Win+r` | 設定の再読込 |
| `Win+/` | whkd のショートカット一覧を表示 |
| `Win+q` | ウィンドウを閉じる |
| `Win+m` | ウィンドウを最小化 |
| `Win+t` | フローティング切替 |
| `Win+Shift+f` | モノクル (最大化) 切替 |
| `Win+Shift+r` | komorebi を再起動 (`stop --whkd` → 2 秒待機 → `start --whkd`) |
| `Win+z` | komorebi の一時停止トグル |

## レイアウト

| キー | 動作 |
| --- | --- |
| `Win+x` | 水平方向にフリップ |
| `Win+y` | 垂直方向にフリップ |

## フォーカス移動

| キー | 動作 |
| --- | --- |
| `Win+u` / `Win+i` / `Win+o` / `Win+p` | 左 / 下 / 上 / 右のウィンドウにフォーカス |
| `Win+Shift+[` | 前のウィンドウへ (`cycle-focus previous`) |
| `Win+Shift+]` | 次のウィンドウへ (`cycle-focus next`) |

## ウィンドウ移動

| キー | 動作 |
| --- | --- |
| `Win+Shift+u` / `i` / `o` / `p` | 左 / 下 / 上 / 右へ移動 |
| `Win+Shift+Enter` | プロモート (マスター位置へ) |

## スタック

| キー | 動作 |
| --- | --- |
| `Win+←/↓/↑/→` | 各方向にスタック |
| `Win+;` | スタックを解除 |
| `Win+[` / `Win+]` | スタック内の前 / 次 |

## リサイズ

| キー | 動作 |
| --- | --- |
| `Win++` / `Win+-` | 水平方向に拡大 / 縮小 |
| `Win+Shift++` / `Win+Shift+-` | 垂直方向に拡大 / 縮小 |

## ワークスペース

| キー | 動作 |
| --- | --- |
| `Win+1`〜`Win+8` | ワークスペース 0〜7 にフォーカス |
| `Win+Shift+1`〜`Win+Shift+8` | アクティブウィンドウを対応ワークスペースへ移動 |

## マルチモニター

| キー | 動作 |
| --- | --- |
| `Win+,` | モニター 0 (メイン: WezTerm/Discord/Spotify) |
| `Win+.` | モニター 1 (サブ: VSCode/Browser) |
| `Win+Shift+,` / `Win+Shift+.` | ウィンドウをモニター 0 / 1 へ移動 |
| `Win+n` | 次のモニターへ |
| `Win+Shift+n` | 前のモニターへ |
