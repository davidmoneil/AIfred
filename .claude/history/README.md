# History System

Structured knowledge capture for learnings, decisions, sessions, and research.

## Structure

```
history/
├── index.md           # Searchable master index
├── templates/         # Entry templates
├── learnings/         # Insights and lessons learned
├── decisions/         # Architectural and technical decisions
├── sessions/          # Session summaries
└── research/          # Research documents
```

## Commands

- `/capture <type> "<title>"` - Add new entry
- `/history search "<query>"` - Search entries
- `/history recent [count]` - Show recent entries
- `/history stats` - Show statistics
- `/history promote <entry>` - Promote to Memory MCP

## Categories

### Learnings
bugs, patterns, tools, workflows, archon, orchestration

### Decisions
architecture, tools, approaches, security, integration

### Research
technologies, approaches, references, aifred-porting

## Integration

- **Memory MCP**: Use `/history promote` for cross-session retrieval
- **Self-Reflection (AC-05)**: Queries history for patterns
- **Session End (AC-09)**: Prompts for `/capture session`

---

*Part of Jarvis Nous (Knowledge) Layer*
