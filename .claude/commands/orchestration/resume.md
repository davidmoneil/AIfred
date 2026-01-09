---
argument-hint: "[orchestration-name]"
description: Resume work on an orchestration after a session break
allowed-tools:
  - Read
  - Glob
  - Grep
  - Bash
  - TodoWrite
  - mcp__mcp-gateway__search_nodes
  - mcp__mcp-gateway__open_nodes
model: sonnet
---

# Task Orchestration: Resume

Restore full context for continuing work on an active orchestration.

## When to Use

- Starting a new session with existing orchestration
- Returning after a break
- Hook detects "continue", "resume", "pick up where we left off"

## Process

### 1. Find Orchestration

If argument provided:
- Look for `.claude/orchestration/*<argument>*.yaml`

If no argument:
- Find most recently modified active orchestration
- Or check `session-state.md` for last active orchestration

### 2. Load Orchestration State

Parse the YAML file:
- Current phase and task statuses
- In-progress tasks
- Next available tasks
- Any blockers or notes

### 3. Gather Related Context

For in-progress and next tasks, gather context:

**a. Check files mentioned in task notes**
```
Read any files referenced in task descriptions or notes
```

**b. Check recent git activity**
```bash
git log --oneline -10 --since="3 days ago"
git diff --stat HEAD~5
```

**c. Load Memory entities**
```
search_nodes("orchestration: <name>")
open_nodes([related entity names])
```

### 4. Identify Current Position

Determine:
- Which task was last worked on
- What was accomplished (from commits, notes)
- What remains for current task
- Any new blockers discovered

### 5. Restore TodoWrite State

Create TodoWrite entries for:
- Current in-progress task (marked in_progress)
- Next 2-3 available tasks (marked pending)

### 6. Present Context Summary

Display comprehensive resume context:

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
📋 Resuming: Build Authentication System
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Overall Progress: 50% (4/8 tasks)
📍 Current Phase: Phase 2 - Implementation

🔄 In Progress:
   T2.2: Registration endpoint
   └── Last commit: abc1234 "Add user validation"
   └── Remaining: Email verification, password hashing

📁 Recently Modified Files:
   - src/auth/register.ts (2 hours ago)
   - src/models/user.ts (yesterday)

🎯 Next Available Tasks:
   1. T2.2: Registration endpoint (continue)
   2. T2.3: Password reset (after T2.2)

📝 Notes from Last Session:
   "Need to add rate limiting before T2.3"

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Ready to continue with T2.2?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

### 7. Update Session State

Update `session-state.md` with resumed orchestration info.

## Tips

- If orchestration seems stale, suggest `/orchestration:status` first
- If major blockers found, note them and suggest addressing first
- If orchestration appears completed, suggest archiving
