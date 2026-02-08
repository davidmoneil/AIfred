# /evolve — Self-Evolution Command

**Purpose**: Trigger AC-06 Self-Evolution cycle to implement queued proposals.

**Usage**: `/evolve [--risk low|medium|high] [--dry-run] [--proposal <id>]`

---

## Overview

The `/evolve` command triggers Jarvis' self-evolution process, implementing approved proposals from the evolution queue with appropriate validation and rollback capability.

## Options

| Option | Values | Default | Description |
|--------|--------|---------|-------------|
| `--risk` | low, medium, high | all | Only process proposals at this risk level or below |
| `--dry-run` | flag | false | Show what would be implemented without making changes |
| `--proposal` | proposal-id | all pending | Process specific proposal only |
| `--skip-validation` | flag | false | Skip post-implementation validation (dangerous) |

## Examples

```bash
# Process all approved proposals
/evolve

# Only process low-risk proposals (safe for autonomous)
/evolve --risk low

# See what would be implemented
/evolve --dry-run

# Implement specific proposal
/evolve --proposal evo-2026-01-001

# Process medium and below risk
/evolve --risk medium
```

## AC-06 Telemetry: Self-Evolution Start

Emit telemetry event at evolution workflow start:

```bash
echo '{"component":"AC-06","event_type":"component_start","data":{"trigger":"evolve-command"}}' | node .claude/hooks/telemetry-emitter.js
```

## Seven-Step Pipeline

### Step 1: Queue Review
- Load evolution-queue.yaml
- Filter by risk level and status
- Sort by priority

### Step 2: Approval Check
- Auto-approved: low-risk proposals
- Require approval: medium/high risk
- R&D proposals: always require approval

### Step 3: Branch Creation
- Create evolution branch: `evolution/<proposal-id>`
- Isolate changes from main branch

### Step 4: Implementation
- Apply changes per proposal specification
- Commit with descriptive message
- Link to proposal ID

### Step 5: Validation
- Run `/tooling-health` if applicable
- Run relevant tests
- Check for regressions against baseline

### Step 6: Merge
- If validation passes: merge to main
- Update VERSION and CHANGELOG
- Delete evolution branch

### Step 7: Cleanup
- Update proposal status in queue
- Generate evolution report
- Create Memory MCP entities

## Risk Levels

| Level | Auto-Approve | Examples |
|-------|--------------|----------|
| **Low** | Yes | Documentation updates, config tweaks, adding comments |
| **Medium** | No (requires user approval) | Hook modifications, command changes, pattern updates |
| **High** | No (requires explicit confirmation) | Core system changes, dependency updates, security changes |

## Safety Mechanisms

### Branch Isolation
All changes made in isolated branch—never direct to main.

### Validation-First
No merge without validation passing.

### Rate Limiting
Maximum 3 evolutions per session (configurable).

### Rollback Capability
```bash
# Revert last evolution
git revert HEAD

# Revert specific evolution
git log --oneline  # find commit
git revert <commit-hash>
```

### AIfred Protection
Self-evolution NEVER modifies the AIfred baseline (read-only rule enforced).

## Output

### Report Location
`.claude/reports/evolutions/evolution-YYYY-MM-DD.md`

### Report Format
```markdown
# Evolution Report — [Date]

## Summary
- Proposals processed: X
- Successful: Y
- Failed: Z

## Implemented Changes
| Proposal | Risk | Status | Commit |
|----------|------|--------|--------|
| evo-001 | low | success | abc123 |

## Validation Results
[Test/health check results]

## Version Update
[New version if bumped]

## Rollback Instructions
[How to revert if needed]
```

### Side Effects
- Git commits on branch (merged to main on success)
- VERSION/CHANGELOG updates
- Evolution queue status updated
- Evolution log appended

## Integration

- **AC-05**: Receives proposals from Self-Reflection
- **AC-07**: Receives proposals from R&D Cycles
- **AC-08**: Receives proposals from Maintenance
- **PR-13**: Uses benchmarks for validation

## AC-06 Telemetry: Self-Evolution Complete

Emit telemetry event at evolution workflow completion:

```bash
echo '{"component":"AC-06","event_type":"component_end","data":{"proposals_evaluated":0,"implementations":0}}' | node .claude/hooks/telemetry-emitter.js
```

**Note**: Replace `0` values with actual counts from the evolution run.

---

*Part of Jarvis Phase 6 Autonomic System (AC-06)*
