---
name: banana4claude
description: |
  AI image generation skill using Nano Banana Pro (Gemini image model)
  via Vertex AI. Supports text-to-image generation, image editing,
  icons, diagrams, and UI mockups.
---

# banana4claude - AI Image Generation with Nano Banana Pro

Generate images using Nano Banana Pro (Gemini) via Vertex AI ADC authentication.
This skill enables autonomous image generation for web development, UI design, and documentation.

## How It Works

All image generation is done by calling the `nanobanana-wrapper` script directly via Bash.
No MCP server is needed.

## Prerequisites

1. **GCP Project Setup**
   ```bash
   export GCP_PROJECT_ID="your-project-id"
   export GCP_REGION="us-central1"  # Optional, defaults to us-central1
   ```

2. **Vertex AI API Enabled** — `aiplatform.googleapis.com`

3. **ADC Authentication** — `gcloud auth application-default login`

4. **IAM Role** — `roles/aiplatform.user`

## Usage

```
/banana4claude <prompt> [options]
```

## CLI Reference

```bash
scripts/nanobanana-wrapper <command> <prompt> [flags]
```

### Commands
| Command | Description |
|---------|-------------|
| `generate` | Generate a new image from text prompt |
| `edit` | Edit an existing image with text instructions |

### Flags
| Flag | Description |
|------|-------------|
| `--style <style>` | Style hint (default: modern) |
| `--aspect-ratio <ratio>` | e.g., 1:1, 4:3, 16:9, 9:16 |
| `--image-size <size>` | e.g., 4K |
| `--image <path>` | Input image path (required for edit) |
| `--output-dir <dir>` | Output directory override |

### Environment Variables
| Variable | Description |
|----------|-------------|
| `GCP_PROJECT_ID` | GCP Project ID (required) |
| `GCP_REGION` | GCP Region (default: us-central1) |
| `NANOBANANA_OUTPUT_DIR` | Output directory (default: ~/.claude/nanobanana-output) |
| `NANOBANANA_MODEL` | Model (default: gemini-3-pro-image-preview) |

## Prompt Enhancement Templates

When generating images, enhance the user's prompt based on the type requested.
Apply these templates before passing to `nanobanana-wrapper`.

### General Image
Call as-is, optionally prepend type hint:
```bash
scripts/nanobanana-wrapper generate "Create a <type>: <user prompt>" --style <style>
```

### Icon (prefix `icon:`)
```bash
scripts/nanobanana-wrapper generate \
  "Create an app icon: <user prompt>. The icon should be simple, recognizable, and work well at small sizes (16x16 to 512x512). Style: <style>. Use appropriate background (transparent or solid color)." \
  --style <style>
```

### Diagram (prefix `diagram:`)
```bash
scripts/nanobanana-wrapper generate \
  "Create a professional <diagram_type> diagram: <user prompt>. The diagram should be clear, well-organized, and easy to understand. Use appropriate shapes, arrows, and labels. Style: clean and modern with good contrast." \
  --style modern
```

### UI Mockup (prefix `ui:` or `mockup:`)
```bash
scripts/nanobanana-wrapper generate \
  "Create a <fidelity> UI mockup for <platform>: <user prompt>. The mockup should show realistic UI elements, proper spacing, and modern design patterns. Include appropriate navigation, buttons, forms, and content areas." \
  --style modern
```

### Image Editing (prefix `edit:`)
```bash
scripts/nanobanana-wrapper edit "<editing instructions>" --image <path_to_image> --style <style>
```

## Command Patterns

### Basic Image Generation
```
/banana4claude A serene mountain landscape at sunset
/banana4claude Abstract geometric pattern with blue and gold --style=minimal
```

### Icon Generation
```
/banana4claude icon: User profile avatar
/banana4claude icon: Shopping cart for e-commerce --style=flat
```

### Diagram Generation
```
/banana4claude diagram: User authentication flow
/banana4claude diagram: OAuth 2.0 authorization code flow --type=sequence
/banana4claude diagram: Database schema for e-commerce --type=er-diagram
```

### UI Mockup Generation
```
/banana4claude ui: Login page with social auth buttons
/banana4claude mockup: Dashboard with analytics charts --platform=web
```

### Image Editing
```
/banana4claude edit: /path/to/image.png Remove the background
/banana4claude edit: ./logo.png Add a gradient overlay
```

## Process Workflow

### 1. Parse Request

Determine the type from the user's prompt:

| Prompt Pattern | Type | Diagram Subtype |
|----------------|------|-----------------|
| No prefix | general | — |
| `icon:` | icon | — |
| `diagram:` | diagram | flowchart (default) |
| `ui:` / `mockup:` | ui-mockup | — |
| `edit:` | edit | — |

### 2. Enhance Prompt

Apply the appropriate template from "Prompt Enhancement Templates" above.

### 3. Execute

Run `nanobanana-wrapper` via Bash. Example:

```bash
scripts/nanobanana-wrapper generate "enhanced prompt here" --style modern
```

The wrapper outputs the file path to stdout on success. Read the generated image with the Read tool to show it to the user.

### 4. Report Results

1. Report the output file path
2. Show the image with the Read tool
3. Offer follow-up actions (edit, variations, resize)

## Style Options

### Image Styles
| Style | Description |
|-------|-------------|
| `photorealistic` | Photo-like realistic images |
| `flat` | Flat design, solid colors |
| `modern` | Contemporary, clean design (default) |
| `pixel-art` | Retro pixel art style |
| `minimal` | Minimalist, simple design |
| `sketch` | Hand-drawn sketch style |
| `watercolor` | Watercolor painting effect |
| `3d-render` | 3D rendered look |

### Icon Styles
| Style | Description |
|-------|-------------|
| `flat` | Flat 2D icons |
| `modern` | Modern, gradient-enabled |
| `minimal` | Ultra-minimal design |
| `skeuomorphic` | Realistic 3D appearance |
| `outline` | Line-based outline icons |
| `3d` | 3D rendered icons |

### Diagram Types
| Type | Use Case |
|------|----------|
| `flowchart` | Process flows, decision trees |
| `architecture` | System architecture diagrams |
| `sequence` | Sequence/interaction diagrams |
| `er-diagram` | Entity-relationship diagrams |
| `network` | Network topology diagrams |
| `mindmap` | Mind maps, concept maps |
| `uml` | UML class/component diagrams |

### UI Mockup Fidelity
| Style | Description |
|-------|-------------|
| `wireframe` | Basic structure outlines |
| `low-fidelity` | Simple, grayscale layouts |
| `high-fidelity` | Detailed, realistic mockups (default) |
| `minimal` | Clean, minimal design |

## Output Location

- **Default:** `~/.claude/nanobanana-output/`
- **Custom:** Use `--output-dir` flag

File naming: `image_YYYYMMDD_HHMMSS_<random>.png`

## Troubleshooting

### Authentication Errors
```bash
gcloud auth application-default login
echo $GCP_PROJECT_ID
```

### Model Errors
```bash
# High quality (global endpoint)
export NANOBANANA_MODEL="gemini-3-pro-image-preview"
# Faster (regional endpoint)
export NANOBANANA_MODEL="gemini-2.5-flash-image"
```

### Output Directory Issues
```bash
mkdir -p ~/.claude/nanobanana-output
```
