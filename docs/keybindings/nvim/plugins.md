# プラグイン別キーバインド

各プラグインの便利キーをここにまとめます。先に [leader-keys.md](leader-keys.md) を読んで `<leader>` プレフィックスのものを把握しておくと理解が早いです。

---

## ファイラ系

### neo-tree.nvim (サイドバーのファイルツリー)

ファイル指定で `nvim foo.txt` のように起動すると **自動でサイドバーに表示**、ファイルを選択すると **自動で閉じる** 動作になっています。

| キー | 動作 |
| --- | --- |
| `<leader>e` | ツリーをトグル (表示/非表示) |
| `<leader>E` | カレントディレクトリで開く |

**ツリー内の操作:**

| キー | 動作 |
| --- | --- |
| `Enter` / `o` | ファイルを開く (開いた瞬間にツリーは自動クローズ) |
| `s` | 水平分割で開く |
| `S` | 垂直分割で開く |
| `t` | 新しいタブで開く |
| `a` | ファイル/フォルダ作成 |
| `d` | 削除 |
| `r` | リネーム |
| `c` / `m` | コピー / 移動 |
| `y` / `Y` | ファイル名 / フルパスをコピー |
| `R` | 再読み込み |
| `H` | 隠しファイル表示トグル |
| `?` | ヘルプ表示 |

### yazi.nvim (ターミナルファイラ)

フルスクリーンでフローティング起動するモダンなファイラ。

| キー | 動作 |
| --- | --- |
| `<leader>y` | カレントファイル位置で yazi を開く |
| `<leader>cw` | 作業ディレクトリで yazi を開く |
| `Ctrl+Up` | 直前の yazi セッションを再開 |
| `Enter` (yazi 内) | ファイルを選んで Neovim で開く |
| `q` (yazi 内) | yazi を閉じる |
| `<f1>` (yazi 内) | yazi のヘルプ |

---

## 検索 / Picker - Snacks

LazyVim 標準の Telescope ではなく **snacks.picker** を使っています。操作感はほぼ同じ。

| キー | 動作 |
| --- | --- |
| `<leader><leader>` | ファイル検索 |
| `<leader>/` | grep |
| `<leader>p` | ピッカーの一覧から選ぶ |
| `<leader>fh` | ヘルプ検索 |
| `<leader>gf` | Git ログ (ファイル) |
| `<leader>nn` | 通知履歴 |

**Picker 内の操作:**

| キー | 動作 |
| --- | --- |
| `Ctrl+n` / `Ctrl+p` | 次/前の候補 |
| `Enter` | 選択 |
| `Ctrl+v` | 垂直分割で開く |
| `Ctrl+s` | 水平分割で開く |
| `Ctrl+t` | 新しいタブで開く |
| `h` (Normal モード) | 隠しファイルトグル |
| `I` (Normal モード) | gitignore 無視のトグル |
| `Esc` / `Ctrl+c` | 閉じる |

---

## バッファ切替 (bufferline.nvim)

| キー | 動作 |
| --- | --- |
| `Tab` | 次のタブ (バッファ) |
| `Shift+Tab` | 前のタブ |
| `<leader>bd` | バッファを閉じる |

---

## ターミナル (snacks.terminal)

| キー | 動作 |
| --- | --- |
| `Ctrl+/` | フローティングターミナル (Root) |
| `Ctrl+_` | フローティングターミナル (cwd) |
| `Esc` (ターミナル内) | Terminal Normal モードへ |
| `i` / `a` (Terminal Normal で) | 入力モードに戻る |

---

## ノイス (noice.nvim)

`:` コマンドや LSP hover をフローティング表示する見た目の改善プラグイン。

| キー | 動作 |
| --- | --- |
| `<leader>snl` | 最新の通知 |
| `<leader>snh` | 通知履歴 |
| `<leader>sna` | 全メッセージ |
| `<leader>snd` | 全 dismiss |
| `Shift+Enter` (`:` コマンド入力中) | コマンド出力を別バッファにリダイレクト |

---

## Treesitter Context

スクロール時に「いま自分は何の関数の中にいるか」を画面上端に固定表示。

| キー | 動作 |
| --- | --- |
| `[c` | 現在スコープ (関数等) の冒頭にジャンプ |
| `<leader>uC` | コンテキスト表示の ON/OFF |

---

## 折りたたみ (ufo.nvim)

| キー | 動作 |
| --- | --- |
| `zR` | 全部展開 |
| `zM` | 全部閉じる |
| `zr` | 1段階展開 |
| `zm` | 1段階閉じる |
| `za` | カーソル位置の折りたたみをトグル (Vim 標準) |
| `K` | 折りたたみプレビュー、無ければ LSP hover |

---

## 囲み文字編集 (mini-surround)

`mini.nvim` の surround モジュール。**`s` がプレフィックス**。

