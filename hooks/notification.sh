#!/bin/bash
# hooks/notification.sh
# Hook 3: Desktop Notifications
# Fires a native desktop alert when Claude needs user permission

INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.message // ""')

if [ -n "$MESSAGE" ]; then
  if command -v notify-send &> /dev/null; then
    notify-send "Claude Code" "$MESSAGE"
  elif command -v osascript &> /dev/null; then
    osascript -e "display notification \"$MESSAGE\" with title \"Claude Code\""
  elif command -v terminal-notifier &> /dev/null; then
    terminal-notifier -title "Claude Code" -message "$MESSAGE"
  else
    echo "Notification: $MESSAGE"
  fi
fi

exit 0