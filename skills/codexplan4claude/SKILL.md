---
name: codexplan4claude
description: |
  Plan mode auto-review gate using Codex CLI.
  Reviews implementation plans before ExitPlanMode, with up to 3 rounds
  of review using codex exec resume --last for context preservation.
---

# Codex Plan Auto-Review Skill

Plan mode でプランを作成した後、**ExitPlanMode の前に** Codex で自動レビュー。
致命的指摘がなくなるまで修正→再レビューをループ（最大3ラウンド）。

## Authentication — サブスクリプション優先

Codex CLI はサブスクリプション認証（`codex login`）で動作する。**API キーは不要。**

### 認証優先順位

1. **サブスクリプション認証（優先）** — `~/.codex/auth.json` に保存済み
   - `codex login` で認証。この環境では認証済み
   - `OPENAI_API_KEY` 環境変数は **設定しない**（設定するとサブスクではなく API 課金になる）
2. **API キー（フォールバック）** — サブスク認証が失敗した場合のみ
   - `secrets4claude` で `OPENAI_API_KEY` を取得して設定

### 重要: secrets4claude を自動発火しない

Codex 実行時に `secrets4claude` で `OPENAI_API_KEY` を自動セットしてはならない。
サブスク認証が使われなくなり、API 課金が発生するため。
認証エラーが出た場合のみ、以下の順序で対処：
1. `codex login` の再実行を案内
2. それでも失敗 → `secrets4claude --bundle openai` でフォールバック

## Usage

```
/codexplan4claude
/codexplan4claude <plan_file_path>
```

引数なしの場合、現在の plan mode コンテキストからプランファイルを自動検出する。

## Trigger

- **手動**: `/codexplan4claude` or `/codexplan4claude <plan_file_path>`
- **自動**: plan mode でプラン作成完了時（ExitPlanMode 直前）

## Review Flow

```
Claude がプラン作成完了
  |
  +---> Round 1: codex exec --sandbox read-only (初回レビュー)
  |       +-- "致命的な問題なし" --> PASS --> ExitPlanMode
  |       +-- 致命的指摘あり --> Claude がプラン修正
  |             |
  +---> Round 2: codex exec resume --last (再レビュー, 文脈保持)
  |       +-- "致命的な問題なし" --> PASS --> ExitPlanMode
  |       +-- 致命的指摘あり --> Claude がプラン修正
  |             |
  +---> Round 3: codex exec resume --last (最終)
  |       +-- 結果に関わらず PASS（未解決はプランに注記）
  |
  +---> エラー時 --> スキップして ExitPlanMode
```

## Codex CLI Execution

### Round 1 (Initial Review)

```bash
OUTPUT_FILE=$(mktemp /tmp/codex-plan-review-XXXXXX.txt)
STDERR_FILE=$(mktemp /tmp/codex-plan-review-err-XXXXXX.txt)

codex exec \
  --full-auto \
  --sandbox read-only \
  --skip-git-repo-check \
  -c 'mcp_servers={}' \
  -o "$OUTPUT_FILE" \
  --cd "$(pwd)" \
  "以下の実装プランをレビューしろ。致命的な問題のみ指摘しろ。瑣末な点へのクソリプはしないで。

致命的な問題とは:
- アーキテクチャの根本的な誤り
- 実装不可能な前提（存在しないAPIの使用等）
- 重大な見落とし（データ損失リスク、セキュリティホール等）
- 依存関係の致命的な矛盾

OK なら一言「致命的な問題なし」とだけ返せ。

<plan>
$(cat {PLAN_FILE})
</plan>

<project_context>
$(cat ./CLAUDE.md 2>/dev/null || echo 'N/A')
</project_context>

If information is insufficient, state your assumptions explicitly.
Do not return questions — always complete your own analysis." 2>"$STDERR_FILE"
```

### Round 2+ (Resume with Context Preservation)

