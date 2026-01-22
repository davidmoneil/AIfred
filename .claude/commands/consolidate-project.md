---
argument-hint: [project-name | --infrastructure | --analyze | --all]
description: Consolidate project knowledge or infrastructure context, create git commit
allowed-tools:
  - Bash(~/Scripts/consolidate-project.sh:*)
  - Bash(git:*)
  - Read
  - Write
  - Edit
  - Grep
  - Glob
---

# Consolidate Project Knowledge or Infrastructure Context

**Two consolidation modes**:
1. **Project Mode**: Organize learned patterns, examples, progress (default)
2. **Infrastructure Mode**: Optimize context window, reduce token usage (--infrastructure)

**CLI Script**: `~/Scripts/consolidate-project.sh` (data gathering)
**Reference**: @knowledge/notes/consolidation-methodology-mcp-context-optimization.md

---

## Parse Arguments

```
If $ARGUMENTS is empty:
  → Ask user: "Consolidate [P]roject or [I]nfrastructure or [A]nalyze?"

If $ARGUMENTS starts with "--":
  → --infrastructure: Run Infrastructure Consolidation
  → --analyze: Run Analysis Mode
  → --all: Run both Project and Infrastructure

If $ARGUMENTS is valid project name:
  → Run Project Consolidation
```

---

## Section A: Project Mode

### Step 1: Gather Project Data (CLI)

```bash
~/Scripts/consolidate-project.sh --project <project-name>
```

This returns JSON with:
- File existence (readme, config, todo, progress, patterns)
- Stats (pattern_count, example_count, recent_changes)
- Health indicators (is_stale, needs_consolidation)
- Recent files modified

### Step 2: Analyze and Consolidate (AI Judgment)

Based on the data gathered:

1. **If `needs_consolidation: true`** (>5 recent changes):
   - Read `learned-patterns.md`
   - Look for duplicate or contradictory patterns
   - Merge similar patterns, remove outdated ones
   - Update the file

2. **If `has_examples: true`**:
   - Review examples directory
   - Decide which to keep vs archive
   - Organize if needed

3. **Update progress.md**:
   - Add entry with today's date
   - Summarize recent accomplishments
   - Note key insights
   - List next steps

4. **Update config.yaml**:
   - Set `last_consolidated: <today>`
   - Update status if stale or goals achieved

### Step 3: Generate Summary

Create consolidation summary:
```markdown
# Consolidation Summary - [Project Title]

**Date**: [today]

## Changes Made
- [List changes]

## Project Health
- Patterns: [count]
- Examples: [count]
- Days since activity: [N]
- Status: [Active/Stale/Completed]

## Key Insights
- [From recent work]

## Recommended Actions
- [Based on analysis]
```

### Step 4: Git Commit

```bash
git add .claude/projects/<project-name>/
git commit -m "Consolidate project: [Project Title]

Patterns: [count]
Examples: [count]
Status: [status]

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Section B: Infrastructure Mode

### Step 1: Gather Infrastructure Data (CLI)

```bash
~/Scripts/consolidate-project.sh --analyze
```

This returns JSON with:
- Top context files by line count
- Agent files by size
- Command files by size
- Skill files with tools/ status
- Totals (context_lines, agent_lines, command_lines)

### Step 2: Identify Targets (AI Analysis)

Based on the data:

1. **Large context files** (>500 lines):
   - Determine if detail can be extracted to `knowledge/reference/`
   - Identify what should stay in context (quick reference)

2. **Large commands** (>200 lines):
   - Flag for potential CLI extraction
   - Per command-invocation-pattern.md

3. **Skills without tools/**:
   - Flag for Code Before Prompts compliance

### Step 3: Apply Consolidation (AI Judgment)

For each target identified:

1. **Categorize content**:
   - Always-loaded: Quick references, decision trees, links
   - On-demand: Detailed workflows, complete references, examples

2. **Extract if appropriate**:
   - Create `knowledge/reference/<category>/<topic>.md`
   - Slim original file
   - Update cross-references

3. **Update CLAUDE.md** if docs moved to on-demand

### Step 4: Document and Commit

```bash
git add .claude/ knowledge/
git commit -m "Consolidate infrastructure context

Changes:
- [List what was consolidated]

Token impact: [estimate if known]

Co-Authored-By: Claude <noreply@anthropic.com>"
```

---

## Section C: Analyze Mode

### Step 1: Gather Data (CLI)

```bash
~/Scripts/consolidate-project.sh --analyze
```

### Step 2: Report Findings

Present analysis:

```
Context Analysis

Top Context Files (by size):
1. [file]: [lines] lines
2. [file]: [lines] lines
...

Top Commands (by size):
1. [command]: [lines] lines
...

Skills Status:
- [skill]: [lines] lines, tools: [yes/no]
...

Totals:
- Context: [N] lines
- Agents: [N] lines
- Commands: [N] lines

Recommendations:
- [List consolidation opportunities]
- [Estimate potential savings]
```

---

## Special Cases

### Project Doesn't Exist

If script returns `{"error": "Project not found"}`:
- List available projects with `~/Scripts/consolidate-project.sh --list-projects`
- Ask user which project to consolidate

### No Changes Needed

If `needs_consolidation: false` and no significant findings:
```
No consolidation needed for [target]

Last consolidated: [date]
Status: [status]

Run with --analyze for detailed breakdown.
```

### Stale Project (>30 days)

If `is_stale: true`:
- Report staleness
- Ask user: Archive, mark paused, or keep as-is?

---

## CLI Script Reference

```bash
# List all projects
~/Scripts/consolidate-project.sh --list-projects

# Get project stats
~/Scripts/consolidate-project.sh --project <name>

# Analyze infrastructure
~/Scripts/consolidate-project.sh --analyze

# Find stale projects (>N days)
~/Scripts/consolidate-project.sh --check-stale 30
```

---

## Related

- Script: @Scripts/consolidate-project.sh
- Pattern: @.claude/context/patterns/capability-layering-pattern.md
- Pattern: @.claude/context/patterns/command-invocation-pattern.md
- Methodology: @knowledge/notes/consolidation-methodology-mcp-context-optimization.md
