# Autonomic Systems Validation Test Plan

**Created**: 2026-01-16
**Purpose**: Incrementally test all Phase 6 autonomous systems
**Method**: Contrived prompts tested in parallel terminal sessions

---

## Testing Protocol

1. **Primary Session** (this terminal): Analyzes systems, creates test prompts
2. **Test Session** (second terminal): Executes test prompts, observes behavior
3. **Validation**: Compare observed behavior against design specifications

---

## System 1: Self-Launch System (AC-01)

### Design Intent
- Automatically greet user with time-appropriate greeting
- Review context files silently
- Present status briefing
- Autonomously suggest next action without waiting

### Current Status: ✅ VALIDATED (2026-01-16)

**Test Results:**

| Test | Prompt | Greeting | Context Read | Briefing | Suggestions |
|------|--------|----------|--------------|----------|-------------|
| 1.1 | `.` | ✅ "Good afternoon, sir" | ✅ Both files | ✅ Full status | ✅ 3 options |
| 1.2 | `Jarvis` | ✅ "Good afternoon, sir" | ✅ Both files | ✅ Table format | ✅ Offered |
| 1.3 | `Hello Jarvis` | ✅ "Good afternoon, sir" | ✅ Both files | ✅ Summary | ✅ 3 options |

**Hook Behavior (from diagnostic log):**
- ✅ Source detection (startup/resume/clear/compact)
- ✅ Time-of-day detection
- ✅ Watcher launched
- ✅ MCP suggestions evaluated
- ✅ Session state parsed

**Known Gaps (documented, not blocking):**
- AIfred baseline sync check not implemented (design says mandatory per PR-1.D)
- Weather fetch not implemented (optional per spec)
- Environment validation not implemented

### Test Prompts

**Test 1.1 — Minimal Prompt** ✅ PASS
```
.
```

**Test 1.2 — Single Word** ✅ PASS
```
Jarvis
```

**Test 1.3 — Greeting** ✅ PASS
```
Hello Jarvis
```

### Gap Analysis

| Aspect | Design | Observed | Status |
|--------|--------|----------|--------|
| Greeting on minimal prompt | Yes | Yes | ✅ |
| Greeting on substantive prompt | Yes | Yes | ✅ |
| Status briefing | Yes | Yes | ✅ |
| Autonomous suggestion | Yes | Yes | ✅ |
| AIfred baseline check | Yes | No | ⚠️ Not implemented |
| Weather fetch | Optional | No | — |

---

## System 2: Wiggum Loop Integration (AC-02)

### Design Intent
- DEFAULT behavior (always on unless "quick/rough/simple" keywords)
- Six-step loop: Execute → Check → Review → Drift → Context → Continue
- Track all work via TodoWrite
- Only stop when objectives met or user interrupts

### Current Status: ❌ NOT IMPLEMENTED (2026-01-16)

**Test Results:**

| Test | Expected | Observed | Status |
|------|----------|----------|--------|
| 2.1 Multi-step | TodoWrite + self-review | Single-pass, no TodoWrite | ❌ |
| 2.2 Quick mode | Suppressed loop | Single-pass (same as 2.1) | ⚠️ |
| 2.3 Blocker | Investigate + continue | Report + stop | ❌ |

**Critical Finding**: Wiggum Loop pattern is documented but NOT active as default behavior.

**Root Cause**:
- Pattern exists in `.claude/context/patterns/wiggum-loop-pattern.md`
- BUT no mechanism injects this into Claude's behavior
- Base Claude behavior is single-pass task completion

**Implementation Needed**:
- Option A: Add Wiggum Loop instructions to CLAUDE.md (always visible)
- Option B: Create UserPromptSubmit hook that injects Wiggum instructions
- Option C: Modify existing system prompt to mandate TodoWrite + self-review

**Implementation Notes:**
- Pattern document exists: `.claude/context/patterns/wiggum-loop-pattern.md`
- State file planned: `.claude/state/components/AC-02-wiggum.json`
- `/ralph-wiggum:ralph-loop` skill exists (manual trigger only)

### Test Prompts

**Test 2.1 — Multi-step Task (Loop Expected)**
```
Create a JavaScript file at /tmp/math-utils.js with three functions: add(a,b), subtract(a,b), and multiply(a,b). Include JSDoc comments and basic error handling for non-numeric inputs.
```

**Expected Behavior:**
1. TodoWrite creates task list (3+ items)
2. Implements each function
3. Self-reviews: "Are JSDoc comments complete? Is error handling robust?"
4. Marks todos complete only when verified
5. Multiple passes possible

**Test 2.2 — Quick Mode (Loop Suppressed)**
```
Quick fix: create a simple add function in /tmp/add.js
```

