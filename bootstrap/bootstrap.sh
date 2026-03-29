#!/usr/bin/env bash
# bootstrap.sh — Install the full AI coding environment (Git Bash on Windows 11)
# Usage: bash bootstrap/bootstrap.sh [--update] [--dry-run] [--gws] [--firebase]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"
MANIFESTS="$ROOT/manifests"
CONFIG="$ROOT/config"
HOOKS="$ROOT/hooks"

UPDATE=false
DRY_RUN=false
FLAG_GWS=false
FLAG_FIREBASE=false

for arg in "$@"; do
    case $arg in
        --update)    UPDATE=true ;;
        --dry-run)   DRY_RUN=true ;;
        --gws)       FLAG_GWS=true ;;
        --firebase)  FLAG_FIREBASE=true ;;
    esac
done

# shellcheck source=bootstrap/lib/utils.sh
source "$SCRIPT_DIR/lib/utils.sh"

# ─────────────────────────────────────────────
# 0. Pre-flight
# ─────────────────────────────────────────────
step "Pre-flight checks"
assert_command "node" "Install Node.js: https://nodejs.org"
assert_command "npm"  "Install Node.js: https://nodejs.org"
assert_command "git"  "Install Git: https://git-scm.com"
load_env_file

# ─────────────────────────────────────────────
# 1. Core CLIs via winget (install if missing)
# ─────────────────────────────────────────────
step "1/7 — Core CLIs (winget)"

# Install python if not present
if ! command -v python &>/dev/null; then
    info "python not found, installing via winget..."
    run winget install Python.Python.3 --accept-package-agreements --accept-source-agreements --silent
else
    ok "python already installed"
fi

# Ensure jq via winget
if ! command -v jq &>/dev/null; then
    info "jq not found, installing via winget..."
    run winget install jqlang.jq --accept-package-agreements --accept-source-agreements --silent
else
    ok "jq already installed"
fi

# ─────────────────────────────────────────────
# 2. npm global packages
# ─────────────────────────────────────────────
step "2/7 — npm global packages"

while IFS= read -r pkg_name pkg_version; do
    [[ "$pkg_name" == "#"* || -z "$pkg_name" ]] && continue
    if npm list -g --depth=0 2>/dev/null | grep -q "$pkg_name" && [[ "$UPDATE" == "false" ]]; then
        ok "$pkg_name already installed"
    else
        info "Installing $pkg_name@$pkg_version..."
        run npm install -g "$pkg_name@$pkg_version"
    fi
