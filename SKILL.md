---
name: codex4claude
description: |
  Multi-round debate skill between Claude Code and Codex CLI (OpenAI GPT).
  Enables deep discussion, critical review, and second opinions by having
  two AI models argue and converge on conclusions.
---

# Codex CLI Discussion - Multi-round Debate Skill

Codex CLI is invoked directly, and Claude and Codex engage in multiple rounds of discussion.
CLI execution (not MCP) enables real-time progress monitoring and flexible control.

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
/codex4claude <topic / question / code to discuss>
```

Run without arguments to start a discussion based on the current conversation context.

## Modes

Automatically selected based on user intent:

| User Expression | Mode | Description |
|----------------|--------|------|
| discuss | `debate` | Argue pros and cons |
| think deeply | `deep-analysis` | Explore from multiple angles |
| critique | `critique` | Thoroughly pursue weaknesses and risks |
| second opinion | `second-opinion` | Get an alternative expert perspective |
| review | `review` | Code/design review |
| challenge / devil's advocate | `devils-advocate` | Intentionally present opposing views |

## Codex CLI Execution

### Basic Command

```bash
# Generate unique output file
OUTPUT_FILE=$(mktemp /tmp/codex-discuss-XXXXXX.txt)
STDERR_FILE=$(mktemp /tmp/codex-discuss-err-XXXXXX.txt)

codex exec \
  --full-auto \
  --sandbox read-only \
  --skip-git-repo-check \
  -c 'mcp_servers={}' \
  -o "$OUTPUT_FILE" \
  --cd "$(pwd)" \
  "<prompt>" 2>"$STDERR_FILE"

# Read output
Read "$OUTPUT_FILE"

# Check stderr only on failure
# If exit code != 0 or output is empty, check $STDERR_FILE
```

### Important Options

| Option | Purpose |
|--------|------|
| `--full-auto` | Execute without confirmations |
| `--sandbox read-only` | Safe read-only execution |
| `--skip-git-repo-check` | Works outside git repositories |
| `-c 'mcp_servers={}'` | Disable MCP servers for fast startup |
| `-o <file>` | Save output to file (for parsing) |
| `--cd "$(pwd)"` | Execute in current project directory |

### Safety Checks Before Execution

Before sending code/text as context, verify:

1. **Secret detection**: Check for `.env`, `.env.local`, `credentials.json`, API key patterns (`sk-`, `ghp_`, `AKIA`, etc.)
2. **File scope**: Limit to files necessary for the discussion. Don't send the entire repository
3. **Binary exclusion**: Don't include images or compiled files

If dangerous patterns are detected, confirm with the user before sending.

### Mandatory Prompt Suffix

To prevent Codex from entering an input-waiting state, **always** append this to the prompt:

```
If information is insufficient, state your assumptions explicitly and branch your conclusions per assumption. Write them out completely.
Do not return questions — always complete your own analysis.
```

### Error Handling

| Situation | Action |
|-----------|--------|
| exit code != 0 | Check stderr file, report error to user |
| Empty output file | Codex failed to generate a response. Check stderr, simplify prompt and retry |
| Timeout | Prompt may be too long. Summarize context and retry |
| Auth error / API key not set | 1) `codex login` 再実行を案内 2) 失敗なら `secrets4claude --bundle openai` でフォールバック |

## Multi-round Discussion Process

### Round 1: Initial Query

Claude organizes the theme and sends to Codex:

```
You are a senior software engineer.
Please state your expert opinion on the following topic.

