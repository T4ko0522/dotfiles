# Leader キー (`,` で始まるショートカット)

本リポジトリの `<leader>` は **`,` (カンマ)** に変更されています。`,` を押してから 1 秒待つと **WhichKey** がポップアップして、現在使えるキーを一覧表示します。**忘れたら `,` を押す**。

> `<localleader>` は `\` のまま。Markdown プラグインなどで使われます。

## 命名のルール (LazyVim ベース)

| プレフィックス | 用途 |
| --- | --- |
| `<leader>a` | AI (Claude Code) |
| `<leader>b` | バッファ (Buffer) |
| `<leader>c` | コード (Code, LSP, format, action) |
| `<leader>d` | デバッグ / lazydocker |
| `<leader>e` | エクスプローラ (neo-tree) |
| `<leader>f` | ファイル / 検索 (find / file) |
| `<leader>g` | Git |
| `<leader>m` | Markdown 関連 |
| `<leader>n` | 通知 (Notification) |
| `<leader>p` | Picker |
| `<leader>q` | セッション/終了 (quit) |
| `<leader>s` | 検索 (Search) |
| `<leader>t` | テスト |
| `<leader>u` | UI トグル |
| `<leader>w` | ウィンドウ |
| `<leader>x` | 診断 (Trouble) |

## トップレベル (`,` の直後)

| キー | 動作 |
| --- | --- |
| `<leader><leader>` | **ファイル検索** (Git プロジェクトルートから。dotfiles では hidden 有効) |
| `<leader>/` | **ファイル内 grep** (Git プロジェクトルートから) |
| `<leader>e` | サイドバーの neo-tree をトグル |
| `<leader>E` | カレントディレクトリで neo-tree |
| `<leader>p` | Snacks Picker の **ピッカー一覧** (全 picker をここから呼べる) |
| `<leader>y` | yazi をフローティングで起動 |
| `<leader>cw` | yazi を現在の作業ディレクトリで起動 |
| `<leader>d` | lazydocker (インストール時のみ) |

## ファイル / 検索 (`<leader>f`, `<leader>s`)

| キー | 動作 |
| --- | --- |
| `<leader>ff` | ファイル検索 |
| `<leader>fr` | 最近開いたファイル |
| `<leader>fb` | バッファ一覧 |
| `<leader>fc` | Neovim 設定ファイルを開く |
| `<leader>fh` | ヘルプタグを picker で検索 |
| `<leader>sg` | grep (LazyVim 標準) |
| `<leader>sw` | カーソル下の単語を grep |
| `<leader>sk` | キーマップ検索 (どのキーが何に割当てられているか) |

## Git (`<leader>g`)

| キー | 動作 |
| --- | --- |
| `<leader>gg` | LazyGit (cwd) |
| `<leader>gG` | LazyGit (Git プロジェクトルート) |
| `<leader>gf` | このファイルの Git ログを picker で表示 (Enter=ブラウザでコミット表示、`o`=checkout) |
| `<leader>gR` | カーソル下の `owner/repo` を GitHub で開く |
| `<leader>gb` | 現在行の blame |

## Code / LSP (`<leader>c`)

| キー | 動作 |
| --- | --- |
| `<leader>ca` | コードアクション |
| `<leader>cr` | リネーム (inc-rename で対話的) |
| `<leader>cf` | フォーマット |
| `<leader>cd` | 行の診断を表示 |
| `<leader>cl` | LSP info |

## AI - Claude Code (`<leader>a`)

| キー | 動作 |
| --- | --- |
| `<leader>ac` | Claude Code をトグル (サイドターミナル) |
| `<leader>af` | Claude Code にフォーカス |
| `<leader>ar` | 前回セッションを再開 (`claude --resume`) |
| `<leader>aC` | 前回セッションを継続 (`claude --continue`) |
| `<leader>ab` | 現在のバッファを Claude に渡す |
| `<leader>as` (Visual) | 選択範囲を Claude に送信 |
| `<leader>as` (neo-tree 内) | カーソル下のファイルを渡す |
| `<leader>aa` | Claude が提示した diff を **Accept** |
| `<leader>ad` | Claude が提示した diff を **Deny** |

## UI トグル (`<leader>u`)

| キー | 動作 |
| --- | --- |
| `<leader>uw` | ワードラップ ON/OFF |
| `<leader>us` | スペルチェック ON/OFF |
| `<leader>ul` | 行番号 ON/OFF |
| `<leader>uL` | 相対行番号 ON/OFF |
| `<leader>ud` | 診断 ON/OFF |
| `<leader>uh` | LSP inlay hint ON/OFF |
| `<leader>uC` | Treesitter コンテキスト表示の ON/OFF |
| `<leader>uT` | Treesitter highlight ON/OFF |
| `<leader>ub` | 背景の dark/light 切替 |

## Notification / Noice (`<leader>n`, `<leader>sn`)

| キー | 動作 |
| --- | --- |
| `<leader>nn` | 通知履歴を picker で表示 |
| `<leader>snl` | Noice 最新メッセージ |
| `<leader>snh` | Noice 履歴 |
| `<leader>sna` | Noice 全メッセージ |
| `<leader>snd` | 通知を全て dismiss |

## Markdown (`<leader>m`)

| キー | 動作 |
| --- | --- |
| `<leader>mp` | 画像/数式をプレビュー (カーソル下) |
| `<leader>mc` | Markdown 文字数カウント (Visual 選択範囲も可) |

## ウィンドウ (`<leader>w`)

| キー | 動作 |
| --- | --- |
| `<leader>ww` | 次のウィンドウへ |
| `<leader>wd` | 現在のウィンドウを閉じる |
| `<leader>w-` | 水平分割 |
| `<leader>w\|` | 垂直分割 |
| `<leader>wr` | winresizer モード (矢印キーでサイズ変更、`q` で確定) |

## バッファ (`<leader>b`)

| キー | 動作 |
| --- | --- |
| `<leader>bd` | バッファを閉じる |
| `<leader>bb` | 直前のバッファに切替 |

## Diagnostic / Trouble (`<leader>x`)

| キー | 動作 |
| --- | --- |
| `<leader>xx` | Trouble (診断一覧) |
| `<leader>xX` | Trouble (バッファのみ) |
| `<leader>xs` | Trouble Symbols |

## ヒントを忘れたら

```
,           ← 押して 1 秒待つ → WhichKey が出る
:WhichKey   ← 全キーを画面で確認
:Telescope keymaps  ← 検索可能なキー一覧 (LazyVim 標準で利用可能)
```
