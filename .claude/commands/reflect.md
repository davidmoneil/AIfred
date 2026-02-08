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

## AC-05 Telemetry: Reflection Start

Emit telemetry event at reflection start:

```bash
echo '{"component":"AC-05","event_type":"component_start","data":{"trigger":"reflect-command","depth":"standard"}}' | node .claude/hooks/telemetry-emitter.js
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

4. **Planning Tracker Verification (Phase 3: MANDATORY)**
   - **Identify active planning/progress documents** from session work
   - Read `.claude/planning-tracker.yaml`
   - **Verify all active documents are registered** in the tracker
   - If documents are missing from tracker:
     - List them in the report
     - Prompt: "Add these to planning-tracker.yaml?"
     - If confirmed, add with appropriate enforcement level
   - This ensures no project documentation falls through the cracks

   ```
   Active document detection:
   1. Scan session-state.md for file paths mentioned
   2. Check git status for modified planning/progress docs
   3. Look for roadmap.md, chronicle.md, design docs in work context
   4. Compare against planning-tracker.yaml entries
   5. Report any gaps
   ```

5. **Output (Phase 4: Proposal)**
   - Generate evolution proposals
   - Create/update lessons entries
   - Update lessons index
   - Write Memory MCP entities
   - Include tracker verification results in report

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
- Planning tracker: [verified / gaps found]

## Problems Found
[List with severity and category]

## Patterns Observed
[Recurring issues and trends]

## Planning Tracker Verification
| Document | In Tracker | Enforcement |
|----------|-----------|-------------|
| [path]   | Yes/No    | [level]     |

**Gaps Found**: [list or "None"]
**Action Taken**: [added to tracker / deferred / N/A]

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

## AC-05 Telemetry: Reflection Complete

After writing the report, emit completion telemetry:

```bash
echo '{"component":"AC-05","event_type":"component_end","data":{"corrections_analyzed":0,"problems_identified":0,"proposals_generated":0}}' | node .claude/hooks/telemetry-emitter.js
```

**Note**: Replace the `0` values with actual counts from the reflection analysis.

---

*Part of Jarvis Phase 6 Autonomic System (AC-05)*
