---
description: Pause an executing plan
argument-hint: <plan-name>
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
---

# Parallel-Dev: Pause Execution

Gracefully pause an executing plan. Active agents will complete their current task before stopping.

## Arguments

- `<plan-name>` - Name of the executing plan to pause

## Process

### 1. Validate

```bash
PLAN_NAME="$ARGUMENTS"
PLAN_SLUG=$(echo "$PLAN_NAME" | tr '[:upper:]' '[:lower:]' | tr ' ' '-')
EXEC_DIR=".claude/parallel-dev/executions/${PLAN_SLUG}"
STATE_FILE="$EXEC_DIR/state.yaml"

if [ ! -f "$STATE_FILE" ]; then
    echo "No execution found for: $PLAN_NAME"
    exit 1
fi

STATUS=$(grep "^status:" "$STATE_FILE" | cut -d: -f2 | xargs)
if [ "$STATUS" != "executing" ]; then
    echo "Execution is not running (status: $STATUS)"
    exit 1
fi
```

### 2. Update State

```bash
TIMESTAMP=$(date -Iseconds)

# Update status (portable: temp file + mv)
tmp=$(mktemp); sed 's/^status:.*/status: paused/' "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"

# Add pause timestamp
tmp=$(mktemp); sed "s/paused_at:.*/paused_at: $TIMESTAMP/" "$STATE_FILE" > "$tmp" && mv "$tmp" "$STATE_FILE"
```

### 3. Record Pause Reason

Ask for optional reason:
- User-initiated pause
- Taking a break
- Need to review progress
- Encountered issue

### 4. Display Status

```
===================================================================
 EXECUTION PAUSED: {plan-name}
===================================================================

Progress at pause: 45% (9/20 tasks)

Active agents will complete current tasks:
  Agent-1: T2.3 - Password reset flow (finishing...)
  Agent-2: T2.4 - Email verification (finishing...)

Paused at: 2026-01-17 14:35:00
Reason: User-initiated

-------------------------------------------------------------------

To resume: /parallel-dev:resume {plan-name}
To check status: /parallel-dev:status {plan-name}

===================================================================
```

### 5. Handle Active Agents

Active agents are allowed to complete their current task:
- Their results will be recorded when they finish
- No new tasks will be assigned
- Progress updates continue until all active agents complete

## Pause Types

| Type | Trigger | Behavior |
|------|---------|----------|
| User | `/parallel-dev:pause` | Graceful, agents finish current task |
| Error | Agent failure | Automatic, logs error details |
| Dependency | Circular or missing dep | Automatic, requires manual fix |
| Session | Context limit | Automatic, preserves state |

## Output

Updates:
- `state.yaml` status to `paused`
- Adds pause timestamp and reason
- Logs pause event

## Related Commands

- `/parallel-dev:resume <name>` - Resume paused execution
- `/parallel-dev:status <name>` - View current state
