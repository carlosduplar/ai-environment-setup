# Hooks Catalog

Hooks that run automatically at AI tool lifecycle events.

## Claude Code Configuration

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "(Edit|Write|Bash)",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/pre-tool-use.ps1"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "(Edit|Write)",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/post-tool-use.ps1"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/notification.ps1"
          }
        ]
      }
    ],
    "PostCompact": [
      {
        "matcher": ".*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/post-compact.ps1"
          }
        ]
      }
    ]
  }
}
```

## Copilot CLI Configuration

Create `.github/hooks/hooks.json` in each repository (must be on default branch):

```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      {
        "type": "command",
        "bash": "hooks/pre-tool-use.sh",
        "powershell": "hooks/pre-tool-use.ps1"
      }
    ],
    "postToolUse": [
      {
        "type": "command",
        "bash": "hooks/post-tool-use.sh",
        "powershell": "hooks/post-tool-use.ps1"
      }
    ]
  }
}
```

The hooks are stored relative to the repository root. Copy hook scripts to the repo's `hooks/` folder.

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

### Hook 1: Auto-Format Every File Edit

Listens for edit or write events. When Claude touches any file, it pipes the file path to Prettier for automatic formatting.

```json
"hooks": {
  "PostToolUse": [{
    "matcher": "(Edit|Write)",
    "hooks": [{
      "type": "command",
      "command": "pwsh -c \"prettier --write $env:CLAUDE_TOOL_INPUT_PATH 2>$null\""
    }]
  }]
}
```

### Hook 2: The .env Bodyguard

Pre-tool use guard that intercepts any edit, write, or bash command before it executes. Blocks access to protected patterns (package-lock, .git, .env, secrets, etc.) with exit code 2.

```json
"hooks": {
  "PreToolUse": [{
    "matcher": "(Edit|Write|Bash)",
    "hooks": [{
      "type": "command",
      "command": "pwsh -c \"$path = $env:CLAUDE_TOOL_INPUT_PATH; if ($path -match '(\\.env|\\.git|package-lock|secrets|\\.ssh)') { exit 2 }\""
    }]
  }]
}
```

### Hook 3: Desktop Notifications

Fires a native desktop alert the moment Claude needs user permission. On Windows, uses PowerShell's BurntToast. On Mac, uses OSAScript. On Linux, uses notify-send.

```json
"hooks": {
  "Notification": [{
    "matcher": ".*",
    "hooks": [{
      "type": "command",
      "command": "pwsh -c \"Install-Module -Name BurntToast -Force -Scope CurrentUser; New-BurntToastNotification -Title 'Claude Needs You' -Message $env:CLAUDE_NOTIFICATION_MESSAGE\""
    }]
  }]
}
```

### Hook 4: Context Memory Refresh

Catches the post compact event. When Claude compacts its context, this hook automatically re-reads critical files back into the session (CLAUDE.md, architecture docs, style guides).

```json
"hooks": {
  "PostCompact": [{
    "matcher": ".*",
    "hooks": [{
      "type": "command",
      "command": "pwsh -c \"Get-Content ~/.claude/CLAUDE.md, ~/.claude/ARCHITECTURE.md -ErrorAction SilentlyContinue | Out-Null\""
    }]
  }]
}
```

### Hook 5: Auto-Approval God Mode

Pre-tool use hook on bash that checks commands against a whitelist. If matches (npm test, npx prettier, git diff, etc.), outputs JSON with decision set to allow. Claude skips permission prompts entirely.

```json
"hooks": {
  "PreToolUse": [{
    "matcher": "Bash",
    "hooks": [{
      "type": "command",
      "command": "pwsh -c \"$cmd = $env:CLAUDE_TOOL_INPUT_COMMAND; if ($cmd -match '^(npm test|npm run lint|npx prettier|git diff|git status|pytest)') { Write-Output '{ \"decision\": \"allow\" }' }\""
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
| `CLAUDE_TOOL_RESULT_PATH` | Path from tool result (PostToolUse) |
| `CLAUDE_NOTIFICATION_MESSAGE` | Message from notification event |

## Hook environment variables (Copilot CLI)

| Variable | Value |
|----------|-------|
| `GITHUB_COPILOT_TOOL_NAME` | Name of the tool being called |
| `GITHUB_COPILOT_TOOL_INPUT_PATH` | Path argument for file tools |
| `GITHUB_COPILOT_TOOL_INPUT_COMMAND` | Command string for Bash |

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
