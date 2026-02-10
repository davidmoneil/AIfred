---
name: ralph-loop
model: sonnet
version: 1.0.0
description: |
  Ralph Loop iterative development methodology for autonomous AI loops.
  Use when: user asks about Ralph Loop, wants to start a Ralph loop, needs to cancel a Ralph loop,
  asks "what is Ralph", "how does Ralph work", "Ralph technique", "iterative AI loop".
  Commands: /ralph-loop <prompt> [--max-iterations N] [--completion-promise TEXT], /cancel-ralph
category: workflow
tags: [automation, iteration, autonomous, development]
created: 2026-01-23
user_invocable: true
arguments:
  - name: action
    description: "start" to begin a loop, "cancel" to stop, "help" for documentation
    required: false
  - name: prompt
    description: The task prompt for the Ralph loop (required for start)
    required: false
  - name: max-iterations
    description: Maximum iterations before auto-stop
    required: false
  - name: completion-promise
    description: Text phrase that signals task completion
    required: false
---

# Ralph Loop Skill

Implement iterative development via continuous AI loops using the Ralph Wiggum technique.

---

## Overview

Ralph Loop is an iterative development methodology pioneered by Geoffrey Huntley. The same prompt is fed to Claude repeatedly, with each iteration seeing its own previous work in files and git history.

**Core Concept:**
```bash
while :; do
  cat PROMPT.md | claude-code --continue
done
```

**Each Iteration:**
1. Claude receives the SAME prompt
2. Works on the task, modifying files
3. Tries to exit
4. Stop hook intercepts and feeds the same prompt again
5. Claude sees its previous work in the files
6. Iteratively improves until completion

---

## Quick Actions

| Need | Command |
|------|---------|
| Start a Ralph loop | `/ralph-loop "task prompt" --max-iterations 20` |
| Cancel active loop | `/cancel-ralph` |
| Get help | This skill |

---

## Starting a Ralph Loop

### Command: /ralph-loop <PROMPT> [OPTIONS]

**Usage:**
```
/ralph-loop "Refactor the cache layer" --max-iterations 20
/ralph-loop "Add tests" --completion-promise "TESTS COMPLETE"
```

**Options:**
- `--max-iterations <n>` - Max iterations before auto-stop
- `--completion-promise <text>` - Promise phrase to signal completion

**How It Works:**
1. Creates `.claude/.ralph-loop.local.md` state file
2. You work on the task
3. When you try to exit, stop hook intercepts
4. Same prompt fed back
5. You see your previous work
6. Continues until promise detected or max iterations

---

## Canceling a Ralph Loop

### Command: /cancel-ralph

**Usage:**
```
/cancel-ralph
```

**How It Works:**
- Checks for active loop state file
- Removes `.claude/.ralph-loop.local.md`
- Reports cancellation with iteration count

---

## Completion Promises

To signal completion, Claude must output a `<promise>` tag:

```
<promise>TASK COMPLETE</promise>
```

The stop hook looks for this specific tag. Without it (or `--max-iterations`), Ralph runs infinitely.

---

## Self-Reference Mechanism

The "loop" doesn't mean Claude talks to itself. It means:
- Same prompt repeated
- Claude's work persists in files
- Each iteration sees previous attempts
- Builds incrementally toward goal

---

## When to Use Ralph

**Good For:**
- Well-defined tasks with clear success criteria
- Tasks requiring iteration and refinement
- Iterative development with self-correction
- Greenfield projects

**Not Good For:**
- Tasks requiring human judgment or design decisions
- One-shot operations
- Tasks with unclear success criteria
- Debugging production issues (use targeted debugging instead)

---

## Example: Interactive Bug Fix

```
/ralph-loop "Fix the token refresh logic in auth.ts. Output <promise>FIXED</promise> when all tests pass." --completion-promise "FIXED" --max-iterations 10
```

Ralph will:
- Attempt fixes
- Run tests
- See failures
- Iterate on solution
- Continue until tests pass or 10 iterations

---

## Learn More

- Original technique: https://ghuntley.com/ralph/
- Ralph Orchestrator: https://github.com/mikeyobrien/ralph-orchestrator

---

## Related

- Stop Hook: @.claude/hooks/stop.sh (intercepts exit for loop continuation)
- State File: `.claude/.ralph-loop.local.md`

---

*Ralph Loop Skill v1.0.0*