**Expected Behavior:**
- Single-pass implementation
- NO self-review iteration
- Immediate completion
- Minimal TodoWrite usage (optional)

**Test 2.3 — Task with Potential Blocker**
```
Read the file /tmp/nonexistent-config.json and summarize its contents
```

**Expected Behavior:**
- Attempts to read file
- File doesn't exist (blocker)
- DOES NOT STOP — investigates, reports, suggests alternatives
- Loop continues with resolution attempt

**Test 2.4 — Scope Drift Detection**
```
Fix the typo in the greeting function
```
Then mid-task: "Actually, also add logging and error handling"

**Expected Behavior:**
- Detects scope expansion
- Notes drift (but accommodates reasonable expansion)
- OR asks for clarification if significant drift

### Validation Criteria
- [ ] TodoWrite used for multi-step tasks
- [ ] Self-review occurs before marking complete
- [ ] Blockers trigger investigation, not immediate stop
- [ ] "Quick" keyword suppresses multi-pass
- [ ] Work verified complete before loop exit

---

## System 3: Independent Milestone Review (AC-03)

### Design Intent
- Semi-autonomous trigger (prompt user for approval)
- Two-level review: code-review agent + project-manager agent
- Review outcomes: Approved, Conditional, Rejected

### Test Prompts

**Test 3.1 — Milestone Completion Signal**
```
I've just completed PR-11. Please review the milestone.
```

**Expected**:
- Prompt user to confirm review
- Launch code-review agent for technical check
- Launch project-manager agent for progress check
- Generate review report

**Test 3.2 — Simulated PR Review**
```
Review the implementation of the Self-Launch System (AC-01) as a milestone review
```

**Expected**: Structured review with pass/fail criteria

### Validation Criteria
- [ ] Review prompt displayed to user
- [ ] Two-level review executed (or simulated)
- [ ] Report generated
- [ ] Outcome clearly stated

---

## System 4: JICM Enhanced Context Management (AC-04)

### Design Intent
- Five-tier threshold system (HEALTHY → EMERGENCY)
- Context exhaustion = pause, not stop
- Checkpoint for continuation

### Test Prompts

**Test 4.1 — Context Budget Check**
```
/context-budget
```

**Expected**: Budget dashboard with tier status

**Test 4.2 — Simulate High Context**
```
Read every file in .claude/context/ and summarize each one
```

**Expected**:
- Context accumulation tracked
- Warning at threshold
- Checkpoint offered before critical

**Test 4.3 — Context Checkpoint**
```
/context-checkpoint
```

**Expected**: Checkpoint created, MCP evaluation, instructions for continuation

### Validation Criteria
- [ ] Context tracking functional
- [ ] Threshold warnings displayed
- [ ] Checkpoint creation works
- [ ] MCP offloading recommendations

---

## System 5: Self-Reflection Cycles (AC-05)

### Design Intent
- Three phases: Identification → Reflection → Proposal
- Sources: corrections.md, selection-audit.jsonl, session-state.md
- Generate evolution proposals

### Test Prompts

**Test 5.1 — Manual Reflection**
```
/reflect
```

**Expected**: Analysis of recent corrections, patterns, proposals

**Test 5.2 — Correction Capture**
First, make a mistake, then correct it:
```
What is 2+2?

Actually, I made an error. Please recalculate.
```

**Expected**: Self-correction captured in corrections.md

### Validation Criteria
- [ ] Reflection command executes
- [ ] Corrections tracked
- [ ] Patterns identified
- [ ] Proposals generated

---

## System 6: Self-Evolution Cycles (AC-06)

### Design Intent
- Seven-step pipeline
- Risk-based approval gates
- Branch-based implementation
- Rollback capability

### Test Prompts

**Test 6.1 — Manual Evolution**
```
/evolve
```

**Expected**: Check evolution queue, process proposals if any

**Test 6.2 — Propose Evolution**
```
I'd like to propose an improvement: add a timestamp to all log files
```

**Expected**: Proposal added to queue with risk classification

### Validation Criteria
- [ ] Evolution queue exists/accessible
- [ ] Proposals can be added
- [ ] Risk classification works
- [ ] Branch workflow understood

---

## System 7: R&D Cycles (AC-07)

### Design Intent
- External (MCP/plugins) + internal (efficiency) research
- Classification: ADOPT/ADAPT/DEFER/REJECT
- High adoption bar

### Test Prompts

**Test 7.1 — Manual Research**
```
/research
```

**Expected**: Research agenda check, discovery report

**Test 7.2 — Tool Discovery Request**
```
Research new MCP servers that could improve Jarvis
```

**Expected**: Structured research with classification recommendations

### Validation Criteria
- [ ] Research command executes
- [ ] External sources scanned
- [ ] Classification applied
- [ ] Proposals generated (require approval)

