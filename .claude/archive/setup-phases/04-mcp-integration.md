# Phase 4: MCP Integration

**Purpose**: Set up MCP servers based on user preferences from Phase 2.

---

## Prerequisites

- Docker must be installed (from Phase 1)
- User opted for Memory MCP (from Phase 2)

If Docker not installed or Memory MCP declined, skip to Phase 5.

---

## MCP Gateway Deployment

### 1. Create Docker Compose

Create `docker/mcp-gateway/docker-compose.yml`:

```yaml
version: '3.8'

services:
  mcp-gateway:
    image: docker/mcp-gateway:latest
    container_name: mcp-gateway
    restart: unless-stopped
    ports:
      - "8811:8080"
    volumes:
      - mcp-memory-data:/data/memory
      - ./config:/config
    environment:
      - MCP_SERVERS=memory,fetch
    networks:
      - mcp-network
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/health"]
      interval: 30s
      timeout: 10s
      retries: 3

volumes:
  mcp-memory-data:
    name: aifred-mcp-memory

networks:
  mcp-network:
    name: aifred-mcp-network
```

### 2. Deploy MCP Gateway

```bash
cd docker/mcp-gateway
docker-compose up -d
```

### 3. Verify Deployment

```bash
# Check container running
docker ps | grep mcp-gateway

# Test health endpoint
curl http://localhost:8811/health
```

### 4. Configure Claude Code MCP

Update `.mcp.json` (in user home or project root):

```json
{
  "mcpServers": {
    "mcp-gateway": {
      "command": "npx",
      "args": ["-y", "@anthropic/mcp-gateway-client"],
      "env": {
        "MCP_GATEWAY_URL": "http://localhost:8811/sse"
      }
    }
  }
}
```

### 5. Initialize Memory

Seed initial memory entities:

```
Entity: "AIfred Installation"
Type: "Event"
Observations:
  - "Installed on [date]"
  - "Host: [hostname]"
  - "Automation level: [level]"
  - "Focus areas: [list]"
```

---

## Memory MCP Guidelines

Create `.claude/context/integrations/memory-usage.md`:

```markdown
# Memory MCP Usage

## What to Store
- Decisions and rationale
- System relationships (A depends on B)
- Temporal events (installs, incidents)
- Lessons learned

## What NOT to Store
- Detailed documentation (use context files)
- Secrets or credentials
- Temporary states
- Duplicates of file content

## Entity Types
- Event: Installations, migrations, incidents
- Decision: Choices and rationale
- Lesson: What was learned from experience
- Relationship: How systems connect

## Pruning
- Entities inactive 90+ days are archived
- Access tracked in metadata
- Weekly cron job manages cleanup
```

---

## Validation

- [ ] MCP Gateway container running
- [ ] Health check passing
- [ ] Claude Code can connect (test with `mcp__mcp-gateway__read_graph`)
- [ ] Initial memory entities seeded
- [ ] Memory usage guidelines created

---

*Phase 4 of 7 - MCP Integration*
