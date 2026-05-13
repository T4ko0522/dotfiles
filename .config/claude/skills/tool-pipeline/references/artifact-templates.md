# Artifact Templates

tool-pipeline スキルが各フェーズで生成する 7 ファイル（`00-manifest.md` 〜 `06-quality-report.md`）+ フィードバックループ用 `feedback/loop-N.md` のテンプレート集約。
各エージェントは該当セクションを Read し、その構造に従って `$PIPELINE_DIR/` に書き出す。

---

## 00-manifest.md

パイプライン実行のメタ情報・進捗ダッシュボード。

```markdown
# Tool Pipeline Manifest

| 項目 | 値 |
|------|-----|
| 実行開始 | YYYY-MM-DD HH:MM |
| プロジェクト | $PROJECT_ROOT |
| パイプラインルート | docs/pipeline |
| 言語 | Go / TypeScript / ShellScript（Phase 1 完了後に確定） |

## Phase ステータス

| Phase | エージェント | モデル | ステータス | 成果物 |
|-------|------------|--------|------------|--------|
| 1: 要件定義 | tp-requirements-analyst | sonnet | pending | 01-requirements.md |
| 2a: 設計 | tp-system-designer | opus | pending | 02-system-design.md |
| 2b: QA 計画 | tp-qa-architect | sonnet | pending | 03-qa-plan.md |
| 3: タスク分解 | tp-task-decomposer | sonnet | pending | 04-task-breakdown.md |
| 4: 実装 | codex:rescue | gpt-5.5 | pending | 05-implementation-log.md |
| 5: 品質チェック | codex:rescue | gpt-5.5 | pending | 06-quality-report.md |

ステータス値: `pending` / `running` / `done` / `failed`

## フィードバックループ履歴

| 回 | 戻り先 | 原因分類 | 主要 BLOCKER | 結果 |
|----|--------|---------|-------------|------|
| -  | -      | -       | -           | -    |

ループが発動するたびに 1 行追加する。
```

---

## 01-requirements.md

```markdown
# 要件定義書

## 概要

<何を作るか、なぜ作るか。1〜3 段落>

## 機能要件

- **FR-01**: <動詞で始まる要件>
- **FR-02**: ...

## 非機能要件

- **NFR-01**: <性能・可搬性・運用面>
- **NFR-02**: ...

## 制約

- <必須技術・禁止事項・依存環境>

## 前提条件

- <動作環境・既存資産・想定ユーザー>

## 技術スタック選定

**選定言語**: <Go / TypeScript / ShellScript の中から 1 つ>

**選定理由**:
1. <理由 1>
2. <理由 2>
3. <理由 3>

**他言語を選ばなかった理由**:
- <なぜ他の 2 つではないか>

## スコープ外

- <今回扱わないこと>

## 受け入れ基準

- <テスト可能な完成条件>
- <要件 ID と紐付け>

## マーカー

- `[推論]` がある箇所: <列挙>
- `[要確認]` がある箇所: <列挙>
```

---

## 02-system-design.md

```markdown
# システム設計書

## アーキテクチャ概観

<ASCII art または Mermaid でレイヤー図>
<各層の責務>

## ディレクトリ構造

```

cmd/<tool-name>/
  main.go
internal/
  domain/
  scanner/
  ...
pkg/        # 公開 API がある場合のみ
tests/

```

## 主要コンポーネント

### <Component Name>

**責務**: <一行説明>

**公開インターフェース**:
```go
type Scanner interface {
    Scan(ctx context.Context, root string) (<-chan FileEntry, error)
}
```

**依存**: <他コンポーネント名>

## データモデル

### FileEntry

```go
type FileEntry struct {
    Path     string    `json:"path"`
    Size     int64     `json:"size"`
    Modified time.Time `json:"modified"`
}
```

## CLI / API 仕様

### サブコマンド `scan`

```
<tool> scan [flags] <root>

Flags:
  -j, --json            JSON 出力
  -L, --max-depth N     最大深度
      --follow-symlinks シンボリックリンクを追う

Exit codes:
  0  成功
  1  一般エラー
  2  引数エラー