done < <(python -c "
import json
data = json.load(open('$MANIFESTS/npm-global.json'))
for p in data['packages']:
    print(p['name'], p.get('version', 'latest'))
")

# ── Optional: Firebase ──────────────────────────────
if [[ "$FLAG_FIREBASE" == "true" ]]; then
    step "Optional — Firebase CLI"
    if npm list -g firebase-tools &>/dev/null && [[ "$UPDATE" == "false" ]]; then
        ok "firebase-tools already installed"
    else
        info "Installing firebase-tools..."
        run npm install -g firebase-tools
    fi
fi

# ── Optional: Google Workspace ──────────────────────
if [[ "$FLAG_GWS" == "true" ]]; then
    step "Optional — Google Workspace CLI"
    if npm list -g @googleworkspace/cli &>/dev/null && [[ "$UPDATE" == "false" ]]; then
        ok "@googleworkspace/cli already installed"
    else
        info "Installing @googleworkspace/cli..."
        run npm install -g "@googleworkspace/cli"
    fi
fi

# ─────────────────────────────────────────────
# 3. Install agent skills
# ─────────────────────────────────────────────
step "3/7 — Install agent skills"
declare -A INSTALLED_SKILLS
SKILL_LIST_OK=false

install_skill_if_needed() {
    local skill="$1"
    if [[ "$SKILL_LIST_OK" == "true" ]] && [[ -n "${INSTALLED_SKILLS[$skill]:-}" ]]; then
        ok "$skill already installed"
        return
    fi

    info "Installing $skill..."
    # Individual skill install fallback
    run npx skills add "$skill" -g -y

    if [[ "$SKILL_LIST_OK" == "true" ]]; then
        INSTALLED_SKILLS["$skill"]=1
    fi
}

install_skills_from_repo() {
    local repo="$1"
    shift
    local skills=("$@")
    local skills_to_install=()

    for skill in "${skills[@]}"; do
        if [[ "$SKILL_LIST_OK" == "true" ]] && [[ -n "${INSTALLED_SKILLS[$skill]:-}" ]]; then
            ok "$skill already installed"
        else
            skills_to_install+=("$skill")
        fi
    done

    if [[ ${#skills_to_install[@]} -gt 0 ]]; then
        local skill_list="${skills_to_install[*]}"
        info "Installing skills from $repo: $skill_list"
        run npx skills add "$repo" --skill $skill_list -g -y

        if [[ "$SKILL_LIST_OK" == "true" ]]; then
            for skill in "${skills_to_install[@]}"; do
                INSTALLED_SKILLS["$skill"]=1
            done
        fi
    fi
}

collect_installed_skills() {
    if [[ "$DRY_RUN" == "true" ]]; then
        info "[DRY-RUN] npx skills ls --json"
        SKILL_LIST_OK=false
        return
    fi

    local skills_json
    if skills_json="$(npx skills ls --json 2>/dev/null)"; then
        local parsed_ok=true
        if [[ -n "$skills_json" ]]; then
            if parsed_skill_names="$("$PYTHON_BIN" -c '
import json
import sys

def emit_name(item):
    if isinstance(item, str):
        return item
    if isinstance(item, dict):
        for key in ("name", "id", "skill"):
            value = item.get(key)
            if isinstance(value, str) and value.strip():
                return value
    return None

raw = sys.stdin.read().strip()
if not raw:
    raise SystemExit(0)

parsed = json.loads(raw)
if isinstance(parsed, list):
    for entry in parsed:
        name = emit_name(entry)
        if name:
            print(name)
else:
    name = emit_name(parsed)
    if name:
        print(name)
' <<< "$skills_json" 2>/dev/null)"; then
                while IFS= read -r skill_name; do
                    [[ -z "$skill_name" ]] && continue
                    INSTALLED_SKILLS["$skill_name"]=1
                done <<< "$parsed_skill_names"
            else
                warn "Unable to parse installed skills from 'npx skills ls --json'; continuing without validation."
                parsed_ok=false
            fi
        fi
        if [[ "$parsed_ok" == "true" ]]; then
            SKILL_LIST_OK=true
        fi
    else
        warn "Unable to list installed skills via 'npx skills ls --json'; continuing without validation."
        SKILL_LIST_OK=false
    fi
}

# Core skills grouped by repository (always installed)
declare -A SKILL_REPOS=(
    ["anthropics/skills"]="docx pdf pptx xlsx webapp-testing frontend-design skill-creator"
    ["vercel-labs/agent-skills"]="vercel-react-best-practices vercel-react-native-skills web-design-guidelines"
    ["vercel-labs/skills"]="find-skills"
    ["coreyhaines31/marketingskills"]="seo-audit"
    ["microsoft/playwright-cli"]="playwright-cli"
    ["upstash/context7"]="context7-cli find-docs"
)

# GWS skills (only with --gws)
declare -A GWS_SKILL_REPOS=(
    ["googleworkspace/cli"]="gws-calendar gws-docs gws-drive gws-gmail gws-keep gws-shared gws-sheets gws-tasks gws-workflow-email-to-task gws-workflow-meeting-prep gws-workflow-standup-report gws-workflow-weekly-digest"
)

collect_installed_skills

if [[ "$SKILL_LIST_OK" == "true" ]] && (( ${#INSTALLED_SKILLS[@]} > 0 )); then
    info "Installed skills detected; running 'npx skills update -g -y' before adding new skills."
    if ! run npx skills update -g -y; then
        warn "'npx skills update -g -y' failed; continuing with add flow."
    fi
fi

# Install core skills grouped by repository
for repo in "${!SKILL_REPOS[@]}"; do
    read -ra skills_array <<< "${SKILL_REPOS[$repo]}"
    install_skills_from_repo "$repo" "${skills_array[@]}"
done

# Install GWS skills if --gws flag is set
if [[ "$FLAG_GWS" == "true" ]]; then
    for repo in "${!GWS_SKILL_REPOS[@]}"; do
        read -ra skills_array <<< "${GWS_SKILL_REPOS[$repo]}"
        install_skills_from_repo "$repo" "${skills_array[@]}"
    done
fi

# ─────────────────────────────────────────────
# 4. Python packages (pip)
# ─────────────────────────────────────────────
step "4/7 — Python packages"
if ! command -v python &>/dev/null; then
    warn "python not found. Skipping pip packages (markitdown will be unavailable)."
else
    while IFS= read -r pkg; do
        [[ "$pkg" == "#"* || -z "$pkg" ]] && continue
        info "Ensuring $pkg..."
        run python -m pip install --user "$pkg"
    done < "$MANIFESTS/pip-packages.txt"
fi

# ─────────────────────────────────────────────
# 5. Detect agents
# ─────────────────────────────────────────────
step "5/7 — Detect agents"

declare -A AGENTS

for pair in "claude:claude" "opencode:opencode" "gemini:gemini" "copilot:gh-copilot"; do
    name="${pair%%:*}"
    cmd="${pair##*:}"
    if command -v "$cmd" &>/dev/null; then
        ok "$name found"
        AGENTS[$name]=true
    else
        warn "$name not found — skipping its config/hooks"
        AGENTS[$name]=false
    fi
done

# ─────────────────────────────────────────────
# 6. Config scaffolding (agent-gated)
# ─────────────────────────────────────────────
step "6/7 — Config scaffolding"
HOME_DIR="$HOME"

declare -A CONFIGS

# Claude Code config + hooks
if [[ "${AGENTS[claude]}" == "true" ]]; then
    CONFIGS["$CONFIG/claude-code/settings.json.example"]="$HOME_DIR/.claude/settings.json"
    CONFIGS["$CONFIG/claude-code/CLAUDE.md"]="$HOME_DIR/.claude/CLAUDE.md"
    CONFIGS["$HOOKS/claude-code-pre-tool-use.sh"]="$HOME_DIR/.claude/hooks/pre-tool-use.sh"
    CONFIGS["$HOOKS/claude-code-pre-tool-use.ps1"]="$HOME_DIR/.claude/hooks/pre-tool-use.ps1"
    CONFIGS["$HOOKS/post-tool-use.sh"]="$HOME_DIR/.claude/hooks/post-tool-use.sh"
    CONFIGS["$HOOKS/post-tool-use.ps1"]="$HOME_DIR/.claude/hooks/post-tool-use.ps1"
    CONFIGS["$HOOKS/notification.sh"]="$HOME_DIR/.claude/hooks/notification.sh"
    CONFIGS["$HOOKS/notification.ps1"]="$HOME_DIR/.claude/hooks/notification.ps1"
    CONFIGS["$HOOKS/post-compact.sh"]="$HOME_DIR/.claude/hooks/post-compact.sh"
    CONFIGS["$HOOKS/post-compact.ps1"]="$HOME_DIR/.claude/hooks/post-compact.ps1"
fi

# OpenCode config + plugin
if [[ "${AGENTS[opencode]}" == "true" ]]; then
    CONFIGS["$CONFIG/opencode/opencode.json.example"]="$HOME_DIR/.config/opencode/opencode.json"
    CONFIGS["$CONFIG/opencode/plugins/security.js"]="$HOME_DIR/.config/opencode/plugins/security.js"
    CONFIGS["$CONFIG/opencode/plugins/format-on-write.js"]="$HOME_DIR/.config/opencode/plugins/format-on-write.js"
    CONFIGS["$CONFIG/opencode/plugins/notifications.js"]="$HOME_DIR/.config/opencode/plugins/notifications.js"
    CONFIGS["$CONFIG/opencode/plugins/context-refresh.js"]="$HOME_DIR/.config/opencode/plugins/context-refresh.js"
    CONFIGS["$CONFIG/opencode/plugins/session-lifecycle.js"]="$HOME_DIR/.config/opencode/plugins/session-lifecycle.js"
fi

# Gemini config + hooks
if [[ "${AGENTS[gemini]}" == "true" ]]; then
    CONFIGS["$CONFIG/gemini/GEMINI.md"]="$HOME_DIR/.gemini/GEMINI.md"
    CONFIGS["$CONFIG/gemini/mcp-server-enablement.json"]="$HOME_DIR/.gemini/mcp-server-enablement.json"
    CONFIGS["$HOOKS/gemini-pre-tool-use.sh"]="$HOME_DIR/.gemini/hooks/pre-tool-use.sh"
    CONFIGS["$HOOKS/gemini-pre-tool-use.ps1"]="$HOME_DIR/.gemini/hooks/pre-tool-use.ps1"
fi

# Copilot config
if [[ "${AGENTS[copilot]}" == "true" ]]; then
    CONFIGS["$CONFIG/github-copilot/copilot-instructions.md"]="$HOME_DIR/.copilot/copilot-instructions.md"
    CONFIGS["$CONFIG/github-copilot/AGENTS.md"]="$HOME_DIR/.copilot/AGENTS.md"
fi

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
# Done
# ─────────────────────────────────────────────
echo ""
echo "Bootstrap complete."
echo "Agents configured: $(for name in "${!AGENTS[@]}"; do [[ "${AGENTS[$name]}" == "true" ]] && echo -n "$name "; done)"
for name in "${!AGENTS[@]}"; do
    [[ "${AGENTS[$name]}" == "false" ]] && echo "Agents skipped:   $name"
done
echo "Next: fill .env.local, then run: bash bootstrap/verify.sh"
