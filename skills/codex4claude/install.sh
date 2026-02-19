#!/bin/bash
# codex4claude - Quick Install Script
# Usage: bash install.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
SKILL_DIR="${HOME}/.claude/skills/codex4claude"
PROMPT_DIR="${HOME}/.claude/prompts/codex"

echo "=== codex4claude Installer ==="
echo ""

# Check prerequisites
echo "[1/4] Checking prerequisites..."

if ! command -v claude &> /dev/null; then
    echo "  WARNING: Claude Code CLI not found."
    echo "  Install: npm install -g @anthropic-ai/claude-code"
    echo "  Then run: claude login"
fi

if ! command -v codex &> /dev/null; then
    echo "  WARNING: Codex CLI not found."
    echo "  Install: npm install -g @openai/codex"
    echo "  Then run: codex login"
fi

# Install skill
echo "[2/4] Installing skill..."
mkdir -p "$SKILL_DIR"
cp "$SCRIPT_DIR/skill/SKILL.md" "$SKILL_DIR/SKILL.md"
echo "  Installed: $SKILL_DIR/SKILL.md"

# Install prompts (optional)
echo "[3/4] Installing prompt templates..."
mkdir -p "$PROMPT_DIR"
cp "$SCRIPT_DIR/prompts/"*.md "$PROMPT_DIR/"
echo "  Installed: $PROMPT_DIR/"

# Verify
echo "[4/4] Verifying installation..."
if [ -f "$SKILL_DIR/SKILL.md" ]; then
    echo "  Skill file: OK"
else
    echo "  Skill file: MISSING"
    exit 1
fi

PROMPT_COUNT=$(ls "$PROMPT_DIR/"*.md 2>/dev/null | wc -l | tr -d ' ')
echo "  Prompt templates: ${PROMPT_COUNT} files"

echo ""
echo "=== Installation complete! ==="
echo ""
echo "Usage in Claude Code:"
echo "  /codex4claude <your topic>"
echo ""
echo "Examples:"
echo "  /codex4claude discuss this microservice architecture"
echo "  /codex4claude review src/auth/jwt.ts critically"
echo ""
