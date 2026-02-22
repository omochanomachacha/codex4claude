---
name: codexmulti4claude
description: |
  Parallel agent execution with cross-pollination.
  Decomposes tasks into 2-4 dimensions, runs Task agents in parallel,
  then resumes each with findings from others for deeper analysis.
  Works for exploration, implementation, and review.
---

# Codex Multi-Agent Parallel Execution Skill

タスクを複数ディメンションに分解し、Task エージェントを並列起動。
Phase 1 完了後、同じエージェントを resume して他エージェントの知見を注入し深掘り。
**探索フェーズにも実装フェーズにも使える汎用並列実行スキル。**

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
/codexmulti4claude <task description>
```

## Trigger

- **手動**: `/codexmulti4claude <task description>`
- **自動**: 3+ の独立サブタスクが識別された場合

## Modes

| Mode | Use Case | Phase 2 Content |
|------|----------|-----------------|
| `explore` | Codebase investigation (for plan mode) | Inject other agents' discoveries, re-investigate |
| `implement` | Parallel implementation (independent modules) | Adjust based on other agents' implementation results |
| `review` | Parallel review (multiple perspectives) | Re-evaluate based on other reviewers' findings |

### Auto Mode Selection

- "調べて" / "explore" / "investigate" / "分析して" → `explore`
- "実装して" / "implement" / "作って" / "追加して" → `implement`
- "レビューして" / "review" / "チェックして" → `review`

## Flow

```
ユーザーがタスク指示
  |
  +---> Claude がタスクを 2-4 ディメンションに分解
  |
  +---> Phase 1: Task エージェント並列起動
  |       +-- Agent A: ディメンション 1
  |       +-- Agent B: ディメンション 2
  |       +-- Agent C: ディメンション 3
  |       +-- Agent D: ディメンション 4 (optional)
  |
  +---> Claude が全結果を統合（クロスポリネーション要約）
  |
  +---> Phase 2: 同じエージェントを resume
  |       +-- Agent A: "B が X、C が Y を発見/実装。これを踏まえて再検討/調整せよ"
  |       +-- Agent B: "A が P を発見/実装。これを踏まえて再検討/調整せよ"
  |       +-- Agent C: "A,B の結果を踏まえて再検討/調整せよ"
  |
  +---> 最終統合 --> ユーザーに結果提示
