# MCP Loading Strategy Pattern

**Created**: 2026-01-02
**Status**: Active
**Applies To**: AIProjects, AIFred, all Claude Code projects

---

## Overview

MCP (Model Context Protocol) servers consume context tokens when loaded. This pattern defines three loading strategies to optimize context usage while maintaining functionality.

**Key Constraint**: MCP servers **cannot be toggled mid-session**. Changes require restarting Claude Code.

---

## The Three Loading Strategies

```
┌─────────────────────────────────────────────────────────────────┐
│                    MCP LOADING STRATEGIES                        │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  ALWAYS-ON                ON-DEMAND               ISOLATED       │
│  ──────────               ─────────               ────────       │
│  Session Start            Session Start           Per-Invocation │
│  (if enabled)             (spawn new process)                    │
│                                                                  │
│  ┌─────────┐              ┌─────────┐            ┌─────────┐    │
│  │ Memory  │              │ n8n-MCP │            │Playwright│    │
│  │ Git     │              │ GitHub  │            │ (21 tools│    │
│  │ Fetch   │              │ SSH     │            │  ~15k)   │    │
│  │Filesys  │              │ Docker  │            └─────────┘    │
│  └─────────┘              └─────────┘                 │          │
│       │                        │                      │          │
│       ▼                        ▼                      ▼          │
│  IN MAIN CONTEXT          IN MAIN CONTEXT        SEPARATE       │
│  (~25k tokens)            (+tokens when on)      PROCESS        │
│                                                  (0 tokens)      │
└─────────────────────────────────────────────────────────────────┘
```

---

## Strategy 1: Always-On

**Definition**: MCP servers loaded at every session start. Cannot be disabled without config change + restart.

**Characteristics**:
| Aspect | Behavior |
|--------|----------|
| When loaded | Session start (automatic) |
| Token impact | Always in context |
| Toggle mid-session | No |
| Best for | Core functionality used in 80%+ of sessions |

**Current Always-On MCPs (AIProjects)**:
- **MCP Gateway** (Memory, Fetch, Docker) - ~15k tokens
- **Git MCP** - ~6k tokens
- **Filesystem MCP** - ~8k tokens

**Decision Criteria - Use Always-On When**:
- [ ] Used in 80%+ of sessions
- [ ] Core to project functionality
- [ ] Token cost acceptable for frequency of use
- [ ] No sensitive/expensive API calls on load

---

## Strategy 2: On-Demand

**Definition**: MCP servers configured but **disabled by default**. Enable for one session only, then **auto-revert to off** at session end.

**Core Principle**: Default state is always OFF. Every enable is temporary (one session).

**Characteristics**:
| Aspect | Behavior |
|--------|----------|
| Default state | **Off** (disabled in settings) |
| When loaded | Session start (only if explicitly enabled) |
| Token impact | In context when enabled |
| Toggle mid-session | No (config change + restart required) |
| Session end behavior | **Auto-disable** (returns to default off) |
| Best for | Task-specific functionality, heavy token cost |

**Current On-Demand MCPs (AIProjects)**:
- **n8n-MCP** - ~28k tokens (42 tools) - Default: OFF
- **GitHub MCP** - ~15k tokens - Default: OFF
- **SSH MCP** - ~5k tokens - Default: OFF
- **Prometheus MCP** - ~8k tokens - Default: OFF
- **Grafana MCP** - ~10k tokens - Default: OFF

**Lifecycle Flow**:
```
SESSION A (MCP off - default)
├── User needs MCP functionality
├── Claude detects MCP unavailable
├── Claude runs /checkpoint (saves state, provides enable command)
└── User exits

USER ENABLES (between sessions)
└── Runs: claude mcp add <server-name>

SESSION B (MCP on - temporary)
├── MCP tools available
├── Work completed
├── Session ends
└── Auto-disable: MCP removed from enabled list

SESSION C (MCP off - back to default)
└── Tokens saved, clean state
```

**Enable Command** (user runs between sessions):
```bash
claude mcp add <server-name>
# Then restart Claude Code
```

**Auto-Disable** (handled by session exit procedure):
- Session exit checks for enabled On-Demand MCPs
- Automatically disables them via settings modification
- No user action required

**When Claude Needs Unavailable MCP**:
1. Claude recognizes the MCP tools are not available
2. Claude runs `/checkpoint` to save current state
3. Checkpoint output includes enable instructions
4. User enables MCP, restarts, and continues from checkpoint

**Decision Criteria - Use On-Demand When**:
- [ ] Used in 20-80% of sessions
- [ ] Specific task categories (n8n work, GitHub PRs, etc.)
- [ ] High token cost worth avoiding when not needed
- [ ] User can predict need at session start

---

## Strategy 3: Isolated

**Definition**: MCP servers never loaded in main session. Spawned in separate Claude process per-invocation.

**Characteristics**:
| Aspect | Behavior |
|--------|----------|
| When loaded | New process spawned per-invocation |
| Token impact | Zero in main session |
| Toggle mid-session | N/A (each call is fresh process) |
| Best for | Heavy token cost, infrequent use, context isolation needed |

