# Wiggum Loop Workflow — Iterative Exploratory Testing

**Version**: 1.0.0
**Created**: 2026-02-13
**Layer**: Nous (procedural knowledge)
**Invokes**: ralph-loop Skill (`.claude/skills/ralph-loop/SKILL.md`), dev-ops Skill (`.claude/skills/dev-ops/SKILL.md`)

---

## Preamble

The Wiggum Loop is a methodology for translating a broad objective — "test this rigorously,"
"explore this system," "find what's broken" — into a structured, self-improving, self-expanding
series of iterated task cycles. It is not a script to execute mechanically. It is a way of
thinking about iterative work.

**The core insight**: The tester doesn't know what they'll find. A rigid test matrix tests
what you already expect. The Wiggum Loop tests what you *don't* expect by following evidence
chains — where each cycle's discoveries shape the next cycle's focus. This exploratory approach
surfaces bugs, inconsistencies, and insights that targeted testing misses.

**When to use this workflow**:
- A user asks for rigorous, multi-pass testing of infrastructure or code
- A user wants iterative problem-solving on a complex, open-ended challenge
- A user wants research or experimentation that should converge on results over N cycles
- Any task where "do it once and call it done" is insufficient

**What this workflow provides**:
- A structured 5-step cycle that prevents aimless wandering
- Evidence chaining that makes each cycle more valuable than the last
- Progress tracking that persists across context boundaries
- A bug registry and documentation template that captures institutional knowledge
- Exit criteria that prevent premature termination

---

## Translating User Intent into Cycles

When a user says something like "test my infrastructure thoroughly" or "iterate on this until
it's solid," translate that into Wiggum Loop parameters:

| User Intent | Loop Count | Domain | Execution Mode |
|-------------|-----------|--------|----------------|
| "Test it rigorously" | 10 | Infrastructure (full rotation) | Manual or ralph-loop |
| "Find what's broken" | 5 | Targeted at suspected area | Manual |
| "Iterate until the tests pass" | 3-5 | Specific module | ralph-loop with promise |
| "Research this topic deeply" | 5-7 | Research domain | Manual with evidence chain |
| "Make this bulletproof" | 10+ | Full coverage | ralph-loop with high max |

**Default parameters** when not specified: 10 loops, full domain rotation, manual execution.

---

## Execution Modes

### Mode 1: Manual (Within Conversation)

Run cycles directly within the current conversation. Each cycle is a brainstorm-plan-execute-
document-review pass performed by the agent in real-time. This is how the first 10-loop
campaign was executed.

**Advantages**: Full agent reasoning at each step, flexible adaptation, rich documentation.
**Disadvantages**: Consumes context window, may require checkpointing across compactions.

### Mode 2: Ralph-Loop Automated

Use the ralph-loop Skill to automate cycling. Write a prompt that describes one cycle, set
`--max-iterations` to the desired loop count, and let the stop hook manage re-feeding.

**Example prompt for ralph-loop**:
```
Execute one Wiggum Loop testing cycle. Read .claude/reports/testing/wiggum-progress.json
for current state. Brainstorm 15 test ideas for the next domain in the rotation. Select
5-7, execute them, document results to wiggum-loop-{N}-results.md, and update the progress
file. Output <promise>CYCLE COMPLETE</promise> when the results file is written.
```

**Advantages**: Survives context compactions, automated iteration, self-contained.
**Disadvantages**: Less adaptive (same prompt each cycle), harder to chain evidence manually.

### Mode 3: Hybrid

Start manually for the first 2-3 cycles to establish patterns and discover initial findings,
then switch to ralph-loop for the remaining cycles using insights from the manual phase to
craft a more specific prompt.

---

## The 5-Step Protocol

Each cycle follows this exact sequence. No step may be skipped.

### Step 1: Brainstorm (Generate 15 Ideas)

Generate **15 test ideas** for the current testing domain. Cast a wide net.

**Template**:
```
1-2.   [Obvious health checks]
3-4.   [Core functionality]
5-6.   [State file validation]
7-8.   [Cross-system interactions]
9-10.  [Edge cases and error paths]
11-12. [Performance and timing]
13-14. [Data format and schema]
15.    [Follow-up from prior cycle findings]
```

**What makes a good idea**: Testable without destructive side effects. Has clear pass/fail.
Targets a specific subsystem. Informed by prior findings (evidence chain).

