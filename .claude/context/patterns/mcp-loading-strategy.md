# MCP Loading Strategy Pattern

**Created**: 2026-01-02
**Updated**: 2026-01-09 (PR-8.5 Revision)
**Status**: Active
**Applies To**: Jarvis, all Claude Code projects

---

## Overview

MCP servers consume context tokens when loaded. This pattern defines three loading tiers to optimize context usage while maintaining functionality.

**Key Constraints**:
- MCP servers cannot be toggled mid-session (changes require restart)
- Tool definitions consume ~45K token budget maximum
- With 15+ MCPs active, some tools won't load (Discovery #7)

---

## The Three Loading Tiers

```
┌─────────────────────────────────────────────────────────────────┐
│                    MCP LOADING TIERS                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                  │
│  TIER 1: ALWAYS-ON       TIER 2: TASK-SCOPED     TIER 3: ON-DEMAND │
│  ──────────────────      ─────────────────────   ────────────────  │
│  Load every session      Load based on task      Load when needed  │
│  (~8K tokens)            (+tokens per MCP)       (isolated use)    │
│                                                                  │
│  ┌─────────────┐         ┌─────────────────┐    ┌─────────────┐  │
│  │ memory      │         │ github          │    │ playwright  │  │
│  │ filesystem  │         │ context7        │    │ lotus-wisdom│  │
│  │ fetch       │         │ sequential-think│    └─────────────┘  │
│  │ git         │         │ brave-search    │         │           │
│  └─────────────┘         │ arxiv           │         ▼           │
│        │                 │ datetime        │    TRIGGERED BY     │
│        │                 │ wikipedia       │    SPECIFIC COMMAND │
│        ▼                 │ chroma          │                      │
│  ALWAYS IN CONTEXT       │ desktop-cmdr    │                      │
│                          │ perplexity      │                      │
│                          │ gptresearcher   │                      │
│                          └─────────────────┘                      │
│                                 │                                 │
│                                 ▼                                 │
│                          ENABLED PER-SESSION                      │
│                          BASED ON WORK TYPE                       │
└─────────────────────────────────────────────────────────────────┘
```

---

## Tier 1: Always-On (~8K tokens)

**Definition**: Core MCPs loaded at every session start. Essential for base functionality.

| MCP | Tokens | Purpose | Tools |
|-----|--------|---------|-------|
| memory | ~1.8K | Persistent knowledge graph | 9 tools |
| filesystem | ~2.8K | External file operations | 13 tools |
| fetch | ~0.5K | Web content retrieval | 1 tool |
| git | ~2.5K | Repository operations | 12 tools |

**Total Tier 1**: ~7.6K tokens

**Characteristics**:
- Loaded automatically every session
- Cannot be disabled without config change
- Used in 80%+ of sessions
- Core to primary workflows

**Decision Criteria**:
- [ ] Used in 80%+ of sessions
- [ ] Core to project functionality
- [ ] Token cost <3K per MCP
- [ ] No external dependencies that may fail

---

## Tier 2: Task-Scoped (~34K total, select subset)

**Definition**: MCPs enabled based on session work type. Select relevant subset at session start.

| MCP | Tokens | Use Case | Enable When |
|-----|--------|----------|-------------|
| github | ~5K | PR/issue work | Working on PRs, issues |
| context7 | ~2K | Library docs | Documentation lookup |
| sequential-thinking | ~1K | Complex reasoning | Architecture decisions |
| brave-search | ~3K | Web search | Research tasks |
| arxiv | ~2K | Academic papers | Academic research |
| datetime | ~1K | Timezone ops | Time-sensitive work |
| wikipedia | ~2K | Reference lookups | Background research |
| chroma | ~4K | Vector storage | Semantic search tasks |
| desktop-commander | ~8K | System operations | File/process management |
| perplexity | ~3K | AI search | Research with citations |
| gptresearcher | ~3K | Deep research | Comprehensive research |

**Characteristics**:
- Enable at session start based on planned work
- Can load 6-8 Tier 2 MCPs alongside Tier 1
- Session-start hook suggests MCPs based on session-state.md
- Changes require `/clear` and restart

**Selection by Work Type**:

| Work Type | Recommended Tier 2 MCPs |
|-----------|------------------------|
| Development | github, context7, sequential-thinking |
| Research | brave-search, perplexity, gptresearcher, arxiv |
| Documentation | wikipedia, chroma |
| System Admin | desktop-commander, datetime |

