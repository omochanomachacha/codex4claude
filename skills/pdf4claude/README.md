# pdf4claude

A Claude Code skill for analyzing PDF files using Vertex AI Gemini.

Sends PDFs natively to Gemini — no text extraction or OCR needed. The model sees the full document including layout, images, charts, and tables.

## Features

- **Native PDF input**: Send PDF files directly to Gemini, preserving all visual information
- **Any prompt**: Summarize, extract tables, translate, review — any analysis task
- **Visual understanding**: Charts, diagrams, scanned pages, handwritten notes all work
- **Large file support**: Automatic GCS upload for PDFs over 20MB
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
mkdir -p ~/.claude/skills/pdf4claude/scripts
cp SKILL.md ~/.claude/skills/pdf4claude/
cp scripts/pdf-analyzer ~/.claude/skills/pdf4claude/scripts/
chmod +x ~/.claude/skills/pdf4claude/scripts/pdf-analyzer
```

## Usage

```
/pdf4claude /path/to/report.pdf Summarize the key findings
/pdf4claude ./invoice.pdf Extract all line items as a table
/pdf4claude ./japanese-doc.pdf Translate to English
/pdf4claude ./architecture.pdf Explain the system diagrams
```

## License

MIT
