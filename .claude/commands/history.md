# /history Command

Search and browse the structured history system.

## Usage

```
/history <subcommand> [args]
```

## Subcommands

### /history search "[query]"

Search across all history entries.

**Process**:
1. Search file names and content in `.claude/history/`
2. Rank by relevance
3. Display matching entries with context

**Example**:
```
/history search "MCP"

# Results:
1. [learning] MCP servers need restart after config changes (2026-01-21)
2. [decision] Use MCP Gateway for browser automation (2026-01-15)
3. [research] MCP authentication patterns (2026-01-21)
```

**Search scope**:
- File names
- Content (title, context, insight, etc.)
- Tags

### /history recent [count]

Show most recent entries.

**Arguments**:
- `count` (optional): Number of entries (default: 10)

**Example**:
```
/history recent 5

# Recent Entries:
1. [session] Upgrade Skill Implementation (2026-01-21)
2. [learning] Hook handlers must return objects (2026-01-21)
3. [decision] Code Before Prompts pattern (2026-01-20)
4. [session] TELOS System Implementation (2026-01-20)
5. [learning] WebFetch follows redirects (2026-01-20)
```

### /history stats

Show history statistics.

**Example**:
```
/history stats

# History Statistics:
Sessions:  15 entries (last: 2026-01-21)
Learnings: 42 entries
  - bugs:      8
  - patterns:  12
  - tools:     15
  - workflows: 7
Decisions: 23 entries
Research:  11 entries

Most active categories:
1. learnings/tools (15)
2. decisions/architecture (10)
3. learnings/patterns (12)

Recent activity:
- This week: 8 entries
- This month: 35 entries
```

### /history show <path-or-id>

Display a specific entry.

**Example**:
```
/history show learnings/tools/2026-01-21-mcp-restart-config.md

# Or by ID:
/history show L-042
```

### /history tags [tag]

Browse by tag.

**Example**:
```
/history tags

# All tags:
#mcp (5 entries)
#hooks (8 entries)
#patterns (12 entries)
#architecture (6 entries)

/history tags mcp

# Entries tagged #mcp:
1. [learning] MCP servers need restart (2026-01-21)
2. [decision] MCP Gateway selection (2026-01-15)
...
```

### /history category <category>

Browse by category.

**Example**:
```
/history category learnings/patterns

# Learnings > Patterns:
1. Code Before Prompts pattern usage (2026-01-20)
2. Hook event handling patterns (2026-01-18)
3. Session state management pattern (2026-01-15)
...
```

### /history related <entry>

Find entries related to a specific entry.

**Example**:
```
/history related learnings/tools/2026-01-21-mcp-restart-config.md

# Related entries:
1. [decision] MCP Gateway configuration (references same topic)
2. [learning] Docker restart best practices (similar category)
3. [session] MCP troubleshooting session (same date)
```

## Search Syntax

### Basic Search
```
/history search "MCP"           # Contains "MCP"
/history search "hook error"    # Contains both words
```

### Filtered Search
```
/history search "MCP" --type learning    # Only learnings
/history search "pattern" --since 2026-01-01   # Since date
/history search "bug" --category bugs    # Specific category
```

### Tag Search
```
/history search "#mcp"          # Tagged with #mcp
/history search "#hooks #bugs"  # Both tags
```

## Output Formats

### Default (Summary)
```
1. [type] Title (date)
   Brief excerpt...
```

### Verbose (-v)
```
1. [type] Title
   Date: 2026-01-21
   Category: learnings/tools
   Tags: #mcp #config

   Context: When updating MCP server configuration...
   Insight: Servers require restart to pick up changes...
```

### Paths Only (--paths)
```
.claude/history/learnings/tools/2026-01-21-mcp-restart-config.md
.claude/history/decisions/tools/2026-01-15-mcp-gateway.md
```

## Integration

### With Memory MCP
```
# Store important learnings in Memory MCP for cross-session retrieval
/history promote L-042  # Promotes learning to Memory MCP
```

### With TELOS
```
# Link history entries to TELOS goals
/history link L-042 G-T1  # Links learning to goal
```

## Examples

### Find all hook-related learnings
```
/history search "hook" --type learning
```

### Browse recent architecture decisions
```
/history category decisions/architecture
/history recent 5 --type decision
```

### Find what was learned in a specific session
```
/history show sessions/2026-01-21-telos-implementation.md
```

## Related

- [Capture Command](@.claude/commands/capture.md) - Add new entries
- [History Index](@.claude/history/index.md) - Browse index
- [Memory MCP](@.claude/context/integrations/memory-mcp-usage.md) - Persistent memory
