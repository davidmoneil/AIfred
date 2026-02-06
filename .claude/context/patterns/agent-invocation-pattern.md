# Agent Invocation Pattern

**Status**: Active
**Created**: 2026-01-21
**Purpose**: Standardize how agents are defined, invoked, and managed

---

## Overview

Agents are autonomous workers that operate with their own context window. They're invoked for tasks requiring judgment, exploration, or extended independent work.

**Core Principle**: Agents work autonomously and return summarized results. They're appropriate when tasks require AI reasoning throughout execution.

---

## Agent Types

### Type 1: Custom Agents (Project-Specific)

Defined in `.claude/agents/*.md`. Invoked via `/agent <name>`.

| Agent | Purpose | Invocation |
|-------|---------|------------|
| `deep-research` | Web research with validation | `/agent deep-research "topic"` |
| `service-troubleshooter` | Systematic diagnosis | `/agent service-troubleshooter "issue"` |
| `docker-deployer` | Guided deployment | `/agent docker-deployer "service"` |
| `memory-bank-synchronizer` | Doc sync | `/agent memory-bank-synchronizer` |
| `ollama-manager` | Ollama operations | `/ollama status` |
| `plex-troubleshoot` | Plex diagnosis | `/plex-troubleshoot` |
| `creative-projects` | Creative work | `/creative workspace "task"` |
| `code-analyzer` | Code analysis | `/code analyze project` |
| `code-implementer` | Implementation | `/code implement project "task"` |
| `code-tester` | Testing | `/code test project` |
| `parallel-dev-*` | Parallel dev stages | `/parallel-dev:*` |

### Type 2: Built-in Subagents (Claude Code)

Automatically available. Invoked via Task tool with `subagent_type`.

| Subagent | Purpose | When to Use |
|----------|---------|-------------|
| `Explore` | Fast codebase exploration | Finding files, understanding architecture |
| `Plan` | Architecture design | Planning implementation strategies |
| `general-purpose` | Flexible worker | Custom agents, complex tasks |
| `claude-code-guide` | Documentation lookup | Claude Code/SDK questions |

### Type 3: Plugin Agents

Provided by installed plugins.

| Agent | Plugin | Purpose |
|-------|--------|---------|
| `feature-dev:code-architect` | feature-dev | Design architectures |
| `feature-dev:code-explorer` | feature-dev | Analyze existing code |
| `feature-dev:code-reviewer` | feature-dev | Review code |
| `hookify:conversation-analyzer` | hookify | Analyze for hooks |
| `agent-sdk-dev:*` | agent-sdk-dev | SDK verification |
| `project-plan-validator` | built-in | Plan validation |

---

## Invocation Methods

### Method 1: Via /agent Command

The standard way to invoke custom agents.

```bash
/agent <agent-name> [arguments]
```

**How it works**:
1. `/agent` command reads `.claude/agents/<agent-name>.md`
2. Builds agent context with session info
3. Uses Task tool with `subagent_type: "general-purpose"`
4. Agent works autonomously
5. Returns summary with links to results

**Example**:
```bash
/agent deep-research "Docker networking best practices"
```

### Method 2: Via Shortcut Command

Some agents have dedicated commands that wrap `/agent`.

```bash
/plex-troubleshoot "won't start"
# Equivalent to:
/agent plex-troubleshoot "won't start"
```

**Pattern for shortcut commands**:
```markdown
---
description: Shortcut for agent
allowed-tools:
  - Task
---

# /command-name

Launch the [agent-name] agent.

## Execution

Invoke via: `/agent agent-name $ARGUMENTS`
```

### Method 3: Via Task Tool Directly

For built-in subagents or when more control is needed.

```typescript
Task({
  subagent_type: "Explore",
  prompt: "Find all files related to authentication",
  description: "Find auth files"
})
```

**Available subagent_types**:
- `Explore` - Fast exploration
- `Plan` - Architecture planning
- `general-purpose` - Flexible (for custom agents)
- `claude-code-guide` - Documentation
- Plugin agents: `feature-dev:code-architect`, etc.

### Method 4: Via Skill Commands

Some skills invoke agents for specific operations.

```bash
/code analyze my-project
# Internally invokes code-analyzer agent

/parallel-dev:validate
# Internally invokes parallel-dev-validator agent
```

---

## Agent Definition Structure

### Required Structure

```
.claude/agents/<agent-name>.md
```

### Template

```markdown
# [Agent Name]

**Purpose**: One-line description
**Type**: Research | Troubleshooting | Implementation | Orchestration
**Memory**: Yes/No (whether to persist learnings)

---

## Capabilities

- Capability 1
- Capability 2
- Capability 3

## Workflow

### Phase 1: [Name]
[Steps]

### Phase 2: [Name]
[Steps]

### Phase N: Completion
[Summary and output]

---

## Inputs

| Input | Required | Description |
|-------|----------|-------------|
| task | Yes | What to accomplish |
| context | No | Additional context |

## Outputs

| Output | Location | Description |
|--------|----------|-------------|
| Results | `.claude/agents/results/<agent>/` | Main output |
| Session | `.claude/agents/sessions/` | Session log |
| Memory | `.claude/agents/memory/<agent>/` | Learnings |

---

## Memory Integration

[If memory enabled, describe what gets stored and how]

---

## Examples

\`\`\`bash
/agent [name] "example task 1"
/agent [name] "example task 2"
\`\`\`

---

## Related

- Commands: /command-that-uses-this
- Skills: skill-name
- Docs: @relevant/doc.md
```

---

## When to Use Agents vs Other Options

