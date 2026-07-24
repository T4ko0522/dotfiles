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
   └── at-explorer        [sonnet]      → 1_explore.md
        │
        ▼
Phase 2  計画 + 計画レビュー
   ├── at-planner         [opus]        → 2_plan.md
   └── at-plan-reviewer   [sonnet→codex]→ reviews/2_plan.codex.md
        │
        ▼  ★ User Gate (計画確定をユーザーに確認)
        ▼
Phase 3  実装 / テスト / ドキュメント (並列、ただし contract → red → green は順序遵守)
   ├── at-implementer     [sonnet]      → 3_contract.md (型/シグネチャ先出し)
   │                                 → 3_impl.md  + コード差分 (Red 確認後に Green 実装)
   ├── at-tester          [sonnet]      → 3_test.md  + テスト差分 (3_contract.md を元に Red 着手)
   └── at-doc-writer      [sonnet]      → 3_doc.md   (構成案は並列、最終反映は 3_impl.md 後)
        │
        ▼
Phase 3R レビュー (各成果物を Opus + Codex で二重レビュー / 並列)
   ├── at-impl-reviewer-opus   [opus]   → reviews/3_impl.opus.md
   ├── at-impl-reviewer-codex  [sonnet] → reviews/3_impl.codex.md
   ├── at-test-reviewer-opus   [opus]   → reviews/3_test.opus.md
   ├── at-test-reviewer-codex  [sonnet] → reviews/3_test.codex.md
   ├── at-doc-reviewer-opus    [opus]   → reviews/3_doc.opus.md
   └── at-doc-reviewer-codex   [sonnet] → reviews/3_doc.codex.md
        │
        ▼
Phase 4  仕上げ監査 (必要に応じて並列)
   ├── at-security-opus   [opus]        → reviews/4_security.opus.md
   ├── at-security-codex  [sonnet]      → reviews/4_security.codex.md
   ├── at-performance     [sonnet]      → 4_performance.md
   └── at-doc-auditor     [sonnet]      → reviews/4_doc-audit.md
        │
        ▼
Phase 5  統合 (オーケストレーター責務)
   ├── 全レビューを集約し BLOCKER / MUST / NICE で分類
   ├── BLOCKER は最大 2 回まで該当 Phase へリトライ
   └── 5_final.md に最終サマリと未対応事項を記録

オンデマンド:
  at-analyzer   [opus]   ← バグ調査・障害分析・5 Whys 用 / 任意フェーズで挿入
```

---

## エージェント一覧

### 作業系 (7)

| Agent          | Model  | 役割                                  |
| -------------- | ------ | ------------------------------------- |
| `at-explorer`     | sonnet | コードベース探索・現状把握            |
| `at-planner`      | opus   | 仕様策定と実装計画                    |
| `at-implementer`  | sonnet | コード実装                            |
| `at-tester`       | sonnet | テスト設計・実行                      |
| `at-doc-writer`   | sonnet | ドキュメント作成                      |
| `at-doc-auditor`  | sonnet | 既存ドキュメントの整合性監査          |
| `at-performance`  | sonnet | パフォーマンス分析・改善提案          |

### レビュー系 (9) — 二重レビュー (Opus と Codex は同期しない)

| Agent                  | Claude Model | 外部レビュー | レビュー対象              |
| ---------------------- | ------------ | ------------ | ------------------------- |
| `at-plan-reviewer`        | sonnet       | Codex CLI    | 計画 (Opus に対する独立票) |
| `at-impl-reviewer-opus`   | opus         | なし         | 実装                       |
| `at-impl-reviewer-codex`  | sonnet       | Codex CLI    | 実装                       |
| `at-test-reviewer-opus`   | opus         | なし         | テスト                     |
| `at-test-reviewer-codex`  | sonnet       | Codex CLI    | テスト                     |
| `at-doc-reviewer-opus`    | opus         | なし         | ドキュメント               |
| `at-doc-reviewer-codex`   | sonnet       | Codex CLI    | ドキュメント               |
| `at-security-opus`        | opus         | なし         | セキュリティ監査           |
| `at-security-codex`       | sonnet       | Codex CLI    | セキュリティ監査           |

### オンデマンド (1)

| Agent      | Model | 役割                          |
| ---------- | ----- | ----------------------------- |
| `at-analyzer` | opus  | 根本原因分析・5 Whys・障害切分 |

> **二重レビューの方針**: at-planner が Opus のため `at-plan-reviewer` は Codex 単独。
> 実装/テスト/ドキュメント/セキュリティは Opus と Codex の両方からレビューを取り、
> 観点の偏りを抑える。

### 補足: tool-pipeline スキル用エージェント (4)

以下の 4 つは Agent Teams パイプラインの一部ではなく、**`tool-pipeline` スキル**（Go / TypeScript / ShellScript 限定の軽量開発パイプライン）から呼び出される独立した subagent。
ディレクトリの都合で同じ `agents/` 配下に置かれているが、Agent Teams のフェーズには登場しない。

| Agent                  | Model  | 役割                                          |
| ---------------------- | ------ | --------------------------------------------- |
| `tp-requirements-analyst` | sonnet | tool-pipeline Phase 1: 要件定義の構造化         |
| `tp-system-designer`      | opus   | tool-pipeline Phase 2a: コードレベルの設計書    |
| `tp-qa-architect`         | sonnet | tool-pipeline Phase 2b: QA 計画・品質チェック計画 |
| `tp-task-decomposer`      | sonnet | tool-pipeline Phase 3: Codex 向けタスク分解     |

詳細は `~/.claude/skills/tool-pipeline/SKILL.md` を参照。

---

## 成果物配置

すべての成果物は **`docs/plans/YYYY-MM-DD-<slug>/`** 配下に集約する。

```
docs/plans/2026-05-13-gemini-support/
├── 0_brief.md             ← ユーザー要求の要約
├── 0_acceptance.md        ← 受入条件
├── 1_explore.md           ← at-explorer
├── 2_plan.md              ← at-planner
├── 3_contract.md          ← at-implementer (型 / シグネチャ / エラー型 — at-tester が Red を書くための入力)
├── 3_impl.md              ← at-implementer のメモ
├── 3_test.md              ← at-tester のメモ
├── 3_doc.md               ← at-doc-writer のメモ
├── 4_performance.md       ← at-performance
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

