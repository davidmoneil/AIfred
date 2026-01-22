# /reflect — Self-Reflection Command

**Purpose**: Trigger AC-05 Self-Reflection cycle to analyze corrections and generate insights.

**Usage**: `/reflect [--depth quick|standard|thorough] [--focus <area>]`

---

## Overview

The `/reflect` command triggers Jarvis' self-reflection process, analyzing corrections, identifying patterns, and generating evolution proposals.

## Options

| Option | Values | Default | Description |
|--------|--------|---------|-------------|
| `--depth` | quick, standard, thorough | standard | Depth of reflection analysis |
| `--focus` | context, tools, hooks, docs, all | all | Focus area for reflection |
| `--dry-run` | flag | false | Show what would be analyzed without writing |

## Depth Levels

### Quick (~2 min)
- Scan recent corrections only
- Generate basic summary
- No new proposals

### Standard (~5-10 min)
- Full corrections analysis
- Pattern matching with prior problems
- Generate evolution proposals
- Update lessons index

### Thorough (~15-20 min)
- All standard analysis
- Cross-reference with Memory MCP
- Historical trend analysis
- Detailed pattern documentation

## Examples

```bash
# Standard reflection
/reflect

# Quick check after short session
/reflect --depth quick

# Focus on tool selection issues
/reflect --focus tools

# Thorough analysis after major PR
/reflect --depth thorough

# See what would be analyzed
/reflect --dry-run
```

## Workflow

1. **Data Collection**
   - Load corrections.md and self-corrections.md
   - Check selection-audit.jsonl (if exists)
   - Query Memory MCP for prior reflections (if available)

2. **Analysis (Phase 1: Identification)**
   - Categorize corrections by type
   - Identify recurring issues
   - Note inefficiencies observed

3. **Reflection (Phase 2)**
   - Root cause analysis
   - Pattern matching
   - Success/failure comparison

4. **Output (Phase 3: Proposal)**
   - Generate evolution proposals
   - Create/update lessons entries
   - Update lessons index
   - Write Memory MCP entities

## Output

### MANDATORY: Create Report File

**ALWAYS create a report file at completion.** This is not optional.

```bash
# Ensure directory exists
mkdir -p .claude/reports/reflections

# Create report file
# Write to: .claude/reports/reflections/reflection-YYYY-MM-DD.md
```

**If multiple reflections same day**: Use suffix `-N` (e.g., `reflection-2026-01-22-2.md`)

### Report Location
`.claude/reports/reflections/reflection-YYYY-MM-DD.md`

### Report Format
```markdown
# Reflection Report — [Date]

## Summary
- Corrections analyzed: X
- Problems identified: Y
- Proposals generated: Z

## Problems Found
[List with severity and category]

## Patterns Observed
[Recurring issues and trends]

## Evolution Proposals
[New proposals added to queue]

## Next Steps
[Recommended actions]
```

### Side Effects
- Creates/updates lessons entries in `problems/`, `solutions/`, `patterns/`
- Updates `lessons/index.md`
- Appends proposals to `evolution-queue.yaml`
- Creates Memory MCP entities (if available)

## Integration

- **AC-05**: This command is the manual trigger for AC-05 Self-Reflection
- **AC-06**: Proposals are queued for AC-06 Self-Evolution
- **AC-09**: Called automatically during `/end-session`

---

*Part of Jarvis Phase 6 Autonomic System (AC-05)*
