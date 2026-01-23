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
1. Determine category (bugs, patterns, tools, workflows, archon, orchestration)
2. Create file in `.claude/history/learnings/<category>/`
3. Fill template with context
4. Update index.md

**Example**:
```
/capture learning "Memory MCP entities need bi-temporal timestamps"

# Creates: .claude/history/learnings/tools/2026-01-23-memory-mcp-bitemporal.md
```

**Categories**:
- `bugs` - Bug patterns and fixes
- `patterns` - Implementation patterns
- `tools` - Tool usage insights
- `workflows` - Workflow improvements
- `archon` - Archon architecture insights
- `orchestration` - Task orchestration learnings

### /capture decision "[decision]"

Record an architectural or technical decision.

**Process**:
1. Determine category (architecture, tools, approaches, security, integration)
2. Capture options considered and rationale
3. Create file in `.claude/history/decisions/<category>/`
4. Update index.md

**Example**:
```
/capture decision "Use JSONL for event logs, YAML for configuration"

# Creates: .claude/history/decisions/tools/2026-01-23-jsonl-logs-yaml-config.md
```

**Categories**:
- `architecture` - System architecture decisions
- `tools` - Tool selection decisions
- `approaches` - Implementation approach decisions
- `security` - Security-related decisions
- `integration` - Integration decisions (AIfred porting, etc.)

### /capture session "[summary]"

Save a session summary at the end of work.

**Process**:
1. Gather accomplishments, decisions, learnings
2. List files modified and commits made
3. Create file in `.claude/history/sessions/`
4. Update index.md

**Example**:
```
/capture session "Implemented JICM complement commands (M3)"

# Creates: .claude/history/sessions/2026-01-23-jicm-complement-commands.md
```

### /capture research "[topic]"

Start or update a research document.

**Process**:
1. Determine category (technologies, approaches, references, aifred-porting)
2. Create or update file in `.claude/history/research/<category>/`
3. Add findings, sources, conclusions
4. Update index.md

**Example**:
```
/capture research "Parallel-dev workflow patterns from AIfred"

# Creates: .claude/history/research/aifred-porting/2026-01-23-parallel-dev-patterns.md
```

**Categories**:
- `technologies` - Technology research
- `approaches` - Approach comparisons
- `references` - External references
- `aifred-porting` - AIfred integration research

## Options

| Option | Description | Example |
|--------|-------------|---------|
| `--category <cat>` | Override auto-detected category | `--category patterns` |
| `--confidence <level>` | Set confidence level | `--confidence high` |
| `--tags <tags>` | Add additional tags | `--tags "mcp,hooks"` |
| `--related <items>` | Link to related entries | `--related "L-001"` |

## Quick Capture Workflow

For rapid capture during work:

```bash
# Quick learning (minimal context)
/capture learning "Hooks must return JSON objects via stdout"

# Quick decision
/capture decision "Use Wiggum Loop for all non-trivial tasks"

# End of session
/capture session "Completed M3 JICM complement commands"
```

## Full Capture Workflow

For comprehensive documentation:

```bash
# Start capture with guidance
/capture learning "Pattern for handling context exhaustion"

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

## Telemetry

Captures are logged via telemetry-emitter.js:
```javascript
telemetry.emit('AC-05', 'knowledge_captured', {
  type: 'learning|decision|session|research',
  category: '<category>',
  tags: ['tag1', 'tag2']
});
```

## Related

- `/history` - Search and browse history
- `.claude/history/index.md` - Searchable index
- Memory MCP - Cross-session knowledge (use `/history promote`)

---

## Instructions for Claude

When user runs `/capture <type> "<title>"`:

1. Determine the type (learning, decision, session, research)

2. Auto-detect category from title/context:
   - `archon` - Mentions Archon, Nous, Pneuma, Soma, layers
   - `orchestration` - Mentions AC components, tasks, Wiggum Loop
   - `bugs` - Mentions bug, fix, error, issue
   - `patterns` - Mentions pattern, convention, standard
   - `tools` - Mentions MCP, hooks, scripts, tools
   - `workflows` - Mentions workflow, process, procedure
   - `security` - Mentions security, credentials, protection
   - `integration` - Mentions AIfred, porting, migration

3. Generate slug from title (lowercase, hyphens, max 50 chars)

4. Create file at `.claude/history/<type>/<category>/YYYY-MM-DD-<slug>.md`

5. Fill the appropriate template:
   - For learning: context, insight, application
   - For decision: options, rationale, consequences
   - For session: accomplishments, files, commits, learnings
   - For research: question, findings, sources, conclusions

6. Update `.claude/history/index.md`:
   - Add to Recent Entries (top 10)
   - Update Stats section
   - Add new tags to Tags Index

7. Emit telemetry event

8. Report success with file path
