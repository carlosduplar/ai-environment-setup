#!/bin/bash
# hooks/pre-tool-use.sh
# Fires before EVERY tool call the agent makes.
# Returns {"permissionDecision":"deny",...} to block; silence = allow.
# Input: JSON via stdin with keys: timestamp, cwd, toolName, toolArgs

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.toolName // ""')
ARGS=$(echo "$INPUT" | jq -r '.toolArgs // ""')

# ── SECRET FILE PROTECTION ──────────────────────────────────────────────────
# Content exclusion is NOT supported by Copilot CLI (confirmed: github/copilot-cli#221).
# This hook is the only enforcement layer available for CLI users.
#
# Block any read, view, edit, or create tool call targeting sensitive paths.
# Patterns are matched against the resolved path string in toolArgs.

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

# Only intercept file-access tools
if [[ "$TOOL" =~ ^(read|view|edit|create|write|str_replace|insert)$ ]] || \
   [[ "$TOOL" == "bash" ]]; then

  TARGET_PATH=$(echo "$ARGS" | jq -r '.path // .file // .command // ""' 2>/dev/null || echo "$ARGS")

  for PATTERN in "${BLOCKED_PATTERNS[@]}"; do
    if echo "$TARGET_PATH" | grep -qiE "$PATTERN"; then
      echo "{\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Secret file access blocked by pre-tool-use hook. Path matched pattern: $PATTERN. Do not attempt to read, write, or reference this file.\"}"
      exit 0
    fi
  done

  # Extra check for bash tool: block cat/less/head/tail on secret files
  if [[ "$TOOL" == "bash" ]]; then
    CMD=$(echo "$ARGS" | jq -r '.command // ""' 2>/dev/null || echo "$ARGS")
    for PATTERN in "${BLOCKED_PATTERNS[@]}"; do
      if echo "$CMD" | grep -qiE "$PATTERN"; then
        echo "{\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Shell command references secret file path (pattern: $PATTERN). Blocked by pre-tool-use hook.\"}"
        exit 0
      fi
    done
  fi
fi

# ── COMPACT SAFETY CHECK ────────────────────────────────────────────────────
# Intercept any attempt to run /compact or trigger compaction while tree is dirty.
if [[ "$TOOL" == "bash" ]]; then
  CMD=$(echo "$ARGS" | jq -r '.command // ""' 2>/dev/null || echo "$ARGS")
  if echo "$CMD" | grep -q "compact"; then
    if ! git diff --quiet HEAD 2>/dev/null; then
      echo "{\"permissionDecision\":\"deny\",\"permissionDecisionReason\":\"Cannot compact with uncommitted changes. Commit or restore all changes first, then update PLAN.md status.\"}"
      exit 0
    fi
  fi
fi

# Allow all other tool calls
exit 0
