#!/usr/bin/env bash
# bootstrap.sh — Install the full AI coding environment (Git Bash on Windows 11)
# Usage: bash bootstrap/bootstrap.sh [--update] [--dry-run]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
MANIFESTS="$ROOT/manifests"
CONFIG="$ROOT/config"

UPDATE=false
DRY_RUN=false

for arg in "$@"; do
    case $arg in
        --update)  UPDATE=true ;;
        --dry-run) DRY_RUN=true ;;
    esac
done

# shellcheck source=bootstrap/lib/utils.sh
source "$SCRIPT_DIR/lib/utils.sh"

# ─────────────────────────────────────────────
# 0. Pre-flight
# ─────────────────────────────────────────────
step "Pre-flight checks"
assert_command "node"   "Install Node.js: https://nodejs.org"
assert_command "npm"    "Install Node.js: https://nodejs.org"
assert_command "python" "Install Python: https://python.org"
assert_command "git"    "Install Git: https://git-scm.com"
load_env_file

# ─────────────────────────────────────────────
# 1. npm global packages
# ─────────────────────────────────────────────
step "1/5 — npm global packages"
while IFS= read -r pkg_name pkg_version; do
    [[ "$pkg_name" == "#"* || -z "$pkg_name" ]] && continue
    if npm list -g --depth=0 2>/dev/null | grep -q "$pkg_name" && [[ "$UPDATE" == "false" ]]; then
        ok "$pkg_name already installed"
    else
        info "Installing $pkg_name@$pkg_version..."
        run npm install -g "$pkg_name@$pkg_version"
    fi
done < <(python3 -c "
import json, sys
data = json.load(open('$MANIFESTS/npm-global.json'))
for p in data['packages']:
    print(p['name'], p.get('version', 'latest'))
")

# ─────────────────────────────────────────────
# 2. Python tools via uv
# ─────────────────────────────────────────────
step "2/5 — Python tools (uv)"
assert_command "uv" "Install uv: https://docs.astral.sh/uv/getting-started/installation/"

while IFS= read -r pkg; do
    [[ "$pkg" == "#"* || -z "$pkg" ]] && continue
    info "Ensuring $pkg..."
    run uv tool install "$pkg"
done < "$MANIFESTS/pip-packages.txt"

# ─────────────────────────────────────────────
# 3. gh extensions
# ─────────────────────────────────────────────
step "3/5 — gh extensions"
assert_command "gh" "Install gh: https://cli.github.com"
run gh extension install github/gh-copilot || warn "gh-copilot extension already installed or failed"

# ─────────────────────────────────────────────
# 4. Config scaffolding
# ─────────────────────────────────────────────
step "4/5 — Config scaffolding"
HOME_DIR="$HOME"

declare -A CONFIGS=(
    ["$CONFIG/claude-code/settings.json.example"]="$HOME_DIR/.claude/settings.json"
    ["$CONFIG/claude-code/CLAUDE.md"]="$HOME_DIR/.claude/CLAUDE.md"
    ["$CONFIG/opencode/opencode.json.example"]="$HOME_DIR/.config/opencode/opencode.json"
    ["$CONFIG/gemini/GEMINI.md"]="$HOME_DIR/.gemini/GEMINI.md"
    ["$CONFIG/gemini/mcp-server-enablement.json"]="$HOME_DIR/.gemini/mcp-server-enablement.json"
)

for src in "${!CONFIGS[@]}"; do
    dst="${CONFIGS[$src]}"
    if [[ -f "$dst" ]] && [[ "$UPDATE" == "false" ]]; then
        ok "$dst exists — skipping"
    else
        info "Copying $src -> $dst"
        if [[ "$DRY_RUN" == "false" ]]; then
            mkdir -p "$(dirname "$dst")"
            cp "$src" "$dst"
        fi
    fi
done

# ─────────────────────────────────────────────
# 5. Claude Code
# ─────────────────────────────────────────────
step "5/5 — Claude Code"
if command -v claude &>/dev/null; then
    ok "claude already installed"
else
    warn "Claude Code not found. Install from: https://docs.anthropic.com/claude-code"
fi

# ─────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────
echo ""
echo "Bootstrap complete."
echo "Next: fill .env.local, then run: bash bootstrap/verify.sh"