Codex 系レビュー (`*-codex`, `at-plan-reviewer`, `at-security-codex`) は **Sonnet がオーケストレーター** となり、
`codex exec` を Bash 経由で呼び出して GPT-5 系モデルの所見を取得する。

### SLUG 受け渡し規約

オーケストレーターは Codex 系 reviewer を起動するとき、プロンプト内で **SLUG を明示する**。
サブエージェントは Bash の最初で受け取った値を変数に代入し、`<slug>` をリテラル展開しない。

```
オーケストレーター → reviewer プロンプト例:
  SLUG=2026-05-13-gemini-client
  以下を実行: ...
```

### 共通テンプレート

```bash
# --- 1. 入力受け取り (必須) ----------------------------------
SLUG="${SLUG:?SLUG is required (orchestrator must pass it)}"
PLAN_DIR="docs/plans/$SLUG"
REVIEWS_DIR="$PLAN_DIR/reviews"
mkdir -p "$REVIEWS_DIR"

# --- 2. Codex CLI 検出 ---------------------------------------
if command -v codex >/dev/null 2>&1; then
  CODEX_BIN=codex
elif command -v codex.exe >/dev/null 2>&1; then
  CODEX_BIN=codex.exe
elif command -v where.exe >/dev/null 2>&1 && where.exe codex >/dev/null 2>&1; then
  CODEX_BIN=codex
else
  CODEX_BIN=
fi

OUT="$REVIEWS_DIR/3_impl.codex.md"

if [ -z "$CODEX_BIN" ]; then
  cat > "$OUT" <<'MARKDOWN'
# Impl Review (Codex)

Status: SKIPPED
Reason: codex CLI not found
Risk: independent second review was not performed (DEGRADED)
MARKDOWN
  exit 0
fi

# --- 3. 外部送信前 preflight ---------------------------------
# secrets / credentials / private data を Codex に渡す前に必ず確認する。
# 詳細は「Codex 外部送信 preflight」セクション参照。

# --- 4. Codex 実行 -------------------------------------------
RAW="$(mktemp)"
{
  cat <<'PROMPT'
以下は実装メモと受入条件です。

---3_impl.md---
PROMPT
  cat "$PLAN_DIR/3_impl.md"
  cat <<'PROMPT'

---0_acceptance.md---
PROMPT
  cat "$PLAN_DIR/0_acceptance.md"
  cat <<'PROMPT'

上記の計画と実装メモをレビューせよ。BLOCKER/MUST/NICE で分類し日本語で出力。
PROMPT
} | "$CODEX_BIN" exec \
      --model gpt-5.5 \
      -c model_reasoning_effort="medium" \
      --sandbox read-only \
      --skip-git-repo-check \
      --output-last-message "$RAW" \
      -

# --- 5. 結果保存 ---------------------------------------------
{
  echo "# Impl Review (Codex)"
  echo
  echo "## 要旨"
  echo "- BLOCKER / MUST / NICE はオーケストレーターが集計"
  echo
  echo "## Codex output"
  cat "$RAW"
} > "$OUT"
rm -f "$RAW"
```

`codex` / `codex.exe` 不在時は、Codex 系エージェントは冒頭で可用性を確認し、
不在時は `reviews/*.codex.md` に「Codex 未導入のためスキップ (DEGRADED)」と明記して終了する。

> Codex 出力をそのまま貼り付ける際は、観点を要約した「日本語の要旨」も先頭に付与する。

