# Service Architecture Pattern

**Purpose**: Standard patterns for building TypeScript services in the AIProjects ecosystem.

**Created**: 2026-01-20
**Last Updated**: 2026-01-20

---

## Overview

This pattern establishes how to build and integrate new TypeScript services. It covers:
- Job queue orchestration (pg-boss)
- MCP exposure for AI agent access
- n8n integration strategy
- Credential management (for external APIs)

---

## Core Principles

### 1. Code-First, n8n-Orchestrated

| Build In TypeScript | Use n8n For |
|---------------------|-------------|
| Business logic | Multi-service orchestration |
| REST API endpoints | Webhook receivers |
| Complex transformations | Visual debugging |
| Real-time processing | Scheduling |
| MCP server exposure | External API retry/fallback |

**Key insight**: n8n becomes the **orchestration layer** that calls your TypeScript services, not where you write business logic.

### 2. PostgreSQL-Native Infrastructure

Use PostgreSQL for everything possible to minimize dependencies:
- Primary data storage
- Job queues (pg-boss, not Redis)
- Credential encryption (pgcrypto)
- Vector embeddings (pgvector)

### 3. MCP-First AI Integration

Every service with an API should also expose an MCP server for direct AI agent access.

---

## Pattern 1: Job Queue with pg-boss

### What is pg-boss?

**pg-boss** is a PostgreSQL-native job queue for Node.js. It uses PostgreSQL's `SKIP LOCKED` for concurrent job processing, providing:
- Exactly-once job delivery
- Automatic retries with exponential backoff
- Scheduled/cron jobs
- Singleton jobs (prevent duplicates)
- No Redis required

### When to Use

- Background processing (voice generation, image generation)
- Scheduled tasks (token refresh, data sync)
- Webhook processing with retry logic
- Any async work that shouldn't block HTTP responses

### Implementation

```typescript
// src/services/jobQueue.ts
import PgBoss from 'pg-boss';
import { z } from 'zod';

// 1. Define job schemas with Zod for type safety
export const VoiceGenerationJobSchema = z.object({
  characterId: z.string(),
  text: z.string(),
  outputPath: z.string(),
  workspace: z.string().optional(),
});

export type VoiceGenerationJob = z.infer<typeof VoiceGenerationJobSchema>;

// 2. Initialize pg-boss
let boss: PgBoss | null = null;

export async function initJobQueue(connectionString: string): Promise<PgBoss> {
  boss = new PgBoss({
    connectionString,
    retryLimit: 3,
    retryDelay: 5,        // 5 seconds
    retryBackoff: true,   // Exponential backoff
  });

  await boss.start();

  // Register workers
  await registerWorkers();

  return boss;
}

export function getJobQueue(): PgBoss {
  if (!boss) throw new Error('Job queue not initialized');
  return boss;
}

// 3. Type-safe job creation
export async function queueVoiceGeneration(data: VoiceGenerationJob) {
  const boss = getJobQueue();
  return boss.send('voice-generation', data, {
    retryLimit: 3,
    retryBackoff: true,
    // Prevent duplicate jobs for same character/text
    singletonKey: `voice-${data.characterId}-${Buffer.from(data.text).toString('base64').slice(0, 20)}`,
  });
}

// 4. Register workers
async function registerWorkers() {
  const boss = getJobQueue();

  await boss.work('voice-generation', { teamSize: 2 }, async (job) => {
    const data = VoiceGenerationJobSchema.parse(job.data);
    // Process job...
    console.log(`Generating voice for ${data.characterId}`);
  });
}

// 5. Scheduled jobs (cron-style)
export async function scheduleTokenRefresh() {
  const boss = getJobQueue();
  await boss.schedule('token-refresh', '*/15 * * * *', {}, {
    tz: 'America/Denver',
  });
}
```

### Job Monitoring Endpoint

