# Insert モード

文字を打ち込むモード。Vim では「打つ」より「移動・編集」のほうがメインなので、**Insert に長居しないのがコツ**。書き終わったらすぐ `Esc` で Normal に戻りましょう。

## モードへの入り方 (Normal → Insert)

| キー | カーソル位置 |
| --- | --- |
| `i` | 現在位置に挿入 (insert) |
| `I` | 行頭 (空白を除く) に挿入 |
| `a` | 現在位置の **次** から挿入 (append) |
| `A` | 行末に挿入 |
| `o` | 下に新規行を作って挿入 |
| `O` | 上に新規行を作って挿入 |
| `s` | 1 文字削除して挿入 (substitute) |
| `S` | 1 行削除して挿入 |
| `cc` | 行を空にして挿入 (`c` + `c`) |

## モードから抜ける

| キー | 動作 |
| --- | --- |
| `Esc` | Normal に戻る |
| `Ctrl+[` | Esc と同じ (ホームポジション維持) |
| `Ctrl+c` | Esc 類似 (autocmd を発火させないので注意) |

## Insert 中の便利キー (本リポジトリのカスタム)

| キー | 動作 |
| --- | --- |
| `Ctrl+a` | 行頭へジャンプ (Emacs 風) |
| `Ctrl+e` | 行末へジャンプ (Emacs 風) |
| `Ctrl+w` | カーソル直前の単語を削除 (Vim 標準。Supermaven の挙動も統合済み) |
| `Ctrl+u` | 行頭まで削除 |
| `Ctrl+h` | 1 文字削除 (Backspace 同等) |
| `Ctrl+t` / `Ctrl+d` | インデント増加 / 減少 |
| `Ctrl+o` + コマンド | **1 回だけ** Normal モードのコマンドを実行して Insert に戻る |
| `Ctrl+r {reg}` | レジスタの内容を挿入 (例: `Ctrl+r +` でシステムクリップボード貼り付け) |

## AI 補完 (Supermaven)

Insert モード中、AI が灰色の **ゴーストテキスト** で続きを提案してきます。

| キー | 動作 |
| --- | --- |
| `Ctrl+l` | 提案を全部受け入れる |
| `Ctrl+j` | 提案を **1 単語だけ** 受け入れる (途中まで採用したいとき) |
| `Ctrl+]` | 提案を消す |

> 初回は `:SupermavenUseFree` でメール認証してください。Pro 契約なら `:SupermavenUsePro`。

## 補完メニュー (blink.cmp)

`.` を打ったときなどに表示される **メニュー型** の補完。Supermaven の ghost text とは別物です。

| キー | 動作 |
| --- | --- |
| `Ctrl+n` / `Ctrl+p` | 次/前の候補 |
| `Tab` / `Shift+Tab` | 次/前の候補 (LuaSnip と連携) |
| `Enter` | 候補を確定 |
| `Ctrl+e` | 候補を閉じる (**注**: 本リポジトリは Ctrl+e を行末ジャンプに割当済なので、blink.cmp 側は Ctrl+e でも閉じる) |
| `Ctrl+y` | 候補を確定 (Vim 標準) |
| `Ctrl+Space` | 補完を手動で起動 |

## スニペット (LuaSnip)

スニペットの placeholder (`$1`, `$2` など) 間を移動。

| キー | 動作 |
| --- | --- |
| `Tab` | 次の placeholder |
| `Shift+Tab` | 前の placeholder |

## Emmet (HTML/JSX 補助)

HTML や JSX のファイルで `div.foo>p` のような略記を展開できます。

| キー | 動作 |
| --- | --- |
| `Ctrl+y` then `,` | Emmet を展開 (デフォルト Leader: `<C-y>`) |

例: `ul>li*3` と書いて `Ctrl+y` `,` を押すと
```html
<ul>
  <li></li>
  <li></li>
  <li></li>
</ul>
```
に展開されます。

## Insert モード時の表示

- カーソル位置の行番号の色が `modicator.nvim` で **Insert 用の色** に変わります
- `noice.nvim` が `:` コマンドのプロンプトをフローティングで描画

## やってはいけないこと

- **矢印キーで移動する** → 早いうちに `hjkl` で移動するクセを身につける。Insert 中の矢印は使わず、`Esc` → 移動 → `i` で戻る習慣を
- **Insert 中に長距離移動する** → 移動は Normal の仕事。`Ctrl+o` で 1 回だけ Normal コマンドを実行する方法も覚えておくとラク
