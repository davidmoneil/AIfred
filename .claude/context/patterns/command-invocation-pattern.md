# Command Invocation Pattern

**Status**: Active
**Created**: 2026-01-21
**Purpose**: Standardize how slash commands delegate work to ensure repeatability and efficiency

---

## Overview

This pattern defines how slash commands should invoke their underlying logic. The goal is to minimize prompt-heavy commands that re-implement logic on every execution, instead delegating to reusable CLI scripts, agents, or skills.

**Core Principle**: Commands are thin wrappers that route to the appropriate execution layer.

---

## Invocation Types

### Type 1: CLI-Backed (Preferred for Deterministic Tasks)

Commands that delegate to shell scripts. **This is the ideal pattern** for tasks that don't require AI judgment.

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  /command arg   │ ──▶ │  ~/Scripts/     │ ──▶ │    Output       │
│                 │     │  command.sh arg │     │                 │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

**Command Structure**:
```markdown
---
description: Brief description
argument-hint: <required> [optional]
allowed-tools:
  - Bash(~/Scripts/command-name.sh:*)
---

# /command-name

Brief description of what this does.

## Execution

Run the CLI script:

\`\`\`bash
~/Scripts/command-name.sh $ARGUMENTS
\`\`\`

Report the results to the user.

## Options

[Document script flags if any]

## Related

- Script: @Scripts/command-name.sh
```

**When to Use**:
- Task is deterministic (same input → same output)
- Task can be automated (no judgment needed)
- Task might need scheduling (cron, systemd)
- Logic should be reusable outside Claude

**Examples**: `/sync-git`, `/check-health`, `/backup-status`, `/checkpoint`

---

### Type 2: Agent-Backed (For Tasks Requiring Judgment)

Commands that launch agents via the Task tool or `/agent` command.

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  /command arg   │ ──▶ │  Task tool or   │ ──▶ │  Agent works    │
│                 │     │  /agent invoke  │     │  autonomously   │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

**Command Structure**:
```markdown
---
description: Brief description
argument-hint: <task>
allowed-tools:
  - Task
  - Read
---

# /command-name

Brief description.

## Execution

Launch the agent via Task tool:
- subagent_type: "general-purpose"
- Load agent definition from `.claude/agents/agent-name.md`
- Pass $ARGUMENTS as task context

## Agent

Uses: `agent-name` agent
Definition: @.claude/agents/agent-name.md
```

**When to Use**:
- Task requires pattern recognition
- Task requires judgment during execution
- Task has branching decisions based on context
- Task benefits from autonomous exploration

**Examples**: `/plex-troubleshoot`, `/ollama`, `/creative`

---

### Type 3: Skill-Backed (For Multi-Step Workflows)

Commands that are part of a skill's command set.

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  /skill:cmd     │ ──▶ │  Skill workflow │ ──▶ │  tools/ CLI +   │
│                 │     │  from SKILL.md  │     │  AI guidance    │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

**Command Structure**:
```markdown
---
description: Brief description
skill: skill-name
---

# /skill:command

Part of the [skill-name](@.claude/skills/skill-name/SKILL.md) skill.

## Execution

Follow the workflow defined in the skill's SKILL.md.
Use tools from `tools/` directory for deterministic operations.
```

**When to Use**:
- Command is part of a larger workflow
- Multiple related commands share context
- Skill has `tools/` directory for CLI operations
- Workflow combines deterministic + AI steps

**Examples**: `/parallel-dev:plan`, `/upgrade discover`, `/plan:new`

---

### Type 4: Isolated Session (For Heavy MCPs)

Commands that spawn separate Claude sessions with specific MCP configs.

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  /command task  │ ──▶ │  claude --mcp   │ ──▶ │  Isolated       │
│                 │     │  spawn new CLI  │     │  session works  │
└─────────────────┘     └─────────────────┘     └─────────────────┘
```

**Command Structure**:
```markdown
---
description: Run X in isolated session (saves ~Nk tokens)
argument-hint: <task>
---

# /command-name

## Execution

Spawn isolated Claude session:

\`\`\`bash
claude \\
  --mcp-config ~/.claude/mcp-profiles/profile.json \\
  --settings ~/.claude/mcp-profiles/settings.json \\
  -p "Task prompt with $ARGUMENTS" \\
  --output-format text
\`\`\`
```

**When to Use**:
- MCP tools consume >10k tokens
- Task is self-contained
- Results can be summarized as text
- Main session should stay lightweight

**Examples**: `/browser`, `/n8n`

---

### Type 5: Direct Execution (Use Sparingly)

