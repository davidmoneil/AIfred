---
name: ralph-loop
model: sonnet
version: 2.0.0
description: |
  Ralph Loop — iterative prompt-feeding engine for autonomous task cycling.
  Stop hook intercepts exit, re-feeds the same prompt, Claude sees prior work in files.
  Use when: "ralph loop", "start ralph", "iterative loop", "ralph technique",
  "cancel ralph", "loop until done", "iterate on this".
  Commands: /ralph-loop <prompt> [--max-iterations N] [--completion-promise TEXT], /cancel-ralph
category: automation
tags: [iteration, autonomous, loop, development, testing]
created: 2026-01-23
updated: 2026-02-13
user_invocable: true
arguments:
  - name: prompt
    description: The task prompt to iterate on (required)
    required: true
  - name: max-iterations
    description: Maximum iterations before forced stop (default unlimited — STRONGLY recommend setting this)
    required: false
  - name: completion-promise
    description: Text phrase signaling genuine completion (detected in <promise> tags)
    required: false
---

# Ralph Loop Skill — Iterative Prompt Engine

Autonomous iterative cycling: same prompt re-fed on each exit, Claude sees accumulated
work in files and git history. Each iteration builds on the last.

---

## Mechanism

```
User invokes /ralph-loop "prompt" --max-iterations 20
  → setup-ralph-loop.sh creates .claude/ralph-loop.local.md (state file)
  → Claude works on the task
  → Claude tries to exit
  → stop-hook.sh intercepts:
      IF iteration < max_iterations AND no <promise> detected:
        → Block exit, re-feed prompt, increment iteration
      ELSE:
        → Allow exit, remove state file
  → Claude sees same prompt + prior work in files
  → Repeat
```

**State file**: `.claude/ralph-loop.local.md` (YAML frontmatter + prompt body)
**Stop hook**: `.claude/hooks/stop-hook.sh` (reads transcript, checks promises, increments counter)
**Setup script**: `.claude/scripts/setup-ralph-loop.sh` (parses args, creates state file)

---

## Commands

| Command | Purpose |
|---------|---------|
| `/ralph-loop "prompt" --max-iterations N` | Start a loop with iteration cap |
| `/ralph-loop "prompt" --completion-promise "DONE"` | Start with completion detection |
| `/cancel-ralph` | Stop an active loop immediately |

---

## Strict Operational Rules

### Exit Criteria

1. **Minimum iterations**: Do NOT emit a completion promise before iteration 3. The first
   iteration orients. The second iteration makes initial progress. The third and beyond
   refine. Premature completion signals waste the iterative methodology.

2. **Max iterations**: When `--max-iterations N` is set, the loop hard-stops at iteration N.
   Always set this. Unlimited loops risk runaway resource consumption. Recommended: 5-20
   depending on task complexity.

3. **Completion promises**: To exit early (before max-iterations), Claude must output:
   ```
   <promise>COMPLETION_TEXT</promise>
   ```
   The stop hook detects this tag in the last assistant message and allows exit.

### Progress Mandate

**Each iteration MUST demonstrate measurable progress.** Acceptable progress includes:
- Files created, modified, or deleted
- Tests written and run (with results)
- Bugs identified and documented
- State files updated with new findings
- Git commits of completed work

**Stagnant iterations are failures.** If an iteration produces no observable output change,
the methodology is not working — reassess the prompt or approach, don't keep cycling.

### Self-Improvement Requirement

Each iteration MUST build on the prior iteration's output:
- If iteration N found a bug, iteration N+1 must address it
- If iteration N wrote tests, iteration N+1 must verify they pass
- If iteration N identified gaps, iteration N+1 must fill them
- Never repeat the same work — always advance

### Prohibited Behaviors

- **False promises**: Do NOT output `<promise>DONE</promise>` when work remains incomplete.
  The promise is a contract. Only emit it when the stated task is genuinely, verifiably complete.
- **Premature exit**: Do NOT claim completion before minimum iterations (3) unless the task
  is trivially simple (< 5 lines of change).
- **Scope reduction**: Do NOT silently narrow the task to declare victory. If the prompt says
  "add tests for all endpoints," do not test one endpoint and declare done.
- **Idle iterations**: Do NOT produce iterations that only summarize or plan without executing.
  Every iteration must include execution.

---

## When to Use

**Good candidates for ralph-loop:**
- Tasks with clear, verifiable completion criteria ("all tests pass", "coverage > 90%")
- Iterative refinement where each pass improves on the last
- Code generation where the prompt defines the target and iteration converges on it
- Testing campaigns where each iteration expands coverage

**Poor candidates:**
- Tasks requiring human design decisions mid-stream
- One-shot operations (use a single prompt instead)
- Tasks with ambiguous success criteria (define criteria first, then loop)
- Exploratory research (use the Wiggum Loop workflow instead)

---

## State File Format

Created at `.claude/ralph-loop.local.md`:

```markdown
---
active: true
iteration: 1
max_iterations: 20
completion_promise: "DONE"
started_at: "2026-02-13T00:00:00Z"
---

The prompt text goes here.
Can be multi-line.
```

**Fields:**
- `active`: Always `true` while loop is running
- `iteration`: Incremented by stop-hook.sh on each cycle
- `max_iterations`: Hard cap (0 = unlimited, discouraged)
- `completion_promise`: Text to detect in `<promise>` tags, or `null`
- `started_at`: ISO-8601 timestamp

---

## Integration Points

| Component | File | Role |
|-----------|------|------|
| Stop hook | `.claude/hooks/stop-hook.sh` | Intercepts exit, re-feeds prompt |
| Setup script | `.claude/scripts/setup-ralph-loop.sh` | Creates state file from args |
| Start command | `.claude/commands/ralph-loop.md` | User-facing `/ralph-loop` |
| Cancel command | `.claude/commands/cancel-ralph.md` | User-facing `/cancel-ralph` |
| Hook config | `.claude/hooks/hooks.json` | Registers Stop event handler |
| Router | `.claude/skills/autonom-ops/SKILL.md` | Absorbed by autonom-ops |

---

## Examples

**Tight loop with clear criteria:**
```
/ralph-loop "Add unit tests for every function in src/auth.ts. Run tests after each addition. Output <promise>ALL TESTS WRITTEN AND PASSING</promise> when complete." --completion-promise "ALL TESTS WRITTEN AND PASSING" --max-iterations 15
```

**Infrastructure testing (pair with Wiggum Loop workflow):**
```
/ralph-loop "Execute one Wiggum Loop testing cycle: brainstorm 15 ideas, plan 5 tests, execute, document to .claude/reports/testing/. Read wiggum-progress.json for current state. Output <promise>CYCLE COMPLETE</promise> when documented." --completion-promise "CYCLE COMPLETE" --max-iterations 5
```

**Refactoring with convergence:**
```
/ralph-loop "Refactor the cache module to use LRU eviction. Run benchmarks after each change. Output <promise>REFACTOR COMPLETE</promise> when benchmarks show improvement and all tests pass." --completion-promise "REFACTOR COMPLETE" --max-iterations 10
```

---

## Learn More

- Original technique: https://ghuntley.com/ralph/
- Ralph Orchestrator: https://github.com/mikeyobrien/ralph-orchestrator

---

*Ralph Loop Skill v2.0.0 — Iterative Prompt Engine*
