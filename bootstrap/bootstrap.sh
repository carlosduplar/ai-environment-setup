#!/usr/bin/env bash
# bootstrap.sh — Install the full AI coding environment (Git Bash on Windows 11)
# Usage: bash bootstrap/bootstrap.sh [--update] [--dry-run]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
MANIFESTS="$ROOT/manifests"
CONFIG="$ROOT/config"
HOOKS="$ROOT/hooks"

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
step "1/6 — npm global packages"
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
# 1.5. Ensure jq
# ─────────────────────────────────────────────
step "1.5/6 — Ensure jq"
if ! command -v jq &>/dev/null; then
    info "jq not found, installing via Chocolatey..."
    if command -v choco &>/dev/null; then
        run choco install jq -y
    elif command -v winget &>/dev/null; then
        run winget install jqlang.jq
    else
        warn "Neither Chocolatey nor WinGet found. Please install jq manually."
    fi
else
    ok "jq already installed"
fi

# ─────────────────────────────────────────────
# 2. Install agent skills
# ─────────────────────────────────────────────
step "2/6 — Install agent skills"
skill_repos=(
    "anthropics/skills"
    "browser-use/browser-use"
    "vercel-labs/skills"
    "github/awesome-copilot"
    "googleworkspace/cli"
    "testdino-hq/playwright-skill/playwright-cli"
    "coreyhaines31/marketingskills"
    "vercel-labs/agent-skills"
)
for repo in "${skill_repos[@]}"; do
    info "Installing skills from $repo..."
    run npx skills add "$repo"
done
info "Installing bright-data-mcp skill..."
run npx skills add https://github.com/brightdata/skills --skill bright-data-mcp

# ─────────────────────────────────────────────
# 3. Python tools via uv
# ─────────────────────────────────────────────
step "4/6 — Python tools (uv)"
assert_command "uv" "Install uv: https://docs.astral.sh/uv/getting-started/installation/"

while IFS= read -r pkg; do
    [[ "$pkg" == "#"* || -z "$pkg" ]] && continue
    info "Ensuring $pkg..."
    run uv tool install "$pkg"
done < "$MANIFESTS/pip-packages.txt"

# ─────────────────────────────────────────────
# 4. GitHub Copilot CLI
# ─────────────────────────────────────────────
step "5/6 — GitHub Copilot CLI"
assert_command "gh" "Install gh: https://cli.github.com"
# Install Copilot CLI via npm (recommended) or curl
if command -v npm &>/dev/null; then
    if npm list -g @github/copilot &>/dev/null; then
        ok "GitHub Copilot CLI already installed via npm"
    else
        info "Installing GitHub Copilot CLI via npm..."
        run npm install -g @github/copilot
    fi
else
    warn "npm not found, trying curl installation..."
    run curl -fsSL https://gh.io/copilot-install | bash
fi

# ─────────────────────────────────────────────
# 5. Config scaffolding
# ─────────────────────────────────────────────
step "6/6 — Config scaffolding"
HOME_DIR="$HOME"

declare -A CONFIGS=(
    ["$CONFIG/claude-code/settings.json.example"]="$HOME_DIR/.claude/settings.json"
    ["$CONFIG/claude-code/CLAUDE.md"]="$HOME_DIR/.claude/CLAUDE.md"
    ["$CONFIG/opencode/opencode.json.example"]="$HOME_DIR/.config/opencode/opencode.json"
    ["$CONFIG/gemini/GEMINI.md"]="$HOME_DIR/.gemini/GEMINI.md"
    ["$CONFIG/gemini/mcp-server-enablement.json"]="$HOME_DIR/.gemini/mcp-server-enablement.json"
    ["$HOOKS/claude-code-pre-tool-use.sh"]="$HOME_DIR/.claude/hooks/pre-tool-use.sh"
    ["$HOOKS/claude-code-pre-tool-use.ps1"]="$HOME_DIR/.claude/hooks/pre-tool-use.ps1"
    ["$HOOKS/opencode-pre-tool-use.sh"]="$HOME_DIR/.config/opencode/hooks/pre-tool-use.sh"
    ["$HOOKS/opencode-pre-tool-use.ps1"]="$HOME_DIR/.config/opencode/hooks/pre-tool-use.ps1"
    ["$HOOKS/gemini-pre-tool-use.sh"]="$HOME_DIR/.gemini/hooks/pre-tool-use.sh"
    ["$HOOKS/gemini-pre-tool-use.ps1"]="$HOME_DIR/.gemini/hooks/pre-tool-use.ps1"
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
            if [[ "$dst" == *.sh ]]; then
                chmod +x "$dst" 2>/dev/null || true
            fi
        fi
    fi
done

# ─────────────────────────────────────────────
# 5. Claude Code
# ─────────────────────────────────────────────
step "7/6 — Claude Code"
if command -v claude &>/dev/null; then
    ok "claude already installed"
else
    info "Installing Claude Code..."
    # Use native bash installer (requires curl)
    if command -v curl &>/dev/null; then
        run curl -fsSL https://claude.ai/install.sh | bash
        # Verify installation
        if command -v claude &>/dev/null; then
            ok "Claude Code installed successfully"
        else
            warn "Claude Code installation may have failed. Install manually from https://code.claude.com/docs/en/setup"
        fi
    else
        warn "curl not found. Install Claude Code manually from https://code.claude.com/docs/en/setup"
    fi
fi

# ─────────────────────────────────────────────
# Done
# ─────────────────────────────────────────────
echo ""
echo "Bootstrap complete."
echo "Next: fill .env.local, then run: bash bootstrap/verify.sh"
