# MCP Servers

This directory catalogs all Model Context Protocol (MCP) servers used across the AI tools in this environment.

## What is MCP?

MCP (Model Context Protocol) is an open standard that lets AI assistants call external tools and data sources. See [modelcontextprotocol.io](https://modelcontextprotocol.io).

## Servers in Use

| Server | Package | Used By | Auth |
|--------|---------|---------|------|
| memory | `@modelcontextprotocol/server-memory` | OpenCode, VSCode | None |
| playwright | `@playwright/mcp` | Gemini (optional) | None |

## Adding a New Server

1. Add the server entry to `mcp-servers.json.example`
2. Add documentation in `servers/<name>.md`
3. Add the server to `config/opencode/opencode.json.example` and `config/vscode/mcp.json.example`
4. Add any new env vars to `templates/.env.example`
5. Document in `docs/mcp-catalog.md`

## Config locations per tool

| Tool | MCP Config |
|------|-----------|
| OpenCode | `~/.config/opencode/opencode.json` → `mcp` key |
| Claude Code | Per-project `.mcp.json` or global settings |
| Gemini CLI | `~/.gemini/mcp-server-enablement.json` |
| VSCode | `%APPDATA%\Code\User\mcp.json` |
