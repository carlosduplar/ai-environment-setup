#!/bin/bash
# hooks/post-tool-use.sh
# Fires after every tool call.
# Input: JSON via stdin with keys: timestamp, cwd, toolName, toolResult

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.toolName // ""')
RESULT_TYPE=$(echo "$INPUT" | jq -r '.toolResult.resultType // ""')

# Hook 1: Auto-Format Every File Edit
if [[ "$TOOL" =~ ^(Edit|Write)$ ]] && [[ "$RESULT_TYPE" == "success" ]]; then
  FILE_PATH=$(echo "$INPUT" | jq -r '.toolResult.path // ""')
  if [ -n "$FILE_PATH" ] && [ -f "$FILE_PATH" ]; then
    EXT="${FILE_PATH##*.}"
    FORMATTABLE_EXTS="js ts jsx tsx json css scss html vue yaml yml md"
    if echo "$FORMATTABLE_EXTS" | grep -q "\b$EXT\b"; then
      npx prettier --write "$FILE_PATH" 2>/dev/null || true
    fi
  fi
fi

# Only act on successful shell/bash executions
if [[ "$TOOL" != "bash" ]] || [[ "$RESULT_TYPE" != "success" ]]; then
  exit 0
fi

# Detect milestone commit without PLAN.md status update
LAST_MSG=$(git log -1 --pretty=%s 2>/dev/null || echo "")
if echo "$LAST_MSG" | grep -qE "^feat: "; then
  FILES_IN_COMMIT=$(git log -1 --name-only --pretty="" 2>/dev/null || echo "")
  if ! echo "$FILES_IN_COMMIT" | grep -q "PLAN.md"; then
    echo "WARNING: feat commit detected but PLAN.md was not updated in the same commit."
    echo "The agent must mark the milestone [DONE] in PLAN.md and commit that change."
  fi
fi

# Warn on 3+ blocked milestones
if [ -f "PLAN.md" ]; then
  BLOCKED=$(grep -c "^### \[BLOCKED\]" PLAN.md 2>/dev/null || echo 0)
  if [ "$BLOCKED" -ge 3 ]; then
    echo "──────────────────────────────────────────"
    echo "WARNING: $BLOCKED milestones are BLOCKED. Review before continuing:"
    grep -E "^### \[BLOCKED\]" PLAN.md | sed 's/^### /  /'
    echo "──────────────────────────────────────────"
  fi
fi