```typescript
// src/routes/jobs.ts
router.get('/jobs/status', async (req, res) => {
  const boss = getJobQueue();
  const stats = await boss.getQueueSize('voice-generation');
  const failed = await boss.getQueueSize('voice-generation', { state: 'failed' });

  res.json({
    pending: stats,
    failed,
    healthy: failed < 10,
  });
});
```

### Key Options

| Option | Purpose | Recommended |
|--------|---------|-------------|
| `retryLimit` | Max retries | 3-5 |
| `retryDelay` | Seconds between retries | 5-30 |
| `retryBackoff` | Exponential backoff | true |
| `singletonKey` | Prevent duplicate jobs | Use for idempotent ops |
| `startAfter` | Delay job start | ISO 8601 or Date |
| `expireInMinutes` | Job timeout | 15-60 |

---

## Pattern 2: MCP Server Exposure

### Why MCP?

MCP (Model Context Protocol) lets AI agents directly call your service's functions. Benefits:
- No need to remember API endpoints
- Type-safe tool definitions
- Works with Claude Code, Claude Desktop, other MCP clients
- Natural language interface to your services

### When to Use

Add an MCP server to any service that:
- Has a REST API you call frequently
- Would benefit from AI-assisted operation
- Manages domain-specific data (characters, projects, configs)

### Implementation

```typescript
// src/mcp-server.ts
import { Server } from '@modelcontextprotocol/sdk/server/index.js';
import { StdioServerTransport } from '@modelcontextprotocol/sdk/server/stdio.js';

const server = new Server(
  { name: 'my-service', version: '1.0.0' },
  { capabilities: { tools: {} } }
);

// Define available tools
server.setRequestHandler('tools/list', async () => ({
  tools: [
    {
      name: 'list_items',
      description: 'List all items, optionally filtered',
      inputSchema: {
        type: 'object',
        properties: {
          filter: { type: 'string', description: 'Optional filter query' },
        },
      },
    },
    {
      name: 'create_item',
      description: 'Create a new item',
      inputSchema: {
        type: 'object',
        properties: {
          name: { type: 'string' },
          data: { type: 'object' },
        },
        required: ['name'],
      },
    },
  ],
}));

// Handle tool calls
server.setRequestHandler('tools/call', async (request) => {
  const { name, arguments: args } = request.params;

  switch (name) {
    case 'list_items': {
      const items = await myService.list(args?.filter);
      return { content: [{ type: 'text', text: JSON.stringify(items, null, 2) }] };
    }
    case 'create_item': {
      const item = await myService.create(args.name, args.data);
      return { content: [{ type: 'text', text: JSON.stringify(item, null, 2) }] };
    }
    default:
      throw new Error(`Unknown tool: ${name}`);
  }
});

// Entry point
async function main() {
  const transport = new StdioServerTransport();
  await server.connect(transport);
}

main().catch(console.error);
```

### Claude Code Configuration

Add to `~/.claude.json`:

```json
{
  "mcpServers": {
    "my-service": {
      "command": "node",
      "args": ["/path/to/service/dist/mcp-server.js"],
      "env": {
        "DATABASE_URL": "postgresql://..."
      }
    }
  }
}
```

### Best Practices

1. **One MCP server per service** - Keep tools focused
2. **Match REST API structure** - If you have `/api/items`, have a `list_items` tool
3. **Return JSON** - Structured data is easier for AI to work with
4. **Include descriptions** - Help the AI understand when to use each tool
5. **Validate inputs** - Use Zod on the MCP side too

---

## Pattern 3: n8n Integration

### Workflow Structure