---

## Codex 外部送信 preflight

Codex 系 reviewer は `git diff`、実装メモ、依存マニフェストを `codex exec` 経由で
**外部 (Codex CLI 上の OpenAI モデル) に送信** する。以下を必ず確認する。

1. **シークレット混入**: `git diff` 内に API キー / トークン / 秘密鍵 / パスワードが含まれないこと
   (`grep -E 'AKIA|sk-|ghp_|xox[bp]-|-----BEGIN'` などで事前スキャン)
2. **`.env` / `credentials.*` / `*.pem` / `*.key`**: これらのパスが diff に出ていたら **Codex に渡さない**
3. **顧客データ / 本番ログ / 個人情報**: 含まれる場合はユーザー許可を得るかスキップ
4. **private / confidential リポジトリ**: 外部送信して良いか不明な場合はスキップし、`reviews/*.codex.md` に
   `Status: SKIPPED (privacy)` と明記
5. **巨大ロックファイル** (`package-lock.json`, `pnpm-lock.yaml`, `Cargo.lock`, `uv.lock` など) は
   `--stat` のみ送るか、`name-only` での依存変更検出に留める

判定に迷う場合は **オーケストレーターにエスカレーション** し、勝手に送信しない。

---

## オーケストレーター (メイン Claude) の責務

1. **トリガー判定**: 「チームで」を検知したら本パイプラインを起動。
2. **Phase 0 初期化**: スラッグ決定 → ディレクトリ作成 → `0_brief.md` / `0_acceptance.md` 記述。
3. **エージェント呼び出し**: `Agent` ツールで `subagent_type` を指定。並列可能な Phase はマルチ tool call で同時起動。
4. **ユーザーゲート**: Phase 2 終了時に計画と Codex レビュー要旨を提示し、承認を得てから Phase 3 へ進む。
5. **統合**: 各レビューを集約。BLOCKER があれば該当 Phase をリトライする。`SendMessage` が使える場合は同 agentId に再依頼し、使えない場合は同じ agent を新規起動して過去成果物を読み込ませる。
6. **完了**: `5_final.md` を生成し、ユーザーに変更差分と未対応事項を簡潔に報告する。

---

## `5_final.md` フォーマット (必須項目)

Phase 5 でオーケストレーターが生成する統合レポート。Codex 系 reviewer がスキップされた場合や
Opus/Codex どちらかが欠落した場合は、**冒頭の Review mode 表で DEGRADED を明示**する。

```markdown
# Final Summary — <slug>

## Review mode
| Reviewer            | Status    | Reason                |
| ------------------- | --------- | --------------------- |
| at-plan-reviewer       | completed | -                     |
| at-impl-reviewer-opus  | completed | -                     |
| at-impl-reviewer-codex | SKIPPED   | codex CLI not found   |
| at-test-reviewer-opus  | completed | -                     |
| at-test-reviewer-codex | SKIPPED   | codex CLI not found   |
| at-doc-reviewer-opus   | completed | -                     |
| at-doc-reviewer-codex  | SKIPPED   | codex CLI not found   |
| at-security-opus       | completed | -                     |
| at-security-codex      | SKIPPED   | secrets in preflight  |
| at-performance         | completed | -                     |
| at-doc-auditor         | skipped   | not required          |

## Mode 判定
- Full review (Opus + Codex 二重): あり
- DEGRADED (片系統のみ): impl / test / doc / security
- 主要リスク: 独立した二票化が機能しなかった成果物では片寄りの可能性

## 集約結果
- BLOCKER: N 件 (すべて対応済 / 残 N 件)
- MUST: N 件 (対応 N 件 / 残 N 件)
- NICE: N 件 (将来課題)

## 変更差分サマリ
- 主要な変更ファイルと意図 (3〜7 行)

## 未対応事項 / 残課題
- ...

## リトライ履歴
- Phase 3R で BLOCKER 検出 → at-implementer 再起動 (1 回目)
- Phase 4 で BLOCKER 検出 → security レビュー再取得 (該当時)
```

**ルール**:

- 一つでも `SKIPPED` がある場合は `## Mode 判定` で **DEGRADED** と明記する。
- `DEGRADED` の理由は Reason 列にできるだけ具体的に書く (`codex CLI not found`, `secrets in preflight`, `privacy` など)。
- BLOCKER がリトライ上限 (2 回) に達した場合はステータスを `BLOCKER_REMAINING` とし、ユーザーへエスカレーションを明記する。

---

## 起動例

```
User: チームで Gemini API クライアントを追加して。
       受入条件は (1) 既存 OpenAI クライアントと同インタフェース (2) ストリーミング対応。

Claude: スラッグを gemini-client とし Phase 0 を開始します。
        → docs/plans/2026-05-13-gemini-client/ を作成
        → at-explorer を起動
        ...
```