```

## Dimension Selection

### Explore Mode Dimensions

| Dimension | Agent Focus |
|-----------|-----------|
| `architecture` | Module boundaries, data flow, extension points |
| `dependencies` | Package dependencies, internal coupling, breaking change risks |
| `test-coverage` | Existing test patterns, coverage gaps |
| `precedents` | Similar features, coding conventions, reusable utilities |
| `security` | Auth flows, input validation, permission boundaries |
| `performance` | Hot paths, query patterns, bottlenecks |

Pick 2-4 most relevant dimensions based on the task.

### Implement Mode Dimensions

Dynamically decomposed based on task. Examples:
- API endpoint + Frontend + Tests
- Data model + Business logic + UI
- Core module + Plugin + Documentation
- Service A + Service B + Service C

### Review Mode Dimensions

- `correctness` — Logic errors, edge cases, data integrity
- `security` — Auth, injection, permissions
- `performance` — Complexity, queries, memory
- `maintainability` — Code clarity, patterns, extensibility

### Agent Count Guidelines

| Complexity | Agent Count |
|-----------|------------|
| 2-axis independent tasks | 2 |
| Multi-module work | 3 |
| Large-scale refactor / new subsystem | 4 (max) |

## Phase 1 Prompt Templates

### Explore Mode

```
You are exploring a codebase for an implementation plan.
Assigned dimension: {dimension}
Task: {user's task}
Project: {project_path}

Explore using Glob, Grep, Read. Do NOT modify files.

Report your findings in this format:

## Findings: {dimension}
### Key Discoveries (file paths + line numbers)
### Constraints Identified
### Patterns to Follow
### Risks / Concerns
### Relevant Files
```

### Implement Mode

```
You are implementing one part of a larger task.
Assigned scope: {scope description}
Task: {user's task}
Project: {project_path}

Implement only your assigned scope. Follow existing patterns.
Report what you created/modified and any integration points.

## Implementation: {scope}
### Files Created/Modified
### Integration Points (other agents need to know)
### Remaining TODOs
```

### Review Mode

```
You are reviewing code from a specific perspective.
Assigned perspective: {perspective}
Task: {user's task}
Project: {project_path}
Files to review: {file_list}

Focus ONLY on your assigned perspective. Be thorough but not nitpicky.

## Review: {perspective}
### Critical Issues (must fix)
### Important Suggestions (should fix)
### Minor Notes (nice to have)
```

## Phase 2 Resume Template

```
New context from other agents:
{Summary of other agents' Phase 1 results}

Re-examine your work with this new information:
1. What changes based on cross-cutting concerns?
2. Any contradictions or conflicts between dimensions?
3. Implementation order constraints?
4. Newly visible risks?

Update your findings/implementation accordingly.
```

## Task Agent Configuration

### For Explore Mode

Use `subagent_type: "Explore"` — read-only agents optimized for codebase search.

```
Task tool call:
  description: "Explore {dimension}"
  subagent_type: "Explore"
  prompt: {Phase 1 explore template}
```

### For Implement Mode

Use `subagent_type: "general-purpose"` — full-capability agents with file editing.
Use `isolation: "worktree"` for independent implementation to avoid conflicts.

```
Task tool call:
  description: "Implement {scope}"
  subagent_type: "general-purpose"
  isolation: "worktree"
  prompt: {Phase 1 implement template}
```

### For Review Mode

Use `subagent_type: "Explore"` — read-only is sufficient for review.

```
Task tool call:
  description: "Review {perspective}"
  subagent_type: "Explore"
  prompt: {Phase 1 review template}
```

## Cross-Pollination Summary

After Phase 1, Claude creates a concise summary of each agent's key findings:

```
## Agent Cross-Pollination Summary

### Agent A ({dimension_A}):
- Key finding 1
- Key finding 2
- Identified risk: ...

### Agent B ({dimension_B}):
- Key finding 1
- Key finding 2
- Identified risk: ...

### Intersections:
- {dimension_A} and {dimension_B} both touch {area} — potential conflict
- {dimension_C} discovered {pattern} that affects {dimension_A}'s approach
```

This summary is injected into each agent's Phase 2 resume prompt.

## Error Handling

| Situation | Action |
|-----------|--------|
| 1 Agent timeout | Continue with remaining agents, note gap |
| 1 Agent failure | Continue with remaining agents, note gap |
| Resume failure | Use Phase 1 results only for that agent |
| All Agents fail | Fall back to sequential execution |

## Phase Execution Pattern

### Phase 1 — Parallel Launch

Launch all agents in a **single message** with multiple Task tool calls:

```
[Task call 1: Agent A - dimension 1]
[Task call 2: Agent B - dimension 2]
[Task call 3: Agent C - dimension 3]
```

All agents run concurrently. Wait for all to complete.

### Phase 2 — Parallel Resume

Resume all agents in a **single message** with multiple Task tool calls using `resume`:

```
[Task call 1: resume Agent A with cross-pollination context]
[Task call 2: resume Agent B with cross-pollination context]
[Task call 3: resume Agent C with cross-pollination context]
```

## Final Integration

After Phase 2, Claude synthesizes all results into a unified output:

### For Explore Mode
- Consolidated findings across all dimensions
- Unified risk assessment
- Recommended implementation approach

### For Implement Mode
- Summary of all changes made
- Integration status between modules
- Remaining manual integration steps

### For Review Mode
- Prioritized list of all issues found
- Cross-cutting concerns
- Overall assessment

## Examples

```
# Explore codebase for auth system design
/codexmulti4claude マルチテナント認証システムの設計に必要な情報を調べて

# Parallel implementation of microservices
/codexmulti4claude 3つのマイクロサービスに API エンドポイントを追加して

# Multi-perspective review
/codexmulti4claude src/auth/ 配下のセキュリティ・パフォーマンス・保守性をレビューして
```

## Notes

- Codex はサブスクリプション認証で動作する（`~/.codex/auth.json`）。API キーは不要
- サブスク認証が有効な場合、`OPENAI_API_KEY` を設定すると API 課金になるため設定しないこと
- Agent 数は最大4。それ以上は管理コストが利益を上回る
- Phase 2 の resume により、各エージェントの文脈が保持される
- implement モードでは worktree 分離を使ってファイル競合を防ぐ
- explore / review モードではエージェントは読み取り専用
- 全エージェントの結果を統合するのは Claude の責務
