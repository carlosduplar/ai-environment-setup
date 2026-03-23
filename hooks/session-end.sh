#!/bin/bash
# hooks/session-end.sh
# Fires when the session ends normally or is terminated.
# Input: JSON via stdin with keys: timestamp, cwd, reason

INPUT=$(cat)
REASON=$(echo "$INPUT" | jq -r '.reason // "unknown"')

echo "──────────────────────────────────────────"
echo "SESSION END — $(date '+%Y-%m-%d %H:%M:%S') (reason: $REASON)"

if [ ! -f "PLAN.md" ]; then
  echo "PLAN.md not found — no summary available."
  echo "──────────────────────────────────────────"
  exit 0
fi

DONE=$(grep -c "^### \[DONE\]" PLAN.md 2>/dev/null || echo 0)
PENDING=$(grep -c "^### \[PENDING\]" PLAN.md 2>/dev/null || echo 0)
BLOCKED=$(grep -c "^### \[BLOCKED\]" PLAN.md 2>/dev/null || echo 0)
TOTAL=$((DONE + PENDING + BLOCKED))

echo "Plan: $DONE/$TOTAL done | $PENDING pending | $BLOCKED blocked"

if [ "$BLOCKED" -gt 0 ]; then
  echo ""
  echo "Blocked milestones:"
  grep -E "^### \[BLOCKED\]" PLAN.md | sed 's/^### /  /'
fi

if [ "$PENDING" -eq 0 ] && [ "$BLOCKED" -eq 0 ] && [ "$TOTAL" -gt 0 ]; then
  echo ""
  echo "All milestones complete. ✓"
fi

echo "──────────────────────────────────────────"
