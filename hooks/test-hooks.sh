#!/bin/bash
# test-hooks.sh
# Run from repo root. Requires: jq, git, pwsh, bash
# Usage: bash hooks/test-hooks.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PASS=0 FAIL=0 SKIP=0

pass() { echo "  PASS  $1"; ((PASS++)); }
fail() { echo "  FAIL  $1"; ((FAIL++)); }
skip() { echo "  SKIP  $1"; ((SKIP++)); }
header() { echo ""; echo "── $1 ──────────────────────────────────────"; }

assert_not_auto_allow() {
  local out=$1 label=$2
  local decision
  decision=$(echo "$out" | jq -r '.permissionDecision // ""' 2>/dev/null)
  if [ -z "$out" ] || [ "$decision" != "allow" ]; then
    pass "$label"
  else
    fail "$label"
  fi
}

# Verify dependencies
for cmd in jq git; do
  if ! command -v "$cmd" &>/dev/null; then
    echo "ERROR: '$cmd' is required but not found." >&2
    exit 1
  fi
done

# Create a temp git repo with PLAN.md and AGENTS.md committed
new_test_repo() {
  local tmp
  tmp=$(mktemp -d "copilot-test-XXXXXX")
  (
    cd "$tmp" || exit 1
    git init -q
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "# test" > README.md
    git add . 2>/dev/null
    git commit -q -m "initial" 2>/dev/null
    cat > AGENTS.md <<EOF
# AGENTS.md
## Test placeholder
EOF
    cat > PLAN.md <<EOF
# PLAN.md

## Test runner
echo tests pass

## Compaction Checkpoints
After Milestone 1

## Milestones

### [PENDING] Milestone 1 — Add feature
**Touched files:**
- \`\`src/feature.ts\`\`

**Depends on:** none
EOF
    git add . 2>/dev/null
    git commit -q -m "add plan" 2>/dev/null
  )
  echo "$tmp"
}

# Run a .sh hook with a given JSON payload
run_hook_sh() {
  local script=$1 payload=$2 cwd=$3
  (cd "$cwd" && echo "$payload" | bash "$script" 2>/dev/null)
}

# ═══════════════════════════════════════════════════════════════════════════════
header "UNIT TESTS — pre-tool-use.sh (secrets blocking)"
SCRIPT="$SCRIPT_DIR/pre-tool-use.sh"

if [ ! -f "$SCRIPT" ]; then
  skip "pre-tool-use.sh not found at $SCRIPT"
else
  REPO=$(new_test_repo)

  # Helper to build a preToolUse payload
  new_payload() {
    local tool=$1 argJson=$2
    echo "{\"timestamp\":1704614400000,\"cwd\":\"$REPO\",\"toolName\":\"$tool\",\"toolArgs\":$argJson}"
  }

  # Should DENY
  OUT=$(run_hook_sh "$SCRIPT" "$(new_payload "read" '{"path":"/project/.env"}')" "$REPO")
  if echo "$OUT" | jq -e '.permissionDecision == "deny"' >/dev/null 2>&1; then
    pass ".env file read is denied"
  else
    fail ".env file read is denied"
  fi

  OUT=$(run_hook_sh "$SCRIPT" "$(new_payload "view" '{"path":".env.production"}')" "$REPO")
  if echo "$OUT" | jq -e '.permissionDecision == "deny"' >/dev/null 2>&1; then
    pass ".env.production view is denied"
  else
    fail ".env.production view is denied"
  fi

  OUT=$(run_hook_sh "$SCRIPT" "$(new_payload "read" '{"path":"/app/secrets/db.json"}')" "$REPO")
  if echo "$OUT" | jq -e '.permissionDecision == "deny"' >/dev/null 2>&1; then
    pass "/secrets/ path read is denied"
  else
    fail "/secrets/ path read is denied"
  fi

  # Should ALLOW
  OUT=$(run_hook_sh "$SCRIPT" "$(new_payload "read" '{"path":"src/main.ts"}')" "$REPO")
  if [ -z "$OUT" ] || echo "$OUT" | jq -e '.permissionDecision != "deny"' >/dev/null 2>&1; then
    pass "src/main.ts read is allowed"
  else
    fail "src/main.ts read is allowed"
  fi

  OUT=$(run_hook_sh "$SCRIPT" "$(new_payload "view" '{"path":"package.json"}')" "$REPO")
  if [ -z "$OUT" ] || echo "$OUT" | jq -e '.permissionDecision != "deny"' >/dev/null 2>&1; then
    pass "package.json view is allowed"
  else
    fail "package.json view is allowed"
  fi

  OUT=$(run_hook_sh "$SCRIPT" "$(new_payload "bash" '{"command":"git show HEAD --stat"}')" "$REPO")
  if echo "$OUT" | jq -e '.permissionDecision == "allow"' >/dev/null 2>&1; then
    pass "git show is auto-allowed"
  else
    fail "git show is auto-allowed"
  fi

  OUT=$(run_hook_sh "$SCRIPT" "$(new_payload "bash" '{"command":"npm run lint"}')" "$REPO")
  if echo "$OUT" | jq -e '.permissionDecision == "allow"' >/dev/null 2>&1; then
    pass "npm run lint is auto-allowed"
  else
    fail "npm run lint is auto-allowed"
  fi

  OUT=$(run_hook_sh "$SCRIPT" "$(new_payload "bash" '{"command":"python -m pytest -q"}')" "$REPO")
  if echo "$OUT" | jq -e '.permissionDecision == "allow"' >/dev/null 2>&1; then
    pass "python -m pytest is auto-allowed"
  else
    fail "python -m pytest is auto-allowed"
  fi

  OUT=$(run_hook_sh "$SCRIPT" "$(new_payload "bash" '{"command":"pip install requests"}')" "$REPO")
  assert_not_auto_allow "$OUT" "pip install is not auto-allowed"

  # Compact safety
  echo "dirty" > "$REPO/dirty.txt"
  OUT=$(run_hook_sh "$SCRIPT" "$(new_payload "bash" '{"command":"/compact"}')" "$REPO")
  if echo "$OUT" | jq -e '.permissionDecision == "deny"' >/dev/null 2>&1; then
    pass "compact denied on dirty tree"
  else
    fail "compact denied on dirty tree"
  fi

  rm "$REPO/dirty.txt"
  OUT=$(run_hook_sh "$SCRIPT" "$(new_payload "bash" '{"command":"/compact"}')" "$REPO")
  if [ -z "$OUT" ] || echo "$OUT" | jq -e '.permissionDecision != "deny"' >/dev/null 2>&1; then
    pass "compact allowed on clean tree"
  else
    fail "compact allowed on clean tree"
  fi

  rm -rf "$REPO"
fi

# ═══════════════════════════════════════════════════════════════════════════════
header "RESULTS"
TOTAL=$((PASS + FAIL + SKIP))
echo "  $PASS passed  /  $FAIL failed  /  $SKIP skipped  (total: $TOTAL)"
echo ""

if [ "$FAIL" -gt 0 ]; then
  echo "Some tests failed. Review output above before deploying hooks."
  exit 1
else
  echo "All tests passed."
  exit 0
fi
