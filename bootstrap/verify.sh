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
for tool in git node npm pwsh bash jq curl; do
    check_tool "$tool"
done

# ─────────────────────────────────────────────
# 2. AI agents (optional)
# ─────────────────────────────────────────────
step "2/5 — AI agents"

has_claude=false
has_opencode=false
has_gemini=false
has_copilot=false

for pair in "claude:has_claude" "opencode:has_opencode" "gemini:has_gemini" "copilot:has_copilot"; do
    cmd="${pair%%:*}"
    var="${pair##*:}"
    if command -v "$cmd" &>/dev/null; then
        ok "$cmd found"
        declare "$var=true"
    else
        warn "$cmd not found (optional)"
    fi
done

# ─────────────────────────────────────────────
# 3. Optional tools (API-key gated)
# ─────────────────────────────────────────────
step "3/5 — Optional tools"

# Check which API keys are available
has_brightdata_key=false
[[ -n "${BRIGHTDATA_API_KEY:-}" ]] && has_brightdata_key=true

# Bright Data CLI - only check if API key is present
if [[ "$has_brightdata_key" == "true" ]]; then
    if command -v brightdata &>/dev/null; then
        ok "brightdata found"
    else
        info "brightdata not found (optional)"
    fi
else
    info "BRIGHTDATA_API_KEY not set — skipping Bright Data CLI check"
fi

# Other optional tools
for tool in python ctx7 playwright npx gcloud firebase gws markitdown; do
    if command -v "$tool" &>/dev/null; then
        ok "$tool found"
    else
        info "$tool not found (optional)"
    fi
done

# ─────────────────────────────────────────────
# 4. Config & hooks (agent-gated)
# ─────────────────────────────────────────────
step "4/5 — Config & hooks"

if [[ "$has_claude" == "true" ]]; then
    check_file "$HOME/.claude/settings.json"              "Claude Code settings"
    check_file "$HOME/.claude/CLAUDE.md"                  "Claude Code system prompt"
    check_file "$HOME/.claude/hooks/pre-tool-use.sh"      "Claude Code hook (sh)"
    check_file "$HOME/.claude/hooks/pre-tool-use.ps1"     "Claude Code hook (ps1)"
    check_file "$HOME/.claude/hooks/post-tool-use.sh"     "Claude post-tool-use hook (sh)"
    check_file "$HOME/.claude/hooks/post-tool-use.ps1"    "Claude post-tool-use hook (ps1)"
    check_file "$HOME/.claude/hooks/notification.sh"      "Claude notification hook (sh)"
    check_file "$HOME/.claude/hooks/notification.ps1"     "Claude notification hook (ps1)"
    check_file "$HOME/.claude/hooks/post-compact.sh"      "Claude post-compact hook (sh)"
    check_file "$HOME/.claude/hooks/post-compact.ps1"     "Claude post-compact hook (ps1)"
else
    info "Claude not installed — skipping its config/hook checks"
fi

if [[ "$has_opencode" == "true" ]]; then
    check_file "$HOME/.config/opencode/opencode.json"       "OpenCode config"
    check_file "$HOME/.config/opencode/plugins/security.js" "OpenCode security plugin"
    check_file "$HOME/.config/opencode/plugins/format-on-write.js" "OpenCode format-on-write plugin"
    check_file "$HOME/.config/opencode/plugins/notifications.js" "OpenCode notifications plugin"
    check_file "$HOME/.config/opencode/plugins/context-refresh.js" "OpenCode context-refresh plugin"
    check_file "$HOME/.config/opencode/plugins/session-lifecycle.js" "OpenCode session-lifecycle plugin"
else
    info "OpenCode not installed — skipping its config checks"
fi

if [[ "$has_gemini" == "true" ]]; then
    check_file "$HOME/.gemini/GEMINI.md"                   "Gemini system prompt"
    check_file "$HOME/.gemini/mcp-server-enablement.json"  "Gemini MCP enablement"
    check_file "$HOME/.gemini/hooks/pre-tool-use.sh"       "Gemini hook (sh)"
    check_file "$HOME/.gemini/hooks/pre-tool-use.ps1"      "Gemini hook (ps1)"
else
    info "Gemini not installed — skipping its config/hook checks"
fi

if [[ "$has_copilot" == "true" ]]; then
    check_file "$HOME/.copilot/copilot-instructions.md"    "Copilot instructions"
    check_file "$HOME/.copilot/AGENTS.md"                  "Copilot AGENTS config"
else
    info "Copilot not installed — skipping its config checks"
fi

# Always check repo-level Copilot hook config
check_file "$ROOT/.github/hooks/hooks.json" "Copilot repo hook config"

# ─────────────────────────────────────────────
# 5. Environment variables
# ─────────────────────────────────────────────
step "5/5 — Environment variables"
# Note: ANTHROPIC_AUTH_TOKEN is managed by the Claude Code CLI itself
for v in BRIGHTDATA_API_KEY NVIDIA_API_KEY OPENROUTER_API_KEY MISTRAL_API_KEY GOOGLE_CLOUD_PROJECT; do
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
