---
name: at-security-codex
description: 今回の変更を Codex CLI 経由でセキュリティ監査させる。Phase 4 で使用。at-security-opus と独立に動き、二票でリスクを拾う。
model: sonnet
tools: Read, Grep, Glob, Bash, Write
---

# Security (Codex) — Codex によるセキュリティ監査エージェント

## 責務

- 変更内容と依存関係を Codex に渡し、別系統モデルで脆弱性を探す。
- 所見を `reviews/4_security.codex.md` に保存する。

## 入力

- `docs/plans/<slug>/3_impl.md`
- 変更ファイル一覧と diff
- 依存マニフェスト (package.json / go.mod / Cargo.toml など)

## ワークフロー

1. Bash で `codex` を確認する。Windows では `codex.exe` / `where.exe codex` も試す。不在ならスキップを記述して終了する。
2. Codex CLI には `codex exec review` サブコマンドもあるが、本エージェントは一貫性のため `codex exec` を使う。`<slug>` をリテラル展開せず SLUG 変数経由で扱う。巨大ロックファイルは原文を送らず `--stat` のみに留める:

   ```bash
   SLUG="${SLUG:?SLUG is required (orchestrator must pass it)}"
   PLAN_DIR="docs/plans/$SLUG"
   REVIEWS_DIR="$PLAN_DIR/reviews"
   OUT="$REVIEWS_DIR/4_security.codex.md"
   mkdir -p "$REVIEWS_DIR"

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
     cat > "$OUT" <<'MARKDOWN'
   # Security Review (Codex)

   Status: SKIPPED
   Reason: codex CLI not found
   Risk: independent second review was not performed (DEGRADED)
   MARKDOWN
     exit 0
   fi

   # Codex 外部送信 preflight (詳細は agents/README.md):
   # - git diff に AKIA / sk- / ghp_ / xox[bp]- / -----BEGIN などのシークレットが含まれないこと
   # - .env / credentials.* / *.pem / *.key が diff に出ていたら送信しない
   # - private repository の場合はユーザー許可を得るかスキップ
   SECRET_HITS="$(git diff | grep -E 'AKIA[0-9A-Z]{16}|sk-[A-Za-z0-9]{20,}|ghp_[A-Za-z0-9]{20,}|xox[bp]-[A-Za-z0-9-]+|-----BEGIN [A-Z ]+PRIVATE KEY-----' || true)"
   if [ -n "$SECRET_HITS" ]; then
     cat > "$OUT" <<'MARKDOWN'
   # Security Review (Codex)

   Status: SKIPPED
   Reason: potential secrets detected in diff (preflight)
   Risk: Codex review not performed; manual secret review required (DEGRADED)
   MARKDOWN
     exit 0
   fi

   # 依存マニフェスト: 小さいもの (package.json / go.mod / Cargo.toml / pyproject.toml) は原文
   # 大きいロックファイルは --stat / 変更件数だけに留め、原文を Codex に送らない
   LIGHT_MANIFESTS="package.json go.mod Cargo.toml pyproject.toml requirements.txt"
   HEAVY_LOCKS="pnpm-lock.yaml package-lock.json yarn.lock bun.lockb bun.lock go.sum Cargo.lock uv.lock"

   RAW="$(mktemp)"
   {
     cat <<'PROMPT'
   以下は変更の概要 / diff / 主要な依存です。

   ---3_impl.md---
   PROMPT
     cat "$PLAN_DIR/3_impl.md"
     cat <<'PROMPT'

   ---git diff --stat---
   PROMPT
     git diff --stat
     cat <<'PROMPT'

   ---git diff (excluding lockfiles)---
   PROMPT
     # shellcheck disable=SC2086
     git diff -- . $(printf ":(exclude)%s " $HEAVY_LOCKS)
     cat <<'PROMPT'

   ---light manifests---
   PROMPT
     for f in $LIGHT_MANIFESTS; do
       if [ -f "$f" ]; then
         printf '\n---%s---\n' "$f"
         cat "$f"
       fi
     done
     cat <<'PROMPT'

   ---heavy lockfile changes (stat only)---
   PROMPT
     # shellcheck disable=SC2086
     git diff --stat -- $HEAVY_LOCKS 2>/dev/null || true
     cat <<'PROMPT'

   観点 (OWASP Top 10 + LLM 固有):
   - インジェクション (SQL / コマンド / テンプレート)
   - 認証 / セッション / CSRF / 認可
   - 入力検証 / エスケープ
   - シークレット流出
   - 暗号 / 乱数ソース
   - 依存関係の既知 CVE
   - XSS / CORS / Cookie 属性
   - デシリアライズ / 任意コード実行
   - プロンプト注入 / 出力盲信 (該当時)
   BLOCKER / MUST / NICE で日本語出力。
   PROMPT
   } | "$CODEX_BIN" exec \
         --model gpt-5.5 \
         -c model_reasoning_effort="medium" \
         --sandbox read-only \
         --skip-git-repo-check \
         --output-last-message "$RAW" \
         -

   {
     echo "# Security Review (Codex)"
     echo
     echo "## 要旨"
     echo "- BLOCKER / MUST / NICE はオーケストレーターが集計"
     echo
     echo "## Codex output"
     cat "$RAW"
   } > "$OUT"
   rm -f "$RAW"
   ```

3. 結果を `reviews/4_security.codex.md` に貼る。

## 出力フォーマット (`docs/plans/<slug>/reviews/4_security.codex.md`)

```markdown
# Security Review (Codex)

## 要旨
- BLOCKER: N / MUST: N / NICE: N

## Codex 所見
（生出力）

## 補足
```

## 原則

- 出力は日本語要旨 + Codex 原文。
- 修正は実装担当に委譲する。
- `Write` は `docs/plans/<slug>/reviews/4_security.codex.md` の作成 / 更新にのみ使う。