```
Is task deterministic?
├─ YES → Use CLI script, not agent
│
└─ NO → Does task require extended autonomous work?
        ├─ YES → Use Agent ✅
        │        - Will work independently
        │        - Returns summary when done
        │        - Appropriate for research, troubleshooting, implementation
        │
        └─ NO → Does task require specific expertise?
                ├─ YES → Use appropriate subagent
                │        - Explore for codebase navigation
                │        - Plan for architecture
                │        - Plugin agents for specialized work
                │
                └─ NO → Direct execution may be appropriate
                         - Simple AI tasks
                         - Interactive guidance
```

---

## Agent Memory System

### Structure

```
.claude/agents/
├── memory/
│   └── <agent-name>/
│       └── learnings.json
├── results/
│   └── <agent-name>/
│       └── YYYY-MM-DD_description.md
└── sessions/
    └── YYYY-MM-DD_<agent>_<timestamp>.md
```

### learnings.json Format

```json
{
  "last_updated": "2026-01-21T10:30:00Z",
  "runs_completed": 15,
  "learnings": [
    {
      "date": "2026-01-20",
      "context": "Troubleshooting Plex",
      "learning": "Database corruption often from unclean shutdown",
      "confidence": "high"
    }
  ],
  "patterns": [
    {
      "pattern": "Service restart loop",
      "cause": "Permission issues on data directory",
      "solution": "Check ownership: chown -R plex:plex /data"
    }
  ]
}
```

### Memory Loading

When agent starts, `/agent` command:
1. Reads `learnings.json` if exists
2. Includes in agent context: "Memory from Previous Runs: [contents]"
3. Agent can reference past learnings

### Memory Updating

Agents should update memory when:
- Discovering new patterns
- Learning from errors
- Finding solutions to recurring issues

---

## Agent Session Flow

```
┌─────────────────────────────────────────────────────────────────┐
│  1. INVOCATION                                                   │
│     /agent deep-research "topic"                                │
├─────────────────────────────────────────────────────────────────┤
│  2. CONTEXT BUILDING                                            │
│     - Load agent definition from .claude/agents/                │
│     - Generate session ID: YYYY-MM-DD_agent_timestamp           │
│     - Load memory from learnings.json                           │
│     - Build full prompt with task + context + memory            │
├─────────────────────────────────────────────────────────────────┤
│  3. TASK LAUNCH                                                 │
│     Task(subagent_type: "general-purpose", prompt: context)     │
├─────────────────────────────────────────────────────────────────┤
│  4. AUTONOMOUS WORK                                             │
│     Agent works independently:                                  │
│     - Creates session log                                       │
│     - Documents process                                         │
│     - Creates results file                                      │
│     - Updates memory with learnings                             │
├─────────────────────────────────────────────────────────────────┤
│  5. COMPLETION                                                  │
│     Returns summary (2-3 sentences) with links to:              │
│     - Session log                                               │
│     - Results file                                              │
│     - Memory file (if updated)                                  │
└─────────────────────────────────────────────────────────────────┘
```

---

## Model Selection

| Task Type | Model | Reasoning |
|-----------|-------|-----------|
| Complex research | `opus` | Needs deep reasoning |
| Implementation | `sonnet` | Good balance |
| Simple diagnostics | `sonnet` | Standard tasks |
| Quick checks | `haiku` | Fast, cheap |

Specify in Task tool:
```typescript
Task({
  subagent_type: "general-purpose",
  model: "sonnet",  // or "opus", "haiku"
  prompt: "..."
})
```

---

## Anti-Patterns

### Anti-Pattern 1: Agent for Simple Tasks

```markdown
# BAD - Agent overkill
/agent file-checker "does config.json exist?"
```

**Fix**: Just use `ls` or Read tool directly.

### Anti-Pattern 2: Agent Without Memory

```markdown
# BAD - Repeats same mistakes
Agent troubleshoots the same issue repeatedly without learning
```

**Fix**: Enable memory, update learnings.json.

### Anti-Pattern 3: Overly Specific Agent

```markdown
# BAD - Too narrow
/agent check-nginx-port-80-on-myserver
```

**Fix**: Generalize to `/agent service-troubleshooter "nginx on aiserver"`.

### Anti-Pattern 4: Agent Re-implements CLI

```markdown
# BAD - Agent runs deterministic steps
Agent workflow:
1. Run docker ps
2. Parse output
3. Check health endpoints
```

**Fix**: Create CLI script, agent calls script or is replaced by CLI command.

---

## Creating New Agents

### When to Create

Create an agent when:
- Task requires autonomous judgment
- Task benefits from accumulated learnings
- Task is invoked repeatedly with variations
- Task involves exploration + decision-making

### Steps

1. **Define purpose** - What does this agent do?
2. **Create definition** - `.claude/agents/<name>.md`
3. **Set up memory** - Create memory directory if needed
4. **Test invocation** - `/agent <name> "test task"`
5. **Iterate on workflow** - Refine based on results
6. **Create shortcut** (optional) - Dedicated command if frequently used

### Checklist

- [ ] Clear purpose statement
- [ ] Defined workflow phases
- [ ] Documented inputs/outputs
- [ ] Memory strategy (if applicable)
- [ ] Examples provided
- [ ] Tested end-to-end

---

## Related Patterns

- @.claude/context/patterns/command-invocation-pattern.md - When to use agents vs CLI
- @.claude/context/patterns/agent-selection-pattern.md - Choosing between agent types
- @.claude/context/patterns/capability-layering-pattern.md - Where agents fit in layers
- @.claude/agents/ - Agent definitions directory
- @.claude/context/systems/agent-system.md - Agent system overview

---

## Versioning

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-21 | Initial pattern definition |
