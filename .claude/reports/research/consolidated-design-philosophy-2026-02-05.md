# Consolidated Design Philosophy Report

**Generated**: 2026-02-05
**Purpose**: Extract engineering principles for Jarvis reliability, predictability, and consistency
**Sources**: Vestige, Marvin, OpenClaw, AFK Code design philosophy analyses

---

## Executive Summary

Four codebases were analyzed not for *what* features they have, but *how* they achieve reliability:

| Project | Core Design Philosophy | Key Principle |
|---------|----------------------|---------------|
| **Vestige** | Science-driven architecture | Deterministic thresholds from research |
| **Marvin** | Workspace separation | File-based commands prevent drift |
| **OpenClaw** | Architectural restraint | Reliability from constraints |
| **AFK Code** | Transparency over automation | Relay, not decision-maker |

### The Meta-Pattern

All four systems achieve reliability through the same fundamental insight:

> **"Reliability comes from constraints, not capabilities."**

They succeed by:
- **Limiting** what can happen (serial execution, schema validation)
- **Enforcing** what must happen (mandatory workflows, invariants)
- **Documenting** what did happen (audit trails, session logs)

---

## Part 1: Behavior Consistency Patterns

### The Problem Jarvis Faces

Currently, Jarvis behavior can vary based on:
- Context window contents (what was discussed earlier)
- Model interpretation (how instructions are parsed)
- Ad-hoc decisions (choosing tools based on "what seems right")

### Solutions from Research

#### Pattern 1: File-Based Command Definitions (Marvin)

**Problem**: Commands defined in system prompts can drift over time.

**Solution**: Commands are markdown files (`.claude/commands/*.md`) that are loaded, not interpreted.

**Implementation for Jarvis**:
```
.claude/commands/
├── new-project.md      # Exactly what happens when user says "new project"
├── end-session.md      # Exactly what happens at session end
├── checkpoint.md       # Exactly what checkpoint involves
└── self-improve.md     # Exactly what self-improvement cycle does
```

Each command file specifies:
1. **Trigger conditions** (when this command fires)
2. **Required steps** (always executed, in order)
3. **Output template** (exact format of response)
4. **Validation criteria** (how to verify success)

#### Pattern 2: Schema-Enforced State (Marvin + OpenClaw)

**Problem**: State files can have inconsistent formats, causing parsing errors or missed information.

**Solution**: Validate state file schema on session start. Refuse to load corrupted state.

**Implementation for Jarvis**:
```yaml
# .claude/schemas/session-state.schema.yaml
required_sections:
  - "Current Work Status"
  - "Completed This Session"
  - "Next Steps"

required_fields:
  status: ["🟢 Active", "🟡 Paused", "🔴 Blocked", "✅ Complete"]

validation:
  on_load: fail_if_invalid
  on_save: validate_before_write
```

#### Pattern 3: Deterministic Thresholds (Vestige)

**Problem**: Decisions based on "feels right" vary between sessions.

**Solution**: Use research-derived or configured thresholds, not intuition.

**Implementation for Jarvis**:
```yaml
# .claude/config/thresholds.yaml
context_management:
  jicm_trigger_pct: 50          # Not "when it feels full"
  critical_pct: 80              # Not "when we should worry"

memory_decisions:
  similarity_reinforce: 0.92    # Not "very similar"
  similarity_update: 0.75       # Not "somewhat related"

task_selection:
  max_concurrent: 1             # Not "whatever fits"
  priority_order: [blockers, in_progress, pending]
```

#### Pattern 4: Explicit State Machines (Vestige + OpenClaw)

**Problem**: Session state is implicit ("we're kind of in the middle of something").

**Solution**: Define explicit states with documented transitions.

**Implementation for Jarvis**:
```
Session States:
┌──────────┐      ┌──────────┐      ┌───────────────┐      ┌──────────┐
│   INIT   │ ──── │  ACTIVE  │ ──── │ CTX_EXHAUSTION│ ──── │  ENDING  │
└──────────┘      └──────────┘      └───────────────┘      └──────────┘
     │                 │                    │                    │
     │                 │                    │                    │
     └─── AC-01 ───────┘                    └─── JICM ───────────┘
                                                 └─── AC-09 ──────┘

State transitions:
- INIT → ACTIVE: After AC-01 completes and user provides first instruction
- ACTIVE → CTX_EXHAUSTION: When JICM threshold reached
- CTX_EXHAUSTION → ACTIVE: After successful /intelligent-compress
- ACTIVE → ENDING: When user invokes /end-session or session timeout
```

---

## Part 2: Documentation System

### The Problem Jarvis Faces

Documentation is currently:
- Scattered across multiple files
- Updated inconsistently
- Format varies between entries

