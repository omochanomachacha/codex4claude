---
name: gemini4claude
description: |
  Multi-round debate skill between Claude Code and Gemini CLI (Google).
  Leverages Gemini's strengths in UI/UX, frontend, and accessibility
  for deep discussion and second opinions.
---

# Gemini CLI Discussion - Multi-round Debate Skill

Gemini CLI is invoked directly, and Claude and Gemini engage in multiple rounds of discussion.
CLI execution (not MCP) enables real-time progress monitoring and flexible control.

## Gemini's Strengths

- **UI/UX Design**: Component design, responsive design, interactions
- **Frontend**: React, Vue, Angular, CSS/Tailwind, animations
- **Accessibility**: WCAG compliance, screen reader support, keyboard navigation
- **Google Ecosystem**: GCP, Firebase, Material Design, Angular

## Usage

```
/gemini4claude <topic / question / code to discuss>
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

## Gemini CLI Execution

### Basic Command

```bash
# Generate unique output file
OUTPUT_FILE=$(mktemp /tmp/gemini-discuss-XXXXXX.txt)
STDERR_FILE=$(mktemp /tmp/gemini-discuss-err-XXXXXX.txt)

gemini -p "<prompt>" \
  -y \
  --approval-mode plan \
  -o text \
  > "$OUTPUT_FILE" 2>"$STDERR_FILE"

# Read output
Read "$OUTPUT_FILE"

# Check stderr only on failure
# If exit code != 0 or output is empty, check $STDERR_FILE
```

### Important Options

| Option | Purpose |
|--------|------|
| `-p "<prompt>"` | Pass prompt in non-interactive mode |
| `-y` | Auto-approve confirmation prompts |
| `--approval-mode plan` | Safe read-only execution |
| `-o text` | Output in text format |
| `> file` | Redirect stdout to save output to file |

### Safety Checks Before Execution

Before sending code/text as context, verify:

1. **Secret detection**: Check for `.env`, `.env.local`, `credentials.json`, API key patterns (`sk-`, `ghp_`, `AKIA`, etc.)
2. **File scope**: Limit to files necessary for the discussion. Don't send the entire repository
3. **Binary exclusion**: Don't include images or compiled files

If dangerous patterns are detected, confirm with the user before sending.

### Mandatory Prompt Suffix

To prevent Gemini from entering an input-waiting state, **always** append this to the prompt:

```
If information is insufficient, state your assumptions explicitly and branch your conclusions per assumption. Write them out completely.
Do not return questions — always complete your own analysis.
```

### Error Handling

| Situation | Action |
|-----------|--------|
| exit code != 0 | Check stderr file, report error to user |
| Empty output file | Gemini failed to generate a response. Check stderr, simplify prompt and retry |
| Timeout | Prompt may be too long. Summarize context and retry |
| Auth error | Guide user to run `gemini auth login` |

## Multi-round Discussion Process

### Round 1: Initial Query

Claude organizes the theme and sends to Gemini:

```
You are a senior frontend engineer / UI/UX specialist.
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

Claude analyzes Gemini's previous round response and:

1. **Acknowledges points of agreement**
2. **Determines if there are points to change with conviction** (don't inflate minor differences)
3. **Examines whether seemingly equal options have a clear winner when analyzed deeply**
4. **Only asks Gemini to reconsider truly important issues**

```
<previous_round>
Your previous analysis:
{Gemini's response from the previous round}
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

- **Full Convergence**: Gemini explicitly states "I agree" and remaining issues are "None"
- **Topic Saturation**: Repetition of the same arguments with different wording
- **Maximum Rounds Reached**: 5 rounds (safety limit)
- **User Instruction**: User explicitly requests termination

#### Deep Analysis Check (always perform before termination)

Before ending discussion, classify remaining "points of disagreement" with these questions:

1. **Can it be verified as fact?** (verifiable via technical specs, benchmarks, documentation)
   -> Additional round trigger: Only when ALL 3 conditions are met: **high impact + primary evidence not yet presented + evidence is obtainable**
2. **Can deeper logical analysis determine a winner?**
   -> Yes: One more round with specific conditions/numbers/examples
3. **Does the answer depend on user's context?**
   -> Yes: Include as conditional branches in final output
4. **All of the above are No**
   -> Claude recommends one side with medium or lower confidence

### Final Synthesis — Generating User Response

After discussion ends, Claude generates **an answer to the user's question, not meeting minutes**.

#### Claude's Role

Claude acts as **"the primary physician who makes a judgment after hearing a second opinion"**.
Hide the internal discussion process and output one integrated answer.

#### Output Principles

1. **No fixed template**: Write in the same style and length as normal Claude chat
2. **Conclusion first**: Answer the user's question directly in the first 1-2 sentences
3. **Don't mention AI names**: Don't use "Claude", "Gemini", "Round" in principle
4. **Leverage discussion depth**: Weave all insights into the answer as natural prose
5. **Express confidence verbally**:
   - High confidence: "You should do X"
   - Medium confidence: "X seems good. However, there's also the perspective of Y"
   - Low confidence: "If X, then A is appropriate; if Y, then B"
6. **Make judgments where possible**: State Claude's own recommendation

#### Discussion Log Handling

Attach raw discussion logs in a collapsible section:

```markdown
<details>
<summary>Discussion details ({N} rounds)</summary>

{Summary of each round here}

</details>
```

## Passing Project Context

To improve discussion quality, include the following context as appropriate:

1. **Code**: Read and include relevant parts of target files (wrap in `<context>` tags)
2. **git diff**: Include `git diff` output when there are changes
3. **Error logs**: Include error information for debugging discussions
4. **Architecture**: Include relevant file structure for design discussions

Always wrap context in `<context>` tags to tell Gemini "only information within tags is factual."

## Examples

```
# Discuss UI design
/gemini4claude Is this dashboard layout appropriate?

# Critical frontend review
/gemini4claude Critique this React component design

# Accessibility review
/gemini4claude Review from an accessibility perspective

# Design system
/gemini4claude Discuss this design system's component structure

# Performance
/gemini4claude Think deeply about frontend bundle size optimization
```

## Notes

- Gemini CLI requires Google account authentication
- Each round consumes API tokens, so avoid unnecessarily long discussions
- Due to `--approval-mode plan`, Gemini cannot modify files. Code changes should be done on the Claude side
- If Gemini's response is long, summarize before passing to the next round
- Always verify no sensitive information (API keys, credentials, .env, etc.) is included before sending
- Clean up output files after discussion completion