Commands where the prompt IS the implementation. **Avoid when possible**.

```
┌─────────────────┐     ┌─────────────────┐
│  /command arg   │ ──▶ │  Claude follows │
│                 │     │  prompt steps   │
└─────────────────┘     └─────────────────┘
```

**When Acceptable**:
- Task inherently requires AI reasoning throughout
- Task cannot be decomposed into deterministic parts
- Task is simple enough that CLI overhead isn't justified
- Task is exploratory/one-off

**Examples**: `/design-review`, `/memory-review`

**Warning Signs** (consider CLI extraction):
- Command is >100 lines
- Command has numbered step-by-step instructions
- Command uses bash commands that could be scripted
- Command is used frequently

---

## Decision Tree

```
Is this task deterministic?
├─ YES → Can it be scripted?
│        ├─ YES → Type 1: CLI-Backed ✅
│        └─ NO  → Why not? (usually can be)
│
└─ NO → Does it require judgment THROUGHOUT?
        ├─ YES → Is it autonomous work?
        │        ├─ YES → Type 2: Agent-Backed
        │        └─ NO  → Type 5: Direct (if simple)
        │
        └─ NO → Can you separate deterministic parts?
                 ├─ YES → Type 3: Skill-Backed (hybrid)
                 └─ NO  → Type 5: Direct (last resort)

Special case: Heavy MCP needed?
└─ YES → Type 4: Isolated Session
```

---

## Command Template

### For New CLI-Backed Commands

```markdown
---
description: [One line description]
argument-hint: [<required>] [optional]
allowed-tools:
  - Bash(~/Scripts/[name].sh:*)
---

# /[name]

[Brief description]

## Usage

\`\`\`
/[name] [arguments]
\`\`\`

## Execution

Run the CLI script:

\`\`\`bash
~/Scripts/[name].sh $ARGUMENTS
\`\`\`

Report the results to the user.

## Options

| Flag | Description |
|------|-------------|
| `-h, --help` | Show help |
| [other flags] | [descriptions] |

## Examples

\`\`\`bash
/[name] example1
/[name] example2 --flag
\`\`\`

## Script Location

\`~/Scripts/[name].sh\`

## Related

- Script: @Scripts/[name].sh
- Pattern: @.claude/context/patterns/capability-layering-pattern.md
```

---

## Migration Guide

### Converting Prompt-Heavy to CLI-Backed

1. **Identify deterministic steps** in the current command
2. **Extract to script**:
   ```bash
   # Create script
   touch ~/Scripts/command-name.sh
   chmod +x ~/Scripts/command-name.sh
   ```
3. **Implement logic** in bash (or call Python/TypeScript)
4. **Update command** to call script
5. **Test** both script standalone and via command
6. **Document** script flags and usage

### Common Extraction Patterns

| In Command | In Script |
|------------|-----------|
| `docker ps` | `docker ps --format json` |
| `git status` | `git status --porcelain` |
| Read file + parse | Script does parsing, returns structured output |
| Multi-step workflow | Script with functions for each step |
| Conditional logic | Case statements or if/else in bash |

---

## Anti-Patterns

### Anti-Pattern 1: Prompt Re-implements CLI Logic

```markdown
# BAD - command has 50 lines of bash commands inline
## Execution
1. Run `docker ps`
2. Parse output for container X
3. Run `docker inspect`
4. Extract ports...
```

**Fix**: Move to script, command just calls script.

### Anti-Pattern 2: Agent for Deterministic Task

```markdown
# BAD - agent launched for simple check
Launch agent to check if file exists and report status.
```

**Fix**: Use CLI script, agent is overkill.

### Anti-Pattern 3: Direct Execution for Complex Workflow

```markdown
# BAD - 200 line command with 10 numbered steps
## Step 1: ...
## Step 2: ...
...
## Step 10: ...
```

**Fix**: Extract to script or skill with tools/.

---

## Compliance Checklist

For each command, verify:

- [ ] **Invocation type identified**: CLI / Agent / Skill / Isolated / Direct
- [ ] **Appropriate for task**: Deterministic tasks have CLI backing
- [ ] **Script exists** (if CLI-backed): `~/Scripts/[name].sh`
- [ ] **allowed-tools correct**: Matches actual tools used
- [ ] **Documentation complete**: Usage, options, examples, related

---

## Related Patterns

- @.claude/context/patterns/capability-layering-pattern.md - The layering philosophy
- @.claude/context/patterns/skill-architecture-pattern.md - Skill structure
- @.claude/context/patterns/agent-invocation-pattern.md - Agent launching

---

## Versioning

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-01-21 | Initial pattern definition |