**Lifecycle**:
```
1. Session Start
   → Hook reads session-state.md
   → Suggests relevant Tier 2 MCPs

2. User enables if needed
   → claude mcp add <name>
   → Run /clear

3. Session End
   → Document active MCPs in session-state
   → Optionally disable for next session
```

---

## Tier 3: On-Demand (~8K total)

**Definition**: MCPs with specialized use cases. Enable only when specific functionality needed.

| MCP | Tokens | Use Case | Trigger |
|-----|--------|----------|---------|
| playwright | ~6K | Browser automation | /browser-test, QA tasks |
| lotus-wisdom | ~2K | Contemplative reasoning | Philosophical analysis |

**Characteristics**:
- Disabled by default
- Enable only for specific tasks
- High token cost or specialized use
- Consider isolated invocation pattern

**Isolated Invocation Pattern**:
```bash
# Spawn separate Claude process with only Playwright
claude \
  --mcp-config ~/.claude/mcp-profiles/playwright.json \
  -p "Navigate to example.com and screenshot" \
  --output-format text
```

---

## Token Budget Management

### Maximum Practical Limit

**Discovery #7**: ~45K tokens is the practical limit for tool definitions.

| Configuration | Tokens | Tools Available |
|---------------|--------|-----------------|
| Tier 1 only | ~8K | All tools load |
| Tier 1 + 6 Tier 2 | ~25K | All tools load |
| Tier 1 + all Tier 2 | ~42K | All tools load |
| All 17 MCPs | ~50K | Some tools won't load |

### Recommended Configurations

**Lean Session** (10 MCPs, ~20K):
```
Tier 1: memory, filesystem, fetch, git
Tier 2: github, context7, datetime, desktop-commander, brave-search, perplexity
```

**Research Session** (12 MCPs, ~30K):
```
Tier 1: memory, filesystem, fetch, git
Tier 2: brave-search, arxiv, perplexity, gptresearcher, wikipedia, chroma, datetime, desktop-commander
```

**Development Session** (10 MCPs, ~22K):
```
Tier 1: memory, filesystem, fetch, git
Tier 2: github, context7, sequential-thinking, datetime, desktop-commander, chroma
```

---

## MCP Enable/Disable Commands

### Enable MCP
```bash
# Add MCP to configuration
claude mcp add <name>

# Then run /clear to reload
```

### Disable MCP
```bash
# Using helper script (adds to disabledMcpServers)
.claude/scripts/disable-mcps.sh <name> [name...]

# Or remove entirely
claude mcp remove <name>
```

### List Status
```bash
# Show all MCPs
claude mcp list

# Show with helper script
.claude/scripts/list-mcp-status.sh
```

---

## MCP Initialization Protocol (PR-8.5)

Full lifecycle for MCP management across sessions:

### Protocol Flow

```
┌────────────────────────────────────────────────────────────────────┐
│                    MCP INITIALIZATION PROTOCOL                       │
├────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  SESSION END                           SESSION START                 │
│  ───────────                           ─────────────                 │
│                                                                      │
│  ┌─────────────────────┐               ┌─────────────────────┐      │
│  │ 1. Update session-  │               │ 1. session-start.sh │      │
│  │    state.md with    │               │    hook fires        │      │
│  │    "Next Step"      │               │                      │      │
│  └─────────┬───────────┘               └─────────┬───────────┘      │
│            │                                     │                   │
│            ▼                                     ▼                   │
│  ┌─────────────────────┐               ┌─────────────────────┐      │
│  │ 2. Run suggest-     │               │ 2. suggest-mcps.sh  │      │
│  │    mcps.sh          │               │    analyzes "Next   │      │
│  │    --capture        │               │    Step" keywords   │      │
│  └─────────┬───────────┘               └─────────┬───────────┘      │
│            │                                     │                   │
│            ▼                                     ▼                   │
│  ┌─────────────────────┐               ┌─────────────────────┐      │
│  │ 3. Update MCP State │               │ 3. Outputs MCP      │      │
│  │    section with     │               │    suggestions in   │      │
│  │    prediction       │               │    systemMessage    │      │
│  └─────────┬───────────┘               └─────────┬───────────┘      │
│            │                                     │                   │
│            ▼                                     ▼                   │
│  ┌─────────────────────┐               ┌─────────────────────┐      │
│  │ 4. Disable Tier 2/3 │               │ 4. User enables     │      │
│  │    MCPs not needed  │               │    suggested MCPs   │      │
│  │    for next step    │               │    + runs /clear    │      │
│  └─────────────────────┘               └─────────────────────┘      │
│                                                                      │
└────────────────────────────────────────────────────────────────────┘
```

