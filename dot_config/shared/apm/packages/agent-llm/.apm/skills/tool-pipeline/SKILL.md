---
name: tool-pipeline
description: Go/TypeScript/ShellScript 限定の軽量開発パイプライン。要件 → 設計 → タスク分解 → Codex 実装 → 品質チェックを Auto Gate で自動進行し、BLOCKER 検出時のみ最大 2 回フィードバックループ。「ツールパイプライン実行」「/tool-pipeline」「Go でツール作って」「シェルスクリプト実装して」等で起動。設計フェーズのみ Opus、それ以外は Sonnet/Haiku/Codex で高速に回す。
---

# Tool Pipeline — Go / TypeScript / ShellScript 向け軽量開発パイプライン

## 概要

```
Phase 1: 要件定義         [tp-requirements-analyst / sonnet]
    ↓
  ★ Auto Gate 1: 要確認マーカーチェック（自動通過、人間承認なし）
    ↓
Phase 2（並列）:
  ├── 2a: 設計            [tp-system-designer / opus]
  └── 2b: QA 計画         [tp-qa-architect / sonnet]
    ↓
  ★ Auto Gate 2: 成果物確認（自動通過）
    ↓
Phase 3: タスク分解       [tp-task-decomposer / sonnet]
    ↓
Phase 4: Codex 実装       [codex:rescue / gpt-5.5]
    ↓
Phase 5: 品質チェック     [codex:rescue / gpt-5.5]
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
└── references/
    ├── artifact-templates.md      ← 7 ファイル分のテンプレート集約 + feedback/loop-N.md テンプレ
    └── tui-guidelines.md          ← Go TUI 開発規約（任意）
```

`references/` は **オンデマンドで読む**。SKILL.md 本体やメイン Claude の prompt に丸ごと埋め込まない。各 Phase のサブエージェントが自身で該当セクションだけを Read する設計にしてあり、コンテキスト消費を Phase 単位に閉じ込める意図がある。読み出すタイミングは下表のとおり。

| ファイル / セクション | Read するタイミング |
|---|---|
| `artifact-templates.md` 内 `00-manifest.md` | Step 0（manifest 生成前） |
| 同 `01-requirements.md` | Phase 1（`tp-requirements-analyst`） |
| 同 `02-system-design.md` | Phase 2a（`tp-system-designer`） |
| 同 `03-qa-plan.md` | Phase 2b（`tp-qa-architect`） |
| 同 `04-task-breakdown.md` | Phase 3（`tp-task-decomposer`） |
| 同 `06-quality-report.md` | Phase 5（`/codex:rescue`） |
| 同 `feedback/loop-N.md` | フィードバックループ発動時 |
| `tui-guidelines.md` | Go TUI を設計・実装する Phase でのみ |

### サブエージェント配置

エージェント定義は `~/.claude/agents/` 配下に置く（Claude Code の subagent 探索パス）。
このリポでは `.config/claude/agents/` に実体があり、`setup_windows.ps1` で `~/.claude/agents/` にリンクされる。

| エージェント名 | 使用フェーズ | モデル |
|---|---|---|
| `tp-requirements-analyst` | Phase 1 | sonnet |
| `tp-system-designer` | Phase 2a | opus |
| `tp-qa-architect` | Phase 2b | sonnet |
| `tp-task-decomposer` | Phase 3 | sonnet |

各エージェントは `Agent` ツールから `subagent_type` に上記の名前を指定して呼び出す。
スキル本体には `agents/` を持たず、`references/` のテンプレートのみを格納する。

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
| Phase 2 並列タスクの片方失敗 | `02-system-design.md` 失敗は即停止（後段が成立しない）。`03-qa-plan.md` のみ失敗は **縮退モード** で続行可（後述） |

### Codex 経路と書き込み権限