### Step 2: Plan (Select 5-7 Tests)

From the 15 ideas, select 5-7 to execute. For each, document:

| Field | Content |
|-------|---------|
| Test ID | `T{loop}.{n}` (e.g., T6.3) |
| Description | One-line summary |
| Method | Execution pattern (A-F, see below) and specific commands |
| Pass/fail criteria | What constitutes each outcome |

**Selection criteria** — prefer tests that:
- Follow up on prior findings (evidence chain)
- Cover untested areas (fill coverage gaps)
- Are independently executable (no cascading dependencies)
- Balance quick checks (Pattern A) with deeper investigations (Pattern B/D)

### Step 3: Execute (Run Tests, Record Results)

Execute each planned test. For each, record:
- **Result**: PASS / FAIL / PARTIAL / NOT RUN
- **Evidence**: Concrete output, measured values, observed behavior
- **Bugs**: If found, assign `BUG-{NN}` identifier with severity

**Rules**:
- Run tests independently
- Capture actual values, not just verdicts
- Note unexpected observations even if the test passes
- If execution is impossible, mark NOT RUN with reason

### Step 4: Document (Write Results Report)

Write to `.claude/reports/testing/wiggum-loop-{NN}-results.md`:

```markdown
# Wiggum Loop {N} — {Domain Title}

**Date**: YYYY-MM-DD
**Focus**: Brief description

---

## Test Results

| Test | Description | Result | Evidence |
|------|-------------|--------|----------|
| T{N}.1 | ... | **PASS** | ... |

**Score**: X/Y PASS (Z%)

---

## Bugs Found

### BUG-NN: Title (SEVERITY)
- **Severity**: Critical / Medium / Low
- **Location**: file:line
- **Root Cause**: ...
- **Impact**: ...
- **Fix**: Applied / Found, unfixed

---

## Key Findings

1. ...

---

*Loop {N} Complete — X/Y PASS*
```

### Step 5: Review (Analyze and Feed Forward)

After documenting, review the cycle:
- **Pattern recognition**: Do multiple findings share a root cause?
- **Coverage assessment**: What subsystems still need testing?
- **Bug triage**: Critical vs cosmetic?
- **Evidence chain**: What findings should inform the next brainstorm?

Update the progress tracker file.

---

## Execution Patterns

### Pattern A: State File Read (No Target Interaction)

Read state files, config, or logs directly. Fastest, safest, context-cheapest.

```bash
bash .claude/scripts/dev/watch-jicm.sh --once --json
cat .claude/state/components/AC-04-jicm.json | python3 -m json.tool
```

### Pattern B: Target Prompt-Response

Send a prompt to W0, wait for response, capture and validate.

```bash
bash .claude/scripts/dev/send-to-jarvis.sh "What is 7+3? Reply with just the number." --wait 30
bash .claude/scripts/dev/capture-jarvis.sh --tail 15
```

**Caution**: Consumes target context. Use sparingly. Prefer Pattern A.

### Pattern C: Signal File IPC

Test command-handler pipeline via signal files.

```bash
echo '/status' > .claude/context/.command-signal
sleep 5
[[ ! -f .claude/context/.command-signal ]] && echo "PASS" || echo "FAIL"
```

### Pattern D: tmux Window Operations

Direct tmux interaction for cross-window tests.

```bash
/Users/aircannon/bin/tmux capture-pane -t jarvis:1 -p | tail -10
/Users/aircannon/bin/tmux list-windows -t jarvis -F "#{window_index}:#{window_name}"
```

**tmux rules**: Always use `/Users/aircannon/bin/tmux` (absolute path). Never combine text
and Enter in one send-keys call. Single-line strings only with `-l`.

### Pattern E: Cross-File Consistency

Validate data matches across files referencing the same values. Best done with inline Python.

### Pattern F: Python Audit Scripts

Complex validation via `python3 -c "..."` — JSON parsing, YAML checks, format audits.

---

## Domain Rotation

Suggested sequence for a 10-cycle infrastructure testing campaign. Adapt based on findings.

