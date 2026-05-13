# Agent Teams — マルチエージェント協調パイプライン

[wasabeef 氏のブログ記事](https://wasabeef.jp/blog/claude-code-agent-teams) に着想を得たエージェントチーム構成。
複数のサブエージェントが探索 → 計画 → 実装 → レビュー → 監査の各フェーズを分担し、
Opus / Sonnet / Codex CLI を組み合わせて二重レビューを行う。

---

## トリガー

ユーザー入力に「**チームで**」が含まれる場合に本パイプラインを起動する。

例:
- 「チームで gemini API 対応を実装して」
- 「チームでこのリファクタリングをレビューして」
- 「チームでパフォーマンス改善を進めて」

`/team <task>` のスラッシュコマンド経由でも同等の挙動とする。
キーワードを含まない通常依頼では、従来どおりオーケストレーター (メイン Claude) が単独で処理する。

---

## パイプライン全体図

```
Phase 0  初期化 (キックオフ)
   ├── docs/plans/YYYY-MM-DD-<slug>/ を作成
   ├── 0_brief.md にユーザー要求を要約
   └── 受入条件を 0_acceptance.md に列挙
        │
        ▼
Phase 1  探索 (並列なし / 高速)
   └── explorer        [sonnet]      → 1_explore.md
        │
        ▼
Phase 2  計画 + 計画レビュー
   ├── planner         [opus]        → 2_plan.md
   └── plan-reviewer   [sonnet→codex]→ reviews/2_plan.codex.md
        │
        ▼  ★ User Gate (計画確定をユーザーに確認)
        ▼
Phase 3  実装 / テスト / ドキュメント (並列)
   ├── implementer     [sonnet]      → 3_impl.md  + コード差分
   ├── tester          [sonnet]      → 3_test.md  + テスト差分
   └── doc-writer      [sonnet]      → 3_doc.md   (構成案は並列、最終反映は 3_impl.md 後)
        │
        ▼
Phase 3R レビュー (各成果物を Opus + Codex で二重レビュー / 並列)
   ├── impl-reviewer-opus   [opus]   → reviews/3_impl.opus.md
   ├── impl-reviewer-codex  [sonnet] → reviews/3_impl.codex.md
   ├── test-reviewer-opus   [opus]   → reviews/3_test.opus.md
   ├── test-reviewer-codex  [sonnet] → reviews/3_test.codex.md
   ├── doc-reviewer-opus    [opus]   → reviews/3_doc.opus.md
   └── doc-reviewer-codex   [sonnet] → reviews/3_doc.codex.md
        │
        ▼
Phase 4  仕上げ監査 (必要に応じて並列)
   ├── security-opus   [opus]        → reviews/4_security.opus.md
   ├── security-codex  [sonnet]      → reviews/4_security.codex.md
   ├── performance     [sonnet]      → 4_performance.md
   └── doc-auditor     [sonnet]      → reviews/4_doc-audit.md
        │
        ▼
Phase 5  統合 (オーケストレーター責務)
   ├── 全レビューを集約し BLOCKER / MUST / NICE で分類
   ├── BLOCKER は最大 2 回まで該当 Phase へリトライ
   └── 5_final.md に最終サマリと未対応事項を記録

オンデマンド:
  analyzer   [opus]   ← バグ調査・障害分析・5 Whys 用 / 任意フェーズで挿入
```

---

## エージェント一覧

### 作業系 (7)
| Agent          | Model  | 役割                                  |
| -------------- | ------ | ------------------------------------- |
| `explorer`     | sonnet | コードベース探索・現状把握            |
| `planner`      | opus   | 仕様策定と実装計画                    |
| `implementer`  | sonnet | コード実装                            |
| `tester`       | sonnet | テスト設計・実行                      |
| `doc-writer`   | sonnet | ドキュメント作成                      |
| `doc-auditor`  | sonnet | 既存ドキュメントの整合性監査          |
| `performance`  | sonnet | パフォーマンス分析・改善提案          |

### レビュー系 (9) — 二重レビュー (Opus と Codex は同期しない)
| Agent                  | Claude Model | 外部レビュー | レビュー対象              |
| ---------------------- | ------------ | ------------ | ------------------------- |
| `plan-reviewer`        | sonnet       | Codex CLI    | 計画 (Opus に対する独立票) |
| `impl-reviewer-opus`   | opus         | なし         | 実装                       |
| `impl-reviewer-codex`  | sonnet       | Codex CLI    | 実装                       |
| `test-reviewer-opus`   | opus         | なし         | テスト                     |
| `test-reviewer-codex`  | sonnet       | Codex CLI    | テスト                     |
| `doc-reviewer-opus`    | opus         | なし         | ドキュメント               |
| `doc-reviewer-codex`   | sonnet       | Codex CLI    | ドキュメント               |
| `security-opus`        | opus         | なし         | セキュリティ監査           |
| `security-codex`       | sonnet       | Codex CLI    | セキュリティ監査           |

### オンデマンド (1)
| Agent      | Model | 役割                          |
| ---------- | ----- | ----------------------------- |
| `analyzer` | opus  | 根本原因分析・5 Whys・障害切分 |

> **二重レビューの方針**: planner が Opus のため `plan-reviewer` は Codex 単独。
> 実装/テスト/ドキュメント/セキュリティは Opus と Codex の両方からレビューを取り、
> 観点の偏りを抑える。

---

## 成果物配置

すべての成果物は **`docs/plans/YYYY-MM-DD-<slug>/`** 配下に集約する。

```
docs/plans/2026-05-13-gemini-support/
├── 0_brief.md             ← ユーザー要求の要約
├── 0_acceptance.md        ← 受入条件
├── 1_explore.md           ← explorer
├── 2_plan.md              ← planner
├── 3_impl.md              ← implementer のメモ
├── 3_test.md              ← tester のメモ
├── 3_doc.md               ← doc-writer のメモ
├── 4_performance.md       ← performance
├── 5_final.md             ← 統合サマリ
└── reviews/
    ├── 2_plan.codex.md
    ├── 3_impl.opus.md
    ├── 3_impl.codex.md
    ├── 3_test.opus.md
    ├── 3_test.codex.md
    ├── 3_doc.opus.md
    ├── 3_doc.codex.md
    ├── 4_security.opus.md
    ├── 4_security.codex.md
    └── 4_doc-audit.md
```

`<slug>` は kebab-case でユーザー要求から導出する (例: `gemini-support`, `perf-tune-router`)。

---

## 共通規約 (全エージェントに適用)

1. **言語**: すべての出力は日本語。コード内コメントも原則日本語。
2. **成果物**: 上記ディレクトリ規約に従ってファイルを作成・更新。
3. **再呼び出し**: 同種のエージェントを 2 回目以降呼ぶ際は、可能なら `SendMessage` で既存 agentId に対して再依頼する。`SendMessage` が使えない実行環境では同じ agent を新規起動し、過去成果物ファイルを明示的に読ませる。
4. **逸脱通知**: 依頼範囲外の問題を見つけたら成果物末尾の `## 補足` セクションに記録する。勝手に修正しない。
5. **判定キーワード**: レビュー系は所見を必ず以下のいずれかに分類する。
   - `BLOCKER` — マージ阻害。リトライ対象。
   - `MUST`    — マージ前に対応すべき。
   - `NICE`    — 望ましいが任意。
6. **2 ループ上限**: BLOCKER 起因のリトライは最大 2 回。3 回目に達したらユーザーへエスカレーション。

---

## Codex CLI 連携

Codex 系レビュー (`*-codex`, `plan-reviewer`, `security-codex`) は **Sonnet がオーケストレーター** となり、
`codex exec` を Bash 経由で呼び出して GPT-5 系モデルの所見を取得する。

```bash
if command -v codex >/dev/null 2>&1; then
  CODEX_BIN=codex
elif command -v codex.exe >/dev/null 2>&1; then
  CODEX_BIN=codex.exe
elif command -v where.exe >/dev/null 2>&1 && where.exe codex >/dev/null 2>&1; then
  CODEX_BIN=codex
else
  CODEX_BIN=
fi

if [ -z "$CODEX_BIN" ]; then
  cat > docs/plans/<slug>/reviews/3_impl.codex.md <<'MARKDOWN'
# Impl Review (Codex)
Codex CLI 未導入のためスキップ。
MARKDOWN
  exit 0
fi

{
  cat <<'PROMPT'
以下は実装メモと受入条件です。

---3_impl.md---
PROMPT
  cat docs/plans/<slug>/3_impl.md
  cat <<'PROMPT'

---0_acceptance.md---
PROMPT
  cat docs/plans/<slug>/0_acceptance.md
  cat <<'PROMPT'

上記の計画と実装メモをレビューせよ。BLOCKER/MUST/NICE で分類し日本語で出力。
PROMPT
} | "$CODEX_BIN" exec --model gpt-5-codex --skip-git-repo-check -
```

`codex` / `codex.exe` 不在時は、Codex 系エージェントは冒頭で可用性を確認し、
不在時は `reviews/*.codex.md` に「Codex 未導入のためスキップ」と明記して終了する。

> Codex 出力をそのまま貼り付ける際は、観点を要約した「日本語の要旨」も先頭に付与する。

---

## オーケストレーター (メイン Claude) の責務

1. **トリガー判定**: 「チームで」を検知したら本パイプラインを起動。
2. **Phase 0 初期化**: スラッグ決定 → ディレクトリ作成 → `0_brief.md` / `0_acceptance.md` 記述。
3. **エージェント呼び出し**: `Agent` ツールで `subagent_type` を指定。並列可能な Phase はマルチ tool call で同時起動。
4. **ユーザーゲート**: Phase 2 終了時に計画と Codex レビュー要旨を提示し、承認を得てから Phase 3 へ進む。
5. **統合**: 各レビューを集約。BLOCKER があれば該当 Phase をリトライする。`SendMessage` が使える場合は同 agentId に再依頼し、使えない場合は同じ agent を新規起動して過去成果物を読み込ませる。
6. **完了**: `5_final.md` を生成し、ユーザーに変更差分と未対応事項を簡潔に報告する。

---

## 起動例

```
User: チームで Gemini API クライアントを追加して。
       受入条件は (1) 既存 OpenAI クライアントと同インタフェース (2) ストリーミング対応。

Claude: スラッグを gemini-client とし Phase 0 を開始します。
        → docs/plans/2026-05-13-gemini-client/ を作成
        → explorer を起動
        ...
```
