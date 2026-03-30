#!/usr/bin/env bash
# analyze-permission-log.sh — Analyze permission logs and suggest auto-allow patterns
# Usage: bash setup/analyze-permission-log.sh

set -euo pipefail

LOG_FILE="$HOME/.config/opencode/permission-log.jsonl"

if [[ ! -f "$LOG_FILE" ]]; then
    echo "No permission log found at $LOG_FILE"
    echo "Run some commands first, then check back!"
    exit 1
fi

echo "Analyzing permission log..."

# Count tool usage
echo ""
echo "=== Tool Usage Summary ==="
jq -r '.tool' "$LOG_FILE" 2>/dev/null | sort | uniq -c | sort -rn | head -20 || echo "(install jq for better formatting)"

# Extract frequent bash commands
echo ""
echo "=== Frequent Bash Commands (candidates for auto-allow) ==="
jq -r 'select(.tool == "bash") | .command' "$LOG_FILE" 2>/dev/null | 
    awk '{print $1}' | 
    sort | 
    uniq -c | 
    sort -rn | 
    head -20 | 
    while read -r count cmd; do
        if [[ "$count" -ge 3 ]]; then
            if [[ "$cmd" =~ ^(git|npm|pnpm|yarn|python|node|ls|cat|rg|grep|find|head|tail|wc|tree)$ ]]; then
                echo "  $cmd *: allow  # Used $count times"
            else
                echo "  $cmd *: ask    # Used $count times (review before allowing)"
            fi
        fi
    done || echo "(install jq for command analysis)"

echo ""
echo "=== Recent Commands (last 10) ==="
tail -10 "$LOG_FILE" | jq -r '[.timestamp[0:19], .tool, .command[0:60]] | @tsv' 2>/dev/null || tail -10 "$LOG_FILE"

echo ""
echo "To add these to your auto-allow list, edit:"
echo "  ~/.config/opencode/opencode.json"
echo ""
echo "Tip: Commands used 5+ times are usually safe to auto-allow"
