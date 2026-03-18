# MCP Server: memory

**Package**: `@modelcontextprotocol/server-memory`  
**Source**: https://github.com/modelcontextprotocol/servers/tree/main/src/memory  
**Auth**: None  
**Used by**: OpenCode, VSCode Copilot

## What it does

Provides a persistent key-value store that AI agents can read and write during a session. Useful for maintaining context across tool calls or storing intermediate results.

## Tools exposed

| Tool | Description |
|------|-------------|
| `create_entities` | Store named entities with observations |
| `search_nodes` | Query stored knowledge |
| `read_graph` | Retrieve the full memory graph |
| `add_observations` | Append observations to an entity |
| `delete_entities` | Remove stored entities |

## Configuration

```json
{
  "memory": {
    "type": "local",
    "command": ["npx", "-y", "@modelcontextprotocol/server-memory"],
    "enabled": true
  }
}
```

## Optional persistence

Set `MEMORY_FILE_PATH` to persist memory across sessions:

```json
"environment": {
  "MEMORY_FILE_PATH": "C:/Users/<YOU>/.config/mcp-memory/memory.json"
}
```
