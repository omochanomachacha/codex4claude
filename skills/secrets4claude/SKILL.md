---
name: secrets4claude
description: |
  Securely fetch API keys and credentials from GCP Secret Manager.
  Secrets are retrieved on-demand and never persisted to disk or environment files.
  Auto-fires when API keys are needed (e.g., before codex exec, external API calls).
---

# secrets4claude - Secure Secret Management via GCP Secret Manager

Fetch API keys and credentials securely from GCP Secret Manager during Claude Code sessions.
Secrets are retrieved on-demand and used inline — never written to files or echoed to the user.

**This skill uses direct secret access only** (`secretAccessor` role). List operations are not available.

## How It Works

The `secret-fetch` script calls `gcloud secrets versions access` to retrieve secret values.
Secrets are used inline in commands or loaded into the current shell session via `eval`.

## Prerequisites

1. **GCP Project Setup**
   ```bash
   export GCP_PROJECT_ID="your-project-id"
   ```

2. **Secret Manager API Enabled** — `secretmanager.googleapis.com`

3. **IAM Role** — `roles/secretmanager.secretAccessor` (direct access only, no list permission)

4. **ADC Authentication** — `gcloud auth login`

5. **Secrets stored in Secret Manager** with matching env var names

## Usage

```
/secrets4claude load OPENAI_API_KEY
/secrets4claude load openai          # Bundle: loads API_KEY + ORG_ID + PROJECT_ID
/secrets4claude get SOME_SECRET
```

## AUTO-FIRE RULES — MUST FOLLOW

**This skill MUST be invoked automatically** (without user asking) when:

1. **API key error detected**: Command output contains "API key not set", "unauthorized", "401", "403", "invalid_api_key"
2. **User mentions API keys, credentials, or secrets**
3. **`.env` file is absent** and environment variables are needed
4. **Any external API call** (curl, npm scripts, etc.) that requires authentication

### EXCEPTION: Codex CLI

**Codex CLI は secrets4claude で OPENAI_API_KEY を自動セットしない。**
Codex はサブスクリプション認証（`~/.codex/auth.json`, `codex login`）で動作する。
`OPENAI_API_KEY` を設定するとサブスクではなく API 課金になるため、通常は設定しない。

Codex の認証エラー時のフォールバック順序：
1. `codex login` の再実行を案内
2. それでも失敗 → `secrets4claude --bundle openai` で API キーをフォールバック取得

### OpenAI Bundle (always load all 3 together)

When OpenAI credentials are needed, **always** fetch all 3 as a bundle:

| Secret Manager Name | Env Var | Purpose |
|---|---|---|
| `OPENAI_API_KEY` | `OPENAI_API_KEY` | API authentication |
| `OPENAI_ORGANIZATION_ID` | `OPENAI_ORGANIZATION_ID` | Organization scope |
| `OPENAI_PROJECT_ID` | `OPENAI_PROJECT_ID` | Project scope |

```bash
eval $(scripts/secret-fetch --bundle openai)
```

**Never load `OPENAI_API_KEY` alone** — always use the bundle to include Org ID and Project ID.

## CLI Reference

```bash
scripts/secret-fetch <secret-name>                    # Get single value
scripts/secret-fetch --env <name1> <name2> ...         # Export statements
scripts/secret-fetch --bundle <bundle-name>            # Export predefined bundle
```

### Bundles
| Bundle | Secrets |
|--------|---------|
| `openai` | `OPENAI_API_KEY`, `OPENAI_ORGANIZATION_ID`, `OPENAI_PROJECT_ID` |

### Environment Variables
| Variable | Description |
|----------|-------------|
| `GCP_PROJECT_ID` | GCP Project ID (required) |
| `SECRET_MANAGER_PROJECT_ID` | Override project for Secret Manager (optional) |

## SECURITY RULES — MUST FOLLOW

1. **NEVER echo or print secret values** to the user. Do not show them in output.
2. **NEVER write secrets to files** (.env, config files, source code, etc.)
3. **NEVER include secrets in git commits**
4. **Use secrets inline** — pass them directly to the commands that need them
5. **Minimize exposure** — fetch only when needed, use immediately, discard

## Command Patterns

### Load OpenAI bundle (most common)
```bash
eval $(scripts/secret-fetch --bundle openai)
```

### Load specific secrets
```bash
eval $(scripts/secret-fetch --env APIFY_API_KEY SOME_OTHER_KEY)
```

### Use a secret inline (single command)
```bash
APIFY_API_KEY=$(scripts/secret-fetch APIFY_API_KEY) curl -H "Authorization: Bearer $APIFY_API_KEY" ...
```

### Fetch a secret for use in another script
```bash
scripts/video-analyzer ./video.mp4 "Analyze this" --api-key $(scripts/secret-fetch SOME_API_KEY)
```

## Process Workflow

### 1. Parse Request

Determine what the user needs:
| Request | Action |
|---------|--------|
| "load" / "set up" / "secrets" + key names | Fetch and eval export statements |
| "load openai" / codex execution | Fetch openai bundle (all 3 keys) |
| "get" + single key name | Fetch single value for inline use |

### 2. Execute

Run `secret-fetch` via Bash. **Always suppress output of actual values.**

For the OpenAI bundle:
```bash
eval $(scripts/secret-fetch --bundle openai)
```

For specific secrets:
```bash
eval $(scripts/secret-fetch --env KEY1 KEY2 KEY3)
```

### 3. Report Results

- Report SUCCESS/FAILURE only — never the actual values
- Example: "OPENAI_API_KEY, OPENAI_ORGANIZATION_ID, OPENAI_PROJECT_ID を読み込みました"
- If a secret is not found, report which one failed

## Storing New Secrets

Guide users to store secrets via gcloud:

```bash
# From a value
echo -n "your-api-key" | gcloud secrets create SECRET_NAME --data-file=- --project=PROJECT_ID

# Update existing secret
echo -n "new-value" | gcloud secrets versions add SECRET_NAME --data-file=- --project=PROJECT_ID
```

## Troubleshooting

### Permission Denied
```bash
# Check IAM — need secretAccessor role
gcloud projects get-iam-policy PROJECT_ID --filter="bindings.role:secretmanager"

# Grant access
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:you@example.com" \
  --role="roles/secretmanager.secretAccessor"
```

### Secret Not Found
```bash
# Try to access directly (no list permission available)
gcloud secrets versions access latest --secret=SECRET_NAME --project=PROJECT_ID
```

### API Not Enabled
```bash
gcloud services enable secretmanager.googleapis.com --project=PROJECT_ID
```