```

## エラーハンドリング戦略

- エラー型は `errors.New` / 独自型 / `fmt.Errorf("...: %w", err)` のどれを使うか
- ユーザー向けメッセージは stderr / 構造化ログのどちらか
- パニックは <方針>

## 設定とロギング

- 設定ファイル形式: <YAML / TOML / JSON / なし>
- 環境変数: `<TOOL>_*` プレフィックス
- ログレベル: <error / warn / info / debug>
- 出力先: <stderr / ファイル>

## テスト容易性

- 依存注入ポイント: <インターフェース名>
- モック対象: <ファイルシステム / ネットワーク / 時刻>
- テストデータ配置: `testdata/`

## ADR（Architecture Decision Records）

### ADR-001: <決定タイトル>

- **文脈**: <なぜ判断が必要か>
- **選択肢**: <検討した案>
- **決定**: <選んだ案>
- **理由**: <なぜ>
- **トレードオフ**: <失うもの・リスク>

### ADR-002: ...

```

---

## 03-qa-plan.md

```markdown
# QA 計画

## 1. 品質目標

| 要件 ID | 品質指標 | 目標値 |
|--------|---------|--------|
| NFR-01 | 起動時間 | < 100ms |
| NFR-02 | スループット | > 1000 ファイル/秒 |

## 2. テストレベル

| レベル | 対象 | 配置 |
|--------|-----|------|
| 単体 | 関数・メソッド単位 | `*_test.go` / `*.test.ts` / `tests/*.bats` |
| 統合 | コンポーネント結合 | `internal/<pkg>/integration_test.go` 等 |
| 受け入れ | CLI / API レベル | `tests/acceptance/` |

## 3. テストツール選定

- **単体テスト**: <ツール名 + バージョン>
- **静的解析**: <ツール名>
- **型チェック**: <ツール名>
- **カバレッジ**: <ツール名>

## 4. 静的解析・Lint ルール

```yaml
# .golangci.yml または .eslintrc など、設定の要点を抜粋
```

## 5. 品質チェックコマンド一覧

```yaml
checks:
  - id: lint
    command: "<具体的コマンド>"
    blocker: true
  - id: unit-test
    command: "<具体的コマンド>"
    blocker: true
  - id: coverage
    command: "<具体的コマンド>"
    blocker: false
```

実行順序: 上から順に。`blocker: true` の失敗で即時 BLOCKER 扱い。

## 6. 品質ゲート基準

- **BLOCKER**: <定義>
- **MAJOR**: <定義>
- **MINOR**: <定義>

PASS 条件: **BLOCKER 指摘ゼロ**。

## 7. カバレッジ目標

| 種別 | 目標 |
|------|------|
| ライン | 70% |
| 分岐 | 60% |

未達は MAJOR 扱い。

## 8. CI 想定

- どのチェックを CI で回すか（参考情報、本パイプラインでは実装しない）

## 9. 失敗 → 原因分類マッピング

```yaml
classification:
  - check_id: <チェック ID>
    failure_class: 要件起因 / 設計起因 / 実装起因
    reason: "<このチェックが失敗したらこの分類になる理由>"
```

詳細・優先順位ルールは `tp-qa-architect` エージェント定義の「失敗 → 原因分類マッピング」を参照。

```

---

## 04-task-breakdown.md

```markdown
# タスク分解

## タスク依存グラフ

```

Group A ── Group B ── Group D
   │           │
   └─→ Group C ┘     └─→ Group E

```

## タスクグループ一覧

| Group | 内容 | 並列性 | 依存 |
|-------|------|--------|------|
| A | 基盤（型・定数・設定） | 並列可 | なし |
| B | ドメインロジック | A 内で順次 | A |
| C | インフラ（I/O・外部呼び出し） | 並列可 | A |
| D | ハンドラー・エントリポイント | 順次 | B, C |
| E | 結合・E2E テスト | 順次 | D |

## タスク詳細

### T-001: <タイトル>

**Group**: A
**設計参照**: 02-system-design.md「## データモデル」
**変更ファイル**:
- `internal/domain/types.go` (新規, ~30 行)

**Codex への指示**:
<Codex がそのまま実行できる自然言語の実装指示>

**検証コマンド**:
```bash
go build ./internal/domain/...
go vet ./internal/domain/...
```

**受け入れ基準**:

- 上記コマンド PASS
- <その他>

---

### T-002: ...

```

---

## 05-implementation-log.md

```markdown
# 実装ログ

## サマリ

| 項目 | 値 |
|------|-----|
| 実行開始 | YYYY-MM-DD HH:MM |
| 実行完了 | YYYY-MM-DD HH:MM |
| 完了タスク数 | N / N |
| 失敗タスク数 | 0 |

## グループ実行結果

### Group A: 基盤

| タスク | ステータス | 作成・変更ファイル | 備考 |
|--------|-----------|------------------|------|
| T-001 | done | internal/domain/types.go (+30) | - |
| T-002 | done | ... | - |

### Group B: ドメインロジック

...

## 失敗ログ

タスクが失敗した場合は以下のフォーマットで記録:

### T-XXX 失敗

- **エラー**: <Codex からの出力>
- **試行回数**: 1
- **対応**: <フィードバックループへ / スキップ / 手動介入>

## 作成・変更ファイル一覧（全グループ集約）

- `cmd/<tool>/main.go` (新規)
- `internal/domain/types.go` (新規)
- ...
```

---

## 06-quality-report.md

```markdown
# 品質レポート

## サマリ

| 項目 | 値 |
|------|-----|
| 実行日時 | YYYY-MM-DD HH:MM |
| 総合判定 | **PASS** / **FAIL** |
| BLOCKER 件数 | 0 |
| MAJOR 件数 | 2 |
| MINOR 件数 | 5 |

**PASS** = BLOCKER ゼロ。MAJOR / MINOR があっても PASS。

## チェック実行結果

| チェック ID | コマンド | 結果 | 終了コード | 所要時間 |
|-----------|---------|------|----------|---------|
| lint | golangci-lint run | PASS | 0 | 12s |
| unit-test | go test -race ./... | PASS | 0 | 45s |
| coverage | go test -cover ./... | MAJOR | 0 | 47s |

## 指摘一覧

### BLOCKER

なし。

または:

#### BLK-001: <タイトル>

- **原因分類**: 実装起因 / 設計起因 / 要件起因
- **影響範囲**: `internal/scanner/scanner.go:42-58`
- **影響ファイル（同一性判定用）**: `internal/scanner/scanner.go`（リポジトリルートからの相対パス、行番号は含めない）
- **検証コマンド ID**: `unit-test`（03-qa-plan.md セクション 5 の `checks[].id`）
- **same_problem_key**: `internal/scanner/scanner.go::unit-test::実装起因`（上記 3 要素を `::` で連結）
- **再現**: `go test ./internal/scanner/`
- **修正案**: <Codex 向けの修正方針>

### MAJOR

#### MAJ-001: カバレッジ未達

- カバレッジ実測 62%、目標 70%
- 影響ファイル: `internal/scanner/scanner.go`
- 修正方針: エラーパスのテスト追加

### MINOR

- スタイル指摘 5 件（命名規約）

## 原因分類サマリ（BLOCKER 全件）

| 分類 | 件数 | 代表 ID |
|------|------|--------|
| 要件起因 | 0 | - |
| 設計起因 | 0 | - |
| 実装起因 | 0 | - |

複数分類が混在する場合は **より上流のフェーズに戻る**（要件 > 設計 > 実装）。

## 推奨アクション

- BLOCKER なし → Phase 完了
- BLOCKER あり → Auto Gate 3 がフィードバックループを発動（最大 2 回）
```

---

## feedback/loop-N.md

```markdown
# フィードバックループ {N} 回目

## 検知 BLOCKER

- BLK-001: <タイトル>（原因分類: <分類>）
- BLK-002: ...

## 原因分析

<06-quality-report.md の BLOCKER を統合的に分析>

## 戻り先フェーズ

**Phase {1 / 2a / 4}**

選定理由: <最も上流の原因に対応するため>

## 修正指示

戻り先エージェントへの指示:

- <修正項目 1>
- <修正項目 2>

修正箇所には `[修正: loop-{N}]` マーカーを付けること。
```
