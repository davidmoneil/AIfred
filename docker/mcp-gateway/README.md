# MCP Gateway

This directory is reserved for MCP (Model Context Protocol) related configurations.

## Current Status

MCP servers are configured via one of these methods:

### Option 1: Docker Desktop MCP (Recommended)
Docker Desktop 4.40+ includes built-in MCP support:
1. Open Docker Desktop
2. Settings → Features → Beta
3. Enable "Docker MCP"

This provides `mcp__docker-mcp__*` tools automatically.

### Option 2: Manual Configuration
Configure MCP servers in `~/.mcp.json`:

```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"]
    },
    "fetch": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-fetch"]
    }
  }
}
```

### Option 3: Skip MCP
Jarvis works without MCP. Memory and advanced features can be added later.

## Note on docker/mcp-gateway Image

The `docker/mcp-gateway` image is designed as an **stdio server** for Docker Desktop MCP integration, not as a standalone HTTP daemon. Do not attempt to run it directly with docker-compose as a long-running service.

See `.claude/archive/setup-phases/04-mcp-integration.md` for full setup instructions.