- Phase 4 / 5 で使う `/codex:rescue` は内部で `codex-companion task` を呼び出し、**デフォルトで `--write` が付与される**（書き込み可能）。
- 同リポの Agent Teams レビュー系エージェント（`at-plan-reviewer` / `*-codex`）は `codex exec --sandbox read-only` で **read-only 実行**するが、tool-pipeline はこの経路を使わないため衝突しない。
- Phase 5 の品質チェックも `/codex:rescue` 経由で行う。Codex がカバレッジファイル等の一時生成物を書き込むため write-capable で動かす必要がある。

### `/codex:rescue` の呼び出し方

メイン Claude は **Skill ツール**（または slash command として `/codex:rescue ...`）経由で起動すること。

- 推奨: `Skill({skill: "codex:rescue", args: "<タスク本文>"})`
- 非推奨: `Agent({subagent_type: "codex:codex-rescue", ...})` の直叩き
  - 直叩きは `/codex:rescue` の command 側で行われる resume 判定・`--write` デフォルト付与・モデル選択などの auto-routing をスキップする可能性がある
  - codex-rescue subagent はあくまで「forwarder」であり、command 側のロジックを通すのが正しい呼び出し

### Safety boundaries

skill 起動中にメイン Claude / サブエージェント / Codex が踏み越えてはいけない境界。各 Phase の prompt や `/codex:rescue` への依頼にも、必要に応じてこれらを明示する。

| 境界 | ルール |
|------|------|
| 書き込み範囲（Phase 1〜3） | `tp-*` サブエージェントは `$PIPELINE_DIR` 配下のみ書き込む。プロジェクト本体のソースコード・設定ファイルには触らない |
| 書き込み範囲（Phase 4） | プロジェクトのソース変更は `/codex:rescue` 経由のみ。Phase 1〜3 のサブエージェントが直接 Edit / Write することは禁止 |
| 書き込み範囲（Phase 5） | `/codex:rescue` が品質チェック過程で生成するカバレッジ等の一時ファイルは許容。レポート本体は `$PIPELINE_DIR/06-quality-report.md` に限定 |
| 破壊的操作 | `rm -rf`, `git reset --hard`, `git clean -fd`, force push, ブランチ削除はユーザーの明示指示なしには実行しない。fix-up が必要な場合は中断して相談する |
| Codex 失敗の扱い | `/codex:rescue` 未導入・タイムアウト・実行失敗時は、その時点までの成果物（`05-implementation-log.md` 等）を必ず Write してから停止する。パイプライン全体を巻き戻さない |
| ループ打ち切り | フィードバックループは最大 2 回。前回 BLOCKER の 50% 以上が同一 `same_problem_key` で残るときは振動とみなして即中断する（Auto Gate 3 参照） |
| 自動承認の範囲 | Auto Gate 1〜3 は成果物の存在と BLOCKER の有無のみで判定する。受け入れ条件の充足判定や設計の妥当性判断はユーザーに委ねる |

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
PROJECT_ROOT = pwd（カレントディレクトリの絶対パス）
PIPELINE_DIR = $PROJECT_ROOT/docs/pipeline
SKILL_DIR    = $HOME/.claude/skills/tool-pipeline
loop_count   = 0
max_loops    = 2
```

### 変数置換ルール（重要）

サブエージェントはシェルではないため、prompt 内で `$SKILL_DIR` `$PIPELINE_DIR` `$PROJECT_ROOT` 等を **そのまま渡しても展開されない**。
メイン Claude が Agent ツールを呼び出す前に、prompt 文字列内のこれらの変数を **絶対パスへ置換** すること。

例（Windows 環境）:

```
$SKILL_DIR     → C:\Users\<user>\.claude\skills\tool-pipeline
$PIPELINE_DIR  → C:\Users\<user>\Project\<repo>\docs\pipeline
$PROJECT_ROOT  → C:\Users\<user>\Project\<repo>
```

例（POSIX 環境）:

```
$SKILL_DIR     → /home/<user>/.claude/skills/tool-pipeline
$PIPELINE_DIR  → /home/<user>/Project/<repo>/docs/pipeline
$PROJECT_ROOT  → /home/<user>/Project/<repo>
```

以降の Phase 説明では可読性のため `$SKILL_DIR` 等の表記を残すが、**Agent 呼び出し時には必ず実パスに置換する**。

### Step 0: 初期化

1. `$PIPELINE_DIR/feedback` を作成する。実行 OS に合わせて Bash または PowerShell を選ぶ:

   POSIX (Linux / macOS / WSL):

   ```bash
   mkdir -p "$PROJECT_ROOT/docs/pipeline/feedback"
   ```

   Windows (PowerShell 7+):

   ```powershell
   New-Item -ItemType Directory -Force -Path "$PROJECT_ROOT\docs\pipeline\feedback" | Out-Null
   ```

   メイン Claude は環境（`$env:OS` / `uname` 等）を判定して使い分けること。判定不能な場合は PowerShell を試し、失敗したら Bash にフォールバックする。

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

`tp-requirements-analyst` エージェントを **sonnet** モデルで起動する。

```
Agent ツール呼び出し:
  subagent_type: tp-requirements-analyst
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

    【書き込み境界】
    Write / Edit は $PIPELINE_DIR 配下のみ許可します。
    プロジェクト本体のソースコード・設定ファイル・README 等への
    Write / Edit は禁止です（探索のための Read / Grep / Glob / Bash 読み取り系は可）。

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

