# gemini4claude

A Claude Code skill that invokes [Gemini CLI](https://github.com/google-gemini/gemini-cli) (Google) for multi-round discussions between Claude and Gemini.

Leverages Gemini's strengths in UI/UX, frontend development, and accessibility to provide diverse perspectives that a single model cannot achieve.

## Features

- **Multi-round debate**: Claude and Gemini alternate presenting arguments, making agreements and disagreements visible
- **6 modes**: debate / deep-analysis / critique / second-opinion / review / devils-advocate
- **Dynamic round control**: Automatically ends discussion based on convergence conditions (max 5 rounds)
- **Safe sandbox**: Gemini runs in plan-only mode, cannot modify files

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- [Gemini CLI](https://github.com/google-gemini/gemini-cli) installed and authenticated (`gemini auth login`)

## Installation

Copy the `SKILL.md` file to your Claude Code skills directory:

```bash
mkdir -p ~/.claude/skills/gemini4claude
cp SKILL.md ~/.claude/skills/gemini4claude/
```

## Usage

```
/gemini4claude Is this dashboard layout appropriate?
/gemini4claude Critique this React component design
/gemini4claude Review from an accessibility perspective
```

## License

MIT
