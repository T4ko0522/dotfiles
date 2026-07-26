---
name: pr-summarizer
description: PR のタイトル・本文・diff・commits・コメント・レビュー・CI 結果を読み、人間が読むための PR 説明文/レビュー用サマリ/マージ判断材料を固定フォーマットで生成する。単なる diff 要約ではなく、背景・影響範囲・レビュー観点・残論点・マージ前チェックリストまで含める。「このPRを読みやすくまとめて」「PR説明文を書いて」「レビューしやすいように要約して」「このPRのコメント込みで現状まとめて」等で起動。コメント/レビュー取得には github-thread-fetcher skill を内部的に利用する。
---

# PR Summarizer Skill

PR を「読みやすい説明文」「レビュー用サマリ」「マージ判断材料」として固定フォーマットでまとめる。diff だけでなく、コメントで指摘された未解決事項も反映するのが目的。

## 前提

- `gh auth status` で認証済みであること
- コメント/レビュー/CI の取得は `github-thread-fetcher` skill と同じ `gh` コマンド・整理ルールに従う（重複実装しない。無ければ同等の手順をその場で行う）

## Input 解決

1. URL または番号指定があればそれを使う
2. 指定が無ければカレントブランチの PR を `gh pr view --json number,url` で解決する
3. Issue が渡された場合は対象外である旨を伝える（このスキルは PR 専用）

## 収集するデータ

```bash
# メタデータ・本文・ファイル一覧・commits・CI 状態
gh pr view <number> --json title,body,author,baseRefName,headRefName,files,commits,additions,deletions,statusCheckRollup,url

# diff 本体
gh pr diff <number>

# コメント・レビュースレッド・CI 失敗・linked issues
# → github-thread-fetcher skill の手順で取得（未解決コメント抽出・bot 除外込み）
```

## 影響範囲の判定

`files` のパスパターンから機械的に分類する。曖昧な場合は無理にどれか一つに決めず複数チェックを付ける。

| パターン例 | 分類 |
|---|---|
| `src/`, `components/`, `*.tsx`, `*.jsx`, `*.vue`, `*.css` | frontend |
| `api/`, `server/`, `*.go`, `*.py`, `*.rb`, `*.java` | backend |
| `*.yml`, `*.yaml`, `*.toml`, `*.json`, `*.nix`, `config/` | config |
| `.github/workflows/` | CI |
| `*.md`, `docs/`, `README*` | docs |

## 出力フォーマット（固定）

以下の見出し・順序を必ず守る。該当情報が無いセクションは「特になし」と明記し、勝手に省略しない。

```markdown
## 概要
このPRで何を変えたか（1〜3文）

## 背景
なぜこの変更が必要か（Issue へのリンクがあれば併記）

## 主な変更点
- ...

## 影響範囲
- frontend: ...
- backend: ...
- config: ...
- CI: ...
- docs: ...

## レビューで見るべきポイント
- ...

## 残っている論点
- github-thread-fetcher で抽出した未解決コメント/レビュースレッドを反映する
- 例: `<path>:<line>` <author>: <要求内容>（未対応）

## マージ前チェック
- [ ] CI が green か（failing check があれば個別に明記）
- [ ] 未解決レビュースレッドが無いか
- [ ] （必要なら）テスト追加/更新の有無
```

## 作成手順

1. データ収集（上記コマンド + github-thread-fetcher の手順）を並列に行う
2. 「概要」「背景」「主な変更点」は本文・commits・diff から要約する。PR 本文がすでに十分書かれている場合はそれを尊重し、書き直しではなく整形・補完に留める
3. 「影響範囲」は上記パターン表で機械分類し、該当ファイル名も添える
4. 「レビューで見るべきポイント」は diff から判断が難しい変更（ロジック分岐、破壊的変更、設定値変更等）を優先的に挙げる
5. 「残っている論点」は github-thread-fetcher の未解決コメント一覧をそのまま反映する（要約を勝手に丸めて重要度を落とさない）
6. 「マージ前チェック」は `statusCheckRollup` の failing 有無、未解決スレッド件数、変更内容からテストの要否を機械的に判定する

## 注意事項

- 出力はあくまで人間のレビュー材料。PR 本文そのものを書き換える場合は、ユーザーに提示してから適用する（勝手に `gh pr edit` しない）
- コメント/レビューの取得結果は github-thread-fetcher のノイズ除外ルール（bot 除外・重複圧縮）をそのまま踏襲する
- diff が大きい場合、diff 全文を出力に含めず、要点のみ抽出する