```
┌─────────────────────────────────────────────────────────────┐
│                    n8n Workflow                              │
│                                                              │
│  ┌──────────┐    ┌──────────────┐    ┌──────────────┐      │
│  │ Trigger  │───▶│ Service A    │───▶│ Service B    │      │
│  │ (Webhook │    │ (HTTP Call)  │    │ (HTTP Call)  │      │
│  │ or Cron) │    └──────────────┘    └──────────────┘      │
│  └──────────┘           │                   │              │
│                         ▼                   ▼              │
│                  ┌──────────────────────────────────┐      │
│                  │      Combine & Transform         │      │
│                  └──────────────────────────────────┘      │
│                                   │                        │
│                                   ▼                        │
│                          ┌──────────────┐                  │
│                          │   Response   │                  │
│                          └──────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

### When to Use n8n

| Use n8n | Use Direct HTTP |
|---------|-----------------|
| Orchestrating multiple services | Single service call |
| Need visual debugging | Simple request/response |
| Webhook receiver | Direct API integration |
| Complex retry/fallback logic | One-shot operations |
| Scheduled batch operations | Real-time streaming |

### n8n Webhook Pattern

```json
{
  "name": "Service Orchestration",
  "nodes": [
    {
      "name": "Webhook",
      "type": "n8n-nodes-base.webhook",
      "parameters": {
        "path": "orchestrate",
        "httpMethod": "POST"
      }
    },
    {
      "name": "Call Service A",
      "type": "n8n-nodes-base.httpRequest",
      "parameters": {
        "url": "http://service-a:8200/api/process",
        "method": "POST",
        "bodyParameters": {
          "parameters": [
            { "name": "input", "value": "={{ $json.input }}" }
          ]
        }
      }
    }
  ]
}
```

---

## Pattern 4: Credential Vault (Future)

### When Needed

Implement this pattern when:
- Adding external API integrations (Google, Slack, Stripe)
- Managing per-user OAuth tokens
- Centralizing credential management across services

### Architecture

```sql
-- Encrypted credential storage
CREATE TABLE connections (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  provider_id VARCHAR(50) NOT NULL,      -- 'google', 'slack', etc.
  user_id VARCHAR(100) NOT NULL,          -- Tenant/user identifier
  encrypted_dek BYTEA NOT NULL,           -- Data Encryption Key
  encrypted_payload BYTEA NOT NULL,       -- Token data
  iv BYTEA NOT NULL,
  auth_tag BYTEA NOT NULL,
  token_expires_at TIMESTAMPTZ,
  refresh_token_encrypted BYTEA,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_connections_provider_user ON connections(provider_id, user_id);
CREATE INDEX idx_connections_expires ON connections(token_expires_at);
```

### Key Components

| Component | Library | Purpose |
|-----------|---------|---------|
| OAuth flows | `simple-oauth2` | Handle OAuth 2.0 dance |
| Encryption | Node.js `crypto` | AES-256-GCM envelope encryption |
| Token refresh | pg-boss scheduler | Proactive refresh before expiry |
| Proxy | Express middleware | Inject auth headers into requests |

### Implementation Reference

See: `.claude/context/designs/api-integration-adoption-plan.md` for full implementation details when needed.

---

## Service Checklist

When building a new TypeScript service:

- [ ] **Database**: Use PostgreSQL (via Prisma, Drizzle, or better-sqlite3 for local)
- [ ] **Job Queue**: Add pg-boss for background processing
- [ ] **REST API**: Express or Fastify with OpenAPI docs
- [ ] **MCP Server**: Expose key operations for AI agents
- [ ] **Health Endpoint**: `GET /api/health` (see health-endpoint-pattern.md)
- [ ] **n8n Workflow**: Create orchestration workflow if multi-service
- [ ] **Docker**: Dockerfile + docker-compose.yml
- [ ] **Registration**: Add to paths-registry.yaml

---

## Related Patterns

- `health-endpoint-pattern.md` - Standard health check endpoints
- `mcp-loading-strategy.md` - When to load MCP servers
- `agent-selection-pattern.md` - When to use agents vs direct tools

---

## Examples in This Project

| Service | pg-boss | MCP Server | n8n Integration |
|---------|---------|------------|-----------------|
| voice-character-system | Planned | Planned | Yes (audio-tools/) |
| image-gen-api | Planned | Planned | Planned |
| grc-platform | No | No | No |
| kali-scanner | No | No | No |