### Keyword-to-MCP Mapping

The `suggest-mcps.sh` script maps keywords in "Next Step" to MCPs:

| Keyword | MCPs Suggested |
|---------|----------------|
| PR, pull request, issue, github | github |
| documentation, library, docs | context7, wikipedia |
| research, search | brave-search, perplexity, gptresearcher |
| paper, academic, arxiv | arxiv |
| architecture, design, complex | sequential-thinking |
| browser, test, QA, automation | playwright |
| vector, semantic, embedding | chroma |
| time, timezone, schedule | datetime |
| file, process, system | desktop-commander |
| deep research, comprehensive | gptresearcher |

### Scripts

| Script | Purpose |
|--------|---------|
| `.claude/scripts/suggest-mcps.sh` | Analyze "Next Step" and suggest MCPs |
| `.claude/scripts/suggest-mcps.sh --capture` | Capture currently enabled MCPs |
| `.claude/scripts/suggest-mcps.sh --json` | JSON output for hooks |
| `.claude/scripts/enable-mcps.sh` | Enable MCPs by name |
| `.claude/scripts/disable-mcps.sh` | Disable MCPs by name |
| `.claude/scripts/list-mcp-status.sh` | Show current MCP state |

### Session State Template

```markdown
### MCP State (PR-8.5 Protocol)

**Current Session**:
- **Tier 1 (Always-On)**: memory, filesystem, fetch, git
- **Tier 2 (Enabled)**: github, context7
- **Tier 3 (On-Demand)**: (none)

**Next Session Prediction**:
- Keywords detected: PR, documentation
- Suggested MCPs: github, context7

**MCP Action on Exit**:
- Disable: (none needed)
- Keep enabled: github, context7
```

---

## Session-Start Hook Details

The session-start hook (`.claude/hooks/session-start.sh`) automatically:

1. **On startup/resume**: Calls `suggest-mcps.sh --json`
2. **Parses results**: Gets `to_enable`, `to_disable`, `tier3_warnings`
3. **Outputs suggestions**: Adds MCP recommendations to systemMessage

**Output Format**:
```
--- MCP SUGGESTIONS ---
Enable for this session: github, context7
  Run: .claude/scripts/enable-mcps.sh github context7 && /clear
Consider disabling (not needed): brave-search
  Run: .claude/scripts/disable-mcps.sh brave-search && /clear
Note: playwright are Tier 3 (high token cost) - consider isolated invocation
---
```

---

## Decision Matrix

| Criteria | Tier 1 | Tier 2 | Tier 3 |
|----------|--------|--------|--------|
| **Usage frequency** | 80%+ sessions | 20-80% sessions | <20% sessions |
| **Token cost** | <3K each | 3K-8K each | >5K or specialized |
| **Loading time** | Session start | Session start | On-demand |
| **Context isolation** | Not needed | Not needed | Beneficial |

---

## Enforcement Rules

### Hard Rules

1. **Restart Required**: MCP changes never take effect mid-session
2. **Token Limit**: Keep total MCPs <15 to ensure all tools load
3. **Document Token Cost**: All MCP additions must include token measurement

### Soft Rules

1. **Pattern Application**: Apply tier classification to new MCPs
2. **Documentation**: All MCPs documented in mcp-installation.md
3. **Review**: Promote/demote MCPs based on actual usage patterns

---

## Related Documentation

- @.claude/context/patterns/mcp-design-patterns.md - Per-MCP best practices
- @.claude/context/patterns/context-budget-management.md - Token budgets
- @.claude/context/patterns/mcp-validation-harness.md - Validation process
- @.claude/context/integrations/mcp-installation.md - Installation guide

---

## Changelog

- **2026-01-09**: MCP Initialization Protocol added
  - Added full MCP Initialization Protocol section
  - Documented keyword-to-MCP mapping
  - Integrated suggest-mcps.sh script
  - Added session state template
  - Added session-start hook details

- **2026-01-09**: Major revision for PR-8.5
  - Updated to 3-tier system (Always-On, Task-Scoped, On-Demand)
  - Added all 17 validated MCPs with accurate token costs
  - Added Discovery #7 token limit findings
  - Added recommended configurations by work type
  - Removed obsolete AIProjects references

- **2026-01-02**: Initial pattern documentation

---

*MCP Loading Strategy Pattern v2.1 — PR-8.5 MCP Init Protocol (2026-01-09)*
