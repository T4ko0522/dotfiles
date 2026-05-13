---
name: tool-pipeline
description: Go/TypeScript/ShellScript 限定の軽量開発パイプライン。要件 → 設計 → タスク分解 → Codex 実装 → 品質チェックを Auto Gate で自動進行し、BLOCKER 検出時のみ最大 2 回フィードバックループ。「ツールパイプライン実行」「/tool-pipeline」「Go でツール作って」「シェルスクリプト実装して」等で起動。設計フェーズのみ Opus、それ以外は Sonnet/Haiku/Codex で高速に回す。
---

# Tool Pipeline — Go / TypeScript / ShellScript 向け軽量開発パイプライン

## 概要

```
Phase 1: 要件定義         [requirements-analyst / sonnet]
    ↓
  ★ Auto Gate 1: 要確認マーカーチェック（自動通過、人間承認なし）
    ↓
Phase 2（並列）:
  ├── 2a: 設計            [system-designer / opus]
  └── 2b: QA 計画         [qa-architect / sonnet]
    ↓
  ★ Auto Gate 2: 成果物確認（自動通過）
    ↓
Phase 3: タスク分解       [task-decomposer / sonnet]
    ↓
Phase 4: Codex 実装       [codex:rescue / GPT-5.4]
    ↓
Phase 5: 品質チェック     [codex:rescue / GPT-5.4]
    ↓
  ★ Auto Gate 3: BLOCKER 判定
    ├── BLOCKER なし → 完了報告
    └── BLOCKER あり → フィードバックループ（最大 2 回）
          └── 原因分類で戻り先決定:
                要件起因  → Phase 1
                設計起因  → Phase 2a
                実装起因  → Phase 4
```

**Gate は自動通過（人間の承認不要）**。フィードバックループは BLOCKER がある場合のみ発動し、最大 2 回で打ち切る。

---

## 依存

### スキルディレクトリ構成

```
$SKILL_DIR/
├── SKILL.md                       ← この文書
├── agents/
│   ├── requirements-analyst.md    ← Phase 1 用エージェント定義
│   ├── system-designer.md         ← Phase 2a 用
│   ├── qa-architect.md            ← Phase 2b 用
│   └── task-decomposer.md         ← Phase 3 用
└── references/
    ├── artifact-templates.md      ← 6 ファイル分のテンプレート集約
    └── tui-guidelines.md          ← Go TUI 開発規約（任意）
```

各エージェントは Claude Code のサブエージェントとして `Agent` ツールから `subagent_type` に指定して呼び出す。エージェント定義の実体は `$SKILL_DIR/agents/*.md`。

### 外部依存

| 依存 | 種別 | 用途 | 必須/任意 |
|------|------|------|----------|
| `/codex:rescue` | スラッシュコマンド | Phase 4 / 5 の実装・品質チェック委譲 | **必須** |
| `new-tui-tool` | スキル | Go TUI 新規ツールの雛形生成 | 任意（Go TUI 時のみ） |
| `/tui-check` | スラッシュコマンド | 全 TUI ツールのガイドライン準拠確認 | 任意 |
| `go-tui-reviewer` | エージェント | Go TUI アーキテクチャレビュー | 任意 |

「任意」依存は Go TUI 開発時のみ使用。未導入でもパイプライン本体は動作する。

### 失敗モード

| 状況 | 挙動 |
|------|------|
| `/codex:rescue` 未導入 | Phase 4 開始時に検知して停止、導入を促す |
| エージェント定義ファイル欠落 | Phase 開始時に Read で検知して停止 |
| Agent タイムアウト / 失敗 | 同 Phase を 1 回だけリトライ、再失敗で停止 |
| Phase 2 並列タスクの片方失敗 | もう一方の完了を待ち、両方の結果を見て続行可否を判定 |

---

## 技術スタック制約

**このパイプラインで使用できる言語は以下の 3 つのみ**:

- **Go** — CLI ツール、デーモン、バイナリ配布が必要なもの
  - TUI を開発する場合は以下のライブラリを使用すること（他の TUI ライブラリは禁止）:
    - `github.com/charmbracelet/bubbletea` — TUI フレームワーク（Elm アーキテクチャ）
    - `github.com/charmbracelet/lipgloss` — スタイリング
  - TUI を含む場合は `$SKILL_DIR/references/tui-guidelines.md` を Read し、
    カラーパレット・スタイル・キーバインド規約に従うこと
  - 新規 TUI ツールの雛形生成は `new-tui-tool` スキルを使用する
