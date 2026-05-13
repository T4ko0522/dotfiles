---
name: team
description: マルチエージェントパイプライン (Agent Teams) を起動する。ユーザー入力に「チームで」が含まれる、または `/team <task>` 形式で明示された場合に発火する。Phase 0〜5 で at-explorer / at-planner / at-implementer / at-tester / at-doc-writer / reviewers を協調動作させ、Opus と Codex の二重レビューで成果物を仕上げる。
---

# Agent Teams

`~/.claude/agents/README.md` に定義された Agent Teams パイプラインを起動する。

ユーザー要求が `/team <task>` の形式で与えられた場合は `<task>` をそのまま要求として扱う。
「チームで」を含む自由文の場合は文全体から要求を抽出する。

## 実行手順

1. **Phase 0**: スラッグを決め、`docs/plans/YYYY-MM-DD-<slug>/` を作成する。
2. `0_brief.md` にユーザー要求を要約し、`0_acceptance.md` に受入条件を列挙する。
3. **Phase 1**: `at-explorer` を起動して `1_explore.md` を取得する。
4. **Phase 2**: `at-planner` で `2_plan.md` を作成し、`at-plan-reviewer` で `reviews/2_plan.codex.md` を取得する。
5. 計画とレビュー要旨をユーザーに提示し、承認を得てから Phase 3 へ進む (**User Gate**)。
6. **Phase 3**: `at-implementer` / `at-tester` / `at-doc-writer` を並列で起動する。
   `at-doc-writer` は計画ベースの構成案を先に作り、実ドキュメントへの最終反映は `3_impl.md` 完了後に行う。
7. **Phase 3R**: 各成果物に対し `*-reviewer-opus` と `*-reviewer-codex` を並列で起動する。
8. **Phase 4**: 必要に応じて `at-security-opus` / `at-security-codex` / `at-performance` / `at-doc-auditor` を並列で起動する。
9. **Phase 5**: レビューを集約し、`5_final.md` に最終サマリと未対応事項を記録する。

## リトライ規約

- BLOCKER 起因のリトライは最大 2 回までとする。
- 再依頼は可能なら `SendMessage` で同 agentId に渡す。
- 同 agentId 維持が使えない実行環境では、同じ agent を新規起動し、過去成果物ファイル (`docs/plans/<slug>/` 配下) を明示的に Read させる。

## 出力規約

- すべてのエージェント出力は日本語。
- 成果物は `docs/plans/<slug>/` 配下に集約 (詳細は `~/.claude/agents/README.md` 参照)。
- レビュー判定キーワードは `BLOCKER` / `MUST` / `NICE` の三択で統一する。
