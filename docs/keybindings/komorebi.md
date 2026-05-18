# komorebi + whkd キーバインド

設定ファイル: [`.config/whkdrc`](../../.config/whkdrc) / [`.config/komorebi/komorebi.json`](../../.config/komorebi/komorebi.json)

前提:

- シェルは `powershell`
- `Win` = Windows キー

## ワークスペース構成

`Win+1/2/3` は **フォーカス中モニターのみ** を切り替える (`focus-workspace` 単数形)。
`Win+F1/F2/F3` は **M1 へフォーカスを移しつつ** IV/V/VI に切り替える (`focus-monitor-workspace 1 N`)。

| Index | M0 `CMN1556` (メイン) | M1 `DELF144` (拡張) |
|---|---|---|
| 0 (`Win+1` / `Win+F1`) | **I** / BSP — WezTerm | **IV** / BSP — VSCode, Brave (プライベート) |
| 1 (`Win+2` / `Win+F2`) | **II** / Grid — Discord | **V** / BSP — Chrome (ビジネス) |
| 2 (`Win+3` / `Win+F3`) | **III** / Columns — Slack, Spotify | **VI** / BSP — Mattermost |

> `Win+F1/F2/F3` はモニターをまたいで M1 側の作業に直接ジャンプしたい時に使う。M0 を見たまま M1 側だけ切り替えたい場合は使えない (フォーカスが M1 に移る)。

### 配置ポリシー

- **M0 = コミュニケーション・開発端末**
  - I: ターミナル作業 (WezTerm)
  - II: 通話・チャット (Discord)
  - III: ワークチャット系 + BGM (Slack, Spotify)
- **M1 = 広い作業領域**
  - IV: コーディング + プライベートブラウジング (VSCode, Brave)
  - V: ビジネス用ブラウジング (Chrome)
  - VI: ビジネスチャット専用 (Mattermost)
- **ブラウザの役割分担**
  - **Brave = プライベート**: 私用閲覧・SNS・動画・課金記事の送り込み防止
  - **Chrome = ビジネス**: Google Workspace, 業務ツール, 顧客サービス

ワークスペース名は `I, II, III` (M0) と `IV, V, VI` (M1) で連番。`Win+3` を押した時に表示される名前 (III or VI) で、どちらのモニターを操作中か即時に判別できる。

### 起動スクリプト

pwsh 起動時 ([`.config/powershell/conf.d/startup.ps1`](../../.config/powershell/conf.d/startup.ps1)) に komorebi が未起動なら [`.config/komorebi/komorebi_start.ps1`](../../.config/komorebi/komorebi_start.ps1) が走り、モニター適応 → komorebi/whkd 起動 → [`morning_setup.ps1`](../../.config/komorebi/morning_setup.ps1) による常用アプリ一括起動まで一気通貫で行う (`workspace_rules` が配置を担当)。2 回目以降の pwsh タブ起動では komorebi の生存を socket 応答で確認し、何もしない。

## 基本

| キー | 動作 |
| --- | --- |
| `Win+r` | 設定の再読込 |
| `Win+/` | whkd のショートカット一覧を表示 |
| `Win+q` | ウィンドウを閉じる |
| `Win+m` | ウィンドウを最小化 |
| `Win+t` | フローティング切替 |
| `Win+Shift+f` | モノクル (最大化) 切替 |
| `Win+z` | komorebi の一時停止トグル |

## レイアウト

| キー | 動作 |
| --- | --- |
| `Win+x` | 水平方向にフリップ |
| `Win+y` | 垂直方向にフリップ |

## フォーカス移動

| キー | 動作 |
| --- | --- |
| `Alt+←` / `Alt+↓` / `Alt+↑` / `Alt+→` | 左 / 下 / 上 / 右のウィンドウにフォーカス (モニター境界を越える) |
| `Win+Shift+[` | 前のウィンドウへ (`cycle-focus previous`) |
| `Win+Shift+]` | 次のウィンドウへ (`cycle-focus next`) |

> `Alt+矢印` の方向フォーカスは `cross_boundary_behaviour: "Monitor"` により Windows が認識する物理配置 (X/Y 座標) を基準にモニター境界を越える。laptop と外部モニターの左右関係は Windows の「ディスプレイの配置」設定で決まり、それを komorebi が自動追従するため、外部モニターを差し替えても `komorebi.json` 側は変更不要。

> 注: `Win+u/i/o/p` は方向フォーカスではなく `preselect-direction` (次に開くウィンドウの配置先指定)。

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
| `Win+1`〜`Win+3` | フォーカス中モニターのワークスペース 0〜2 にフォーカス |
| `Win+F1`〜`Win+F3` | M1 へフォーカスを移しつつ M1 のワークスペース 0〜2 (IV/V/VI) に切替 |
| `Win+Alt+1`〜`Win+Alt+3` | アクティブウィンドウをフォーカス中モニターのワークスペース 0〜2 へ移動 |

## マルチモニター

| キー | 動作 |
| --- | --- |
| `Win+,` | モニター 0 (メイン: WezTerm / Discord / Slack+Spotify) |
| `Win+.` | モニター 1 (拡張: VSCode+Brave / Chrome / Mattermost) |
| `Win+Shift+,` / `Win+Shift+.` | ウィンドウをモニター 0 / 1 へ移動 |
| `Win+n` | 次のモニターへ |
| `Win+Shift+n` | 前のモニターへ |