- **TypeScript** — Node.js ベースのスクリプト、ウェブツール
- **ShellScript** — 軽量な自動化、既存コマンドの組み合わせ（POSIX sh / bash 前提、PowerShell は対象外）

各フェーズのエージェントへの指示に必ずこの制約を含める。

---

## セットアップ

パイプライン開始時に以下を初期化する:

```
PROJECT_ROOT = pwd（カレントディレクトリ）
PIPELINE_DIR = $PROJECT_ROOT/docs/pipeline
SKILL_DIR    = $HOME/.claude/skills/tool-pipeline
loop_count   = 0
max_loops    = 2
```

### Step 0: 初期化

1. `$PIPELINE_DIR/feedback` を Bash で作成する:
   ```bash
   mkdir -p "$PROJECT_ROOT/docs/pipeline/feedback"
   ```

2. `$SKILL_DIR/references/artifact-templates.md` を Read し、`00-manifest.md` テンプレートを取得する

3. `$PIPELINE_DIR/00-manifest.md` を Write で生成する（実行日時、プロジェクトパスを記入）

4. ユーザーに要件のヒアリングを行う:
   ```
   ツールパイプラインを開始します。
   作りたいものの要件を教えてください。
   （概要、目的、Go / TypeScript / ShellScript のどれを使うか、制約があれば合わせて記載してください）
   ```
   ユーザーの回答を `user_requirements` として保持する。

---

## Phase 1: 要件定義

`requirements-analyst` エージェントを **sonnet** モデルで起動する。

```
Agent ツール呼び出し:
  subagent_type: requirements-analyst
  model: sonnet
  prompt: |
    以下のユーザー要件をもとに要件定義書を作成してください。

    【技術スタック制約】
    使用できる言語は Go / TypeScript / ShellScript のみです。
    他の言語・ランタイムは選択しないでください。

    【ユーザー要件】
    {user_requirements の内容}

    【プロジェクトルート】
    $PROJECT_ROOT

    【出力先】
    $PIPELINE_DIR/01-requirements.md

    【テンプレート参照】
    $SKILL_DIR/references/artifact-templates.md の「01-requirements.md」セクションを
    Read して、そのテンプレートに従って出力してください。

    【手順】
    1. プロジェクトルートを探索して既存コード・設定を把握する
    2. ユーザー要件を構造化する（機能要件・非機能要件・制約・前提条件）
    3. 技術スタックは Go / TypeScript / ShellScript の中から選定し、選定理由を記載する
    4. 曖昧な点は [推論] マーカー、確認が必要な点は [要確認] マーカーを付ける
    5. 出力先にファイルを Write する
```

**完了確認**: `$PIPELINE_DIR/01-requirements.md` が生成されたことを Read で確認する。
`00-manifest.md` の Phase 1 ステータスを更新する。

### Auto Gate 1

`01-requirements.md` を Read し、`[要確認]` マーカーの件数で分岐する。

| `[要確認]` 件数 | 挙動 |
|---|---|
| 0 件 | 自動的に Phase 2 へ進む |
| 1〜5 件 | マーカー箇所を列挙してユーザーに通知し、続行する（Gate 自動通過） |
| 6 件以上 | パイプラインを一時停止し、ユーザーに以下のいずれかを促す:<br>① マーカー箇所を確認し具体値を返答 → 取り込んで Phase 1 を再実行<br>② このまま続行を明示的に指示 → 続行 |

`[推論]` マーカーの件数は閾値判定の対象外（合理的仮定として扱う）。

requirements-analyst エージェントは `[要確認]` を抑えるよう指示済み（判断が本当に必要なときのみ `[要確認]`、合理的仮定で埋められるものは `[推論]` を使う）。

---

## Phase 2: 設計 & QA 計画（並列）

**2 つの Agent ツール呼び出しを同一メッセージ内で並列実行する。**

