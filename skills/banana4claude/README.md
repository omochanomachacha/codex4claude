# banana4claude

A Claude Code skill for AI image generation using Nano Banana Pro (Gemini image model) via Vertex AI.

Supports text-to-image generation, image editing, icons, diagrams, and UI mockups — all from within Claude Code.

## Features

- **Text-to-image**: Generate images from natural language prompts
- **Image editing**: Modify existing images with text instructions
- **Specialized templates**: Icons, diagrams, UI mockups with optimized prompts
- **Multiple styles**: photorealistic, flat, modern, pixel-art, minimal, sketch, watercolor, 3d-render
- **Flexible output**: Custom aspect ratios, sizes, and output directories

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- GCP project with Vertex AI API enabled (`aiplatform.googleapis.com`)
- ADC authentication: `gcloud auth application-default login`
- IAM role: `roles/aiplatform.user`
- Environment variable: `export GCP_PROJECT_ID="your-project-id"`

## Installation

Copy the skill files to your Claude Code skills directory:

```bash
mkdir -p ~/.claude/skills/banana4claude/scripts
cp SKILL.md ~/.claude/skills/banana4claude/
cp scripts/nanobanana-wrapper ~/.claude/skills/banana4claude/scripts/
chmod +x ~/.claude/skills/banana4claude/scripts/nanobanana-wrapper
```

## Usage

```
/banana4claude A serene mountain landscape at sunset
/banana4claude icon: Shopping cart for e-commerce --style=flat
/banana4claude diagram: User authentication flow
/banana4claude ui: Login page with social auth buttons
/banana4claude edit: /path/to/image.png Remove the background
```

## License

MIT
