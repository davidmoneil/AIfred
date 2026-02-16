# Prompt Design Review Pattern (PARC)

**Last Updated**: 2026-01-01
**Status**: Active

## Overview

This pattern ensures that **before implementing any task**, Claude considers existing design patterns, architectural implications, and reuse opportunities. It prevents ad-hoc solutions that create technical debt.

**Mnemonic**: **PARC** - Prompt → Assess → Relate → Create

---

## The Pattern

### Phase 1: Prompt (Parse the Request)

Understand what's being asked:
- What is the core objective?
- What type of task is this? (code, infrastructure, documentation, automation)
- What are the explicit requirements?
- What are the implicit requirements?

### Phase 2: Assess (Pattern Check)

Before implementing, check against existing patterns:

| Check | Question | Where to Look |
|-------|----------|---------------|
| **Existing patterns** | Does a pattern already exist for this? | `.claude/context/patterns/` |
| **Workflow templates** | Is there a workflow I should follow? | `.claude/context/workflows/` |
| **Similar implementations** | Has something similar been done? | Search codebase, Memory MCP |
| **Agent selection** | Should I use an agent for this? | See agent-selection-pattern.md |
| **Design principles** | What principles apply? | See below |

**Agent Selection Quick Check**:
- Code/architecture work? → Built-in subagent (feature-dev:*, Explore, Plan)
- Recurring multi-step task? → Custom agent (`/agent`)
- Quick repeatable operation? → Skill/slash command
- Simple one-off? → Direct tools

### Phase 3: Relate (Connect to Architecture)

Consider how this fits into the broader system:

| Dimension | Question |
|-----------|----------|
| **Scope** | Is this task-specific or should it be generalized? |
| **Reuse** | Can existing components be leveraged? |
| **Impact** | What other systems might be affected? |
| **Debt** | Does this create technical debt? |
| **Future** | Will this need to scale or evolve? |

### Phase 4: Create (Apply Patterns)

Implement with patterns in mind:
- Apply identified patterns explicitly
- Document any new patterns discovered
- Note deviations from patterns with reasoning
- Update pattern docs if pattern evolves

---

## Design Principles Reference

### Infrastructure Patterns

| Principle | Description | Example |
|-----------|-------------|---------|
| **DDLA** | Discover → Document → Link → Automate | New Docker container → doc it → link in paths-registry → automate check |
| **COSA** | Capture → Organize → Structure → Automate | Scattered notes → context file → linked index → slash command |
| **MCP-First** | Use MCP tools before bash commands | `mcp__docker` before `docker ps` |
| **Symlink Strategy** | External resources via `external-sources/` | Never hardcode external paths |

### Code Patterns

| Principle | Description | When to Apply |
|-----------|-------------|---------------|
| **DRY** | Don't Repeat Yourself | 3+ similar implementations → extract |
| **KISS** | Keep It Simple, Stupid | Start minimal, add complexity when needed |
| **YAGNI** | You Aren't Gonna Need It | Don't over-engineer for hypotheticals |
| **Single Responsibility** | One purpose per component | Functions/files/services do one thing |

### Project Patterns

| Principle | Description | Trigger |
|-----------|-------------|---------|
| **Document on 3x** | Create docs after 3 uses | Repeated explanations → document |
| **Automate on 3x** | Create slash command after 3 uses | Repeated tasks → automate |
| **Memory on discovery** | Store new patterns in Memory MCP | Non-obvious learnings |

---

## Task Type Classification

Different task types require different pattern considerations:

### New Feature / Capability

```
□ Check for similar implementations in codebase
□ Review relevant context files
□ Consider extraction for reuse
□ Plan for documentation
□ Consider slash command if repeatable
```

### Bug Fix / Issue Resolution

```
□ Check if issue pattern exists in Memory MCP
□ Look for similar past fixes
□ Consider root cause vs symptom fix
□ Document lesson if non-obvious solution
□ Update relevant context if config-related
```

### Infrastructure Change

```
□ Review system documentation first
□ Check paths-registry.yaml for affected paths
□ Consider impact on dependent services
□ Plan rollback approach
□ Document new configuration patterns
```

### Automation / Script

```
□ Check existing slash commands for similarity
□ Follow workflow template structure
□ Include Memory MCP storage pattern
□ Reference appropriate context files
□ Consider error handling patterns
```

---

## Quick Reference Checklist

Before implementing ANY significant task:

```
PARC Checklist:
□ PROMPT: Clearly understand the objective
□ ASSESS:
  □ Searched .claude/context/patterns/ for relevant patterns
  □ Checked .claude/context/workflows/ for applicable workflow
  □ Searched Memory MCP for similar past work
□ RELATE:
  □ Considered scope (specific vs generalizable)
  □ Identified reuse opportunities
  □ Assessed architectural impact
□ CREATE:
  □ Applying identified patterns
  □ Will document new patterns if discovered
  □ Plan to update relevant docs
```

---

## When to Apply PARC

### Always Apply (Significant Tasks)

- New slash commands
- Infrastructure changes
- New integrations
- Multi-file changes
- Anything that might be repeated

### Light Apply (Quick Tasks)

- Simple bug fixes
- Documentation updates
- Single-file edits
- Routine maintenance

For light tasks, mentally run through PARC in seconds:
> "Is there a pattern for this? No. Will this be repeated? No. → Proceed."

### Skip (Trivial Tasks)

- Typo fixes
- Simple queries
- One-off commands

---

## Integration with Other Patterns

| Pattern | Integration Point |
|---------|-------------------|
| Agent Selection Pattern | Choose automation approach in Assess phase |
| Memory Storage Pattern | Store new patterns discovered during PARC |
| Session Exit Procedure | Document PARC findings in session notes |
| Workflow Template | PARC is implicit in workflow structure |
| Severity/Status System | Use when classifying PARC findings |

---

## Slash Command

Use `/design-review` to explicitly invoke PARC analysis before a task:

```
/design-review "Add caching to the n8n API calls"
```

This will walk through all PARC phases with structured output.

---

## Examples

### Example 1: New Slash Command Request

**Prompt**: "Create a command to check Plex status"

**PARC Analysis**:
- **Assess**: Found `/check-service` pattern already exists
- **Relate**: This is a specific instance of service health check
- **Create**: Use `/check-service` as template, customize for Plex

**Result**: Followed existing pattern, created `/plex-troubleshoot` based on template

### Example 2: Script Automation Request

**Prompt**: "Write a script to backup config files"

**PARC Analysis**:
- **Assess**: No backup pattern exists, but restic is already used
- **Relate**: Should integrate with existing restic infrastructure
- **Create**: Extend restic approach rather than create new system

**Result**: Used existing backup infrastructure, avoided tool sprawl

### Example 3: Bug Fix

**Prompt**: "Fix the n8n workflow timeout issue"

**PARC Analysis**:
- **Assess**: Searched Memory MCP for past n8n timeout issues - found one
- **Relate**: Past issue was different root cause, but similar symptoms
- **Create**: Investigate fresh but reference past lesson

**Result**: Found new root cause, stored as new Lesson entity

---

## Related Documentation

- @.claude/context/patterns/agent-selection-pattern.md - Choose between agents/subagents/skills/tools
- @.claude/context/patterns/memory-storage-pattern.md - When to store findings
- @.claude/context/integrations/workflow-patterns.md - Workflow patterns
- @.claude/commands/design-review.md - Slash command for explicit invocation
- @knowledge/docs/claude-code-best-practices.md - General best practices

---

**Maintained by**: Claude Code
