---
name: secrets4claude
description: |
  Securely fetch API keys and credentials from GCP Secret Manager.
  Secrets are retrieved on-demand and never persisted to disk or environment files.
---

# secrets4claude - Secure Secret Management via GCP Secret Manager

Fetch API keys and credentials securely from GCP Secret Manager during Claude Code sessions.
Secrets are retrieved on-demand and used inline — never written to files or echoed to the user.

## How It Works

The `secret-fetch` script calls `gcloud secrets versions access` to retrieve secret values.
Secrets are used inline in commands or loaded into the current shell session via `eval`.

## Prerequisites

1. **GCP Project Setup**
   ```bash
   export GCP_PROJECT_ID="your-project-id"
   ```

2. **Secret Manager API Enabled** — `secretmanager.googleapis.com`

3. **IAM Role** — `roles/secretmanager.secretAccessor`

4. **ADC Authentication** — `gcloud auth login`

5. **Secrets stored in Secret Manager** — Use the same name as the env var:
   ```bash
   echo -n "sk-..." | gcloud secrets create OPENAI_API_KEY --data-file=- --project=your-project-id
   echo -n "apify_..." | gcloud secrets create APIFY_API_KEY --data-file=- --project=your-project-id
   ```

## Usage

```
/secrets4claude load OPENAI_API_KEY APIFY_API_KEY
/secrets4claude list
/secrets4claude get OPENAI_API_KEY
```

## CLI Reference

```bash
scripts/secret-fetch <secret-name>                    # Get single value
scripts/secret-fetch --env <name1> <name2> ...         # Export statements
scripts/secret-fetch --list                            # List secrets
```

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

### Load secrets into current shell session
When the user asks to load secrets, use `eval`:
```bash
eval $(scripts/secret-fetch --env OPENAI_API_KEY OPENAI_ORGANIZATION_ID OPENAI_PROJECT_ID)
```
This sets the env vars for subsequent commands in the same Bash session.

### Use a secret inline (single command)
```bash
APIFY_API_KEY=$(scripts/secret-fetch APIFY_API_KEY) curl -H "Authorization: Bearer $APIFY_API_KEY" ...
```

### List available secrets
```bash
scripts/secret-fetch --list
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
| "list" / "what secrets" | List available secrets |
| "get" + single key name | Fetch single value for inline use |

### 2. Execute

Run `secret-fetch` via Bash. **Always suppress output of actual values.**

For loading multiple secrets:
```bash
eval $(scripts/secret-fetch --env KEY1 KEY2 KEY3)
```

For listing:
```bash
scripts/secret-fetch --list
```

### 3. Report Results

- Report SUCCESS/FAILURE only — never the actual values
- Example: "OPENAI_API_KEY, APIFY_API_KEY を読み込みました"
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
# Check IAM
gcloud projects get-iam-policy PROJECT_ID --filter="bindings.role:secretmanager"

# Grant access
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member="user:you@example.com" \
  --role="roles/secretmanager.secretAccessor"
```

### Secret Not Found
```bash
# List all secrets
gcloud secrets list --project=PROJECT_ID

# Check if secret exists
gcloud secrets describe SECRET_NAME --project=PROJECT_ID
```

### API Not Enabled
```bash
gcloud services enable secretmanager.googleapis.com --project=PROJECT_ID
```