---

## System 8: Maintenance Workflows (AC-08)

### Design Intent
- Five tasks: Cleanup, Freshness, Health, Organization, Optimization
- Dual scope: Jarvis AND active project
- Non-destructive (proposes, requires approval)

### Test Prompts

**Test 8.1 — Manual Maintenance**
```
/maintain
```

**Expected**: Maintenance task menu or execution

**Test 8.2 — Health Check**
```
Run a health check on Jarvis systems
```

**Expected**: Hook validation, settings check, MCP connectivity

**Test 8.3 — Freshness Audit**
```
Check documentation freshness
```

**Expected**: Stale docs identified, update suggestions

### Validation Criteria
- [ ] Maintenance command executes
- [ ] Cleanup tasks available
- [ ] Health checks functional
- [ ] Non-destructive (proposals, not actions)

---

## System 9: Session Completion (AC-09)

### Design Intent
- USER-PROMPTED ONLY
- Pre-completion offer for Tier 2 cycles
- Seven-step completion protocol

### Test Prompts

**Test 9.1 — Session End**
```
/end-session
```

**Expected**:
- Pre-completion offer (maintenance, reflection)
- Work state capture
- Memory persistence
- Git operations
- Handoff preparation

**Test 9.2 — Quick Exit**
```
/end-session --quick
```

**Expected**: Skip pre-completion offers, minimal handoff

### Validation Criteria
- [ ] Pre-completion offer displayed
- [ ] Work state captured
- [ ] Memory updated
- [ ] Checkpoint created
- [ ] Git commit (if changes)

---

## Orchestration Command

### Test 10 — Self-Improvement Orchestration

```
/self-improve
```

**Expected**: Orchestrated sequence through AC-05 → AC-08 → AC-07 → AC-06

---

## Implementation Status Summary

| System | Spec | Hook/Script | Command | Status |
|--------|------|-------------|---------|--------|
| AC-01 Self-Launch | ✅ | ✅ session-start.sh | — | ✅ **VALIDATED** |
| AC-02 Wiggum Loop | ✅ | ❌ (behavioral) | — | ❌ **NOT IMPLEMENTED** |
| AC-03 Milestone Review | ✅ | ✅ agents created | ❌ | NEEDS TESTING |
| AC-04 JICM | ✅ | ✅ context-accumulator.js | ✅ /context-budget | ✅ **VALIDATED** |
| AC-05 Self-Reflection | ✅ | ❌ | ✅ /reflect | NEEDS TESTING |
| AC-06 Self-Evolution | ✅ | ❌ | ✅ /evolve | NEEDS TESTING |
| AC-07 R&D Cycles | ✅ | ❌ | ✅ /research | NEEDS TESTING |
| AC-08 Maintenance | ✅ | ❌ | ✅ /maintain | NEEDS TESTING |
| AC-09 Session Completion | ✅ | ❌ | ✅ /end-session | ⚠️ **PARTIAL** |

**Key**: ✅ = Implemented/Validated, ❌ = Not implemented/Failed, PARTIAL = Some components exist

### Validation Summary (Updated 2026-01-16)

| System | Result | Key Finding |
|--------|--------|-------------|
| AC-01 | ✅ PASS | All 3 tests passed. Hook working. AIfred baseline check missing (documented gap). |
| AC-02 | ❌ FAIL | Pattern documented but NOT active. Single-pass behavior observed. Needs injection mechanism. |
| AC-04 | ✅ PASS | /context-budget and /context-checkpoint both working. Checkpoint resume triggers autonomous work! |
| AC-09 | ⚠️ PARTIAL | Exit procedure works (state update, git commit, push, summary). Missing: pre-completion Tier 2 offer. |

---

## Incremental Test Order

| Order | System | Priority | Notes |
|-------|--------|----------|-------|
| 1 | AC-01 Self-Launch | HIGH | ✅ VALIDATED |
| 2 | AC-02 Wiggum Loop | HIGH | Core work behavior (behavioral test) |
| 3 | AC-09 Session Completion | HIGH | Has /end-session command |
| 4 | AC-04 JICM | MEDIUM | Has /context-budget command |
| 5 | AC-08 Maintenance | MEDIUM | Design only - limited test |
| 6 | AC-05 Self-Reflection | LOW | Design only - limited test |
| 7 | AC-06 Self-Evolution | LOW | Design only - limited test |
| 8 | AC-07 R&D Cycles | LOW | Design only - limited test |
| 9 | AC-03 Milestone Review | LOW | Design only - limited test |

---

## Test Session Setup

In the second terminal:
```bash
cd ~/Claude/Jarvis
claude
```

Then enter test prompts one at a time, observing behavior.

---

*Autonomic Validation Test Plan — Jarvis Phase 6*
