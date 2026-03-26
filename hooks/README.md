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
| `session.deleted` | Session ended/deleted |
| `session.compacted` | Session compacted |
| `permission.asked` | Permission requested |
| `experimental.session.compacting` | Before compaction prompt is finalized |

Plugins copied to `~/.config/opencode/plugins/`:

- `security.js` → secret-path guard + compact safety (`tool.execute.before`)
- `format-on-write.js` → auto-format supported edited files (`tool.execute.after`)
- `notifications.js` → desktop/terminal notifications (`permission.asked`, `session.idle`)
- `context-refresh.js` → compaction memory hook (`experimental.session.compacting`, `session.compacted`)
- `session-lifecycle.js` → session start/end checks and PLAN summary (`session.created`, `session.idle`, `session.deleted`)
- `binary-to-markdown.js` → convert supported binary reads to Markdown (`tool.execute.before`)

## Binary-to-Markdown Package

This repository also ships a dedicated hook package at `hooks/binary-to-markdown/` for binary document conversion.

- `convert.py` runs `markitdown` and optionally falls back to Mistral OCR for poor PDF extraction.
- `claude-code.sh/.ps1` returns Claude block responses with injected converted Markdown.
- `gemini.sh/.ps1` converts and logs guidance (Gemini cannot inject replacement content).
- `codex.sh/.ps1` is an explicit stub until Codex hook specs are published.
- OpenCode uses `config/opencode/plugins/binary-to-markdown.js` instead of shell wrappers.

### OpenCode compatibility for README hook options

| Hook option in this README | OpenCode mapping | Status |
|----------------------------|------------------|--------|
| `PreToolUse` / `BeforeTool` / `preToolUse` | `tool.execute.before` | Implemented |
| `PostToolUse` / `AfterTool` / `postToolUse` | `tool.execute.after` | Implemented |
| `Notification` | `permission.asked` | Implemented |
| `PostCompact` | `session.compacted` + `experimental.session.compacting` | Implemented |
| `SessionStart` / `sessionStart` | `session.created` | Implemented |
| `Stop` / `SessionEnd` / `sessionEnd` | `session.idle` + `session.deleted` | Implemented |
| `BeforeAgent` | No equivalent plugin event in docs | Not supported |
| `BeforeToolSelection` | No equivalent plugin event in docs | Not supported |
| `AfterModel` | No equivalent plugin event in docs | Not supported |
| `AfterAgent` | No equivalent plugin event in docs | Not supported |

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
