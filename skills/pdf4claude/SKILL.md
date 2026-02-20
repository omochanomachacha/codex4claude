---
name: pdf4claude
description: |
  Analyze PDF files using Vertex AI Gemini.
  Sends the PDF natively — no text extraction or OCR needed.
  Supports any user-defined prompt for flexible multimodal analysis.
---

# pdf4claude - PDF Analysis with Vertex AI Gemini

Analyze PDF files by sending them directly to Gemini via Vertex AI.
The PDF is sent as-is (native multimodal input), preserving all visual layout,
images, charts, tables, and formatting.

## How It Works

All PDF analysis is done by calling the `pdf-analyzer` script via Bash.
The script sends the PDF file to Vertex AI's Gemini API as inline data (or via GCS for large files)
and returns the text analysis.

## Prerequisites

1. **GCP Project Setup**
   ```bash
   export GCP_PROJECT_ID="your-project-id"
   export GCP_REGION="us-central1"  # Optional, defaults to us-central1
   ```

2. **Vertex AI API Enabled** — `aiplatform.googleapis.com`

3. **ADC Authentication** — `gcloud auth application-default login`

4. **IAM Role** — `roles/aiplatform.user`

5. **For large PDFs (>20MB)** — Set `VERTEX_GCS_TEMP_BUCKET` for GCS upload

## Usage

```
/pdf4claude <pdf_path> <prompt>
```

## CLI Reference

```bash
scripts/pdf-analyzer <pdf_path> <prompt> [flags]
```

### Flags
| Flag | Description |
|------|-------------|
| `--model <model>` | Gemini model ID (default: gemini-2.5-pro) |
| `--gcs-bucket <bucket>` | GCS bucket for large file upload |
| `--timeout <seconds>` | Request timeout in seconds (default: 300) |

### Environment Variables
| Variable | Description |
|----------|-------------|
| `GCP_PROJECT_ID` | GCP Project ID (required) |
| `GCP_REGION` | GCP Region (default: us-central1) |
| `VERTEX_ANALYSIS_MODEL` | Model override (default: gemini-2.5-pro) |
| `VERTEX_GCS_TEMP_BUCKET` | GCS bucket for large files |

## Command Patterns

### Document Summary
```
/pdf4claude /path/to/report.pdf Summarize the key findings
/pdf4claude ./contract.pdf List all obligations and deadlines
```

### Data Extraction
```
/pdf4claude ./invoice.pdf Extract all line items, quantities, and amounts as a table
/pdf4claude ./resume.pdf Extract skills, experience, and education in structured format
```

### Visual Analysis (charts, diagrams, layouts)
```
/pdf4claude ./quarterly-report.pdf Describe all charts and their trends
/pdf4claude ./architecture.pdf Explain the system architecture shown in the diagrams
```

### Translation & Localization
```
/pdf4claude ./japanese-doc.pdf Translate the full content to English
/pdf4claude ./manual.pdf Translate to Japanese, preserving formatting descriptions
```

### Comparison & Review
```
/pdf4claude ./proposal.pdf Review this proposal and list strengths and weaknesses
/pdf4claude ./paper.pdf Critically analyze the methodology and conclusions
```

### Form & Table Analysis
```
/pdf4claude ./form.pdf Extract all form fields and their values
/pdf4claude ./spreadsheet.pdf Convert all tables to markdown format
```

## Process Workflow

### 1. Receive Request

The user provides:
- A PDF file path (absolute or relative)
- A natural language prompt describing what to analyze

### 2. Validate Input

- Verify the file exists and has a PDF header
- Check file size to determine upload method (inline vs GCS)

### 3. Execute

Run `pdf-analyzer` via Bash:

```bash
scripts/pdf-analyzer "/path/to/document.pdf" "Your analysis prompt here"
```

For a specific model:
```bash
scripts/pdf-analyzer "/path/to/document.pdf" "Your prompt" --model gemini-2.5-pro
```

For large files:
```bash
scripts/pdf-analyzer "/path/to/large-doc.pdf" "Your prompt" --gcs-bucket my-temp-bucket
```

The script outputs the analysis text to stdout.

### 4. Report Results

1. Present the analysis text to the user
2. Offer follow-up analysis if needed (e.g., deeper dive on specific sections)

## Model Selection Guide

| Model | Best For |
|-------|----------|
| `gemini-2.5-pro` | Fast analysis, short docs, simple prompts (default) |
| `gemini-2.5-pro` | Detailed analysis, long docs, complex reasoning, nuanced extraction |

## Why Native PDF Input?

Sending the PDF as-is to Gemini (rather than extracting text first) has key advantages:

- **Layout preservation**: Tables, columns, headers are understood in context
- **Visual content**: Charts, images, diagrams, logos are analyzed
- **Scanned documents**: Handwritten notes and scanned pages work without separate OCR
- **Formatting context**: Bold, italic, font sizes inform the analysis
- **Multi-language**: No need for language-specific text extraction

## Size Limits

- **Inline upload**: Up to ~20MB (works for most documents)
- **GCS upload**: For larger files, set `VERTEX_GCS_TEMP_BUCKET`
  - Temp files are auto-cleaned after analysis

## Troubleshooting

### Authentication Errors
```bash
gcloud auth application-default login
echo $GCP_PROJECT_ID
```

### Timeout on Large PDFs
```bash
# Increase timeout to 10 minutes
scripts/pdf-analyzer ./large-doc.pdf "Summarize" --timeout 600
```

### File Too Large
```bash
# Use GCS for large files
export VERTEX_GCS_TEMP_BUCKET="my-project-vertex-temp"
scripts/pdf-analyzer ./large-doc.pdf "Analyze"
```