```bash
OUTPUT_FILE_N=$(mktemp /tmp/codex-plan-review-XXXXXX.txt)

codex exec resume --last \
  --full-auto \
  --skip-git-repo-check \
  --json \
  "プランを修正した。前回の指摘が解決されたか確認し、新たな致命的問題がないかチェックしろ。
瑣末な点へのクソリプはしないで。OK なら「致命的な問題なし」とだけ返せ。

修正後プラン:
$(cat {PLAN_FILE})

Do not return questions — always complete your own analysis." > "$OUTPUT_FILE_N" 2>/dev/null
```

**注意**: `codex exec resume` は `-o` フラグ非対応。`--json` + stdout リダイレクトで取得。

### Important Options

| Option | Purpose |
|--------|------|
| `--full-auto` | Execute without confirmations |
| `--sandbox read-only` | Safe read-only execution (Round 1 only) |
| `--skip-git-repo-check` | Works outside git repositories |
| `-c 'mcp_servers={}'` | Disable MCP servers for fast startup (Round 1 only) |
| `-o <file>` | Save output to file (Round 1 only) |
| `--cd "$(pwd)"` | Execute in current project directory (Round 1 only) |
| `resume --last` | Resume last session with context preservation (Round 2+) |
| `--json` | JSON output for stdout capture (Round 2+) |

## Convergence Criteria

| Condition | Action |
|-----------|--------|
| "致命的な問題なし" or short affirmative response | **PASS** — proceed to ExitPlanMode |
| Contains "致命的" / "critical" / "blocker" / "security hole" | Modify plan → next round |
| Round 3 completed | **Force PASS** — note unresolved issues in plan |
| Codex execution failure (non-zero exit / empty output) | **Skip** — proceed to ExitPlanMode |

### Convergence Detection Logic

Claude reads the output file and checks:

1. **PASS signals**: Output contains "致命的な問題なし" / "no critical issues" / "LGTM" / is a short affirmative (< 100 chars)
2. **FAIL signals**: Output contains "致命的" / "critical" / "blocker" / "security hole" / "data loss" / "vulnerability"
3. **Ambiguous**: If neither clear PASS nor FAIL, treat as PASS (don't over-loop)

## Plan Modification on Failure

When Codex identifies critical issues:

1. Claude reads the specific issues from the output
2. Claude modifies the plan file to address each critical issue
3. Claude notes the modification with a brief comment
4. Proceed to next review round

## User Visibility

The review process is **invisible to the user**. Only the reviewed plan is presented.
If critical issues were found and fixed, append a single note at the end of the plan:

```
> Note: Codex cross-review で修正済み: [1-line summary]
```

## Safety Checks

Before sending plan content to Codex:

1. **Secret detection**: Check for API keys, credentials, tokens in plan content
2. **Scope limit**: Only send the plan file and CLAUDE.md, not the entire codebase
3. **Binary exclusion**: Don't include images or compiled files

## Error Handling

| Situation | Action |
|-----------|--------|
| exit code != 0 | Check stderr file, skip review, proceed to ExitPlanMode |
| Empty output file | Skip review, proceed to ExitPlanMode |
| Timeout | Skip review, proceed to ExitPlanMode |
| Auth error | 1) `codex login` 再実行を案内 2) 失敗なら `secrets4claude --bundle openai` でフォールバック |

## Examples

```
# Auto-review current plan (in plan mode)
/codexplan4claude

# Review a specific plan file
/codexplan4claude /tmp/plan-auth-system.md

# Typical auto-fire scenario:
# 1. Claude creates plan in plan mode
# 2. codexplan4claude auto-fires
# 3. Codex reviews → Claude fixes → re-review
# 4. PASS → ExitPlanMode
```

## Notes

- Codex はサブスクリプション認証で動作する（`~/.codex/auth.json`）。API キーは不要
- サブスク認証が有効な場合、`OPENAI_API_KEY` を設定すると API 課金になるため設定しないこと
- 最大3ラウンド。通常は1-2ラウンドで収束する
- `resume --last` により前回の議論文脈が保持される
- レビューはプランの品質ゲートであり、実装の代替ではない
- 出力ファイルは各ラウンド後にクリーンアップすること