### Solutions from Research

#### Pattern 5: Date-Based Session Logs (Marvin)

**Problem**: `session-state.md` is overwritten each session—no history.

**Solution**: Append to `sessions/YYYY-MM-DD.md` files.

**Implementation for Jarvis**:
```
.claude/sessions/
├── 2026-02-05.md    # Today's sessions (multiple entries)
├── 2026-02-04.md    # Yesterday
└── 2026-02-03.md    # Earlier
```

**Session Log Schema**:
```markdown
# Session Log: 2026-02-05

## Session 1: 09:15 - 14:30

### Objectives
- [What we set out to do]

### Completed
- [x] Task 1
- [x] Task 2

### Decisions Made
- [Why we chose X over Y]

### Blockers Encountered
- [What stopped progress]

### Context at End
- Tokens: 156,734 (78%)
- JICM triggers: 2
- Commits: f83c128, f9df991

---

## Session 2: 15:00 - ...
```

#### Pattern 6: Mandatory Metadata Capture (Marvin)

**Problem**: Some sessions are documented thoroughly, others sparsely.

**Solution**: Define mandatory fields that MUST be captured.

**Implementation for Jarvis**:
```yaml
# .claude/schemas/session-log.schema.yaml
mandatory_per_session:
  - start_time
  - end_time
  - primary_objective
  - completion_status: [complete, partial, blocked, abandoned]
  - tokens_used
  - commits_made

mandatory_per_task:
  - task_description
  - approach_taken
  - outcome: [success, partial, failed]
  - time_estimate_vs_actual
```

#### Pattern 7: JSONL Audit Trails (OpenClaw + AFK Code)

**Problem**: No tamper-proof record of what Jarvis actually did.

**Solution**: Append-only JSONL logs alongside human-readable markdown.

**Implementation for Jarvis**:
```
.claude/logs/
├── audit-2026-02-05.jsonl    # Machine-readable actions
├── decisions-2026-02-05.jsonl # Autonomous decisions made
└── errors-2026-02-05.jsonl    # Failures and recoveries
```

**Audit Entry Schema**:
```json
{
  "timestamp": "2026-02-05T14:32:15Z",
  "action": "tool_invocation",
  "tool": "Bash",
  "command": "git commit -m '...'",
  "outcome": "success",
  "tokens_before": 145000,
  "tokens_after": 145500,
  "session_id": "abc123"
}
```

---

## Part 3: Tool Selection Logic

### The Problem Jarvis Faces

Tool selection can become habitual:
- Using Bash when specialized tool exists
- Using grep when Grep tool is available
- Choosing "familiar" approaches over optimal ones

### Solutions from Research

#### Pattern 8: Tool Selection Decision Tree (OpenClaw)

**Problem**: Ad-hoc tool selection leads to inconsistent behavior.

**Solution**: Explicit decision tree for tool selection.

**Implementation for Jarvis**:
```
Tool Selection Protocol:

1. FILE OPERATIONS
   ├── Read file content? → Read tool (NEVER cat/head/tail)
   ├── Search file contents? → Grep tool (NEVER grep/rg in Bash)
   ├── Find files by pattern? → Glob tool (NEVER find in Bash)
   ├── Edit existing file? → Edit tool (NEVER sed/awk)
   └── Create new file? → Write tool (NEVER echo/cat heredoc)

2. EXPLORATION
   ├── Open-ended search? → Task tool (Explore agent)
   ├── Specific class/function? → Glob + Read
   └── Understanding codebase? → Task tool (Explore agent)

3. RESEARCH
   ├── Web information needed? → WebSearch + WebFetch
   ├── GitHub repo info? → gh CLI via Bash
   └── Complex multi-source? → Task tool (deep-research agent)

4. EXECUTION
   ├── Git operations? → Bash (git commands)
   ├── npm/docker/system? → Bash
   └── Multi-step task? → TodoWrite + sequential execution
```

#### Pattern 9: Tool Preference Hierarchy (Vestige)

**Problem**: Multiple tools can accomplish the same task.

**Solution**: Define explicit preference order.

**Implementation for Jarvis**:
```yaml
# .claude/config/tool-preferences.yaml
file_reading:
  prefer: [Read]
  avoid: [Bash cat, Bash head, Bash tail]
  reason: "Read tool provides line numbers, handles large files"

content_search:
  prefer: [Grep]
  avoid: [Bash grep, Bash rg]
  reason: "Grep tool is optimized for permissions and output format"

file_finding:
  prefer: [Glob]
  avoid: [Bash find, Bash ls]
  reason: "Glob is faster and handles patterns correctly"

codebase_exploration:
  prefer: [Task:Explore]
  condition: "When search may require multiple rounds"
  avoid: [Direct Grep/Glob for open-ended searches]
```

