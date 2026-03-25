#!/bin/bash
# hooks/gemini-pre-tool-use.sh
# Fires before EVERY tool call in Gemini CLI.
# Uses environment variables: GEMINI_TOOL_NAME, GEMINI_TOOL_INPUT_PATH, GEMINI_TOOL_INPUT_COMMAND.
# Exit 0 to allow, non-zero to deny.

# ── SECRET FILE PROTECTION ──────────────────────────────────────────────────
# Block any read, view, edit, or create tool call targeting sensitive paths.
# Patterns are matched against the resolved path string.

BLOCKED_PATTERNS=(
  "\.env"
  "\.env\."
  "/secrets/"
  "/secret/"
  "\.pem$"
  "\.key$"
  "\.p12$"
  "\.pfx$"
  "\.jks$"
  "id_rsa"
  "id_ed25519"
  "id_ecdsa"
  "\.netrc$"
  "\.npmrc"
  "\.pypirc"
  "credentials$"
  "credentials\.json"
  "service.account"
  "serviceaccount"
  "\.aws/credentials"
  "\.aws/config"
  "kubeconfig"
  "\.kube/config"
  "terraform\.tfvars"
  "\.tfvars$"
  "vault\.hcl"
  "auth\.json$"
  "token\.json$"
  "client_secret"
)

TOOL="$GEMINI_TOOL_NAME"
TARGET_PATH="$GEMINI_TOOL_INPUT_PATH"
COMMAND="$GEMINI_TOOL_INPUT_COMMAND"

# Determine which string to check
CHECK_STRING=""
if [[ -n "$TARGET_PATH" ]]; then
    CHECK_STRING="$TARGET_PATH"
elif [[ -n "$COMMAND" ]]; then
    CHECK_STRING="$COMMAND"
fi

if [[ -n "$CHECK_STRING" ]]; then
    for PATTERN in "${BLOCKED_PATTERNS[@]}"; do
        if echo "$CHECK_STRING" | grep -qiE "$PATTERN"; then
            echo "Secret file access blocked by pre-tool-use hook. Path matched pattern: $PATTERN. Do not attempt to read, write, or reference this file." >&2
            exit 1
        fi
    done
fi

# ── COMPACT SAFETY CHECK ────────────────────────────────────────────────────
# Intercept any attempt to run /compact or trigger compaction while tree is dirty.
if [[ "$TOOL" == "Bash" && "$COMMAND" =~ compact ]]; then
    GIT_STATUS=$(git status --porcelain 2>/dev/null || true)
    if [[ -n "$GIT_STATUS" ]]; then
        echo "Cannot compact with uncommitted changes. Commit or restore all changes first, then update PLAN.md status." >&2
        exit 1
    fi
fi

# Allow all other tool calls
exit 0
