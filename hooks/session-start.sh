#!/bin/bash
# hooks/session-start.sh
# Fires when a new CLI session starts or resumes after /compact.
# Input: JSON via stdin with keys: timestamp, cwd, source, initialPrompt

INPUT=$(cat)
SOURCE=$(echo "$INPUT" | jq -r '.source // "unknown"')

echo "──────────────────────────────────────────"
echo "SESSION ${SOURCE^^} — $(date '+%Y-%m-%d %H:%M:%S')"
echo "Branch : $(git rev-parse --abbrev-ref HEAD 2>/dev/null || echo 'not a git repo')"
echo "Commit : $(git rev-parse --short HEAD 2>/dev/null || echo 'n/a')"

# Require PLAN.md
if [ ! -f "PLAN.md" ]; then
  echo ""
  echo "ERROR: PLAN.md not found."
  echo "Run the planning agent (Opus/Sonnet, plan mode) first."
  echo "──────────────────────────────────────────"
  # Exit 1 blocks session start
  exit 1
fi

# Require AGENTS.md
if [ ! -f "AGENTS.md" ]; then
  echo ""
  echo "ERROR: AGENTS.md not found in repo root."
  echo "──────────────────────────────────────────"
  exit 1
fi

# Require clean working tree
if ! git diff --quiet HEAD 2>/dev/null; then
  echo ""
  echo "ERROR: Uncommitted changes detected. Commit or stash before starting."
  git status --short
  echo "──────────────────────────────────────────"
  exit 1
fi

# Print PLAN.md status
echo ""
echo "PLAN.md status:"
grep -E "^### \[(DONE|PENDING|BLOCKED)\]" PLAN.md \
  | sed 's/^### /  /' \
  || echo "  (no milestones found — check PLAN.md format)"

echo ""
echo "Next pending:"
grep -m 1 "^### \[PENDING\]" PLAN.md | sed 's/^### /  /' \
  || echo "  None — plan may be complete or all blocked"

echo "──────────────────────────────────────────"
