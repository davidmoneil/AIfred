---
argument-hint: "<task-id> [commit-message]"
description: Link a git commit to an orchestration task and update status
allowed-tools:
  - Read
  - Write
  - Edit
  - Bash
  - TodoWrite
model: haiku
---

# Task Orchestration: Commit

Create a git commit linked to a specific orchestration task and update progress.

## Arguments

- `task-id`: Task ID (e.g., T2.1) or "current" for the in-progress task
- `commit-message`: Optional commit message (will prompt if not provided)

## Process

### 1. Identify Task

If `task-id` is "current":
- Find the task with `status: in_progress` in active orchestration

Otherwise:
- Find the task matching the provided ID

### 2. Gather Changes

Check git status:
```bash
git status --short
git diff --cached --stat
```

If no staged changes, prompt to stage files first.

### 3. Generate Commit Message

If message not provided, suggest based on:
- Task description
- Files changed
- Done criteria

Format: `<type>(<task-id>): <message>`

Types:
- `feat` - New feature/functionality
- `fix` - Bug fix
- `refactor` - Code restructuring
- `docs` - Documentation
- `test` - Tests
- `chore` - Maintenance

Example: `feat(T2.1): Add login endpoint with JWT validation`

### 4. Create Commit

```bash
git commit -m "<formatted-message>

Task: <task-id> - <description>
Orchestration: <orchestration-name>

Co-Authored-By: Claude <noreply@anthropic.com>"
```

### 5. Update Orchestration YAML

Update the task in the orchestration file:
- Add commit hash to `commits` array
- If task complete: set `status: completed`
- If partial progress: keep `status: in_progress`, add note

### 6. Check Cascade Effects

After task completion:
- Check if other tasks are now unblocked
- Check if phase is now complete
- Recalculate overall progress percentage

### 7. Update TodoWrite

- Mark completed task as done
- Add newly unblocked tasks to pending

### 8. Display Update

```
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
✅ Committed: feat(T2.1): Add login endpoint
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

📊 Progress: 5/8 tasks (62%) [was 50%]
✅ Completed: T2.1 - Login endpoint

🔓 Now Unblocked:
   - T2.3: Password reset

🎯 Next Available:
   1. T2.2: Registration endpoint (in progress)
   2. T2.3: Password reset (newly available)

━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
```

## Quick Usage

```
# Complete current task with auto-message
/orchestration:commit current

# Complete specific task
/orchestration:commit T2.1 "Add login with JWT"

# Partial commit (task continues)
/orchestration:commit T2.1 --partial "Add validation logic"
```
