#!/usr/bin/env bash
# verify.sh — Assert the AI environment is correctly installed
# Usage: bash bootstrap/verify.sh [--security]

set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(dirname "$SCRIPT_DIR")"

SECURITY=false
for arg in "$@"; do
    [[ "$arg" == "--security" ]] && SECURITY=true
done

# shellcheck source=bootstrap/lib/utils.sh
source "$SCRIPT_DIR/lib/utils.sh"

# ─────────────────────────────────────────────
# 1. Core tools
# ─────────────────────────────────────────────
step "1/5 — Core tools"
for tool in git node npm pwsh bash jq curl gh; do
    check_tool "$tool"
done

# ─────────────────────────────────────────────
# 2. AI tools
# ─────────────────────────────────────────────
step "2/5 — AI tools"
for tool in claude opencode gemini uv python; do
    check_tool "$tool"
done

# ─────────────────────────────────────────────
# 3. Additional CLIs
# ─────────────────────────────────────────────
step "3/5 — Additional CLIs"
for tool in playwright ctx7 firebase gcloud gws markitdown npx uvx; do
    check_tool "$tool"
done

# ─────────────────────────────────────────────
# 4. Config files
# ─────────────────────────────────────────────
step "4/5 — Config files"
check_file "$HOME/.claude/settings.json"               "Claude Code settings"
check_file "$HOME/.claude/CLAUDE.md"                   "Claude Code system prompt"
check_file "$HOME/.config/opencode/opencode.json"      "OpenCode config"
check_file "$HOME/.gemini/GEMINI.md"                   "Gemini system prompt"
check_file "$HOME/.gemini/mcp-server-enablement.json"  "Gemini MCP enablement"
check_file "$HOME/.gitconfig"                          "Git global config"

# ─────────────────────────────────────────────
# 5. Environment variables
# ─────────────────────────────────────────────
step "5/5 — Environment variables"
for v in ANTHROPIC_AUTH_TOKEN BRIGHT_DATA_API_TOKEN GITHUB_TOKEN; do
    check_env "$v"
done
for v in NVIDIA_API_KEY OPENROUTER_API_KEY MISTRAL_API_KEY GOOGLE_CLOUD_PROJECT FIREBASE_TOKEN; do
    [[ -n "${!v:-}" ]] && ok "$v set" || info "$v not set (optional)"
done

# ─────────────────────────────────────────────
# Security scan
# ─────────────────────────────────────────────
if [[ "$SECURITY" == "true" ]]; then
    step "Security — scanning for accidental secrets"
    patterns=(
        'sk-[a-zA-Z0-9]{32,}'
        'nvapi-[a-zA-Z0-9_-]{40,}'
        'AIza[a-zA-Z0-9_-]{35}'
    )
    for pattern in "${patterns[@]}"; do
        if grep -r --include="*.json" --include="*.md" --include="*.yaml" \
                --include="*.toml" --include="*.sh" --include="*.ps1" \
                -l -E "$pattern" "$ROOT" 2>/dev/null | grep -q .; then
            fail "POSSIBLE SECRET matching /$pattern/ found — run grep manually to inspect"
        fi
    done
    ok "Security scan complete"
fi

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────
echo ""
echo "Results: $_pass passed, $_warn warnings, $_fail failed"
[[ $_fail -gt 0 ]] && exit 1 || exit 0
