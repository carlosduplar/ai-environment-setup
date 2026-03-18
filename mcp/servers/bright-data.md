# MCP Server: bright-data

**Package**: `@brightdata/mcp`  
**Source**: https://github.com/brightdata-com/brightdata-mcp  
**Auth**: `BRIGHT_DATA_API_TOKEN` (required)  
**Used by**: OpenCode, VSCode Copilot

## What it does

Gives AI agents access to Bright Data's web scraping and SERP API — unlocking any webpage (including JS-heavy, bot-protected sites) and returning structured content.

## Tools exposed

| Tool | Description |
|------|-------------|
| `scrape_as_markdown` | Scrape a URL and return Markdown |
| `search_engine` | Google/Bing/Yandex SERP results |
| `scrape_batch` | Scrape multiple URLs in parallel |
| `search_engine_batch` | Multiple search queries in parallel |

## Auth

1. Sign up at https://brightdata.com/
2. Create an API token in your dashboard
3. Add to `.env.local`:

```
BRIGHT_DATA_API_TOKEN=<your_token>
```

## Configuration

```json
{
  "bright-data": {
    "type": "local",
    "command": ["npx", "-y", "@brightdata/mcp"],
    "enabled": true,
    "environment": {
      "API_TOKEN": "$BRIGHT_DATA_API_TOKEN"
    }
  }
}
```
