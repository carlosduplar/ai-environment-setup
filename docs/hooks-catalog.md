# Hooks Catalog

Hooks that run automatically at AI tool lifecycle events.

## Currently configured hooks

No hooks are configured by default. Add hooks to `~/.claude/settings.json` → `hooks` key.

## Example hooks

### Audit all file edits

```json
"hooks": {
  "PostToolUse": [{
    "matcher": "Edit",
    "hooks": [{
      "type": "command",
      "command": "pwsh -c \"Add-Content -Path $env:USERPROFILE/edit-audit.log -Value \\\"$(Get-Date -Format o) $env:CLAUDE_TOOL_INPUT_PATH\\\"\""
    }]
  }]
}
```

### Auto-format edited files

```json
"hooks": {
  "PostToolUse": [{
    "matcher": "Edit",
    "hooks": [{
      "type": "command",
      "command": "prettier --write \"$CLAUDE_TOOL_INPUT_PATH\" 2>/dev/null || true"
    }]
  }]
}
```

### Block edits to secrets

```json
"hooks": {
  "PreToolUse": [{
    "matcher": "Edit",
    "hooks": [{
      "type": "command",
      "command": "pwsh -c \"if ($env:CLAUDE_TOOL_INPUT_PATH -match '\\.env|\\.ssh|secrets') { exit 1 }\""
    }]
  }]
}
```

## Adding a hook

1. Add the script to `hooks/scripts/<name>.ps1` or `hooks/scripts/<name>.sh`
2. Reference it in `~/.claude/settings.json`
3. Document it in this catalog

## Hook environment variables (Claude Code)

| Variable | Value |
|----------|-------|
| `CLAUDE_TOOL_NAME` | Name of the tool being called |
| `CLAUDE_TOOL_INPUT_PATH` | Path argument for file tools |
| `CLAUDE_TOOL_INPUT_COMMAND` | Command string for Bash |

## Hook environment variables (Gemini CLI)

| Variable | Value |
|----------|-------|
| `GEMINI_TOOL_NAME` | Name of the tool being called |
| `GEMINI_TOOL_INPUT_PATH` | Path argument for file tools |
| `GEMINI_TOOL_INPUT_COMMAND` | Command string for Bash |

## Pre‑built hook scripts

The repository includes ready‑to‑use hook scripts for secret‑file protection and compact safety:

- `claude-code-pre-tool-use.sh` / `.ps1` – for Claude Code (uses environment variables)
- `opencode-pre-tool-use.sh` / `.ps1` – for OpenCode (expects JSON input)
- `gemini-pre-tool-use.sh` / `.ps1` – for Gemini CLI (uses environment variables)

These are copied to `~/.claude/hooks/`, `~/.config/opencode/hooks/`, and `~/.gemini/hooks/` by the bootstrap scripts. See `hooks/README.md` for details.
