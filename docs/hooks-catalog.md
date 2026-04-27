# Hooks Catalog

Hooks that run automatically at AI tool lifecycle events.

## Claude Code Configuration

Add to `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Read",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/pretooluse.ps1",
            "shell": "powershell",
            "timeout": 30
          }
        ]
      },
      {
        "matcher": "Write|Edit|MultiEdit|Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/file-guard.ps1",
            "shell": "powershell",
            "timeout": 10
          },
          {
            "type": "command",
            "command": "~/.claude/hooks/bash-guard.ps1",
            "shell": "powershell",
            "timeout": 5
          },
          {
            "type": "command",
            "command": "~/.claude/hooks/write-guard.ps1",
            "shell": "powershell",
            "timeout": 5
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/notify.ps1",
            "shell": "powershell",
            "timeout": 15
          }
        ]
      }
    ],
    "PostToolUseFailure": [
      {
        "matcher": "*",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/posttoolusefailure.ps1",
            "shell": "powershell",
            "timeout": 5
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "startup|resume|compact",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/session-start-reminder.ps1",
            "shell": "powershell",
            "timeout": 5
          }
        ]
      }
    ]
  }
}
```

### Hook Scripts Reference

| Script | Purpose |
|--------|---------|
| `pretooluse.ps1` | Pre-read guard - optimizes images/PDFs to temp files before reading |
| `file-guard.ps1` | Blocks edits to protected paths (.env, .git, secrets), prevents outside-workspace access |
| `bash-guard.ps1` | Blocks dangerous bash commands (sudo, rm -rf /, eval, curl \| bash) |
| `write-guard.ps1` | Blocks writes containing secrets, allows safe files (.env.example, tests, .md) |
| `notify.ps1` | Desktop notifications via Windows Toast |
| `posttoolusefailure.ps1` | Logs tool failures to `~/.claude/logs/errors/` with rotation |
| `session-start-reminder.ps1` | Shows project type, branch, uncommitted changes on session start |
| `post-edit-format.ps1` | Auto-formats edited files (Prettier for JS/TS, Black for Python) |

## Copilot CLI Configuration

Create `.github/hooks/hooks.json` in each repository (must be on default branch):

```json
{
  "version": 1,
  "hooks": {
    "preToolUse": [
      {
        "type": "command",
        "bash": "../../hooks/pre-tool-use.sh",
        "powershell": "../../hooks/pre-tool-use.ps1"
      }
    ],
    "postToolUse": [
      {
        "type": "command",
        "bash": "../../hooks/post-tool-use.sh",
        "powershell": "../../hooks/post-tool-use.ps1"
      }
    ]
  }
}
```

Paths in `.github/hooks/hooks.json` are resolved from `.github/hooks/`. In this repository, hooks live in `hooks/`, so we use `../../hooks/*`.

## OpenCode Configuration

OpenCode uses JS plugins instead of shell hook scripts. Copy these plugins to:

```text
~/.config/opencode/plugins/security.js
~/.config/opencode/plugins/format-on-write.js
~/.config/opencode/plugins/notifications.js
~/.config/opencode/plugins/context-refresh.js
~/.config/opencode/plugins/session-lifecycle.js
~/.config/opencode/plugins/binary-to-markdown.js
```

Event mapping (validated against OpenCode plugin docs via Context7):

- `tool.execute.before` → pre-tool guard (`security.js`)
- `tool.execute.after` → post-tool formatter (`format-on-write.js`)
- `permission.asked` → notification trigger (`notifications.js`)
- `session.created` → session-start checks (`session-lifecycle.js`)
- `session.idle` / `session.deleted` → session-end summaries (`session-lifecycle.js`)
- `session.compacted` / `experimental.session.compacting` → compact lifecycle hooks (`context-refresh.js`)
- `tool.execute.before` → binary file conversion hook (`binary-to-markdown.js`)

## Currently configured hooks

Hooks only run when referenced in each tool's settings (for Claude Code, `~/.claude/settings.json` → `hooks`).

| Hook | Description |
|------|-------------|
| binary-to-markdown | Converts binary files (PDF, DOCX, XLSX, PPTX…) to Markdown before the AI reads them, reducing token consumption by 10–30× |

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

Pre-tool use hook on bash that checks commands against a whitelist. If matched, it auto-allows low-risk local commands (git/file inspection and local test/lint/typecheck/build checks). Install/network/destructive commands remain approval-gated or denied.

```json
"hooks": {
  "PreToolUse": [{
    "matcher": "Bash",
    "hooks": [{
      "type": "command",
      "command": "pwsh -c \"$cmd = $env:CLAUDE_TOOL_INPUT_COMMAND; if ($cmd -match '^(npm test|npm run lint|npm run typecheck|npm run build|git diff|git status|git show|git log|rg\\s|grep\\s|pytest|python -m pytest|ruff check|mypy\\s)') { Write-Output '{ \\\"permissionDecision\\\":\\\"allow\\\" }' }\""
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

## Pre-built hook assets

The repository includes ready-to-use hook assets:

- `claude-code-pre-tool-use.sh` / `.ps1` – Claude Code pre-tool guard
- `post-tool-use.sh` / `.ps1`, `notification.sh` / `.ps1`, `post-compact.sh` / `.ps1` – Claude Code lifecycle hooks
- `gemini-pre-tool-use.sh` / `.ps1` – Gemini CLI pre-tool guard
- `hooks/binary-to-markdown/convert.py`, `claude-code.sh` / `.ps1`, `gemini.sh` / `.ps1`, `codex.sh` / `.ps1` – binary document conversion package
- `pre-tool-use.sh` / `.ps1`, `post-tool-use.sh` / `.ps1`, `session-start.sh` / `.ps1`, `session-end.sh` / `.ps1` – Copilot CLI repo hooks
- `config/opencode/plugins/security.js`, `format-on-write.js`, `notifications.js`, `context-refresh.js`, `session-lifecycle.js`, `binary-to-markdown.js` – OpenCode plugin hooks

Bootstrap copies these to user hook/plugin directories (Claude, Gemini, OpenCode). Copilot hooks stay repo-scoped in `.github/hooks/hooks.json`.
