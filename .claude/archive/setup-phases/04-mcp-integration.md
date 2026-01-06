# Phase 4: MCP Integration

**Purpose**: Configure MCP (Model Context Protocol) servers based on user preferences.

---

## Overview

MCP servers extend Claude Code's capabilities by providing:
- **Memory**: Persistent knowledge graph storage
- **Fetch**: Web content retrieval
- **Filesystem**: File access beyond workspace
- **Custom tools**: Project-specific functionality

**This phase is OPTIONAL.** Jarvis works without MCP servers, but some features like persistent memory between sessions require MCP.

---

## Prerequisites Check

```bash
# Validate Docker is available (CLI tools only - no Docker Desktop required)
if command -v docker &> /dev/null && docker info &> /dev/null 2>&1; then
  echo "✅ Docker available and running"
  docker --version
else
  echo "⚠️ Docker not available - MCP servers using Docker will be skipped"
fi
```

**If Docker is not available**: Skip to Phase 5. MCP can be configured later.

---

## MCP Configuration Options

Present these options to the user:

### Option 1: Skip MCP (Simplest)
- No persistent memory between sessions
- Jarvis still fully functional
- Can add MCP later with `/setup-mcp`

### Option 2: Docker Desktop MCP (Recommended if using Docker Desktop)
- Built into Docker Desktop (Settings → Features → Beta → MCP)
- Provides memory, fetch, and other MCP servers
- Automatic management by Docker Desktop
- **Note**: Requires Docker Desktop, not just Docker CLI

### Option 3: Manual MCP Configuration
- Configure MCP servers in `.mcp.json` or `~/.mcp.json`
- Full control over which servers run
- Requires more setup knowledge

---

## Option 1: Skip MCP

If user chooses this option:

1. Update user preferences:
   ```yaml
   enable_memory_mcp: false
   mcp_configuration: "none"
   ```

2. Note in session state:
   ```markdown
   MCP: Not configured (can enable later with /setup-mcp)
   ```

3. Proceed to Phase 5

---

## Option 2: Docker Desktop MCP

If user has Docker Desktop and wants MCP:

### Check Docker Desktop Version
```bash
# Docker Desktop 4.40+ required for MCP
docker version --format '{{.Server.Version}}'
```

### Enable MCP in Docker Desktop
1. Open Docker Desktop
2. Go to **Settings → Features → Beta**
3. Enable **"Docker MCP"** (or "MCP Servers")
4. Click **Apply & Restart**

### After Enabling
Docker Desktop MCP provides servers that appear in Claude Code automatically:
- `mcp__docker-mcp__*` tools for container management
- `mcp__memory__*` tools for persistent memory (if enabled)

### Verify
After enabling, test in Claude Code:
```
# Try calling an MCP tool - should show available tools
Use mcp__docker-mcp__list_containers
```

**Note for setup**: Mark MCP as "pending Docker Desktop enablement" if the user needs to enable it separately.

---

## Option 3: Manual MCP Configuration

For users who want specific MCP servers without Docker Desktop MCP:

### Create .mcp.json

Create `~/.mcp.json` (global) or `.mcp.json` (project-specific):

```json
{
  "mcpServers": {
    "memory": {
      "command": "npx",
      "args": ["-y", "@modelcontextprotocol/server-memory"],
      "env": {}
    },
    "fetch": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-fetch"],
      "env": {}
    }
  }
}
```

**Available MCP Servers** (npm packages):
- `@modelcontextprotocol/server-memory` - Knowledge graph memory
- `@anthropic/mcp-fetch` - Web fetching
- `@modelcontextprotocol/server-filesystem` - File access
- `@modelcontextprotocol/server-brave-search` - Brave search (needs API key)

### Restart Claude Code

After creating/updating `.mcp.json`, restart Claude Code to load the MCP servers.

---

## Memory Usage Guidelines

If Memory MCP is enabled (any option), create guidelines:

Create `.claude/context/integrations/memory-usage.md`:

```markdown
# Memory MCP Usage

## What to Store
- **Decisions**: Why you chose approach A over B
- **Relationships**: Service X depends on Service Y
- **Events**: When things were installed, migrated, or broke
- **Lessons**: Solutions that worked, patterns to follow

## What NOT to Store
- Detailed documentation (use context files instead)
- Secrets or credentials (NEVER)
- Temporary states
- Duplicates of file content
- Obvious facts

## Entity Types
- **Event**: Installations, migrations, incidents
- **Decision**: Choices and rationale
- **Lesson**: What was learned from experience
- **Relationship**: How systems connect

## Pruning
- Entities inactive 90+ days should be reviewed
- Access tracked in metadata
- Clean up stale entities periodically
```

---

## Validation

Before proceeding:

- [ ] User selected MCP option (skip/docker-desktop/manual)
- [ ] If Option 2: Docker Desktop MCP status documented (enabled/pending)
- [ ] If Option 3: .mcp.json created and verified
- [ ] If any MCP enabled: memory-usage.md created
- [ ] paths-registry.yaml updated with MCP configuration

### Quick Verification

```bash
# Check if .mcp.json exists
[ -f ~/.mcp.json ] && echo "✅ Global .mcp.json exists" || echo "ℹ️ No global .mcp.json"
[ -f .mcp.json ] && echo "✅ Project .mcp.json exists" || echo "ℹ️ No project .mcp.json"
```

---

## Troubleshooting

### MCP servers not appearing in Claude Code
1. Verify `.mcp.json` syntax: `cat ~/.mcp.json | jq .`
2. Restart Claude Code completely
3. Check Claude Code logs for MCP errors

### Docker Desktop MCP not working
1. Verify Docker Desktop version 4.40+
2. Check Settings → Features → Beta → MCP is enabled
3. Restart Docker Desktop
4. Restart Claude Code

### Memory not persisting
1. Verify memory server is running
2. Check that memory tools (`mcp__memory__*`) are available
3. Test with `mcp__memory__read_graph`

---

*Phase 4 of 7 - MCP Integration*
*Docker is optional. MCP is optional. Both can be added later.*
