# video4claude

A Claude Code skill for analyzing video files using Vertex AI Gemini.

Sends videos natively to Gemini — no transcription or frame extraction needed. The model sees the full video including visual content and audio.

## Features

- **Native video input**: Send MP4, MOV, AVI, MKV, WebM files directly to Gemini
- **Any prompt**: Summarize, extract, analyze, describe — any analysis task
- **Large file support**: Automatic GCS upload for videos over 20MB
- **Model choice**: Use gemini-2.5-flash (fast) or gemini-2.5-pro (detailed)

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- GCP project with Vertex AI API enabled (`aiplatform.googleapis.com`)
- ADC authentication: `gcloud auth application-default login`
- IAM role: `roles/aiplatform.user`
- Environment variable: `export GCP_PROJECT_ID="your-project-id"`

## Installation

Copy the skill files to your Claude Code skills directory:

```bash
mkdir -p ~/.claude/skills/video4claude/scripts
cp SKILL.md ~/.claude/skills/video4claude/
cp scripts/video-analyzer ~/.claude/skills/video4claude/scripts/
chmod +x ~/.claude/skills/video4claude/scripts/video-analyzer
```

## Usage

```
/video4claude /path/to/video.mp4 What is happening in this video?
/video4claude ./meeting.mp4 Summarize the key discussion points
/video4claude ./demo.mp4 List all UI interactions shown
/video4claude ./presentation.mp4 Extract all text from the slides
```

## License

MIT