---

## Part 4: Autonomic Trigger Design

### The Problem Jarvis Faces

Autonomic components (AC-01 through AC-09) fire inconsistently:
- Sometimes AC-01 runs fully, sometimes partially
- JICM triggers at varying thresholds
- Self-improvement cycles are manual

### Solutions from Research

#### Pattern 10: Event-Driven Hooks (OpenClaw)

**Problem**: Autonomic behaviors are embedded in system prompt, not enforced.

**Solution**: Event-driven hooks that ALWAYS fire on specific events.

**Implementation for Jarvis**:
```yaml
# .claude/config/autonomic-triggers.yaml
events:
  session:start:
    - hook: AC-01-launch
      required: true
      timeout: 30s
      on_failure: warn_user

  context:threshold_50:
    - hook: jicm-prepare
      required: true

  context:threshold_80:
    - hook: jicm-compress
      required: true

  task:complete:
    - hook: AC-03-review
      required: false  # Can be skipped

  session:end:
    - hook: AC-09-completion
      required: true
      steps:
        - update_session_state
        - write_session_log
        - commit_changes
        - document_learnings
```

#### Pattern 11: Workflow Templates (Marvin)

**Problem**: "New project" setup varies each time.

**Solution**: Mandatory workflow templates for common operations.

**Implementation for Jarvis**:
```markdown
# .claude/workflows/new-project.md

## Trigger
User requests new project creation

## Required Steps (ALWAYS execute in order)

### 1. Clarification (if needed)
- [ ] Project name confirmed
- [ ] Project type identified (web, CLI, library, service)
- [ ] Primary language/framework confirmed

### 2. Structure Creation
- [ ] Create project directory: `projects/{name}/`
- [ ] Create subdirectories: docs/, src/, tests/
- [ ] Create README.md with standard template
- [ ] Create roadmap.md with phases
- [ ] Create chronicle.md for progress tracking

### 3. Configuration
- [ ] Add to planning-tracker.yaml
- [ ] Create project-specific CLAUDE.md if needed
- [ ] Initialize git if not in repo

### 4. Documentation
- [ ] Update current-priorities.md
- [ ] Log project creation in session log

### 5. Confirmation
- [ ] Present project structure to user
- [ ] Confirm next steps

## Output Template
"Project {name} created at projects/{name}/ with:
- README.md (overview)
- roadmap.md (phases and milestones)
- chronicle.md (progress tracking)

Next suggested action: Define Phase 1 objectives in roadmap.md"
```

---

## Part 5: Failure Handling Philosophy

### The Problem Jarvis Faces

Failures are handled inconsistently:
- Sometimes retried silently
- Sometimes reported to user
- Sometimes cause cascade failures

### Solutions from Research

#### Pattern 12: Graceful Degradation Hierarchy (AFK Code + OpenClaw)

**Problem**: Component failures cascade to system failure.

**Solution**: Define degradation hierarchy—what fails first, what's protected.

**Implementation for Jarvis**:
```
Degradation Hierarchy (fail in order):

LEVEL 1 - OPTIONAL (fail silently, log)
├── Memory MCP unavailable → Continue without memory queries
├── WebSearch fails → Note limitation, use cached knowledge
└── Subagent timeout → Report partial results

LEVEL 2 - DEGRADED (warn user, continue)
├── Hook execution fails → Log error, skip hook, continue
├── MCP tool fails → Fallback to Bash equivalent
└── Git operation fails → Warn user, suggest manual action

LEVEL 3 - CRITICAL (stop, require intervention)
├── Session state corrupted → Refuse to load, require recovery
├── Context >95% → Force compression before any action
└── Repeated tool failures → Stop, diagnose, report

LEVEL 4 - PROTECTED (never compromised)
├── User data integrity
├── Git repository safety (no force push main)
└── Credential security
```

#### Pattern 13: Circuit Breaker Pattern (AFK Code)

**Problem**: Retrying failing operations wastes resources and time.

**Solution**: Circuit breaker stops retries after threshold.

**Implementation for Jarvis**:
```yaml
# .claude/config/circuit-breakers.yaml
mcp_calls:
  max_consecutive_failures: 3
  reset_after: 300s  # 5 minutes
  on_open: "Skip MCP, use local fallback"

web_fetch:
  max_consecutive_failures: 2
  reset_after: 60s
  on_open: "Report URL inaccessible, continue without"

subagent_spawn:
  max_consecutive_failures: 2
  reset_after: 120s
  on_open: "Handle task directly instead of delegating"
```

#### Pattern 14: Explicit Recovery Procedures (Vestige)