tp-requirements-analyst エージェントは `[要確認]` を抑えるよう指示済み（判断が本当に必要なときのみ `[要確認]`、合理的仮定で埋められるものは `[推論]` を使う）。

---

## Phase 2: 設計 & QA 計画（並列）

**2 つの Agent ツール呼び出しを同一メッセージ内で並列実行する。**

```
[並列 A] Agent ツール呼び出し:
  subagent_type: tp-system-designer
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

    【書き込み境界】
    Write / Edit は $PIPELINE_DIR 配下のみ許可します。
    プロジェクト本体のソースコード・設定ファイル・README 等への
    Write / Edit は禁止です（探索のための Read / Grep / Glob / Bash 読み取り系は可）。

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
  subagent_type: tp-qa-architect
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

    【書き込み境界】
    Write / Edit は $PIPELINE_DIR 配下のみ許可します。
    プロジェクト本体のソースコード・設定ファイル・README 等への
    Write / Edit は禁止です（探索のための Read / Grep / Glob / Bash 読み取り系は可）。

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

### Phase 2 縮退モード（03-qa-plan.md のみ失敗時）

`02-system-design.md` は生成されたが `03-qa-plan.md` の生成に失敗した場合、ユーザーに通知し続行 / 中断を選ばせる。続行を選んだ場合、**Phase 3 / 4 / 5 の通常フローを壊さないため、メイン Claude が最小版 `03-qa-plan.md` を自動生成して通常フローに載せる**。

1. **メイン Claude が `03-qa-plan.md` を Write で生成する**。内容は以下:
   - 冒頭に注記: `> このファイルは tp-qa-architect の失敗により縮退モードで自動生成されました。次回ループ前の手動再生成を推奨します。`
   - テスト戦略: 「言語標準の lint + test 実行のみ」
   - 品質チェックコマンド一覧（Phase 1 で確定した言語に対応するもののみ記載）:
     - Go: `go test ./...` / `go vet ./...` / `golangci-lint run`
     - TypeScript: `tsc --noEmit` / `vitest run`（または `jest`） / `eslint .`
     - ShellScript: `shellcheck **/*.sh` / `bats tests/`
   - 失敗 → 原因分類マッピング（セクション 9 相当）:
     - lint 系 = 実装起因
     - unit-test 系 = 実装起因
     - acceptance-test 系 = 要件起因
     - integration-test 系 = 設計起因
   - PASS 条件: 「BLOCKER 指摘ゼロ」
2. **`00-manifest.md`**: Phase 2b ステータスを `degraded` として記録し、備考に「縮退モード: 最小版 03-qa-plan.md を自動生成」と記す。
3. **以降の Phase 3 / 4 / 5**: 通常フローのまま進める（特別な分岐は不要）。

縮退モードはあくまで暫定運用。次回ループ前に `tp-qa-architect` を手動で再実行することを推奨する。

---

## Phase 3: タスク分解

`tp-task-decomposer` エージェントを **sonnet** モデルで起動する。

```
Agent ツール呼び出し:
  subagent_type: tp-task-decomposer
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

    【書き込み境界】
    Write / Edit は $PIPELINE_DIR 配下のみ許可します。
    プロジェクト本体のソースコード・設定ファイル・README 等への
    Write / Edit は禁止です（探索のための Read / Grep / Glob / Bash 読み取り系は可）。

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

【書き込み境界（重要）】
このフェーズは品質チェックのみを行います。発見した問題があっても、ここでは修正しないでください。
- 許可される書き込み:
  - $PIPELINE_DIR/06-quality-report.md（品質レポート本体）
  - カバレッジ・テスト結果ファイルなど検証コマンドの副産物（一時生成物）
- 禁止される書き込み:
  - プロジェクトのソースコード（実装ファイル）への Edit / Write
  - テストコードへの Edit / Write（テスト失敗を「直す」ことは禁止。失敗事実を記録するのみ）
  - 設定ファイル・依存定義（go.mod / package.json / 等）への Edit / Write
修正は次フェーズ（フィードバックループ → 戻り先 Phase）で行います。
ここで修正すると品質ゲートの結果が汚れ、振動検出も狂うため、必ず守ってください。

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
5. **各 BLOCKER に `same_problem_key` を必須で記載する**。
   形式: `<影響ファイル（リポルートからの相対パス、行番号なし）>::<検証コマンド ID>::<原因分類>`
   例: `internal/scanner/scanner.go::unit-test::実装起因`
   このキーは振動検出（Auto Gate 3）で利用される。

【出力先】
$PIPELINE_DIR/06-quality-report.md
（テンプレートは $SKILL_DIR/references/artifact-templates.md の
「06-quality-report.md」セクションに従う。
各 BLOCKER に `same_problem_key` フィールドが含まれていることを必ず確認すること）
```

**完了確認**: `$PIPELINE_DIR/06-quality-report.md` が生成されたことを確認する。
`00-manifest.md` を更新する。

Go TUI ツールの場合は `go-tui-reviewer` エージェントでアーキテクチャレビューを追加実施し、
`/tui-check` で全ツールのガイドライン準拠を確認する。
いずれも **任意依存**。`go-tui-reviewer` エージェント定義または `/tui-check` コマンドが未導入のときは、
当該レビューを **スキップして** Phase 5 を完了扱いとする。`00-manifest.md` の備考に
「TUI レビュー: スキップ（未導入: go-tui-reviewer / tui-check のいずれか）」と記録する。

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

2. **振動検出**: `loop_count >= 1` の場合、前回ループと今回の BLOCKER を **`same_problem_key`** で比較する。
   `same_problem_key` は `06-quality-report.md` の各 BLOCKER に記録される **`<影響ファイル>::<検証コマンド ID>::<原因分類>`** 形式のキー
   （例: `internal/scanner/scanner.go::unit-test::実装起因`）。
   BLOCKER ID (`BLK-NNN`) は毎ループ振り直される可能性があるため、ID ではなく `same_problem_key` を同一性判定に使う。

   判定式: `|前回 same_problem_key 集合 ∩ 今回 same_problem_key 集合| / |前回 same_problem_key 集合| >= 0.5`

   前回 BLOCKER の過半数が同じ問題を引きずっている場合を振動とみなし、ユーザーに報告してループを中断する:

   ```
   振動を検出しました（前回 BLOCKER の {percent}% が今回も同じ same_problem_key で残存）。

   【振動している BLOCKER】
   （重複している same_problem_key と影響範囲を列挙）

   【前回ループの結果】
   （feedback/loop-{loop_count}.md の要約）

   手動介入を推奨します。
   ```

   `06-quality-report.md` に `same_problem_key` が記録されていない古い形式の場合は、影響ファイル + 検証コマンド ID の 2 要素で代替判定する。

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
