# Command モード (`:` で始まる Ex コマンド)

`:` を押すと画面下 (本リポジトリでは `noice.nvim` のおかげで中央フローティング) にコマンドラインが現れます。これは「Ex コマンド」モードとも呼ばれ、Vim 設定・ファイル操作・置換などをここから実行します。

## 開始と終了

| キー | 動作 |
| --- | --- |
| `:` | コマンドモード開始 |
| `Enter` | 実行 |
| `Esc` または `Ctrl+c` | 中止 |
| `Tab` | 補完 |
| `Ctrl+f` | コマンドライン履歴のウィンドウを開く (これ自体は Normal モードで編集できる) |
| `q:` | コマンドライン履歴ウィンドウ (Ctrl+f と同等) |

## 必須コマンド

| コマンド | 動作 |
| --- | --- |
| `:w` | 保存 |
| `:w {file}` | 別名保存 |
| `:q` | 終了 |
| `:q!` | 保存せず終了 |
| `:wq` または `:x` | 保存して終了 |
| `:e {file}` | ファイルを開く |
| `:e!` | ファイルを再読み込み (変更を破棄) |
| `:qa` | 全ウィンドウ終了 |
| `:wa` | 全ウィンドウ保存 |
| `:wqa` | 全保存して終了 |

## ヘルプ

| コマンド | 動作 |
| --- | --- |
| `:help <topic>` または `:h <topic>` | ヘルプを開く (例: `:h motion`) |
| `:H <topic>` | **カスタム**: 右側に縦分割でヘルプを開く |
| `:helpgrep <pattern>` | ヘルプ全体をパターン検索 |

> `helplang=ja` 設定なので、日本語ヘルプ (vimdoc-ja) が優先表示されます。

## 検索と置換

| コマンド | 動作 |
| --- | --- |
| `:%s/old/new/g` | ファイル全体で `old` → `new` に置換 |
| `:%s/old/new/gc` | 1 件ずつ確認しながら置換 |
| `:'<,'>s/old/new/g` | 直前の Visual 選択範囲内で置換 |
| `:noh` | 検索ハイライトを消す |

`#` (Normal モード) を押すとカーソル下の単語を `:%s/word//g` に流し込む小ワザがあります — [normal.md](normal.md) 参照。

## バッファ・タブ・ウィンドウ

| コマンド | 動作 |
| --- | --- |
| `:tabnew` | 新しいタブ |
| `:tabnext` / `:tabprev` | タブ移動 (Tab / Shift+Tab がショートカット) |
| `:bnext` / `:bprev` | 次/前のバッファ |
| `:bd` | バッファを閉じる |
| `:split` (= `ss`) | 水平分割 |
| `:vsplit` (= `sv`) | 垂直分割 |
| `:only` | カレント以外の分割を閉じる |

## ファイラ・Picker (Snacks)

| コマンド | 動作 |
| --- | --- |
| `:Neotree` | サイドバーのファイルツリーをトグル |
| `:Neotree show` | 開く (自動でフォーカスは編集側) |
| `:Yazi` | yazi をフローティングで起動 |
| `:Lazy` | プラグインマネージャを開く |
| `:Mason` | LSP/Formatter/Linter インストーラを開く |
| `:LazyExtras` | LazyVim Extras 一覧 |

## AI

| コマンド | 動作 |
| --- | --- |
| `:SupermavenUseFree` | Supermaven の無料プランで認証 |
| `:SupermavenUsePro` | Pro プランで認証 |
| `:SupermavenStop` / `:SupermavenStart` | 一時停止 / 再開 |
| `:SupermavenStatus` | 状態確認 |
| `:ClaudeCode` | Claude Code をサイドターミナルで起動 (`<leader>ac`) |
| `:ClaudeCodeFocus` | フォーカスを Claude Code 側へ |
| `:ClaudeCodeAdd %` | 現在のバッファを Claude に渡す |

## Git

| コマンド | 動作 |
| --- | --- |
| `:Gitsigns toggle_current_line_blame` | 現在行の blame をトグル |
| `:LazyGit` | LazyGit を起動 (`<leader>gg` と同じ) |

## カスタムユーザーコマンド (本リポジトリ独自)

| コマンド | 動作 |
| --- | --- |
| `:CountCleanTextLength` | Markdown 記法を除いた文字数を表示 (バッファ全体 or Visual 選択) |
| `:CoAuthoredBy <github-user>` | GitHub ユーザー名から Co-Authored-By トレーラーを生成して挿入 |
| `:InsertDatetime` | カーソル位置に現在時刻を `YYYY-MM-DD HH:MM:SS` で挿入 |
| `:Arto [file]` | 引数 or 現在のファイルを Arto (Markdown エディタ) で開く (macOS) |
| `:RFC` | RFC 閲覧 (rfc.nvim — 既に削除済の場合は使えません) |
| `:Codic <word>` | プログラミング英単語辞書 (`naming` で困ったとき) |
| `:CompilerOpen` / `:CompilerToggleResults` | compiler.nvim でコンパイル/結果トグル |
| `:OverseerRun` / `:OverseerToggle` | overseer (タスクランナー) を起動/トグル |

## :H で日本語ヘルプを右に開く

```
:H motion       ← motion.txt を右に縦分割で開く
:H w            ← w コマンドのヘルプ
:H vim-modes    ← モードの概念
```

`:H` は `abbrev` (略式コマンド) なので `:H` と打ったあとに Space を入れると `:belowright vertical help` に展開されます。

## Vim 公式チュートリアル

- ターミナルで `vimtutor` (英語) または `vimtutor ja` (日本語)
- 30 分で基本がひととおり身につくのでオススメ
