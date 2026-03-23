# MCP Catalog

All Model Context Protocol servers configured in this environment.

| Server | Package | Auth | Tools |
|--------|---------|------|-------|
| [playwright](../mcp/servers/playwright.md) | `@playwright/mcp` | None | browser automation |

## Adding a server

See [mcp/README.md](../mcp/README.md).

## Per-tool config locations

| Tool | File |
|------|------|
| OpenCode | `~/.config/opencode/opencode.json` |
| VSCode Copilot | `%APPDATA%\Code\User\mcp.json` |
| Gemini CLI | `~/.gemini/mcp-server-enablement.json` |
| Claude Code | Per-project `.mcp.json` |
