# Hooks

Hooks allow custom scripts to run at specific points in the AI tool lifecycle — before/after file edits, before/after bash commands, on session start/stop, etc.

## Supported Tools

| Tool | Hook Mechanism | Config Location |
|------|---------------|-----------------|
| Claude Code | Shell scripts | `~/.claude/settings.json` → `hooks` |
| OpenCode | JS/TS plugins | `~/.config/opencode/plugins/*.js` |
| Gemini CLI | Shell scripts | `~/.gemini/settings.json` → `hooks` |
| GitHub Copilot CLI | Repo-scoped hook JSON | `.github/hooks/hooks.json` |

## Claude Code

Shell scripts referenced from `~/.claude/settings.json`:

```json
{
  "hooks": {
    "PreToolUse": [{
      "matcher": ".*",
      "hooks": [{ "type": "command", "command": "~/.claude/hooks/pre-tool-use.sh" }]
    }]
  }
}
```

| Event | Trigger |
|-------|---------|
| `PreToolUse` | Before any tool call |
| `PostToolUse` | After any tool call |
| `Notification` | On agent notifications |
| `Stop` | When agent completes |

Scripts copied to `~/.claude/hooks/`: `pre-tool-use.*`, `post-tool-use.*`, `notification.*`, `post-compact.*`

## OpenCode

Uses JS/TS plugins, NOT shell scripts. Plugins export an async function returning event handlers:

```javascript
export const SecurityPlugin = async ({ $ }) => {
  return {
    "tool.execute.before": async (input, output) => {
      // block secret file access
    }
  }
}
```

| Event | Trigger |
|-------|---------|
| `tool.execute.before` | Before any tool call |
| `tool.execute.after` | After any tool call |
| `session.created` | New session started |
| `session.idle` | Session becomes idle |
| `permission.asked` | Permission requested |

Plugin: `config/opencode/plugins/security.js` → copied to `~/.config/opencode/plugins/security.js`

## Gemini CLI

Shell scripts referenced from `~/.gemini/settings.json`:

```json
{
  "hooks": {
    "BeforeTool": [{
      "matcher": "*",
      "hooks": [{ "name": "security", "type": "command", "command": "bash ~/.gemini/hooks/pre-tool-use.sh" }]
    }]
  }
}
```

| Event | Trigger |
|-------|---------|
| `SessionStart` | Session starts |
| `BeforeAgent` | Before agent runs |
| `BeforeToolSelection` | Before LLM selects tools |
| `BeforeTool` | Before tool execution |
| `AfterTool` | After tool execution |
| `AfterModel` | After model response |
| `AfterAgent` | After agent completes |
| `SessionEnd` | Session ends |

Scripts: `gemini-pre-tool-use.sh/ps1` → copied to `~/.gemini/hooks/pre-tool-use.sh/ps1`

## GitHub Copilot CLI

Copilot CLI hooks are repository-scoped. This repo config lives at `.github/hooks/hooks.json` and points to scripts in `hooks/`.

| Event | Script |
|-------|--------|
| `preToolUse` | `hooks/pre-tool-use.sh` / `.ps1` |
| `postToolUse` | `hooks/post-tool-use.sh` / `.ps1` |
| `sessionStart` | `hooks/session-start.sh` / `.ps1` |
| `sessionEnd` | `hooks/session-end.sh` / `.ps1` |

There is no native global/user-level hook file for Copilot CLI; each repository must include its own `.github/hooks/hooks.json`.

## Security note

Hook commands run with your user privileges. Never execute untrusted content from AI output in a hook. Always validate inputs.
