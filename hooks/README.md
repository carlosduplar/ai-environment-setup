# Hooks

Hooks allow custom scripts to run at specific points in the AI tool lifecycle — before/after file edits, before/after bash commands, on session start/stop, etc.

## Supported Tools

| Tool | Hook Support | Config Location |
|------|-------------|-----------------|
| Claude Code | Yes (PreToolUse, PostToolUse) | `~/.claude/settings.json` → `hooks` |
| OpenCode | Yes (bash hooks) | `~/.config/opencode/opencode.json` |
| Gemini CLI | Limited | N/A |
| GitHub Copilot CLI | No | N/A |

## Hook types (Claude Code)

| Event | Trigger |
|-------|---------|
| `PreToolUse` | Before any tool call |
| `PostToolUse` | After any tool call |
| `Notification` | On agent notifications |
| `Stop` | When agent completes |

## Example: log all edits

```json
// In ~/.claude/settings.json
"hooks": {
  "PostToolUse": [
    {
      "matcher": "Edit",
      "hooks": [
        {
          "type": "command",
          "command": "echo \"Edited: $CLAUDE_TOOL_INPUT_PATH\" >> ~/edit-audit.log"
        }
      ]
    }
  ]
}
```

## Example: auto-format on edit

```json
"hooks": {
  "PostToolUse": [
    {
      "matcher": "Edit",
      "hooks": [
        {
          "type": "command",
          "command": "prettier --write \"$CLAUDE_TOOL_INPUT_PATH\" 2>/dev/null || true"
        }
      ]
    }
  ]
}
```

## Adding a hook

1. Add the hook script to `hooks/scripts/<name>.sh` or `hooks/scripts/<name>.ps1`
2. Reference it from your tool's config
3. Document it in `docs/hooks-catalog.md`

## Security note

Hook commands run with your user privileges. Never execute untrusted content from AI output in a hook. Always validate inputs.
