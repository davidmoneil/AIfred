---
description: TELOS goal alignment system - view, update, and review strategic goals
model: sonnet
---

# /telos Command

Manage the TELOS goal alignment system - the strategic layer above current-priorities.md.

## Usage

```
/telos                    # Show current TELOS summary
/telos goals              # List all active goals with status
/telos domain <name>      # Show specific domain (technical, creative, personal)
/telos update <goal-id>   # Update goal status/progress
/telos review [type]      # Start review workflow (weekly|monthly|quarterly)
/telos add goal           # Add new goal (guided)
/telos link <goal> <priority>  # Link goal to priority item
```

## Behavior

### Default: /telos

Show compact TELOS summary:
1. Read `.claude/context/telos/TELOS.md`
2. Read `.claude/context/telos/goals/active-goals.yaml`
3. Display:
   - Overall mission statement
   - This quarter's focus theme
   - Top 3 active goals with status emojis
   - Key metrics summary

### /telos goals

List all active goals across domains:
1. Parse `active-goals.yaml`
2. For each domain, show:
   - Mission summary (one line)
   - All goals with: ID, name, timeline, status emoji, linked priorities

Status emojis:
- 🟢 on_track
- 🟡 at_risk
- 🔴 blocked
- ✅ achieved
- ⬜ needs_definition

### /telos domain <name>

Deep dive into specific domain (technical, creative, or personal):
1. Read `.claude/context/telos/domains/<name>.md`
2. Display full content: Problems, Mission, Goals, Metrics

### /telos update <goal-id>

Update goal progress interactively:
1. Find goal in `active-goals.yaml` and domain file
2. Show current status
3. Ask for new status (on_track, at_risk, blocked, achieved)
4. Ask for progress note
5. Update both files with timestamp

### /telos review [type]

Start appropriate review workflow based on type:
- `weekly` (default): Quick 5-10 min status check
- `monthly`: Comprehensive 30-60 min review with metrics
- `quarterly`: Strategic 60-90 min reassessment

Workflow: Read `.claude/context/workflows/telos-review.md` for detailed steps.

### /telos add goal

Guided goal creation:
1. Ask: Which domain? (technical, creative, personal, cross-domain)
2. Ask: Goal name and target (measurable outcome)
3. Ask: Timeline (quarter or specific date)
4. Ask: Which problems does this serve?
5. Ask: Success criteria (list)
6. Ask: Link to current-priorities.md items?
7. Create entry in:
   - `active-goals.yaml`
   - `domains/<domain>.md`

### /telos link <goal-id> <priority-anchor>

Create bidirectional link:
1. Add priority link to goal in `active-goals.yaml`
2. Add priority link to goal in domain file
3. Add TELOS reference in `current-priorities.md` item (if not present)

## File Locations

| File | Purpose |
|------|---------|
| `.claude/context/telos/TELOS.md` | Master file - identity, mission, quarter focus |
| `.claude/context/telos/domains/*.md` | Domain-specific problems, mission, goals, metrics |
| `.claude/context/telos/goals/active-goals.yaml` | Machine-readable goals for hooks |
| `.claude/context/workflows/telos-review.md` | Review procedures |

## Examples

```bash
# Quick summary
/telos

# See all goals
/telos goals

# Deep dive into technical domain
/telos domain technical

# Update goal status
/telos update G-T1

# Start weekly review
/telos review weekly

# Start monthly review
/telos review monthly

# Add new goal
/telos add goal

# Link goal to priority
/telos link G-T4 deterministic-skill-architecture
```

## Review Cadence

| Type | Frequency | Duration | Purpose |
|------|-----------|----------|---------|
| Weekly | Every Monday | 5-10 min | Status check, flag at-risk |
| Monthly | 1st of month | 30-60 min | Metrics review, adjust goals |
| Quarterly | End of quarter | 60-90 min | Strategic reassessment |
| On-Change | As needed | Varies | Goal completion, direction shift |

## Integration

- **Session Start**: TELOS summary auto-injected via session-start.js hook
- **Priorities**: Bidirectional links with current-priorities.md
- **Orchestration**: Complex goals can be broken down via `/orchestration:plan`

## Related

- @.claude/context/telos/README.md - TELOS system documentation
- @.claude/context/telos/TELOS.md - Master TELOS file
- @.claude/context/workflows/telos-review.md - Review workflow details
- @.claude/context/projects/current-priorities.md - Tactical execution