```
[並列 A] Agent ツール呼び出し:
  subagent_type: system-designer
  model: opus
  prompt: |
    要件定義書をもとにシステム設計書を作成してください。

    【技術スタック制約】
    使用できる言語は Go / TypeScript / ShellScript のみです。
    要件定義書で選定された言語を尊重し、そのエコシステム内で設計してください。
    他の言語・ランタイム・フレームワークは選択しないでください。
    Go で TUI を開発する場合は以下のみ使用すること:
    - github.com/charmbracelet/bubbletea（TUI フレームワーク）
    - github.com/charmbracelet/lipgloss（スタイリング）
    - TUI を含む設計の場合は $SKILL_DIR/references/tui-guidelines.md を Read し、
      カラーパレット・スタイル・キーバインド規約を設計書に反映すること

    【入力】
    $PIPELINE_DIR/01-requirements.md を Read してください。

    【プロジェクトルート】
    $PROJECT_ROOT

    【出力先】
    $PIPELINE_DIR/02-system-design.md

    【テンプレート参照】
    $SKILL_DIR/references/artifact-templates.md の「02-system-design.md」セクションを
    Read し、テンプレートに従ってください。

    【手順】
    1. 要件定義書を読み込む
    2. プロジェクトの既存コードを探索する
    3. 技術スタックは Go / TypeScript / ShellScript のいずれかに限定して確定する
    4. アーキテクチャ、コンポーネント、データモデル、CLI/API、エラーハンドリングを設計する
    5. Codex が参照するため、コードレベルの具体性を持たせる
    6. 設計判断を ADR 形式で記録する

[並列 B] Agent ツール呼び出し:
  subagent_type: qa-architect
  model: sonnet
  prompt: |
    要件定義書をもとに品質保証計画を作成してください。

    【技術スタック制約】
    使用できる言語は Go / TypeScript / ShellScript のみです。
    テストツール・静的解析ツールも該当言語のエコシステム内で選定してください。
    - Go: go test, golangci-lint, staticcheck
    - TypeScript: vitest / jest, eslint, tsc --noEmit
    - ShellScript: shellcheck, bats

    【入力】
    $PIPELINE_DIR/01-requirements.md を Read してください。

    【プロジェクトルート】
    $PROJECT_ROOT

    【出力先】
    $PIPELINE_DIR/03-qa-plan.md

    【テンプレート参照】
    $SKILL_DIR/references/artifact-templates.md の「03-qa-plan.md」セクションを
    Read し、テンプレートに従ってください。

    【手順】
    1. 要件定義書を読み込む
    2. 言語に対応したテストツール・静的解析ツールを選定する
    3. テスト戦略、品質基準、静的解析ルールを設計する
    4. Phase 5 で Codex が実行する品質チェックコマンド一覧を明示する
    5. PASS 条件は「BLOCKER 指摘ゼロ」とする
```

**完了確認**: 両ファイル (`02-system-design.md`, `03-qa-plan.md`) が生成されたことを Read で確認する。
`00-manifest.md` を更新する。

### Auto Gate 2

両ファイルの存在を Read で確認する。成果物が揃っていれば自動的に Phase 3 へ進む。

---

## Phase 3: タスク分解

`task-decomposer` エージェントを **sonnet** モデルで起動する。

```
Agent ツール呼び出し:
  subagent_type: task-decomposer
  model: sonnet
  prompt: |
    設計書と QA 計画をもとに、Codex が実装可能なタスクに分解してください。

    【技術スタック制約】
    使用できる言語は Go / TypeScript / ShellScript のみです。
    各タスクの実装指示もこの制約に従ってください。

    【入力】
    - $PIPELINE_DIR/02-system-design.md
    - $PIPELINE_DIR/03-qa-plan.md
    上記のファイルを Read してください。

    【プロジェクトルート】
    $PROJECT_ROOT

    【出力先】
    $PIPELINE_DIR/04-task-breakdown.md

    【テンプレート参照】
    $SKILL_DIR/references/artifact-templates.md の「04-task-breakdown.md」セクションを
    Read し、テンプレートに従ってください。

    【手順】
    1. 設計書と QA 計画を読み込む
    2. 基盤 → ドメイン → インフラ → ハンドラー → テスト の順でタスクを抽出
    3. 依存関係を整理し、並列実行可能なグループにまとめる
    4. 各タスクに「Codex への指示」を記載する（設計書の該当部分を抜粋・要約）
    5. 1 タスク = 1〜5 ファイルの変更が目安
```

