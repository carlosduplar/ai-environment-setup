# MCP Server: playwright

**Package**: `@playwright/mcp`  
**Source**: https://github.com/microsoft/playwright-mcp  
**Auth**: None  
**Used by**: Gemini CLI (optional), VSCode Copilot (optional)

## What it does

Provides browser automation tools to AI agents via Playwright — navigate pages, fill forms, take screenshots, extract text, click elements.

## Prerequisites

```powershell
# Install browsers (run once)
playwright install
# or: playwright install chromium
```

## Tools exposed

| Tool | Description |
|------|-------------|
| `browser_navigate` | Navigate to a URL |
| `browser_click` | Click an element |
| `browser_type` | Type text |
| `browser_screenshot` | Capture a screenshot |
| `browser_get_text` | Extract visible text |

## Configuration

```json
{
  "playwright": {
    "type": "local",
    "command": ["npx", "-y", "@playwright/mcp"],
    "enabled": false
  }
}
```

Set `"enabled": true` to activate. Disabled by default to save resources.

## Gemini CLI enablement

Edit `~/.gemini/mcp-server-enablement.json`:

```json
{
  "playwright": { "enabled": true }
}
```