<context>
Topic: {user's question/theme}

Context:
{relevant code and background information}
</context>

Mode: {debate|critique|deep-analysis|...}

Please analyze from the following perspectives:
- Technical accuracy
- Design trade-offs
- Potential risks and oversights
- Alternative approach proposals

【Output Format】
After your free-form analysis, always include the following at the end:
- Assumptions: List any assumptions you made
- New Issues: Key issues raised in this analysis (max 5)
- Falsification Conditions: Conditions under which your claims would be invalidated
- Recommended Actions: Concrete next steps (max 3)

If information is insufficient, state your assumptions explicitly and branch your conclusions per assumption. Write them out completely.
Do not return questions — always complete your own analysis.
```

### Round 2-N: Iterative Discussion

Claude analyzes Codex's previous round response and:

1. **Acknowledges points of agreement**
2. **Determines if there are points to change with conviction** (don't inflate minor differences)
3. **Examines whether seemingly equal options have a clear winner when analyzed deeply**
4. **Only asks Codex to reconsider truly important issues**

```
<previous_round>
Your previous analysis:
{Codex's response from the previous round}
</previous_round>

<counter_arguments>
Feedback on the above:
{Claude's analysis/counterarguments/agreements}
</counter_arguments>

Based on the above, please respond to the following:

1. If you want to change any points with conviction, state them. If not, explicitly say "I agree."
2. If you've updated any views, explicitly state what changed and why.
3. For points of disagreement, could deeper analysis reach a conclusion? If so, dig deeper.

Important (mode-specific policy):
- debate / second-opinion / deep-analysis mode: Don't actively seek differences. Only continue discussing truly important issues.
- critique / devils-advocate mode: Finding differences is the goal, so actively point out weaknesses, contradictions, and risks. But prioritize quality of criticism over nitpicking.
- review mode: Only point out important differences.

【Output Format】
After your free-form analysis, always include the following at the end:
- Updates: Points where views changed or were added (or "None")
- Remaining Issues: Important issues without conclusions yet (or "None")
- Room for Deeper Analysis: Can further analysis of remaining issues reach conclusions? (Yes/No + reason)
- Recommended Actions: Concrete next steps (max 3)

If information is insufficient, state your assumptions explicitly and branch your conclusions per assumption. Write them out completely.
Do not return questions — always complete your own analysis.
```

### Convergence Detection (Dynamic Round Control)

**Default: Minimum 2 rounds.** After that, judge by convergence conditions.

#### Termination Conditions (end discussion when any are met)

- **Full Convergence**: Codex explicitly states "I agree" and remaining issues are "None"
- **Topic Saturation**: Repetition of the same arguments with different wording
- **Maximum Rounds Reached**: 5 rounds (safety limit)
- **User Instruction**: User explicitly requests termination

#### Deep Analysis Check (always perform before termination)

Before ending discussion, classify remaining "points of disagreement" with these questions:

1. **Can it be verified as fact?** (verifiable via technical specs, benchmarks, documentation)
   -> Additional round trigger: Only when ALL 3 conditions are met: **high impact + primary evidence not yet presented + evidence is obtainable**. Otherwise, judge with current information
2. **Can deeper logical analysis determine a winner?** (seems equal on surface, but deep analysis reveals differences)
   -> Yes: One more round with specific conditions/numbers/examples
3. **Does the answer depend on user's context?**
   -> Yes: Include as conditional branches in final output
4. **All of the above are No**
   -> Claude recommends one side and ends. Express with **medium or lower confidence** (e.g., "If I had to choose, X seems better")

**"Disagreement" is an intermediate state, not a final state.** Don't take the easy "either is fine" escape — dig deeper where possible.

However, for **high-impact irreversible decisions** (fundamental architecture choices, technology stack changes, etc.), it's acceptable to present conditions and defer to the user.

### Final Synthesis — Generating User Response

After discussion ends, Claude generates **an answer to the user's question, not meeting minutes**.

#### Claude's Role

Claude acts not as a "neutral minute-taker" but as **"the primary physician who makes a judgment after hearing a second opinion"**.
Hide the internal discussion process (who said what, how many rounds) and output one integrated answer.

#### Output Principles

1. **No fixed template**: Use headings and bullet points freely to fit the question format. Write in the same style and length as normal Claude chat
2. **Conclusion first**: Answer the user's question directly in the first 1-2 sentences. No preambles, greetings, or meta-descriptions
3. **Don't mention AI names**: Don't use "Claude", "Codex", "Round" in principle (exception: when necessary as the topic of the user's question)
4. **Leverage discussion depth**: Weave all insights from the discussion (counterarguments, trade-off analysis, conditional branches) into the answer. But as natural prose, not "In Round 1... In Round 2..."
5. **Express confidence verbally**:
   - High confidence (converged): "You should do X" "X is optimal"
   - Medium confidence (somewhat divided): "X seems good. However, there's also the perspective of Y"
   - Low confidence (significantly divided): "If X, then A is appropriate; if Y, then B"
6. **Make judgments where possible**: Don't end with "there are arguments on both sides" — state Claude's own recommendation. Only use conditional branches when it truly depends on user context

#### Required Response Elements (use as checklist, not as headings)

- [ ] Direct answer to user's question (conclusion)
- [ ] Evidence (why this can be said)
- [ ] Conditional judgments ("however, in case of X, then Y")
- [ ] Concrete next actions
- [ ] If uncertain, branches with explicit assumptions

#### Self-Check (perform internally before output, don't show to user)

1. Does the opening directly answer the user's question?
2. Are forbidden words (Claude / Codex / Round) unnecessarily included?
3. Are the checklist elements satisfied?
4. Is it as readable and appropriately sized as normal chat? (Not report-style?)

#### Discussion Log Handling

Attach raw discussion logs in a collapsible section. Supplementary material for interested users, not the main answer.

```markdown
<details>
<summary>Discussion details ({N} rounds)</summary>

{Summary of each round here}

</details>
```

## Code Review Mode

When performing code review with `/codex4claude`, the `codex review` command is also available:

```bash
# Review uncommitted changes
codex review --uncommitted

# Review diff against a specific branch
codex review --base main

# Review a specific commit
codex review --commit <SHA>

# Review with custom instructions
codex review "Please review especially from a security perspective"
```

`codex review` runs non-interactively and outputs results directly.
However, use `codex exec` for the discussion loop when multi-round discussion is needed.

## Passing Project Context

To improve discussion quality, include the following context as appropriate:

1. **Code**: Read and include relevant parts of target files (wrap in `<context>` tags)
2. **git diff**: Include `git diff` output when there are changes
3. **Error logs**: Include error information for debugging discussions
4. **Architecture**: Include relevant file structure for design discussions

Always wrap context in `<context>` tags to tell Codex "only information within tags is factual."

## Examples

```
# Discuss a design
/codex4claude Is this microservice split appropriate?

# Critical code review
/codex4claude Critique the security of src/auth/jwt.ts

# Second opinion
/codex4claude I want a second opinion on Redis vs Memcached selection

# Deep analysis
/codex4claude Think deeply about the root solution for this N+1 query problem

# Request counterarguments
/codex4claude I think CSR is more appropriate than SSR in this case. Challenge that
```

## Notes

- Codex はサブスクリプション認証で動作する（`~/.codex/auth.json`）。API キーは不要
- サブスク認証が有効な場合、`OPENAI_API_KEY` を設定すると API 課金になるため設定しないこと
- Each round consumes tokens, so avoid unnecessarily long discussions
- Due to `--sandbox read-only`, Codex cannot modify files. Code changes should be done on the Claude side
- If Codex's response is long, summarize before passing to the next round
- Always verify no sensitive information (API keys, credentials, .env, etc.) is included before sending
- Clean up output files after discussion completion