| Cycle | Domain | Focus Areas |
|-------|--------|-------------|
| 1 | Control Reliability | Prompt delivery, idle detection, JICM baseline |
| 2 | Command IPC | Signal consumption, handler health, malformed signals |
| 3 | Window Management | All windows present, cross-window captures, process audit |
| 4 | JICM Monitoring | State accuracy, token tracking, context growth, freshness |
| 5 | Resilience | Error recovery, stale artifacts, signal lifecycle |
| 6 | AC System | State format, version consistency, dependencies, telemetry |
| 7 | Session Lifecycle | Session IDs, directory structure, archives, isolation |
| 8 | Performance | Poll intervals, growth rates, file sizes, cycle timing |
| 9 | Edge Cases | Format validation, naming conventions, PID integrity |
| 10 | Integration | State snapshot, cross-file consistency, hook paths, bug summary |

**Evidence chaining examples**:
- Cycle 4 finds state freshness bug → Cycle 8 measures exact timing impact
- Cycle 3 finds Virgil stopped → Cycle 10 confirms persistence of issue
- Cycle 6 finds field name drift → check all consumers in later cycles

---

## State Tracking

### Progress File (`wiggum-progress.json`)

```json
{
  "current_loop": 1,
  "total_loops": 10,
  "completed_loops": [],
  "current_step": "brainstorm",
  "tests_run_this_loop": 0,
  "total_tests_run": 0,
  "total_tests_passed": 0,
  "total_tests_failed": 0,
  "total_tests_partial": 0,
  "started_at": "ISO-8601",
  "last_updated": "ISO-8601"
}
```

Update after each step transition and loop completion. This file enables seamless
continuation across context compactions.

### Bug Registry

Sequential IDs: `BUG-01`, `BUG-02`, etc. Track across all cycles.

**Severity levels**:
- **Critical**: Breaks core functionality
- **Medium**: Incorrect data or degraded operation
- **Low**: Minor or inconclusive

### Final Report

After all cycles, generate `.claude/reports/testing/wiggum-final-report.md`:
- Executive summary (totals, pass rate, bug count)
- Per-cycle results table
- Complete bug registry with fix status
- Top findings and recommendations
- Subsystem coverage matrix

---

## Exit Criteria

**The Wiggum Loop exits ONLY when ALL conditions are met:**
1. Requested number of cycles completed (default 10)
2. Each cycle has all 5 steps completed
3. Each cycle executed at least 3 tests (not just planned)
4. Results documented in per-cycle report files
5. Final report generated

**The Wiggum Loop MUST NOT exit due to:**
- Environmental issues (troubleshoot them)
- Script failures (debug, fix, or work around)
- Target being busy (wait, or use Pattern A tests)
- Context limitations (use progress file to persist state)
- "Good enough" judgment (complete the requested cycle count)

---

## Lessons Learned (Campaign 1: 2026-02-13)

These operational lessons emerged from the first 10-cycle, 59-test campaign:

1. **Pattern A dominates** (~70% of tests): State file reads don't consume target context
   and run fastest. Prefer them when possible.

2. **Field name drift is a recurring bug class**: When a producer renames fields, all
   consumers must be updated. Found twice in Campaign 1 (BUG-08, BUG-09).

3. **Log files are test gold**: The watcher log contained complete cycle timing data.
   Always read logs early in a campaign.

4. **Python inline scripts beat bash for validation**: JSON parsing, format audits, and
   cross-file consistency are cleaner via `python3 -c "..."`.

5. **Bugs cluster by root cause**: Two clusters found (stale data: BUG-05/07; field names:
   BUG-08/09). When you find one bug, look for siblings.

6. **Context-free tests enable long campaigns**: The progress file + disk documentation
   allows testing to span multiple context windows seamlessly.

7. **Check large file sizes**: debug.log at 89MB was hiding in plain sight. Include a
   file-size audit in the integration cycle.

8. **Repeat monitoring tests**: Virgil stopping (BUG-06) was confirmed across Cycles 3
   and 10 — distinguishing persistent issues from transient failures.

---

## Reference

- **First campaign results**: `.claude/reports/testing/wiggum-loop-{01-10}-results.md`
- **First campaign final report**: `.claude/reports/testing/wiggum-final-report.md`
- **Ralph-loop Skill**: `.claude/skills/ralph-loop/SKILL.md`
- **Dev-ops Skill**: `.claude/skills/dev-ops/SKILL.md`
- **Dev scripts**: `.claude/scripts/dev/` (send-to-jarvis.sh, capture-jarvis.sh, watch-jicm.sh, restart-watcher.sh)
- **Dev session instructions**: `.claude/context/dev-session-instructions.md`

---

*Wiggum Loop Workflow v1.0.0 — Iterative Exploratory Testing*