**Problem**: Recovery from failures is improvised.

**Solution**: Document specific recovery procedures.

**Implementation for Jarvis**:
```markdown
# .claude/recovery/session-state-corruption.md

## Symptoms
- Session start fails with parse error
- "Current Work Status" section missing
- Invalid status value

## Automatic Recovery
1. Attempt to load from `.claude/sessions/` archive
2. If archive exists, reconstruct session-state.md
3. If no archive, create minimal valid state

## Manual Recovery
1. Check git history: `git log --oneline .claude/context/session-state.md`
2. Restore from commit: `git checkout <commit> -- .claude/context/session-state.md`
3. Validate restored file
4. Resume session

## Prevention
- Always validate before writing
- Keep 3 most recent versions in .backup/
```

---

## Part 6: Implementation Roadmap

### Phase 1: Foundation (Week 1-2)

**Goal**: Establish consistency infrastructure

| Task | Priority | Effort | Impact |
|------|----------|--------|--------|
| Create session log archive system | HIGH | 3 hrs | Historical continuity |
| Add state file schema validation | HIGH | 4 hrs | Corruption prevention |
| Define explicit session state machine | HIGH | 2 hrs | Clear transitions |
| Create tool selection decision tree | MEDIUM | 2 hrs | Consistent tool use |

### Phase 2: Workflows (Week 3-4)

**Goal**: Standardize common operations

| Task | Priority | Effort | Impact |
|------|----------|--------|--------|
| Create `/new-project` workflow template | HIGH | 3 hrs | Consistent project setup |
| Create `/end-session` workflow template | HIGH | 2 hrs | Consistent closure |
| Create `/checkpoint` workflow template | MEDIUM | 2 hrs | Consistent checkpointing |
| Migrate commands to file-based definitions | MEDIUM | 4 hrs | Drift prevention |

### Phase 3: Reliability (Week 5-6)

**Goal**: Handle failures gracefully

| Task | Priority | Effort | Impact |
|------|----------|--------|--------|
| Implement circuit breakers for MCPs | MEDIUM | 3 hrs | Failure isolation |
| Define degradation hierarchy | MEDIUM | 2 hrs | Clear failure modes |
| Create recovery procedures | MEDIUM | 4 hrs | Documented recovery |
| Add pre-compaction memory flush to JICM | HIGH | 3 hrs | Data preservation |

### Phase 4: Observability (Week 7-8)

**Goal**: Know what Jarvis is doing

| Task | Priority | Effort | Impact |
|------|----------|--------|--------|
| Implement JSONL audit logging | MEDIUM | 4 hrs | Action traceability |
| Add token/cost tracking per session | MEDIUM | 3 hrs | Resource visibility |
| Create health status endpoint | LOW | 2 hrs | Monitoring capability |
| Build metrics dashboard (JSON file) | LOW | 3 hrs | Performance insights |

---

## Summary: The Jarvis Reliability Framework

### Core Principles (Adopted from Research)

1. **Constraints Over Capabilities**: Limit what can happen to ensure what should happen
2. **Schemas Over Interpretation**: Validate structure, don't guess format
3. **Thresholds Over Intuition**: Use configured values, not "feels right"
4. **Files Over Prompts**: Commands in files prevent drift
5. **Logs Over Memory**: What's written persists, what's remembered doesn't
6. **Degradation Over Failure**: Partial function beats total failure

### Measurement Criteria

**Reliability**: Same input → same output (deterministic)
**Predictability**: User knows what will happen before it happens
**Consistency**: Every invocation follows same workflow
**Traceability**: Every action is logged and auditable
**Recoverability**: Every failure has documented recovery path

### Anti-Patterns to Avoid

1. **Vibe Coding**: Shipping without review
2. **Intuitive Thresholds**: "When it feels right"
3. **Ad-hoc Tool Selection**: "Whatever works"
4. **Silent Failures**: Errors without notification
5. **State Drift**: Format changes over time
6. **Memory-Only Documentation**: Relying on context window

---

## Individual Report References

| Project | Design Philosophy Report | Size |
|---------|--------------------------|------|
| Vestige | `vestige-design-philosophy-2026-02-05.md` | 695 lines |
| Marvin | `marvin-design-philosophy-2026-02-05.md` | 1,087 lines |
| OpenClaw | `openclaw-design-philosophy-2026-02-05.md` | 42KB |
| OpenClaw | `openclaw-key-takeaways.md` | 7.4KB |
| AFK Code | `afk-code-design-philosophy-2026-02-05.md` | 830 lines |

---

*Jarvis Reliability Framework — Synthesized from 4 codebase analyses*
*"Move deliberately and maintain invariants"*