| キー | 動作 |
| --- | --- |
| `saiw"` | 単語を `"` で囲む (**s**urround **a**dd **i**nner **w**ord) |
| `sd"` | 囲んでいる `"` を削除 (**s**urround **d**elete) |
| `srd("` | `(` を `"` に置換 (**s**urround **r**eplace) |
| `sf` | 「次の囲い」を探して操作 |

---

## AI 補完 (Supermaven)

Insert モード中、灰色のゴーストテキストで提案が出ます。

| キー | 動作 |
| --- | --- |
| `Ctrl+l` | 提案を全部受け入れる |
| `Ctrl+j` | 1単語だけ受け入れる |
| `Ctrl+]` | 提案を消す |

**コマンド:**

| コマンド | 動作 |
| --- | --- |
| `:SupermavenUseFree` | 無料プランで認証 (初回必須) |
| `:SupermavenUsePro` | Pro プランで認証 |
| `:SupermavenStop` / `:SupermavenStart` | 一時停止 / 再開 |

---

## AI エージェント (claude-code.nvim)

| キー | 動作 |
| --- | --- |
| `<leader>ac` | Claude Code を toggle (サイドターミナル起動) |
| `<leader>af` | Claude Code にフォーカス |
| `<leader>ar` | `claude --resume` |
| `<leader>aC` | `claude --continue` |
| `<leader>ab` | 現在のバッファを Claude に渡す |
| `<leader>as` (Visual) | 選択範囲を送信 |
| `<leader>as` (neo-tree) | ツリーで選択中のファイルを送信 |
| `<leader>aa` | Claude の diff を Accept |
| `<leader>ad` | Claude の diff を Deny |

---

## Markdown プレビュー (peek.nvim)

| コマンド | 動作 |
| --- | --- |
| `:PeekOpen` | ブラウザでプレビュー表示 |
| `:PeekClose` | 閉じる |

`<leader>mp` でカーソル下の画像/数式を hover プレビュー (snacks.image)。

---

## Git (gitsigns - LazyVim 標準)

| キー | 動作 |
| --- | --- |
| `]h` / `[h` | 次/前の hunk へ |
| `<leader>ghs` | hunk をステージ |
| `<leader>ghr` | hunk をリセット |
| `<leader>ghp` | hunk をプレビュー |
| `<leader>ghb` | 現在行の blame |

---

## ウィンドウ (winresizer)

| キー | 動作 |
| --- | --- |
| `<leader>wr` | winresizer 起動 (矢印キーでサイズ変更、`q` で確定) |
| `Ctrl+w` `r` | 同上 |

---

## カラー編集 (color-picker, minty)

| コマンド | 動作 |
| --- | --- |
| `:Shades` | minty/volt のシェードビュー |
| `:Huefy` | minty/volt の色相ビュー |

---

## コードコメント (Comment.nvim - LazyVim 標準)

| キー | 動作 |
| --- | --- |
| `gcc` | 現在行をコメント/解除 |
| `gc<motion>` | モーション範囲をコメント (例: `gcap` で段落) |
| `gc` (Visual) | 選択範囲をコメント |

---

## hlchunk / rainbow-delimiters / modicator / incline / smear-cursor

これらは **キー操作なし**。常時動いていて見た目を補助します。

- **hlchunk**: 現在のコードブロックを枠で強調
- **rainbow-delimiters**: 括弧の対応を色分け
- **modicator**: モードごとに行番号の色変化
- **incline**: 各ウィンドウ右上にファイル名表示
- **smear-cursor**: カーソル移動時の軌跡アニメ

---

## テスト (neotest - LazyVim 標準)

| キー | 動作 |
| --- | --- |
| `<leader>tt` | 現在のテストを実行 |
| `<leader>tT` | ファイルの全テストを実行 |
| `<leader>tr` | 最後のテストを再実行 |
| `<leader>ts` | テスト Summary を開く |
| `<leader>to` | テスト出力を表示 |

---

## コンパイル / タスク (compiler.nvim + overseer.nvim)

| コマンド | 動作 |
| --- | --- |
| `:CompilerOpen` | コンパイルメニューを開いて実行 |
| `:CompilerToggleResults` | 結果バッファをトグル |
| `:CompilerRedo` | 前回と同じコマンドを再実行 |
| `:OverseerToggle` | タスクランナーのリストをトグル |
| `:OverseerRun` | タスクを実行 |

---

## 英単語辞書 (codic-vim)

関数名を考えるときに便利。

| コマンド | 動作 |
| --- | --- |
| `:Codic <word>` | 日本語 → 英語 候補を表示 |

例: `:Codic 検索` → `search`, `find`, `lookup` などの候補

---

## まだ覚えてないものがあったら

```
,                       ← WhichKey で <leader> 配下を確認
:Telescope keymaps      ← 全キー検索 (LazyVim 標準は telescope.nvim)
:WhichKey               ← 全キーをツリー表示
:Lazy                   ← プラグイン一覧 (各プラグインの詳細を確認)
:help <plugin名>        ← プラグインのヘルプ (例: :help neo-tree)
```
