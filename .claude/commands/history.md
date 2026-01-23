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
1. [learning] Memory MCP entities need bi-temporal timestamps (2026-01-23)
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
1. [session] M3 JICM Complement Commands (2026-01-23)
2. [learning] Hooks must return JSON objects (2026-01-23)
3. [decision] Wiggum Loop for all tasks (2026-01-22)
4. [session] Archon Architecture Implementation (2026-01-22)
5. [learning] Context compaction essentials (2026-01-22)
```

### /history stats

Show history statistics.

**Example**:
```
/history stats

# History Statistics:
Sessions:  15 entries (last: 2026-01-23)
Learnings: 42 entries
  - bugs:         8
  - patterns:     12
  - tools:        15
  - workflows:    4
  - archon:       2
  - orchestration: 1
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
/history show learnings/tools/2026-01-23-memory-mcp-bitemporal.md

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
#archon (3 entries)
#wiggum (4 entries)

/history tags mcp

# Entries tagged #mcp:
1. [learning] Memory MCP bi-temporal timestamps (2026-01-23)
2. [decision] MCP Gateway selection (2026-01-15)
...
```

### /history category <category>

Browse by category.

**Example**:
```
/history category learnings/archon

# Learnings > Archon:
1. Archon three-layer architecture (2026-01-22)
2. Nous layer contains all knowledge (2026-01-22)
...
```

### /history related <entry>

Find entries related to a specific entry.

**Example**:
```
/history related learnings/tools/2026-01-23-memory-mcp-bitemporal.md

# Related entries:
1. [decision] Memory MCP configuration (references same topic)
2. [learning] Cross-session knowledge persistence (similar category)
3. [session] M2 Analytics Hooks (same date)
```

### /history promote <entry>

Promote a history entry to Memory MCP for cross-session retrieval.

**Process**:
1. Read the history entry
2. Create Memory MCP entity with entry content
3. Add observation linking to file path
4. Report entity ID for future reference

**Example**:
```
/history promote learnings/archon/2026-01-22-three-layer-architecture.md

# Promoted to Memory MCP:
Entity: Jarvis_Learning_ThreeLayerArchitecture
Observations: 3
Cross-session retrieval enabled.
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
/history search "#archon #wiggum"  # Both tags
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
   Date: 2026-01-23
   Category: learnings/archon
   Tags: #archon #architecture

   Context: While implementing the Archon architecture...
   Insight: The three layers (Nous, Pneuma, Soma) provide...
```

### Paths Only (--paths)
```
.claude/history/learnings/archon/2026-01-22-three-layer-architecture.md
.claude/history/decisions/architecture/2026-01-22-archon-naming.md
```

## Integration

### With Memory MCP
```
# Promote important entries to Memory MCP for cross-session retrieval
/history promote L-042
```

### With Self-Reflection (AC-05)
```
# /reflect can query history for patterns
# Frequently accessed entries suggest importance
```

## Examples

### Find all Archon-related learnings
```
/history search "archon" --type learning
```

### Browse recent architecture decisions
```
/history category decisions/architecture
/history recent 5 --type decision
```

### Find what was learned in a specific session
```
/history show sessions/2026-01-23-jicm-complement-commands.md
```

## Related

- `/capture` - Add new entries
- `.claude/history/index.md` - Browse index
- Memory MCP - Cross-session knowledge

---

## Instructions for Claude

When user runs `/history <subcommand>`:

### For /history search "[query]"
1. Read files in `.claude/history/` recursively
2. Match query against file names and content
3. Rank by relevance (title match > content match > tag match)
4. Display top 10 results with excerpts

### For /history recent [count]
1. List files in `.claude/history/` sorted by date (from filename)
2. Return most recent `count` entries (default 10)
3. Display type, title, date

### For /history stats
1. Count files by type (sessions, learnings, decisions, research)
2. Count by category within each type
3. Calculate recent activity (this week, this month)
4. Display formatted statistics

### For /history show <path>
1. Read the specified file
2. Display full content with metadata
3. Show related entries if available

### For /history tags [tag]
1. If no tag: scan all files for #tags, count occurrences
2. If tag given: find all files containing that tag
3. Display sorted list

### For /history category <category>
1. List files in `.claude/history/<category>/`
2. Sort by date
3. Display with titles and excerpts

### For /history related <entry>
1. Read the entry file
2. Find entries with matching tags, category, or date
3. Score by relevance
4. Display top 5 related entries

### For /history promote <entry>
1. Read the entry file
2. Create Memory MCP entity:
   - Name: `Jarvis_<Type>_<TitleSlug>`
   - Entity type: `Knowledge_<Type>`
3. Add observations from entry content
4. Report success with entity ID
