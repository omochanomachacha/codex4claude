#!/usr/bin/env bash
#
# codex4claude Skill Pack — Installer
#
# Usage:
#   curl -sL https://raw.githubusercontent.com/omochanomachacha/codex4claude/main/install.sh | bash
#   curl -sL https://raw.githubusercontent.com/omochanomachacha/codex4claude/main/install.sh | bash -s -- --auto-update
#
# Options:
#   --auto-update   Enable automatic daily update via Claude Code hook
#   --uninstall     Remove skills and clean up settings.json
#
set -euo pipefail

REPO_URL="https://github.com/omochanomachacha/codex4claude.git"
INSTALL_DIR="${HOME}/.claude/skills/codex4claude"
SETTINGS_FILE="${HOME}/.claude/settings.json"
UPDATE_SCRIPT="${HOME}/.claude/bin/codex4claude-auto-update.sh"

# Colors (disabled if not a terminal)
if [ -t 1 ]; then
  GREEN='\033[0;32m'; YELLOW='\033[1;33m'; RED='\033[0;31m'; BOLD='\033[1m'; NC='\033[0m'
else
  GREEN=''; YELLOW=''; RED=''; BOLD=''; NC=''
fi

info()  { printf "${GREEN}[✓]${NC} %s\n" "$1"; }
warn()  { printf "${YELLOW}[!]${NC} %s\n" "$1"; }
err()   { printf "${RED}[✗]${NC} %s\n" "$1" >&2; exit 1; }
step()  { printf "${BOLD}→${NC} %s\n" "$1"; }

# ── Parse args ──────────────────────────────────────────────
AUTO_UPDATE=false
UNINSTALL=false
for arg in "$@"; do
  case "$arg" in
    --auto-update) AUTO_UPDATE=true ;;
    --uninstall)   UNINSTALL=true ;;
    --help|-h)
      echo "Usage: install.sh [--auto-update] [--uninstall]"
      echo "  --auto-update  Enable daily auto-update via Claude Code hook"
      echo "  --uninstall    Remove all installed skills"
      exit 0 ;;
    *) err "Unknown option: $arg (use --help for usage)" ;;
  esac
done

if [ "$AUTO_UPDATE" = true ] && [ "$UNINSTALL" = true ]; then
  err "--auto-update and --uninstall cannot be used together."
fi

# ── Dependency check ────────────────────────────────────────
command -v git     >/dev/null 2>&1 || err "git is required but not installed."
command -v python3 >/dev/null 2>&1 || err "python3 is required for JSON manipulation."

# ── Uninstall mode ──────────────────────────────────────────
if [ "$UNINSTALL" = true ]; then
  step "Uninstalling codex4claude skill pack..."

  python3 - "$SETTINGS_FILE" "$INSTALL_DIR" << 'PYEOF'
import json, sys, os, tempfile

settings_file = sys.argv[1]
install_dir = os.path.realpath(sys.argv[2])

if not os.path.isfile(settings_file):
    print("  No settings.json found, nothing to clean.")
    sys.exit(0)

try:
    with open(settings_file, 'r', encoding='utf-8') as f:
        settings = json.load(f)
except (json.JSONDecodeError, IOError) as e:
    print(f"  Warning: Could not parse settings.json: {e}")
    print("  Skipping settings cleanup.")
    sys.exit(0)

if not isinstance(settings, dict):
    print("  Warning: settings.json is not a dict. Skipping.")
    sys.exit(0)

# Remove skills managed by this pack
removed = []
skills = settings.get('skills', {})
if isinstance(skills, dict):
    to_remove = [k for k, v in skills.items()
                 if isinstance(v, dict) and v.get('_managedBy') == 'codex4claude']
    # Also remove skills whose path is under install_dir (legacy entries)
    for k, v in skills.items():
        if k not in to_remove and isinstance(v, dict):
            raw_path = v.get('path', '')
            if not isinstance(raw_path, str) or not raw_path:
                continue
            p = os.path.realpath(raw_path)
            if os.path.commonpath([p, install_dir]) == install_dir:
                to_remove.append(k)
    for k in set(to_remove):
        del skills[k]
        removed.append(k)

# Remove auto-update hook if present
hooks = settings.get('hooks', {})
if isinstance(hooks, dict):
    for hook_type in list(hooks.keys()):
        hook_list = hooks[hook_type]
        if isinstance(hook_list, list):
            hooks[hook_type] = [
                h for h in hook_list
                if not (isinstance(h, dict) and isinstance(h.get('command'), str)
                        and 'codex4claude-auto-update' in h['command'])
            ]
            if not hooks[hook_type]:
                del hooks[hook_type]
    if not hooks:
        settings.pop('hooks', None)

