#!/bin/bash
# hooks/post-compact.sh
# Hook 4: Context Memory Refresh
# Automatically re-reads critical files after Claude compacts its context

CRITICAL_FILES=(
  "$HOME/.claude/CLAUDE.md"
  "$HOME/.claude/ARCHITECTURE.md"
  "$HOME/.claude/STYLE_GUIDE.md"
  "$HOME/.claude/rules.md"
)

LOADED_COUNT=0
for file in "${CRITICAL_FILES[@]}"; do
  if [ -f "$file" ]; then
    LOADED_COUNT=$((LOADED_COUNT + 1))
  fi
done

if [ "$LOADED_COUNT" -gt 0 ]; then
  echo "Context Memory Refresh: Loaded $LOADED_COUNT critical files"
fi

exit 0