**Current Isolated MCPs (AIProjects)**:
- **Playwright MCP** - ~15k tokens (21 tools) - Via `/browser` skill

**Implementation Pattern**:
```bash
# Create a skill/command that spawns isolated session:
claude \
  --mcp-config ~/.claude/mcp-profiles/<server>.json \
  --settings ~/.claude/mcp-profiles/<server>-settings.json \
  -p "Task: $ARGUMENTS" \
  --output-format text
```

**Required Files**:
1. `~/.claude/mcp-profiles/<server>.json` - MCP config with only that server
2. `~/.claude/mcp-profiles/<server>-settings.json` - Permissions for that server
3. `.claude/commands/<server>.md` - Skill to invoke isolated session

**Decision Criteria - Use Isolated When**:
- [ ] Used in <20% of sessions
- [ ] Very high token cost (>10k tokens)
- [ ] Results can be returned as text summary
- [ ] Context isolation is beneficial (browser state, etc.)
- [ ] Latency of spawning new process is acceptable

---

## Decision Matrix

| Criteria | Always-On | On-Demand | Isolated |
|----------|-----------|-----------|----------|
| **Usage frequency** | 80%+ sessions | 20-80% sessions | <20% sessions |
| **Token cost** | <10k acceptable | 10-30k | >10k |
| **Predictable need** | Always | At session start | During session |
| **Context isolation** | Not needed | Not needed | Beneficial |
| **Latency tolerance** | N/A | Restart OK | Process spawn OK |

---

## Implementation Checklist

### Adding a New Always-On MCP

1. [ ] Add to global `~/.claude.json` or project `.mcp.json`
2. [ ] Verify token impact with `/context`
3. [ ] Document in `mcp-servers.md`
4. [ ] Update architecture docs

### Adding a New On-Demand MCP

1. [ ] Add to config (disabled by default)
2. [ ] Document enable/disable commands
3. [ ] Add to `mcp-servers.md` as Tier 2
4. [ ] Create task-specific enable instructions

### Adding a New Isolated MCP

1. [ ] Create `~/.claude/mcp-profiles/<server>.json`
2. [ ] Create `~/.claude/mcp-profiles/<server>-settings.json`
3. [ ] Create `.claude/commands/<server>.md` skill
4. [ ] Document in architecture as isolated
5. [ ] Add usage examples

---

## Current State (AIProjects)

```
DEFAULT SESSION (~22k tokens - lean)
├── Always-On
│   ├── MCP Gateway (Memory, Fetch, Docker) ~15k
│   ├── Git MCP ~6k
│   └── Filesystem MCP ~8k
│
├── On-Demand (Default: OFF, auto-revert after use)
│   ├── n8n-MCP (~28k tokens)
│   ├── GitHub MCP (~15k tokens)
│   ├── SSH MCP (~5k tokens)
│   ├── Prometheus MCP (~8k tokens)
│   └── Grafana MCP (~10k tokens)
│
└── Isolated (Separate Process)
    └── Playwright MCP (via /browser skill)
```

---

## Enforcement

### Session Exit Procedure (Hard Rule)

The session exit procedure **must** disable any On-Demand MCPs that were enabled:

```bash
# At session end, for each On-Demand MCP that is enabled:
claude mcp remove <server-name>
# This ensures next session starts with default (off) state
```

### Checkpoint Workflow (Soft Rule)

When Claude needs an unavailable On-Demand MCP:
1. Run `/checkpoint` to save state
2. Output enable instructions for user
3. User enables, restarts, continues from checkpoint

### Soft Rules

1. **Pattern Application**: When adding new MCP servers, apply this decision matrix
2. **Documentation**: All MCP servers must be documented with their loading strategy
3. **Review**: Periodically review On-Demand servers - promote to Always-On if usage >80%, demote to Isolated if <20%
4. **Missing MCP Detection**: When MCP tools are needed but unavailable, run `/checkpoint`

### Hard Rules

1. **Restart Required**: Never assume MCP changes take effect mid-session
2. **Isolated for Heavy**: Any MCP >15k tokens should default to Isolated pattern
3. **Document Token Cost**: All MCP additions must include token cost measurement
4. **Auto-Revert On-Demand**: Session exit MUST disable any enabled On-Demand MCPs

---

## Related Documentation

- @.claude/commands/checkpoint.md - Checkpoint command for MCP transitions
- @.claude/context/workflows/session-exit.md - Session exit with MCP auto-disable
- @profiles/README.md - Environment profiles (may affect MCP configuration)

---

## Changelog

- **2026-01-02**: Added On-Demand auto-revert pattern
  - On-Demand MCPs now default to OFF
  - Auto-disable at session end (returns to default)
  - Added `/checkpoint` command integration
  - Updated enforcement with hard rule for auto-revert

- **2026-01-02**: Initial pattern documentation
  - Formalized three-strategy model
  - Added decision matrix
  - Documented enforcement approach