# Atomic write: temp file + rename
settings_dir = os.path.dirname(settings_file)
fd, tmp_path = tempfile.mkstemp(dir=settings_dir, suffix='.json')
try:
    with os.fdopen(fd, 'w', encoding='utf-8') as f:
        json.dump(settings, f, indent=2, ensure_ascii=False)
        f.write('\n')
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp_path, settings_file)
except Exception:
    os.unlink(tmp_path)
    raise

for r in sorted(removed):
    print(f"  - Removed: {r}")
if not removed:
    print("  No managed skills were registered.")
PYEOF

  # Remove auto-update script
  [ -f "$UPDATE_SCRIPT" ] && rm -f "$UPDATE_SCRIPT"

  if [ -d "$INSTALL_DIR" ]; then
    rm -rf "$INSTALL_DIR"
    info "Removed $INSTALL_DIR"
  fi
  info "Uninstall complete."
  exit 0
fi

# ── Install / Update ───────────────────────────────────────
echo ""
printf "${BOLD}codex4claude Skill Pack Installer${NC}\n"
echo "─────────────────────────────────────────"
echo ""

# Step 1: Clone or update
if [ -d "$INSTALL_DIR/.git" ]; then
  step "Updating existing installation..."
  if git -C "$INSTALL_DIR" pull --ff-only -q 2>/tmp/codex4claude-pull-err.txt; then
    info "Repository updated."
  else
    warn "Update failed. Details: $(cat /tmp/codex4claude-pull-err.txt 2>/dev/null)"
    warn "Using existing version."
  fi
  rm -f /tmp/codex4claude-pull-err.txt
elif [ -d "$INSTALL_DIR" ]; then
  warn "$INSTALL_DIR exists but is not a git repository."
  warn "Moving to ${INSTALL_DIR}.bak and cloning fresh."
  mv "$INSTALL_DIR" "${INSTALL_DIR}.bak.$(date +%s)"
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone -q "$REPO_URL" "$INSTALL_DIR"
  info "Cloned to $INSTALL_DIR"
else
  step "Cloning repository..."
  mkdir -p "$(dirname "$INSTALL_DIR")"
  git clone -q "$REPO_URL" "$INSTALL_DIR"
  info "Cloned to $INSTALL_DIR"
fi

# Step 2: Register skills in settings.json
step "Registering skills..."

python3 - "$SETTINGS_FILE" "$INSTALL_DIR" << 'PYEOF'
import json, sys, os, tempfile

settings_file = sys.argv[1]
install_dir = sys.argv[2]

# Ensure directory exists
os.makedirs(os.path.dirname(settings_file), exist_ok=True)

# Read or initialize settings
if os.path.isfile(settings_file):
    try:
        with open(settings_file, 'r', encoding='utf-8') as f:
            settings = json.load(f)
    except json.JSONDecodeError as e:
        # Backup corrupted file and start fresh
        backup = settings_file + f".bak.corrupt"
        import shutil
        shutil.copy2(settings_file, backup)
        print(f"  Warning: settings.json was corrupted. Backed up to {backup}")
        settings = {}
else:
    settings = {}

if not isinstance(settings, dict):
    settings = {}

if 'skills' not in settings or not isinstance(settings.get('skills'), dict):
    settings['skills'] = {}

def extract_description(skill_md_path):
    """Extract description from YAML frontmatter."""
    try:
        with open(skill_md_path, 'r', encoding='utf-8') as f:
            content = f.read()
    except IOError:
        return ""
    if not content.startswith("---"):
        return ""
    parts = content.split("---", 2)
    if len(parts) < 3:
        return ""
    frontmatter = parts[1]
    lines = frontmatter.strip().split('\n')
    desc_lines = []
    in_desc = False
    for line in lines:
        if line.startswith('description:'):
            rest = line[len('description:'):].strip()
            if rest and rest != '|':
                return rest.strip('"').strip("'")
            in_desc = True
            continue
        if in_desc:
            if line.startswith('  '):
                desc_lines.append(line.strip())
            elif line.startswith('---') or (line and not line[0].isspace()):
                break
    return ' '.join(desc_lines)

added = []
updated = []
skipped = []
unchanged = []

def register_skill(name, skill_md):
    desc = extract_description(skill_md)
    existing = settings['skills'].get(name)
    if existing is None:
        settings['skills'][name] = {
            'path': skill_md,
            'description': desc or name,
            '_managedBy': 'codex4claude'
        }
        added.append(name)
    elif isinstance(existing, dict) and existing.get('_managedBy') == 'codex4claude':
        # We own this entry — update it
        existing['path'] = skill_md
        if desc:
            existing['description'] = desc
        unchanged.append(name)
    else:
        # Owned by someone else or unexpected type — don't overwrite
        skipped.append(name)

