# UsefulSkill-by-Kubotin

A collection of [Claude Code](https://docs.anthropic.com/en/docs/claude-code) skills for multi-model AI collaboration and image generation.

## Skills

### [codex4claude](skills/codex4claude/)

Multi-round debate between Claude Code and [Codex CLI](https://github.com/openai/codex) (OpenAI GPT). Get deep discussions, critical reviews, and second opinions by having two AI models argue and converge on conclusions.

**Requires:** Claude Code + Codex CLI (`npm install -g @openai/codex`)

### [gemini4claude](skills/gemini4claude/)

Multi-round debate between Claude Code and [Gemini CLI](https://github.com/google-gemini/gemini-cli) (Google). Leverages Gemini's strengths in UI/UX, frontend, and accessibility for diverse perspectives.

**Requires:** Claude Code + Gemini CLI

### [banana4claude](skills/banana4claude/)

AI image generation using Nano Banana Pro (Gemini image model) via Vertex AI. Supports text-to-image, image editing, icons, diagrams, and UI mockups — all from within Claude Code.

**Requires:** Claude Code + GCP project with Vertex AI API enabled

## Installation

Each skill can be installed independently. See the README in each skill directory for instructions.

### Quick Install (all skills)

```bash
git clone https://github.com/AnyMindGroup/UsefulSkill-by-Kubotin.git
cd UsefulSkill-by-Kubotin

# codex4claude
mkdir -p ~/.claude/skills/codex4claude
cp skills/codex4claude/SKILL.md ~/.claude/skills/codex4claude/

# gemini4claude
mkdir -p ~/.claude/skills/gemini4claude
cp skills/gemini4claude/SKILL.md ~/.claude/skills/gemini4claude/

# banana4claude
mkdir -p ~/.claude/skills/banana4claude/scripts
cp skills/banana4claude/SKILL.md ~/.claude/skills/banana4claude/
cp skills/banana4claude/scripts/nanobanana-wrapper ~/.claude/skills/banana4claude/scripts/
chmod +x ~/.claude/skills/banana4claude/scripts/nanobanana-wrapper
```

## License

MIT License. See [LICENSE](LICENSE) for details.
