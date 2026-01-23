# Capability Layering Pattern

**Status**: Active
**Created**: 2026-01-23 (ported from AIfred)
**Purpose**: Maximize repeatability and minimize AI dependency for automated tasks

## Overview

The Capability Layering pattern ensures that automated capabilities are built through deterministic layers, with AI used only for creation and routing—not repeated execution.

**Core Principle**: AI creates automation once, execution flows through deterministic CLI calls thereafter.

## The Layers

```
┌─────────────────────────────────────────────────────────────────┐
│  LAYER 5: USER REQUEST                                          │
│  Natural language or programmatic delegation                    │
│  "Check my infrastructure health"                               │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 4: PROMPT (Skill / Agent / Command)                      │
│  Routes request to correct CLI, handles edge cases              │
│  /check-health docker                                           │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 3: CLI (Command Line Interface)                          │
│  Bash-callable with arguments, scriptable, schedulable          │
│  ./scripts/weekly-health-check.sh --section docker              │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 2: CODE (Implementation)                                 │
│  Actual logic - script, function, API wrapper                   │
│  scripts/weekly-health-check.sh (450 lines of bash)             │
├─────────────────────────────────────────────────────────────────┤
│  LAYER 1: IDEA (Capability Goal)                                │
│  What we want to accomplish                                     │
│  "Validate infrastructure health automatically"                 │
└─────────────────────────────────────────────────────────────────┘
```

## Layer Definitions

### Layer 1: IDEA
- The capability goal or user need
- Example: "I want to manage context exhaustion automatically"
- This is the starting point for new capabilities

### Layer 2: CODE
- The actual implementation that does the work
- Can be: Bash script, Python script, TypeScript tool, hook
- Must be: Testable, version-controlled, documented
- Location: `scripts/`, `.claude/hooks/`, `.claude/skills/*/tools/`

### Layer 3: CLI
- Command-line interface that exposes the code
- Requirements:
  - Callable via `bash` or direct execution
  - Accepts arguments/flags for configuration
  - Returns meaningful exit codes (0 = success)
  - Outputs to stdout/stderr appropriately
- Benefits: Scriptable, schedulable (cron/systemd), composable

### Layer 4: PROMPT
- Slash command, skill, or agent that routes to CLI
- Responsibilities:
  - Parse natural language intent
  - Map to correct CLI command
  - Handle errors gracefully
  - Provide user-friendly output
- Should NOT: Re-implement logic that exists in CLI

**Prompt Layer Sub-Types**:

| Type | When to Use | Pattern |
|------|-------------|---------|
| **Command → CLI** | Deterministic tasks | command-invocation-pattern.md |
| **Command → Agent** | Tasks requiring judgment | agent-invocation-pattern.md |
| **Skill → tools/** | Multi-step workflows | Code Before Prompts |

### Layer 5: USER REQUEST
- Natural language from user
- Programmatic delegation (n8n workflow, another agent, API call)
- The prompt layer handles translation to CLI

## When Each Layer is Appropriate

### Full Stack (All Layers) - PREFERRED

Use when:
- Task is repeatable (will be done again)
- Task is deterministic (same input → same output)
- Task can be automated (no human judgment needed mid-execution)

Examples:
- Health checks
- Git operations
- Backups
- Context checkpoints
- File operations

### AI-Appropriate (Prompt Only)

Use when task inherently requires:
- Pattern recognition across contexts
- Judgment calls during execution
- Creative synthesis
- Multi-step reasoning with branching decisions

Examples:
- Design review
- Code analysis
- Research (`/agent deep-research`)
- Planning
- Troubleshooting with diagnosis

### Decision Tree

```
Is this task repeatable?
├─ NO → One-off, just do it directly
└─ YES → Continue...
    │
    Does it require judgment DURING execution?
    ├─ YES → AI-Appropriate (Prompt layer only)
    └─ NO → Continue...
        │
        Can it be expressed as: input → deterministic output?
        ├─ YES → FULL STACK (Code → CLI → Prompt)
        └─ NO → Hybrid (Code what you can, AI for the rest)
```

## Benefits of Full Stack

| Benefit | Explanation |
|---------|-------------|
| **Cost Control** | No tokens burned for repeated execution |
| **Predictability** | Same input always produces same output |
| **Schedulability** | Can run via cron, systemd without AI |
| **Composability** | CLI commands can be chained, piped, scripted |
| **Debuggability** | Logs, exit codes, deterministic behavior |
| **Speed** | No API latency for execution |
| **Offline Capable** | Works without internet (for local operations) |

## Implementation Template

When creating a new capability, follow this template:

### Step 1: Define the IDEA
```markdown
## Capability: [Name]
**Goal**: What should this accomplish?
**Trigger**: When would someone use this?
**Inputs**: What information is needed?
**Outputs**: What should be produced?
```

### Step 2: Write the CODE
```bash
#!/bin/bash
# Location: scripts/[capability-name].sh
# Purpose: [One line description]
# Usage: ./scripts/[capability-name].sh [args]

set -euo pipefail

# Parse arguments
# Implement logic
# Output results
# Exit with appropriate code
```

### Step 3: Expose via CLI
Ensure the script:
- Is executable (`chmod +x`)
- Has a `--help` flag
- Accepts arguments for all configurable options
- Documents usage in header comments

### Step 4: Create PROMPT layer
```markdown
# /[capability-name]

## Usage
/[capability-name] [arguments]

## Execution
Run the CLI:
\`\`\`bash
scripts/[capability-name].sh $ARGUMENTS
\`\`\`

Report the results to the user.
```

## Anti-Patterns

### Anti-Pattern 1: Prompt-Heavy
```
❌ /sync-git command that has LLM run 10 git commands each time
✅ sync-git.sh script that /sync-git calls
```

### Anti-Pattern 2: Reinventing in Prompt
```
❌ Prompt that re-implements health check logic
✅ Prompt that calls existing health check script
```

### Anti-Pattern 3: No CLI Layer
```
❌ Code exists but only callable through AI
✅ Code exposed via CLI, then AI routes to it
```

### Anti-Pattern 4: Over-Automating AI Tasks
```
❌ Trying to script design review decisions
✅ Accepting that some tasks need AI judgment
```

## Audit Checklist

For each capability, verify:

- [ ] **CODE exists**: Is there an implementation (script/hook)?
- [ ] **CLI callable**: Can it be run from bash with arguments?
- [ ] **PROMPT routes**: Does the prompt call CLI (not re-implement)?
- [ ] **Documented**: Is usage documented in the script and prompt?
- [ ] **Tested**: Has it been run successfully?
- [ ] **Scheduled** (if recurring): Is it in cron/systemd?

## Related Patterns

- code-before-prompts-pattern.md - Deterministic code principle
- command-invocation-pattern.md - Command routing patterns
- agent-invocation-pattern.md - Agent definition and invocation

---

## Pattern vs Workflow vs Script

| Concept | Question It Answers | Location | Executable? |
|---------|---------------------|----------|-------------|
| Pattern | "How should we approach this?" | `patterns/` | No |
| Workflow | "What steps do I follow?" | `workflows/` | No |
| Script | "What code runs?" | `scripts/` | Yes |
| Prompt | "How do I invoke it?" | `commands/` | Via AI |

---

*Ported from AIfred baseline — Jarvis v2.1.0*