# Register root SKILL.md as codex4claude
root_skill = os.path.join(install_dir, "SKILL.md")
if os.path.isfile(root_skill):
    register_skill('codex4claude', root_skill)

# Register skills in skills/ directory
skills_dir = os.path.join(install_dir, "skills")
if os.path.isdir(skills_dir):
    for name in sorted(os.listdir(skills_dir)):
        skill_md = os.path.join(skills_dir, name, "SKILL.md")
        if not os.path.isfile(skill_md):
            continue
        if name == 'codex4claude':
            continue  # Already registered from root
        register_skill(name, skill_md)

# Atomic write: temp file + rename
settings_dir = os.path.dirname(settings_file)
fd, tmp_path = tempfile.mkstemp(dir=settings_dir, suffix='.json')
try:
    with os.fdopen(fd, 'w', encoding='utf-8') as f:
        json.dump(settings, f, indent=2, ensure_ascii=False)
        f.write('\n')
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp_path, settings_file)
except Exception:
    os.unlink(tmp_path)
    raise

for s in added:
    print(f"  + {s}")
for s in unchanged:
    print(f"  = {s} (up to date)")
for s in skipped:
    print(f"  ! {s} (conflict: already registered by another source, skipped)")
PYEOF

# Step 3: Auto-update hook (optional)
if [ "$AUTO_UPDATE" = true ]; then
  step "Setting up auto-update..."

  # Create update script outside repo tree
  mkdir -p "$(dirname "$UPDATE_SCRIPT")"
  cat > "$UPDATE_SCRIPT" << 'UPDATESCRIPT'
#!/usr/bin/env bash
# codex4claude auto-update (throttled to once per day)
INSTALL_DIR="${HOME}/.claude/skills/codex4claude"
STAMP_FILE="${HOME}/.claude/bin/.codex4claude-update-stamp"
INTERVAL=86400  # 24 hours

[ ! -d "$INSTALL_DIR/.git" ] && exit 0

NOW=$(date +%s)
if [ -f "$STAMP_FILE" ]; then
  LAST=$(cat "$STAMP_FILE" 2>/dev/null || echo 0)
  DIFF=$((NOW - LAST))
  [ "$DIFF" -lt "$INTERVAL" ] && exit 0
fi

if git -C "$INSTALL_DIR" pull --ff-only -q 2>/dev/null; then
  echo "$NOW" > "$STAMP_FILE"
fi
UPDATESCRIPT
  chmod +x "$UPDATE_SCRIPT"

  # Register hook in settings.json
  python3 - "$SETTINGS_FILE" "$UPDATE_SCRIPT" << 'PYEOF'
import json, sys, os, tempfile

settings_file = sys.argv[1]
update_script = sys.argv[2]

with open(settings_file, 'r', encoding='utf-8') as f:
    settings = json.load(f)

if not isinstance(settings, dict):
    settings = {}

hook_entry = {"command": update_script}

if 'hooks' not in settings or not isinstance(settings.get('hooks'), dict):
    settings['hooks'] = {}

if 'PreToolUse' not in settings['hooks'] or not isinstance(settings['hooks'].get('PreToolUse'), list):
    settings['hooks']['PreToolUse'] = []

# Check if already registered (exact path match)
existing = [h for h in settings['hooks']['PreToolUse']
            if isinstance(h, dict) and h.get('command') == update_script]
if not existing:
    settings['hooks']['PreToolUse'].append(hook_entry)
    print("  + Auto-update hook added to PreToolUse")
else:
    print("  = Auto-update hook already registered")

# Atomic write
settings_dir = os.path.dirname(settings_file)
fd, tmp_path = tempfile.mkstemp(dir=settings_dir, suffix='.json')
try:
    with os.fdopen(fd, 'w', encoding='utf-8') as f:
        json.dump(settings, f, indent=2, ensure_ascii=False)
        f.write('\n')
        f.flush()
        os.fsync(f.fileno())
    os.replace(tmp_path, settings_file)
except Exception:
    os.unlink(tmp_path)
    raise
PYEOF

  info "Auto-update enabled (checks daily via PreToolUse hook)."
else
  echo "  To enable auto-update, re-run with --auto-update flag."
fi

# ── Summary ─────────────────────────────────────────────────
echo ""
echo "─────────────────────────────────────────"
info "Installation complete!"
echo ""
echo "  Skills installed at: $INSTALL_DIR"
echo "  Settings updated:    $SETTINGS_FILE"
echo ""
echo "  Manual update:  git -C \"$INSTALL_DIR\" pull"
echo "  Uninstall:      bash \"$INSTALL_DIR/install.sh\" --uninstall"
echo ""