**完了確認**: `$PIPELINE_DIR/04-task-breakdown.md` が生成されたことを確認する。
`00-manifest.md` を更新する。

---

## Phase 4: Codex 実装

`04-task-breakdown.md` を Read し、タスクグループごとに Codex に委譲する。

```
FOR EACH グループ（Group A, B, C...）:

  1. 04-task-breakdown.md からグループ内のタスクを抽出する
  2. 設計書の該当セクションを Read で取得する
  3. 以下のコマンドで Codex に委譲する:

  /codex:rescue
  以下のタスクグループを実装してください。

  【技術スタック制約】
  使用できる言語は Go / TypeScript / ShellScript のみです。
  他の言語・ランタイムは使用しないでください。

  【タスクグループ: {Group 名}】
  {グループ内の各タスクの詳細（Codex への指示フィールド）}

  【制約】
  - 設計書に従うこと（参照: $PIPELINE_DIR/02-system-design.md）
  - 各タスクの検証コマンドが PASS すること
  - 新規ファイルは設計書のディレクトリ構造に従って配置すること
  - テストも合わせて実装すること（QA 計画参照: $PIPELINE_DIR/03-qa-plan.md）
  - TUI を含む実装の場合は $SKILL_DIR/references/tui-guidelines.md を Read し、
    カラーパレット・スタイル・キーバインド規約に従うこと

  4. Codex の実行結果を確認する
  5. 次のグループに進む
```

すべてのグループ完了後、`$PIPELINE_DIR/05-implementation-log.md` を Write で生成する。
各タスクの実行結果（完了/失敗、作成ファイル）を記録する。

`00-manifest.md` を更新する。

---

## Phase 5: 品質チェック

`03-qa-plan.md` の品質チェックコマンド一覧を Read し、Codex に品質チェックを委譲する。

```
/codex:rescue
以下の品質チェックを実行し、結果を報告してください。

【技術スタック制約】
使用できる言語は Go / TypeScript / ShellScript のみです。

【品質チェックコマンド】
（03-qa-plan.md のセクション 5 から品質チェックコマンド一覧を転記）

【品質ゲート基準】
PASS 条件: BLOCKER 指摘ゼロ。MAJOR / MINOR は記録のみで PASS 扱い。

【チェック手順】
1. 各コマンドを順に実行する
2. テスト結果、静的解析結果、カバレッジを記録する
3. 各問題を BLOCKER / MAJOR / MINOR に分類する
4. BLOCKER がある場合は原因分類（要件起因 / 設計起因 / 実装起因）を記載する。
   分類は 03-qa-plan.md セクション 9「失敗 → 原因分類マッピング」に従う。
   マッピングにないチェックの失敗のみ Codex の判断で分類する。

【出力先】
$PIPELINE_DIR/06-quality-report.md
（テンプレートは $SKILL_DIR/references/artifact-templates.md の
「06-quality-report.md」セクションに従う）
```

**完了確認**: `$PIPELINE_DIR/06-quality-report.md` が生成されたことを確認する。
`00-manifest.md` を更新する。

Go TUI ツールの場合は `go-tui-reviewer` エージェントでアーキテクチャレビューを追加実施し、
`/tui-check` で全ツールのガイドライン準拠を確認する。

---

## Auto Gate 3: BLOCKER 判定 & フィードバックループ

`06-quality-report.md` を Read し、BLOCKER の有無で分岐する。

### BLOCKER なし → 完了

完了報告セクションへ進む。

### BLOCKER あり → フィードバックループ

1. **ループ上限チェック**: `loop_count >= max_loops`（2 回）の場合はユーザーに報告して終了:
   ```
   フィードバックループが最大回数（2 回）に達しました。

   【残存する BLOCKER】
   （06-quality-report.md の BLOCKER 指摘を列挙）

   【ループ履歴】
   （feedback/ 配下のファイルを要約）

   手動で修正して再実行するか、現状で受け入れるかを判断してください。
   ```

