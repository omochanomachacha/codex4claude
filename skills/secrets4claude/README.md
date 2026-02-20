# secrets4claude

A Claude Code skill for securely fetching API keys and credentials from GCP Secret Manager.

Secrets are retrieved on-demand via `gcloud` and never persisted to disk. Designed for use with tools that need API keys (OpenAI, Apify, Data365, etc.) without storing them in `.env` files or shell config.

## Features

- **On-demand fetch**: Retrieve secrets only when needed, use inline
- **Batch loading**: Load multiple secrets into the shell session at once
- **Security-first**: SKILL.md enforces rules against echoing or saving secret values
- **Simple naming**: Secret name = environment variable name (e.g., `OPENAI_API_KEY`)

## Prerequisites

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and authenticated
- GCP project with Secret Manager API enabled (`secretmanager.googleapis.com`)
- ADC authentication: `gcloud auth login`
- IAM role: `roles/secretmanager.secretAccessor`
- Environment variable: `export GCP_PROJECT_ID="your-project-id"`

## Installation

Copy the skill files to your Claude Code skills directory:

```bash
mkdir -p ~/.claude/skills/secrets4claude/scripts
cp SKILL.md ~/.claude/skills/secrets4claude/
cp scripts/secret-fetch ~/.claude/skills/secrets4claude/scripts/
chmod +x ~/.claude/skills/secrets4claude/scripts/secret-fetch
```

## Storing Secrets

```bash
echo -n "sk-..." | gcloud secrets create OPENAI_API_KEY --data-file=- --project=your-project-id
echo -n "apify_..." | gcloud secrets create APIFY_API_KEY --data-file=- --project=your-project-id
```

## Usage

```
/secrets4claude load OPENAI_API_KEY APIFY_API_KEY DATA365_API_KEY
/secrets4claude list
/secrets4claude get OPENAI_API_KEY
```

## License

MIT
