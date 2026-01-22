# /capture Command

Quickly capture learnings, decisions, sessions, and research to the structured history system.

## Usage

```
/capture <type> "<title>" [options]
```

## Types

### /capture learning "[insight]"

Record a learning or insight discovered during work.

**Process**:
1. Determine category (bugs, patterns, tools, workflows)
2. Create file in `.claude/history/learnings/<category>/`
3. Fill template with context
4. Update index.md

**Example**:
```
/capture learning "MCP servers need restart after config changes"

# Creates: .claude/history/learnings/tools/2026-01-21-mcp-restart-config.md
```

**Categories**:
- `bugs` - Bug patterns and fixes
- `patterns` - Implementation patterns
- `tools` - Tool usage insights
- `workflows` - Workflow improvements

### /capture decision "[decision]"

Record an architectural or technical decision.

**Process**:
1. Determine category (architecture, tools, approaches)
2. Capture options considered and rationale
3. Create file in `.claude/history/decisions/<category>/`
4. Update index.md

**Example**:
```
/capture decision "Use YAML for config, JSON for data files"

# Creates: .claude/history/decisions/tools/2026-01-21-yaml-config-json-data.md
```

**Categories**:
- `architecture` - System architecture decisions
- `tools` - Tool selection decisions
- `approaches` - Implementation approach decisions

### /capture session "[summary]"

Save a session summary at the end of work.

**Process**:
1. Gather accomplishments, decisions, learnings
2. List files modified and commits made
3. Create file in `.claude/history/sessions/`
4. Update index.md

**Example**:
```
/capture session "Implemented Upgrade Skill and Structured History System"

# Creates: .claude/history/sessions/2026-01-21-upgrade-skill-history-system.md
```

### /capture research "[topic]"

Start or update a research document.

**Process**:
1. Determine category (technologies, approaches, references)
2. Create or update file in `.claude/history/research/<category>/`
3. Add findings, sources, conclusions
4. Update index.md

**Example**:
```
/capture research "MCP server authentication patterns"

# Creates: .claude/history/research/technologies/2026-01-21-mcp-auth-patterns.md
```

**Categories**:
- `technologies` - Technology research
- `approaches` - Approach comparisons
- `references` - External references

## Options

| Option | Description | Example |
|--------|-------------|---------|
| `--category <cat>` | Override auto-detected category | `--category patterns` |
| `--confidence <level>` | Set confidence level | `--confidence high` |
| `--tags <tags>` | Add additional tags | `--tags "mcp,hooks"` |
| `--related <items>` | Link to related entries | `--related "learning-001"` |

## Quick Capture Workflow

For rapid capture during work:

```bash
# Quick learning (minimal context)
/capture learning "Hook handlers must return objects, not strings"

# Quick decision
/capture decision "Use TypeScript for all new skill tools"

# End of session
/capture session "Implemented structured history system"
```

## Full Capture Workflow

For comprehensive documentation:

```bash
# Start capture with guidance
/capture learning "Pattern for handling MCP rate limits"

# Claude will prompt for:
# - Category selection
# - Context (what led to this)
# - Insight (what was learned)
# - Application (how to apply)
# - Related items
# - Tags
```

## Index Updates

Each capture automatically updates `.claude/history/index.md`:
- Adds entry to Recent Entries
- Updates category counts
- Adds to Tags Index
- Links to related entries

## Templates

Templates are in `.claude/history/templates/`:
- `session.md` - Session summary template
- `learning.md` - Learning template
- `decision.md` - Decision template
- `research.md` - Research template

## Examples

### Capture a Bug Pattern

```
/capture learning "Memory leak in session-start hook when reading large files"
```

Output file: `.claude/history/learnings/bugs/2026-01-21-memory-leak-session-start.md`

### Capture an Architecture Decision

```
/capture decision "Adopted Code Before Prompts pattern for skills with TypeScript tools"
```

Output file: `.claude/history/decisions/architecture/2026-01-21-code-before-prompts.md`

### Capture a Session Summary

```
/capture session "TELOS implementation and Upgrade Skill development"
```

Output file: `.claude/history/sessions/2026-01-21-telos-upgrade-skill.md`

## Related

- [History Command](@.claude/commands/history.md) - Search and browse history
- [History Index](@.claude/history/index.md) - Searchable index
- [TELOS](@.claude/context/telos/TELOS.md) - Link learnings to goals