2. **振動検出**: `loop_count >= 1` の場合、前回ループ（`feedback/loop-{loop_count}.md`）の
   BLOCKER ID 集合と今回の `06-quality-report.md` の BLOCKER ID 集合を比較する。
   両集合の積集合が前回集合の **50% 以上** を占める場合は振動と判定し、
   ユーザーに報告してループを中断する:

   判定式: `|前回 BLOCKER ID ∩ 今回 BLOCKER ID| / |前回 BLOCKER ID| >= 0.5`

   完全一致だけでなく、過半数が同じ問題を引きずっている場合を振動とみなす。
   タスク ID で対応する検証コマンドが同じ場合も「同一問題」として ID 一致扱いにする。

   ```
   振動を検出しました（前回 BLOCKER の {percent}% が今回も残存）。

   【振動している BLOCKER】
   （重複している BLOCKER ID と影響範囲を列挙）

   【前回ループの結果】
   （feedback/loop-{loop_count}.md の要約）

   手動介入を推奨します。
   ```

3. **原因分類で戻り先を決定**（最も上流のフェーズを優先）:

   | 原因分類 | シグナル例 | 戻り先 |
   |---------|-----------|--------|
   | 要件起因 | 受け入れ条件が曖昧・要件間矛盾・スコープ漏れ | Phase 1 |
   | 設計起因 | インターフェース不整合・循環依存・データモデル不備 | Phase 2a |
   | 実装起因 | テスト失敗・Lint エラー・コンパイルエラー | Phase 4 |

   複数の分類にまたがる場合は、より上流のフェーズを選ぶ（Phase 1 > Phase 2a > Phase 4）。

4. `$PIPELINE_DIR/feedback/loop-{loop_count + 1}.md` を Write で生成する:
   - 問題サマリ（BLOCKER 一覧）
   - 原因分析
   - 戻り先フェーズへの修正指示

5. `loop_count` をインクリメントする。

6. `00-manifest.md` のフィードバックループ履歴を更新する。

7. 戻り先フェーズを再実行する。エージェントの prompt 冒頭に以下を追加する:
   ```
   【フィードバックループ {loop_count} 回目】
   前回の成果物に対して品質チェックで BLOCKER が検出されました。
   まず $PIPELINE_DIR/feedback/loop-{loop_count}.md を Read し、
   問題内容を把握してください。
   その上で、前回の成果物を修正してください。
   修正箇所には [修正: loop-{loop_count}] マーカーを付けてください。
   ```

---

## 完了報告

1. `00-manifest.md` の全 Phase ステータスを完了に更新する

2. ユーザーに最終報告を表示する:
   ```
   --- パイプライン完了 ---

   【生成された成果物】
   - docs/pipeline/01-requirements.md（要件定義書）
   - docs/pipeline/02-system-design.md（設計書）
   - docs/pipeline/03-qa-plan.md（QA 計画）
   - docs/pipeline/04-task-breakdown.md（タスク分解）
   - docs/pipeline/05-implementation-log.md（実装ログ）
   - docs/pipeline/06-quality-report.md（品質レポート）

   【実装されたファイル】
   （05-implementation-log.md から作成・変更ファイルの一覧を抜粋）

   【品質サマリ】
   （06-quality-report.md の結果サマリを抜粋）

   【フィードバックループ】
   {loop_count} 回（最大 2 回）
   ```

---

## 途中報告フォーマット

各フェーズ開始時:

```
--- Phase N: {フェーズ名} ---
[{エージェント名} / {モデル}] 実行中...
```

各フェーズ完了時:

```
--- Phase N 完了 ---
成果物: $PIPELINE_DIR/{ファイル名}
```

---

## 注意事項

- **技術スタック制約の徹底**: 全フェーズで Go / TypeScript / ShellScript のみを使用する。
  Python、Ruby、Rust 等の提案・使用は禁止。
- **Gate は自動通過**: ユーザーへの承認要求は行わない。全フェーズを自動で実行する。
- **BLOCKER のみがループ条件**: MAJOR / MINOR は記録のみで PASS 扱い。
- **フィードバックループ上限**: 最大 2 回。達した場合はユーザーに報告して終了。
- **コンテキスト最適化**: Agent ツールの prompt にはファイルパスを渡し、
  エージェント自身に Read させる。大量のテキストを prompt に含めない。
- **Codex 連携**: `/codex:rescue` はフォアグラウンドで実行される。
  結果を受け取ってから次のフェーズに進む。
