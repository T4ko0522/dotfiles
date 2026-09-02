---
name: github-thread-fetcher
description: GitHub の Issue / PR にある本文・コメント・レビュースレッド・CI 失敗・リンク済み Issue を gh CLI 経由で取得し、通常コメントとレビューコメントを分けて整理する。未解決の会話のみ抽出したり、bot コメント・重複を除外したりできる。「このPRについたコメントを取得して」「issue 12 の議論をまとめて」「remoteのPRコメント見て未対応だけ出して」「このレビューコメントの対応方針を出して」等、Issue/PR のリモート会話を取得・整理する依頼で起動。pr-summarizer から内部的に呼び出されることもある。
---

# GitHub Thread Fetcher Skill

GitHub 上の Issue / PR の「会話全体」を `gh` CLI で取得し、読みやすく整理する。素の `gh` 出力は本文・コメント・レビューが別々の場所に散らばるため、このスキルが一箇所にまとめる。

## 前提

- `gh auth status` で認証済みであること。未認証なら `gh auth login`（repo スコープ）を案内してから止める
- リポジトリは `gh` がカレントディレクトリの remote から解決する。別リポジトリを指す URL が渡された場合はそちらを優先する

## Input 解決

1. ユーザー入力が URL (`https://github.com/<owner>/<repo>/issues/<n>` or `.../pull/<n>`) ならそこから owner/repo/number/type を切り出す
2. 番号のみの指定（例: 「issue 12」「PR #45」）ならカレントリポジトリ + 指定 type として扱う
3. 何も指定がなければ、カレントブランチに紐づく PR を `gh pr view --json number,url` で解決する。Issue/PR どちらか不明な場合はユーザーに確認する

## 取得対象と手順

### 1. Issue の場合

```bash
gh issue view <number> --json title,body,author,state,labels,comments,url
```

- `comments` に本文コメントの配列が入る（レビュースレッドは無いので Issue はこれで十分）

### 2. PR の場合

```bash
# 本文・メタデータ・conversation コメント
gh pr view <number> --json title,body,author,state,baseRefName,headRefName,reviewDecision,comments,reviews,files,commits,statusCheckRollup,url

# レビューコメント（行コメント）の生データ。scope や in_reply_to_id を持つ
gh api repos/{owner}/{repo}/pulls/<number>/comments --paginate
```

- `gh pr view --json` の `comments` = PR 会話タブの通常コメント
- `gh pr view --json` の `reviews` = レビューの承認/変更要求と本文（行コメントは含まない）
- `gh api .../pulls/<number>/comments` = 行レベルのレビューコメント（スレッドの一次データ）

### 3. レビュースレッドの解決済み/未解決を判定する（GraphQL 必須）

REST API には `isResolved` が無いため、未解決コメントの抽出には GraphQL を使う。

```bash
gh api graphql -f query='
query($owner: String!, $repo: String!, $number: Int!) {
  repository(owner: $owner, name: $repo) {
    pullRequest(number: $number) {
      reviewThreads(first: 100) {
        nodes {
          isResolved
          isOutdated
          path
          line
          comments(first: 50) {
            nodes { author { login } body createdAt url }
          }
        }
      }
      closingIssuesReferences(first: 20) {
        nodes { number title url state }
      }
    }
  }
}' -f owner=<owner> -f repo=<repo> -F number=<number>
```

- `reviewThreads.nodes[].isResolved` で未解決スレッドだけ絞り込める
- `closingIssuesReferences` で「linked issues」（`Closes #n` 等で紐づく Issue）を同時に取得できる

### 4. CI / checks の失敗要約

```bash
gh pr checks <number> --json name,state,bucket,link,workflow,startedAt,completedAt
```

- `state != SUCCESS` のものだけ抽出し、GitHub Actions の run なら `gh run view <run_id> --log-failed` で失敗ログの要点を添える
- GitHub Actions 以外（Buildkite 等）は URL のみ報告し、ログ取得は行わない（gh-fix-ci skill と同じ方針）

## 整理のルール

1. **通常コメントとレビューコメントを分ける**: `comments`（会話タブ）と `reviewThreads`（行コメント）を別セクションに出す
2. **未解決の抽出**: `isResolved: false` のスレッドのみ「対応待ち」として一覧化する。解決済みは件数のみ添える
3. **bot / ノイズ除外**: `author.login` が `[bot]` で終わるもの（`github-actions[bot]`, `dependabot[bot]`, `codecov[bot]`, `vercel[bot]` 等）や CI の自動投稿コメントは既定で除外する。ユーザーが「bot コメントも見せて」と言った場合のみ含める
4. **重複除外**: 同一 body・同一 author の連続投稿（force-push 後の再通知等）はまとめて 1 件に圧縮する
5. **「誰が何を要求しているか」への要約**: 未解決コメントは `author: 要求内容（該当ファイル:行）` の形式で 1 行に要約する。元コメントが長い場合は要点のみ抜き出し、原文が必要なら URL を添える

## 出力フォーマット

```markdown
## Issue/PR #<number>: <title>

## 本文
<body の要約 or 原文>

## 会話コメント (<件数>, bot <除外件数> 件を除外)
- <author>: <要約>

## レビュースレッド
### 未対応 (<件数>)
- `<path>:<line>` <author>: <要求内容> ([原文]<url>)

### 解決済み (<件数> 件、詳細省略)

## CI / checks
- ❌ <check name>: <失敗要点> ([ログ]<url>)
- ✅ 成功 <件数> 件

## リンク済み Issue
- #<number> <title> (<state>)
```

## 注意事項

- 認証済みリポジトリ外を勝手に操作しない。`gh api` の owner/repo はユーザーが指定した対象のみに限定する
- 大量コメントがある場合は `--paginate` を使い、取りこぼしを黙って切り捨てない（件数が多すぎる場合はその旨を明記する）
- コメント内容を要約する際、ニュアンス（強い要求か軽い提案か）を勝手に強めたり弱めたりしない
