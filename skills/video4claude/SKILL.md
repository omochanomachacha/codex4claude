---
name: video4claude
description: |
  Analyze video files (MP4, MOV, AVI, etc.) using Vertex AI Gemini.
  Sends the video natively — no transcription or frame extraction needed.
  Supports any user-defined prompt for flexible multimodal analysis.
---

# video4claude - Video Analysis with Vertex AI Gemini

Analyze video files by sending them directly to Gemini via Vertex AI.
The video is sent as-is (native multimodal input), preserving all visual and audio information.

## How It Works

All video analysis is done by calling the `video-analyzer` script via Bash.
The script sends the video file to Vertex AI's Gemini API as inline data (or via GCS for large files)
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

5. **For large videos (>20MB)** — Set `VERTEX_GCS_TEMP_BUCKET` for GCS upload

## Usage

```
/video4claude <video_path> <prompt>
```

## CLI Reference

```bash
scripts/video-analyzer <video_path> <prompt> [flags]
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

### Supported Video Formats
| Extension | MIME Type |
|-----------|-----------|
| `.mp4` | video/mp4 |
| `.mov` | video/quicktime |
| `.avi` | video/x-msvideo |
| `.mkv` | video/x-matroska |
| `.webm` | video/webm |
| `.wmv` | video/x-ms-wmv |
| `.flv` | video/x-flv |
| `.3gp` | video/3gpp |

## Command Patterns

### General Analysis
```
/video4claude /path/to/video.mp4 What is happening in this video?
/video4claude ./meeting.mp4 Summarize the key discussion points
```

### Content Extraction
```
/video4claude ./presentation.mp4 Extract all text shown on slides
/video4claude ./whiteboard.mov Transcribe everything written on the whiteboard
```

### Technical Analysis
```
/video4claude ./demo.mp4 List all UI interactions and their timestamps
/video4claude ./bug-recording.mp4 Identify the bug shown in this screen recording
```

### Creative Analysis
```
/video4claude ./ad.mp4 Analyze the visual storytelling techniques used
/video4claude ./product-demo.mp4 Write product copy based on the features shown
```

## Process Workflow

### 1. Receive Request

The user provides:
- A video file path (absolute or relative)
- A natural language prompt describing what to analyze

### 2. Validate Input

- Verify the file exists and is a supported video format
- Check file size to determine upload method (inline vs GCS)

### 3. Execute

Run `video-analyzer` via Bash:

```bash
scripts/video-analyzer "/path/to/video.mp4" "Your analysis prompt here"
```

For a specific model:
```bash
scripts/video-analyzer "/path/to/video.mp4" "Your prompt" --model gemini-2.5-pro
```

For large files:
```bash
scripts/video-analyzer "/path/to/large-video.mp4" "Your prompt" --gcs-bucket my-temp-bucket
```

The script outputs the analysis text to stdout.

### 4. Report Results

1. Present the analysis text to the user
2. Offer follow-up analysis if needed (e.g., deeper dive on specific timestamps)

## Model Selection Guide

| Model | Best For |
|-------|----------|
| `gemini-2.5-pro` | Fast analysis, short videos, simple prompts (default) |
| `gemini-2.5-pro` | Detailed analysis, long videos, complex reasoning |

## Size Limits

- **Inline upload**: Up to ~20MB (works for most short clips)
- **GCS upload**: For larger files, set `VERTEX_GCS_TEMP_BUCKET`
  - Temp files are auto-cleaned after analysis

## Troubleshooting

### Authentication Errors
```bash
gcloud auth application-default login
echo $GCP_PROJECT_ID
```

### Timeout on Large Videos
```bash
# Increase timeout to 10 minutes
scripts/video-analyzer ./long-video.mp4 "Summarize" --timeout 600
```

### File Too Large
```bash
# Use GCS for large files
export VERTEX_GCS_TEMP_BUCKET="my-project-vertex-temp"
scripts/video-analyzer ./large-video.mp4 "Analyze"
```
