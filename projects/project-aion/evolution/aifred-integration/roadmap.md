# AIfred-Jarvis Comprehensive Integration Roadmap

**Generated**: 2026-01-21
**Version**: 2.0 (Revised based on feedback)
**Scope**: Complete analysis, corrections, and phased integration plan

---

## Document Purpose

This roadmap supersedes the initial analysis documents with:

1. **Corrections** to factual errors in original analysis
2. **Dedicated reports** for major AIfred subsystems
3. **Auto-* wrapper refactoring proposal**
4. **Phased integration plan** with research, testing, and finishing stages

---

# PART 1: CORRECTIONS TO ORIGINAL ANALYSIS

## 1.1 Factual Corrections

| Original Claim                                     | Correction                                                                                                                                         |
| -------------------------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------- |
| "context-accumulator.js was removed"               | **FALSE** — `context-accumulator.js` EXISTS in Jarvis and is a core JICM component (517 lines)                                            |
| "prompt-enhancer.js overlaps with selection-audit" | **FALSE** — `selection-audit.js` logs tool selections to JSONL; `prompt-enhancer.js` injects guidance pre-tool-use. Different purposes. |
| "AIfred has skills in .claude/skills/"             | **FALSE** — AIfred has NO skills directory. The skills listed are JARVIS additions.                                                         |
| "session-start.js in Jarvis"                       | **Correction** — Jarvis uses `session-start.sh` (shell script, 522 lines) not a .js hook                                                  |

## 1.2 Architectural Clarifications

### Jarvis Session Startup Architecture

Jarvis uses a **shell script** (`session-start.sh`) for AC-01 Self-Launch Protocol:

- Weather integration
- AIfred baseline sync check
- Environment validation
- JICM reset on startup/clear
- Checkpoint/compressed context restoration
- MCP suggestions

**AIfred** uses a **JavaScript hook** (`session-start.js`) with simpler functionality:

- Read session-state.md and current-priorities.md
- Get git branch and uncommitted count
- Inject as additionalContext

**Decision**: Keep Jarvis approach — more comprehensive.

### Jarvis Has No Overlapping File-Access Tracker

Jarvis does NOT have a dedicated file-access tracker. The `selection-audit.js` tracks:

- Task delegations
- Skill invocations
- MCP tool selections
- WebSearch/WebFetch calls

But NOT file read patterns. **AIfred's `file-access-tracker.js` fills this gap**.

## 1.3 Docker-Specific Hooks Naming

The following AIfred hooks are Docker-specific and should be renamed for clarity:

| Current Name                 | Proposed Name                       | Function                                      |
| ---------------------------- | ----------------------------------- | --------------------------------------------- |
| `health-monitor.js`        | `docker-health-monitor.js`        | Monitors container health status changes      |
| `restart-loop-detector.js` | `docker-restart-loop-detector.js` | Detects containers in restart loops           |
| `docker-health-check.js`   | `docker-post-op-health.js`        | Checks container health after docker commands |

---

# PART 2: DEDICATED SUBSYSTEM REPORTS

## 2.1 Parallel Development System (`/parallel-dev`)

### Overview

A complete workflow for autonomous parallel development using git worktrees and multiple agents.

### Components

| Category  | Count | Details                                                            |
| --------- | ----- | ------------------------------------------------------------------ |
| Commands  | 14    | init, start, status, plan, decompose, validate, merge, etc.        |
| Agents    | 4     | implementer, tester, documenter, validator                         |
| Templates | 5     | plan, tasks, execution-state, validation-config, validation-report |
| Config    | 1     | config.json (worktree paths, agent settings)                       |

### Workflow Architecture

```
User Request
    ↓
/parallel-dev:plan → Guided requirement gathering (asks ALL questions upfront)
    ↓
/parallel-dev:decompose → Task breakdown with dependencies (YAML)
    ↓
/parallel-dev:start → Creates git worktree, spawns agents
    ↓
┌─────────────────────────────────────────────────────────────────────┐
│ Parallel Agent Execution (up to 5 concurrent)                       │
│ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐ ┌──────────────┐│
│ │ Implementer  │ │   Tester     │ │ Documenter   │ │  Validator   ││
│ │   Agent      │ │   Agent      │ │   Agent      │ │   Agent      ││
│ │ (code impl)  │ │ (test write) │ │ (docs update)│ │ (QA checks)  ││
│ └──────────────┘ └──────────────┘ └──────────────┘ └──────────────┘│
└─────────────────────────────────────────────────────────────────────┘
    ↓
/parallel-dev:validate → Lint, typecheck, test, build, acceptance criteria
    ↓
/parallel-dev:merge → Conflict resolution, cleanup worktrees
```

### Key Innovations

1. **All Questions Upfront**: Planning phase gathers ALL requirements before work begins
2. **Git Worktree Isolation**: True filesystem isolation for parallel work
3. **Structured Task Decomposition**: YAML-based task dependencies
4. **Multi-Agent Orchestration**: Up to 5 agents working simultaneously
5. **Validation Pipeline**: Comprehensive QA before merge

### Integration with Jarvis

**Recommendation**: Coexist with Wiggum Loop, not replace it.

| Mode                   | Use When                                                     |
| ---------------------- | ------------------------------------------------------------ |
| **Wiggum Loop**  | Sequential work requiring multi-pass verification            |
| **Parallel-Dev** | Large features benefiting from parallelization               |
| **Combined**     | Parallel-dev execution WITH Wiggum Loop validation per-agent |

### Implementation Effort

**Estimated**: 8-16 hours for full integration including:

- Port all 14 commands
- Port 4 agents with Jarvis naming
- Create Jarvis-specific config
- Integrate with existing orchestration
- Test worktree management

---

## 2.2 Structured Planning System (`/plan`)

### Overview

Guided conversational planning with dynamic question depth for new designs, system reviews, and feature development.

### Components

| Category  | Count | Details                                       |
| --------- | ----- | --------------------------------------------- |
| Commands  | 4     | /plan, /plan:new, /plan:review, /plan:feature |
| Templates | 4     | question-bank.yaml (12KB), spec templates     |
| Tools     | 1     | TypeScript CLI (index.ts - 13KB)              |
| Config    | 1     | config.json (paths, depth settings)           |

### Three Planning Modes

| Mode                    | Purpose                 | Output                                                            |
| ----------------------- | ----------------------- | ----------------------------------------------------------------- |
| **New Design**    | Build from scratch      | Full specification (Vision, Scope, Technical, Constraints, Risks) |
| **System Review** | Assess existing system  | Review findings (Current State, Pain Points, Gap Analysis)        |
| **Feature**       | Add to existing project | Lighter spec (Feature Scope, Integration, Acceptance)             |

### Dynamic Depth System

Questions auto-calibrate based on answer complexity:

- **Minimal**: Quick mode, minimal questions
- **Auto** (default): Adjust based on signals
- **Comprehensive**: Full question battery

**Complexity Signals**: Uncertainty, multiple stakeholders, integrations, scale, security concerns

### Integration with Jarvis

**Relationship to Orchestration**:

- `/plan` creates specifications
- Orchestration converts specs to task breakdown
- Could integrate: `/plan` → auto-generate `/orchestration:plan`

**Effort**: 2-4 hours for adaptation

---

## 2.3 Upgrade Self-Improvement System (`/upgrade`)

### Overview

Self-improvement system for discovering and applying updates from Claude Code, libraries, and infrastructure.

### Workflow Phases

```
PHASE 1: DISCOVER
  /upgrade discover
  └── Fetch external sources (GitHub, docs, blogs)
  └── Compare against baselines.json
  └── Store discoveries in pending-upgrades.json

PHASE 2: ANALYZE
  /upgrade analyze
  └── Score relevance (category match, recency, security, breaking changes)
  └── Prioritize by value/effort ratio

PHASE 3: PROPOSE
  /upgrade propose [id]
  └── Generate implementation plan
  └── Identify files to modify
  └── Assess risks and rollback strategy

PHASE 4: IMPLEMENT
  /upgrade implement <id>
  └── Create git checkpoint (pre-UP-xxx tag)
  └── Apply changes
  └── Run validation
  └── Log to upgrade-history.jsonl

PHASE 5: VERIFY
  └── Capture learning
  └── Update Memory MCP
  └── Store in TELOS if goal-relevant
```

### Scheduled Execution

```bash
# Weekly discovery - Sunday 6:00 AM via cron
0 6 * * 0 claude-scheduled.sh upgrade-discover
```

Uses AIfred's **autonomous-execution-pattern** with "analyze" permission tier.

### Comparison with Jarvis Self-Improvement

| Aspect              | AIfred /upgrade                           | Jarvis /evolve + /self-improve                      |
| ------------------- | ----------------------------------------- | --------------------------------------------------- |
| **Focus**     | External updates (Claude Code, MCP, libs) | Internal improvements (patterns, hooks, efficiency) |
| **Discovery** | Web scraping, API checks                  | Session analysis, corrections review                |
| **Trigger**   | Scheduled (cron)                          | Manual or downtime-triggered                        |
| **Approval**  | Per-upgrade user approval                 | Risk-based (auto for low-risk)                      |

### Integration Recommendation

**Merge into unified self-improvement system**:

1. Keep Jarvis AC-05/06/07/08 for internal improvement
2. Add AIfred's external discovery phase to AC-07 R&D Cycles
3. Scheduled automation via autonomous-execution-pattern
4. Unified proposal queue with risk-based approval

**Effort**: 4-6 hours

---

## 2.4 TELOS Strategic Framework (`/telos`)

### Overview

Strategic goal alignment framework providing a layer above tactical priorities.

### Architecture

```
TELOS (Strategic - Quarterly)
    │
    ├── Identity Statements
    │   └── Mission, vision, values
    │
    ├── Domains
    │   ├── Technical (infrastructure, tools, efficiency)
    │   ├── Creative (projects, explorations)
    │   └── Personal (learning, growth)
    │
    ├── Goals (per domain)
    │   ├── G-T1: Infrastructure Maturity
    │   ├── G-T2: Development Velocity
    │   └── ...
    │
    └── Anti-Goals (scope prevention)
        └── What NOT to do
    │
    ↓
current-priorities.md (Tactical - Weekly)
    │
    ↓
session-state.md (Operational - Session)
```

### Key Features

1. **Quarterly Focus**: Review and update quarterly
2. **Domain Organization**: Separate technical, creative, personal goals
3. **Anti-Goals**: Explicit "don't do" list to prevent scope creep
4. **Metrics Dashboard**: Track goal progress
5. **Operational Reviews**: Weekly and monthly review workflows

### Integration with Jarvis

**Fits ABOVE existing structure**:

- `roadmap.md` → Project-level milestones
- `current-priorities.md` → Weekly tactical tasks
- **TELOS** → Quarterly strategic direction

**Integration Points**:

- Link goals to roadmap milestones
- Reference TELOS in session-start for context
- Use in `/reflect` to check goal alignment

**Effort**: 4-8 hours for adaptation

---

## 2.5 Context Analysis (`/context-analyze`)

### What It Does

Analyzes Claude Code context usage patterns using:

1. **Session Statistics** — Tool usage from audit logs
2. **File Size Analysis** — CLAUDE.md and context/ files
3. **Git Churn** — Frequently modified files
4. **Auto-Archive** — Old logs (>365 days)
5. **Auto-Reduce** — Large context files using **Ollama** (local LLM)

### Key Difference from JICM

| Aspect              | /context-analyze            | JICM (Jarvis)                |
| ------------------- | --------------------------- | ---------------------------- |
| **Purpose**   | Weekly maintenance analysis | Real-time context management |
| **Trigger**   | Scheduled (cron) or manual  | Automatic on threshold       |
| **Reduction** | Ollama-based summarization  | Claude-based compression     |
| **Scope**     | File-level analysis         | Session-level tracking       |

### Integration

**Complement to JICM**, not replacement:

- Run weekly for file-level optimization
- Identify context growth patterns
- Generate reports for manual review
- Ollama handles reduction (cost-free)

**Effort**: 1-2 hours (adapt script paths)

---

## 2.6 Codebase Analysis (`/analyze-codebase`)

### What It Does

Systematically analyzes a codebase and generates modification-ready documentation:

- `_index.md` — Quick reference, navigation, common tasks
- `architecture.md` — Mermaid diagrams
- `modification-guide.md` — Where to change what
- `key-files.md` — Important files reference

### Analysis Depths

| Depth    | Time      | Mermaid Diagrams | Function Mapping |
| -------- | --------- | ---------------- | ---------------- |
| Quick    | 2-5 min   | 2                | No               |
| Standard | 5-15 min  | 5-6              | No               |
| Deep     | 15-30 min | 8+               | Yes              |

### How It Differs from code-review Agent

| Aspect             | /analyze-codebase                        | code-review agent         |
| ------------------ | ---------------------------------------- | ------------------------- |
| **Purpose**  | Generate documentation for understanding | Review code quality       |
| **Output**   | Markdown docs with diagrams              | Quality assessment report |
| **Scope**    | Entire codebase structure                | Specific changes/files    |
| **Use Case** | Onboarding to new project                | PR/milestone reviews      |

### Integration

**Port directly** — fills documentation generation gap in Jarvis.

**Effort**: 1-2 hours

---

# PART 3: AUTO-* WRAPPER REFACTORING PROPOSAL

## 3.1 Current Problem

Jarvis has 17 auto-* commands:

- auto-usage, auto-context, auto-cost, auto-stats, auto-doctor
- auto-todos, auto-review, auto-security-review, auto-export
- auto-bashes, auto-hooks, auto-release-notes, auto-rename
- auto-resume, auto-plan, auto-status, auto-settings

**Issues**:

1. Command bloat (17 commands that wrap built-in commands)
2. Each requires separate skill registration
3. Maintenance overhead for each wrapper
4. New Claude Code commands need new auto-* versions

## 3.2 Proposed Solution: Universal Autonomous Wrapper

### Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│  User/Jarvis Request: "run /status autonomously"                    │
├─────────────────────────────────────────────────────────────────────┤
│  1. Jarvis checks if command is blocklisted                         │
│     └── Blocklist: /settings (interactive), /edit (opens editor)   │
├─────────────────────────────────────────────────────────────────────┤
│  2. If allowed, creates signal file with command                    │
│     └── .claude/context/.command-signal { "command": "/status" }    │
├─────────────────────────────────────────────────────────────────────┤
│  3. auto-command-watcher.sh detects signal                          │
│     └── Polls every 2 seconds                                       │
├─────────────────────────────────────────────────────────────────────┤
│  4. Watcher injects keystroke via tmux                              │
│     └── tmux send-keys -t jarvis "/status" Enter                    │
├─────────────────────────────────────────────────────────────────────┤
│  5. Claude Code executes command, work continues                    │
└─────────────────────────────────────────────────────────────────────┘
```

### Implementation

**New Skill**: `universal-autonomous-command`

```markdown
# Universal Autonomous Command Skill

Execute ANY Claude Code slash command autonomously via signal-based watcher.

## Usage

```bash
# Via signal helper
source .claude/scripts/signal-helper.sh && signal_command "/status"
source .claude/scripts/signal-helper.sh && signal_command "/rename My Session"
source .claude/scripts/signal-helper.sh && signal_command "/export session.md"
```

## Blocked Commands

Commands that require interactive input or don't produce AI-useable output:

| Command   | Reason                 |
| --------- | ---------------------- |
| /settings | Opens interactive menu |
| /edit     | Opens text editor      |
| /help     | Static help text       |
| /config   | Opens interactive menu |

```

### signal-helper.sh Enhancement

```bash
# Add universal signal function
signal_command() {
    local cmd="$1"

    # Check blocklist
    BLOCKED_COMMANDS=("/settings" "/edit" "/help" "/config")
    for blocked in "${BLOCKED_COMMANDS[@]}"; do
        if [[ "$cmd" == "$blocked"* ]]; then
            echo "ERROR: $blocked is blocked from autonomous execution"
            return 1
        fi
    done

    # Create signal
    echo "{\"command\": \"$cmd\", \"timestamp\": \"$(date -Iseconds)\"}" > \
        "$CLAUDE_PROJECT_DIR/.claude/context/.command-signal"

    echo "Signal sent for: $cmd"
}
```

### Migration Plan

1. **Keep existing auto-* commands** temporarily for backwards compatibility
2. **Implement universal wrapper** as new primary approach
3. **Deprecate auto-* commands** after testing
4. **Archive auto-* commands** after confirmation period

### Benefits

1. **Single implementation** handles all commands
2. **No new skills needed** for new Claude Code commands
3. **Blocklist-based security** instead of allowlist
4. **Simpler maintenance** — one file to update

**Effort**: 2-3 hours

---

# PART 4: ADDITIONAL FEEDBACK RESPONSES

## 4.1 credential-guard.js and Jarvis Credentials

**Concern**: Don't block Jarvis' own credential files.

**Solution**: Add Jarvis-specific exclusions:

```javascript
const JARVIS_ALLOWED = [
  '.claude/config/',           // Jarvis config files
  '.claude/state/',            // State files
  'paths-registry.yaml'        // Project registry
];
```

## 4.2 Integration of pre-compact.js with JICM

**Proposal**: Use AIfred's static file list as JICM baseline.

```javascript
// In context-accumulator.js or context-compressor agent
const ALWAYS_PRESERVE = [
  'session-state.md',          // Current work
  'current-priorities.md',     // Task queue
  'recent-blockers.md'         // Known issues
];
```

JICM can use this as minimum preservation set while still doing dynamic compression.

## 4.3 session-exit-enforcer.js for End-Session

**Recommendation**: Adapt functionality into `/end-session` command.

Current Jarvis `/end-session` already has exit checklist. Consider adding:

- Activity tracking from session-exit-enforcer
- Files modified count
- Memory updates count
- Exit completeness score

## 4.4 session-tracker.js for Self-Learning

**Value**: Session lifecycle events can feed into self-reflection:

- Session duration patterns
- Error frequency trends
- Work type distribution

**Integration**: Pipe to telemetry-emitter for unified logging.

## 4.5 /capture Command for Learnings

**Current Jarvis State**: `/reflect` captures learnings, but no dedicated `/capture` command.

**Recommendation**: Port AIfred's `/capture` for:

- Explicit learning capture
- Decision documentation
- Pattern recording
- Merge into Memory MCP

## 4.6 /audit-log for Autonomous Log Analysis

**Concept**: Make log analysis autonomous so Jarvis can:

- Query own logs
- Transform to clean database
- Generate usage reports
- Feed into self-reflection

**Implementation**: Add to R&D Cycles (AC-07) or Maintenance (AC-08).

## 4.7 /self-improve vs /evolve Clarification

| Command                 | Scope                                                                    | Duration   |
| ----------------------- | ------------------------------------------------------------------------ | ---------- |
| **/self-improve** | Meta-orchestrator running ALL AC systems (AC-05, 06, 07, 08) in sequence | 20-120 min |
| **/evolve**       | Single system (AC-06) — implement queued proposals                      | 20-60 min  |

**/self-improve** = `/reflect` → `/maintain` → `/research` → `/evolve`

## 4.8 Jarvis Utility Command Redundancy Report

**Request**: Collapse closely related utilities.

| Category           | Commands                                                             | Recommendation                                    |
| ------------------ | -------------------------------------------------------------------- | ------------------------------------------------- |
| Context Management | /checkpoint, /smart-checkpoint, /context-checkpoint                  | Consolidate to `/checkpoint` with flags         |
| Compaction         | /jicm-compact, /smart-compact, /intelligent-compress, /trigger-clear | Consolidate to `/compact` with JICM integration |
| Status             | /status, /tooling-health, /health-report                             | Keep separate — different scopes                 |
| Validation         | /validate-selection, /setup-readiness                                | Keep separate — different purposes               |

## 4.9 MCP Decomposer Tool

**Current State**: Jarvis has `plugin-decompose.sh` for plugins.

**Request**: MCP decomposer to:

- Analyze MCP servers
- Identify if MCP serving is actually required
- Extract tool logic to direct Claude tools
- Reduce MCP overhead

**Recommendation**: Create `mcp-decompose` skill or extend plugin-decompose.

**Effort**: 4-6 hours

## 4.10 Autonomous Execution Pattern Clarification

**Purpose**: Scheduled headless Claude CLI execution.

**NOT** the same as Jarvis autonomic components (AC-01 through AC-09).

**Use Cases**:

- Overnight maintenance runs
- Weekly context analysis
- Scheduled upgrade discovery
- Periodic health checks

**Key Feature**: Permission tiers (Discovery/Analyze/Implement) control what Claude can do.

---

# PART 5: DESIGN PHILOSOPHY INTEGRATION

## 5.1 Parallel-Dev + Wiggum Loop Coexistence

**Your Suggestion**: Let parallel-dev work AS Wiggum loops.

**Architecture**:

```
User Request
    ↓
/parallel-dev:plan (optional: --with-wiggum)
    ↓
/parallel-dev:start
    ↓
┌─────────────────────────────────────────────────────────────────────┐
│ For each parallel agent:                                             │
│                                                                       │
│   ┌─────────────────────────────────────────────────────────────┐   │
│   │ WIGGUM LOOP WRAPPER                                          │   │
│   │                                                               │   │
│   │   Execute (implement/test/document)                          │   │
│   │       ↓                                                       │   │
│   │   Check (verify it works)                                    │   │
│   │       ↓                                                       │   │
│   │   Review (self-review for quality)                           │   │
│   │       ↓                                                       │   │
│   │   Drift Check (still aligned with task?)                     │   │
│   │       ↓                                                       │   │
│   │   Context Check (near limit?)                                │   │
│   │       ↓                                                       │   │
│   │   Continue/Complete                                          │   │
│   │                                                               │   │
│   └─────────────────────────────────────────────────────────────┘   │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
    ↓
/parallel-dev:validate (overall QA)
    ↓
/parallel-dev:merge
```

**Benefits**:

- Parallel execution for speed
- Wiggum Loop per-agent for quality
- Best of both approaches

## 5.2 Capability Layering Pattern Integration

**AIfred Pattern** (Code Before Prompts):

```
LAYER 1 (Idea): Capability goal
LAYER 2 (Code): Bash/Python/TypeScript implementation
LAYER 3 (CLI): Bash-callable with arguments
LAYER 4 (Prompt): Slash command routes to CLI
LAYER 5 (User Request): Natural language triggers prompt
```

**Integration**: Document in Jarvis patterns, reference in skill-creator.

## 5.3 Tracking System Unification

**Proposal**: Unified logging architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    JARVIS UNIFIED LOGGING                            │
├─────────────────────────────────────────────────────────────────────┤
│                                                                       │
│  SOURCES:                                                            │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │ audit-logger.js  │  │ telemetry-emitter│  │ file-access-     │  │
│  │ (tool execution) │  │ (AC components)  │  │ tracker.js       │  │
│  └────────┬─────────┘  └────────┬─────────┘  └────────┬─────────┘  │
│           │                      │                      │            │
│           ▼                      ▼                      ▼            │
│  ┌───────────────────────────────────────────────────────────────┐  │
│  │                   UNIFIED EVENT STREAM                         │  │
│  │                   .claude/logs/events.jsonl                    │  │
│  └───────────────────────────────────────────────────────────────┘  │
│                                  │                                    │
│           ┌──────────────────────┼──────────────────────┐            │
│           ▼                      ▼                      ▼            │
│  ┌──────────────────┐  ┌──────────────────┐  ┌──────────────────┐  │
│  │ Analysis         │  │ Self-Reflection  │  │ Reports          │  │
│  │ (patterns,       │  │ (AC-05 input)    │  │ (dashboards)     │  │
│  │  efficiency)     │  │                  │  │                  │  │
│  └──────────────────┘  └──────────────────┘  └──────────────────┘  │
│                                                                       │
└─────────────────────────────────────────────────────────────────────┘
```

---

# PART 6: PHASED INTEGRATION ROADMAP

## Phase 1: Security & Observability (Week 1)

### 1.1 Critical Security Hooks

| Component                | Action                      | Effort |
| ------------------------ | --------------------------- | ------ |
| `credential-guard.js`  | Port with Jarvis exclusions | 30 min |
| `branch-protection.js` | Port directly               | 15 min |
| `amend-validator.js`   | Port directly               | 15 min |

### 1.2 Docker Observability

| Component                           | Action          | Effort |
| ----------------------------------- | --------------- | ------ |
| `docker-health-monitor.js`        | Port and rename | 20 min |
| `docker-restart-loop-detector.js` | Port and rename | 20 min |
| `docker-post-op-health.js`        | Port and rename | 20 min |

### 1.3 File Access Tracking

| Component                        | Action                    | Effort |
| -------------------------------- | ------------------------- | ------ |
| `file-access-tracker.js`       | Port directly             | 15 min |
| Integration with selection-audit | Configure unified logging | 30 min |

**Total Phase 1 Effort**: ~3 hours

---

## Phase 2: Commands & Patterns (Week 2)

### 2.1 JICM Complement Commands

| Component            | Action                 | Effort |
| -------------------- | ---------------------- | ------ |
| `/context-analyze` | Port with path updates | 30 min |
| `/context-loss`    | Port directly          | 15 min |

### 2.2 Knowledge Capture

| Component    | Action        | Effort |
| ------------ | ------------- | ------ |
| `/capture` | Port directly | 20 min |
| `/history` | Port directly | 20 min |

### 2.3 Codebase Analysis

| Component             | Action                 | Effort |
| --------------------- | ---------------------- | ------ |
| `/analyze-codebase` | Port with Jarvis paths | 45 min |

### 2.4 Documentation Patterns

| Pattern                     | Action        | Effort |
| --------------------------- | ------------- | ------ |
| capability-layering-pattern | Port directly | 10 min |
| code-before-prompts-pattern | Port directly | 10 min |
| command-invocation-pattern  | Port directly | 10 min |
| agent-invocation-pattern    | Port directly | 10 min |

**Total Phase 2 Effort**: ~3 hours

---

## Phase 3: Auto-* Wrapper Refactoring (Week 2-3)

### 3.1 Implementation

| Task                                     | Effort |
| ---------------------------------------- | ------ |
| Create universal signal_command function | 1 hour |
| Update auto-command-watcher.sh           | 1 hour |
| Create blocklist configuration           | 30 min |
| Test with various commands               | 1 hour |

### 3.2 Migration

| Task                              | Effort |
| --------------------------------- | ------ |
| Document new approach             | 30 min |
| Deprecation notices on old auto-* | 15 min |
| Monitoring period                 | 1 week |
| Archive old auto-*                | 15 min |

**Total Phase 3 Effort**: ~4-5 hours

---

## Phase 4: Utility Consolidation (Week 3)

### 4.1 Command Consolidation

| Consolidation       | From                                                 | To                          |
| ------------------- | ---------------------------------------------------- | --------------------------- |
| Checkpoint commands | /checkpoint, /smart-checkpoint, /context-checkpoint  | `/checkpoint [--mode simple |
| Compaction commands | /jicm-compact, /smart-compact, /intelligent-compress | `/compact [--mode jicm      |

### 4.2 Redundancy Cleanup

| Action                 | Components                       |
| ---------------------- | -------------------------------- |
| Review all commands    | 56 commands                      |
| Identify overlaps      | Document in redundancy-report.md |
| Propose consolidations | Create migration plan            |

**Total Phase 4 Effort**: ~4 hours

---

## Phase 5: Major Feature Evaluation (Week 4)

### 5.1 Parallel-Dev Prototype

| Task                    | Effort  |
| ----------------------- | ------- |
| Port parallel-dev skill | 4 hours |
| Port 4 agents           | 2 hours |
| Test in isolated branch | 2 hours |
| Wiggum Loop integration | 2 hours |

### 5.2 Structured Planning Evaluation

| Task                           | Effort  |
| ------------------------------ | ------- |
| Port structured-planning skill | 2 hours |
| Test question-bank workflow    | 1 hour  |
| Integration with orchestration | 1 hour  |

### 5.3 TELOS Framework Evaluation

| Task                    | Effort  |
| ----------------------- | ------- |
| Adapt for Jarvis/Aion   | 3 hours |
| Link to roadmap.md      | 1 hour  |
| Test quarterly workflow | 1 hour  |

**Total Phase 5 Effort**: ~19 hours

---

## Phase 6: Self-Improvement Unification (Week 5)

### 6.1 Upgrade Integration

| Task                               | Effort  |
| ---------------------------------- | ------- |
| Merge upgrade discovery into AC-07 | 3 hours |
| Add external source monitoring     | 2 hours |
| Unified proposal queue             | 1 hour  |

### 6.2 Autonomous Execution

| Task                              | Effort  |
| --------------------------------- | ------- |
| Port autonomous-execution-pattern | 2 hours |
| Create scheduled jobs             | 2 hours |
| Test permission tiers             | 1 hour  |

**Total Phase 6 Effort**: ~11 hours

---

## Phase 7: Final Integration & Inventory (Week 6)

### 7.1 Complete Component Inventory

| Task                               | Effort  |
| ---------------------------------- | ------- |
| Inventory all .claude/ directories | 2 hours |
| Generate component matrix          | 1 hour  |
| Identify remaining redundancies    | 1 hour  |

### 7.2 Selection Pattern Optimization

| Task                                | Effort  |
| ----------------------------------- | ------- |
| Update selection-intelligence-guide | 1 hour  |
| Create decision flowcharts          | 1 hour  |
| Document agent-swarming patterns    | 2 hours |

### 7.3 Documentation Finalization

| Task                          | Effort |
| ----------------------------- | ------ |
| Update CLAUDE.md              | 30 min |
| Update capability-matrix      | 30 min |
| Archive integration documents | 15 min |

**Total Phase 7 Effort**: ~9 hours

---

## Summary Timeline

| Phase           | Description              | Effort               | Week              |
| --------------- | ------------------------ | -------------------- | ----------------- |
| 1               | Security & Observability | 3 hrs                | 1                 |
| 2               | Commands & Patterns      | 3 hrs                | 2                 |
| 3               | Auto-* Refactoring       | 4-5 hrs              | 2-3               |
| 4               | Utility Consolidation    | 4 hrs                | 3                 |
| 5               | Major Features           | 19 hrs               | 4                 |
| 6               | Self-Improvement         | 11 hrs               | 5                 |
| 7               | Final Integration        | 9 hrs                | 6                 |
| **TOTAL** |                          | **~53-54 hrs** | **6 weeks** |

---

## Appendix: Files to Create/Modify

### New Files

```
.claude/hooks/credential-guard.js
.claude/hooks/branch-protection.js
.claude/hooks/amend-validator.js
.claude/hooks/docker-health-monitor.js
.claude/hooks/docker-restart-loop-detector.js
.claude/hooks/docker-post-op-health.js
.claude/hooks/file-access-tracker.js
.claude/hooks/session-tracker.js
.claude/hooks/memory-maintenance.js

.claude/commands/capture.md
.claude/commands/history.md
.claude/commands/context-analyze.md
.claude/commands/context-loss.md
.claude/commands/analyze-codebase.md

.claude/context/patterns/capability-layering-pattern.md
.claude/context/patterns/code-before-prompts-pattern.md
.claude/context/patterns/command-invocation-pattern.md
.claude/context/patterns/agent-invocation-pattern.md
.claude/context/patterns/autonomous-execution-pattern.md

.claude/skills/parallel-dev/SKILL.md (+ templates, config)
.claude/skills/structured-planning/SKILL.md (+ templates, tools)
.claude/skills/universal-autonomous-command/SKILL.md

.claude/context/telos/TELOS.md (+ domains, goals)
```

### Modified Files

```
.claude/settings.json (add new hooks)
.claude/CLAUDE.md (update references)
.claude/scripts/signal-helper.sh (add universal signal)
.claude/scripts/auto-command-watcher.sh (update for universal signals)
.claude/context/patterns/_index.md (add new patterns)
.claude/context/integrations/capability-matrix.md (update)
```

---

# PART 7: WIGGUM LOOP + PARALLEL-DEV ARCHITECTURE

## 7.1 Two Perpendicular Approaches

### Approach A: Loops IN Parallelization

Each parallel agent runs its own internal Wiggum Loop.

```
/parallel-dev:start
    ↓
┌─────────────────────────────────────────────────────────────────────┐
│ PARALLEL AGENTS (each with internal loop)                           │
│                                                                       │
│  ┌───────────────────┐ ┌───────────────────┐ ┌───────────────────┐  │
│  │ IMPLEMENTER       │ │ TESTER            │ │ DOCUMENTER        │  │
│  │ ╔═══════════════╗ │ │ ╔═══════════════╗ │ │ ╔═══════════════╗ │  │
│  │ ║ WIGGUM LOOP   ║ │ │ ║ WIGGUM LOOP   ║ │ │ ║ WIGGUM LOOP   ║ │  │
│  │ ║ Execute       ║ │ │ ║ Execute       ║ │ │ ║ Execute       ║ │  │
│  │ ║ Check         ║ │ │ ║ Check         ║ │ │ ║ Check         ║ │  │
│  │ ║ Review        ║ │ │ ║ Review        ║ │ │ ║ Review        ║ │  │
│  │ ║ Loop/Done     ║ │ │ ║ Loop/Done     ║ │ │ ║ Loop/Done     ║ │  │
│  │ ╚═══════════════╝ │ │ ╚═══════════════╝ │ │ ╚═══════════════╝ │  │
│  │ Loops: 1-3        │ │ Loops: 1-3        │ │ Loops: 1-2        │  │
│  └───────────────────┘ └───────────────────┘ └───────────────────┘  │
└─────────────────────────────────────────────────────────────────────┘
    ↓
/parallel-dev:validate (one-shot, post-hoc)
    ↓
/parallel-dev:merge (one-shot)
```

**Characteristics**:

- Fine-grained quality control per-agent
- Agents self-correct in isolation
- Integration issues discovered late (at merge)
- If one agent fails, only that agent loops

### Approach B: Parallelization IN Loops (RECOMMENDED)

The entire parallel-dev workflow is ONE Wiggum iteration.

```
╔══════════════════════════════════════════════════════════════════════════╗
║ WIGGUM LOOP (Feature Level)                                               ║
╠══════════════════════════════════════════════════════════════════════════╣
║                                                                            ║
║  ITERATION 1                                                               ║
║  ┌────────────────────────────────────────────────────────────────────┐   ║
║  │ EXECUTE: Run entire parallel-dev workflow                          │   ║
║  │                                                                     │   ║
║  │   /parallel-dev:plan → /parallel-dev:decompose                     │   ║
║  │            ↓                                                        │   ║
║  │   /parallel-dev:start                                               │   ║
║  │   ┌─────────────┐ ┌─────────────┐ ┌─────────────┐                  │   ║
║  │   │ Implementer │ │   Tester    │ │ Documenter  │ (1-shot each)    │   ║
║  │   └─────────────┘ └─────────────┘ └─────────────┘                  │   ║
║  │            ↓                                                        │   ║
║  │   /parallel-dev:validate → /parallel-dev:merge                     │   ║
║  │                                                                     │   ║
║  │   OUTPUT: Feature attempt #1                                        │   ║
║  └────────────────────────────────────────────────────────────────────┘   ║
║           ↓                                                                ║
║  ┌────────────────────────────────────────────────────────────────────┐   ║
║  │ CHECK: Did the feature work?                                        │   ║
║  │   • Build passes? Tests pass? Acceptance criteria met?              │   ║
║  └────────────────────────────────────────────────────────────────────┘   ║
║           ↓                                                                ║
║  ┌────────────────────────────────────────────────────────────────────┐   ║
║  │ REVIEW: AC-03 Milestone Review                                      │   ║
║  │   • Technical Rating: [1-5]                                         │   ║
║  │   • Progress Rating: [1-5]                                          │   ║
║  └────────────────────────────────────────────────────────────────────┘   ║
║           ↓                                                                ║
║  ┌────────────────────────────────────────────────────────────────────┐   ║
║  │ DECISION                                                            │   ║
║  │   • Ratings >= 4 → COMPLETE ✓                                       │   ║
║  │   • Ratings < 4  → LOOP (refine plan, run iteration 2)              │   ║
║  └────────────────────────────────────────────────────────────────────┘   ║
║                                                                            ║
╚══════════════════════════════════════════════════════════════════════════╝
```

**Characteristics**:

- Holistic quality check (whole feature, not pieces)
- Integration issues caught every iteration
- Session boundaries are natural (1 iteration = 1 session)
- Learnings from iteration 1 inform iteration 2's planning

## 7.2 Comparison Matrix

| Dimension                        | Loops IN Parallelization             | Parallelization IN Loops    |
| -------------------------------- | ------------------------------------ | --------------------------- |
| **Quality granularity**    | Per-agent (fine)                     | Per-feature (coarse)        |
| **Integration testing**    | Late (at merge only)                 | Early (every iteration)     |
| **Failure handling**       | Agent loops independently            | Whole workflow re-attempts  |
| **Learning propagation**   | Agent-local                          | Feature-global              |
| **Session boundaries**     | Unclear (agents at different stages) | Clear (iteration = session) |
| **Context management**     | Complex (5 agent states)             | Simple (1 iteration state)  |
| **Mental model**           | Complex (nested loops)               | Simple (single outer loop)  |
| **Wasted work on failure** | Less (only failed agent)             | More (all agents)           |

## 7.3 Recommendation

**Parallelization IN Loops** is the recommended architecture because:

1. **Integration issues are the hardest problems** — catching them at the loop level (every iteration) beats catching them only at merge (once).
2. **Session boundaries are natural** — one iteration = one complete attempt = one session.
3. **Learning propagates globally** — if iteration 1 reveals a requirement misunderstanding, iteration 2's PLANNING phase incorporates that learning. With Loops IN Parallelization, each agent learns in isolation.
4. **Wiggum's strength is holistic** — "did we achieve the goal?" makes more sense at the feature level than the agent level.
5. **Parallel-dev's built-in validation** already handles per-agent quality — Wiggum handles the "should we try again?" decision.
6. **Milestone reviews integrate naturally** — AC-03 reviews happen at iteration boundaries, not buried inside agent loops.

---

# APPENDIX A: SESSION-BASED WORK BREAKDOWN

## Session Guidelines

| Constraint                     | Value                      | Rationale                                            |
| ------------------------------ | -------------------------- | ---------------------------------------------------- |
| **Max session duration** | 2 hours                    | Context compaction typically needed around 45-60 min |
| **Target deliverable**   | 1 complete milestone       | Clear exit criteria                                  |
| **Session boundary**     | After milestone completion | Clean handoff points                                 |
| **Scope management**     | Pre-defined, no drift      | Each session has explicit outputs                    |

## Session Map

Total estimated effort: ~53 hours → ~27 sessions at 2 hours each

### Milestone 1: Security Foundation (Sessions 1-2)

**Prerequisite**: None
**Deliverable**: All security hooks ported and registered

#### Session 1.1: Critical Security Hooks

**Duration**: ~1.5 hours
**Scope**:

- Port `credential-guard.js` with Jarvis exclusions
- Port `branch-protection.js`
- Port `amend-validator.js`
- Register in settings.json
- Test all three hooks

**Exit Criteria**:

- [ ] All 3 hooks in `.claude/hooks/`
- [ ] Hooks registered in settings.json
- [ ] Manual test: credential read blocked
- [ ] Manual test: force push blocked
- [ ] Commit: "feat: Add security hooks from AIfred baseline"

**Milestone Review Trigger**: After Session 1.1

---

#### Session 1.2: Docker Observability Hooks

**Duration**: ~1.5 hours
**Scope**:

- Port `docker-health-monitor.js` (renamed)
- Port `docker-restart-loop-detector.js` (renamed)
- Port `docker-post-op-health.js` (renamed)
- Register and test

**Exit Criteria**:

- [ ] All 3 Docker hooks ported with `docker-` prefix
- [ ] Hooks registered
- [ ] Docker health monitoring functional
- [ ] Commit: "feat: Add Docker observability hooks"

**Milestone Review Trigger**: After Session 1.2 (Milestone 1 Complete)

---

### Milestone 2: Analytics & Tracking (Sessions 3-4)

**Prerequisite**: Milestone 1 complete
**Deliverable**: File access tracking and unified logging foundation

#### Session 2.1: File Access & Session Tracking

**Duration**: ~1.5 hours
**Scope**:

- Port `file-access-tracker.js`
- Port `session-tracker.js`
- Port `memory-maintenance.js`
- Configure integration with existing selection-audit

**Exit Criteria**:

- [ ] File access tracking to `.claude/logs/file-access.json`
- [ ] Session events logged
- [ ] Memory entity access tracked
- [ ] Commit: "feat: Add analytics hooks"

---

#### Session 2.2: Unified Logging Design

**Duration**: ~1.5 hours
**Scope**:

- Design unified event stream architecture
- Document integration points
- Update telemetry-emitter if needed
- Create logging architecture doc

**Exit Criteria**:

- [ ] Logging architecture documented
- [ ] Event stream schema defined
- [ ] Integration points identified
- [ ] Commit: "docs: Unified logging architecture"

**Milestone Review Trigger**: After Session 2.2 (Milestone 2 Complete)

---

### Milestone 3: JICM Complements (Sessions 5-6)

**Prerequisite**: Milestone 2 complete
**Deliverable**: Context analysis and loss reporting commands

#### Session 3.1: Context Analysis Commands

**Duration**: ~2 hours
**Scope**:

- Port `/context-analyze` command
- Adapt script paths for Jarvis
- Port `/context-loss` command
- Test with actual context usage

**Exit Criteria**:

- [ ] `/context-analyze` generates reports
- [ ] `/context-loss` captures trimmed context
- [ ] Ollama integration working (if available)
- [ ] Commit: "feat: Add JICM complement commands"

---

#### Session 3.2: Knowledge Capture Commands

**Duration**: ~1.5 hours
**Scope**:

- Port `/capture` command
- Port `/history` command
- Integrate with Memory MCP
- Test capture → retrieval workflow

**Exit Criteria**:

- [ ] `/capture` stores learnings/decisions
- [ ] `/history` shows session history
- [ ] Memory MCP entities created
- [ ] Commit: "feat: Add knowledge capture commands"

**Milestone Review Trigger**: After Session 3.2 (Milestone 3 Complete)

---

### Milestone 4: Documentation & Patterns (Sessions 7-8)

**Prerequisite**: Milestone 3 complete
**Deliverable**: All pattern documentation ported

#### Session 4.1: Core Patterns

**Duration**: ~1.5 hours
**Scope**:

- Port `capability-layering-pattern.md`
- Port `code-before-prompts-pattern.md`
- Port `command-invocation-pattern.md`
- Port `agent-invocation-pattern.md`
- Update `_index.md`

**Exit Criteria**:

- [ ] 4 patterns in `.claude/context/patterns/`
- [ ] Pattern index updated
- [ ] Cross-references working
- [ ] Commit: "docs: Port AIfred patterns"

---

#### Session 4.2: Autonomous Execution Pattern + Codebase Analysis

**Duration**: ~2 hours
**Scope**:

- Port `autonomous-execution-pattern.md`
- Port `/analyze-codebase` command
- Test codebase analysis on small project

**Exit Criteria**:

- [ ] Autonomous execution pattern documented
- [ ] `/analyze-codebase` generates documentation
- [ ] Mermaid diagrams working
- [ ] Commit: "feat: Add autonomous execution and codebase analysis"

**Milestone Review Trigger**: After Session 4.2 (Milestone 4 Complete)

---

### Milestone 5: Auto-* Wrapper Refactoring (Sessions 9-11)

**Prerequisite**: Milestone 4 complete
**Deliverable**: Universal autonomous command wrapper replacing 17 auto-* commands

#### Session 5.1: Universal Signal Implementation

**Duration**: ~2 hours
**Scope**:

- Implement `signal_command()` in signal-helper.sh
- Create blocklist configuration
- Update auto-command-watcher.sh
- Test with 3-5 commands

**Exit Criteria**:

- [ ] Universal signal function working
- [ ] Blocklist preventing interactive commands
- [ ] Watcher detecting and executing signals
- [ ] Commit: "feat: Universal autonomous command wrapper"

---

#### Session 5.2: Migration & Testing

**Duration**: ~2 hours
**Scope**:

- Test all 17 existing auto-* command equivalents
- Document migration path
- Add deprecation notices to old commands
- Create universal-autonomous-command skill

**Exit Criteria**:

- [ ] All commands testable via universal wrapper
- [ ] Skill documentation complete
- [ ] Deprecation notices added
- [ ] Commit: "feat: Complete auto-* migration"

---

#### Session 5.3: Cleanup & Archive

**Duration**: ~1 hour
**Scope**:

- Archive old auto-* command files
- Update CLAUDE.md references
- Update capability-matrix.md
- Final testing

**Exit Criteria**:

- [ ] Old commands archived
- [ ] Documentation updated
- [ ] No broken references
- [ ] Commit: "chore: Archive deprecated auto-* commands"

**Milestone Review Trigger**: After Session 5.3 (Milestone 5 Complete)

---

### Milestone 6: Command Consolidation (Sessions 12-13)

**Prerequisite**: Milestone 5 complete
**Deliverable**: Consolidated checkpoint and compaction commands

#### Session 6.1: Checkpoint Consolidation

**Duration**: ~2 hours
**Scope**:

- Analyze /checkpoint, /smart-checkpoint, /context-checkpoint
- Design unified `/checkpoint [--mode]` command
- Implement consolidated command
- Migrate functionality

**Exit Criteria**:

- [ ] Single `/checkpoint` command with modes
- [ ] All previous functionality preserved
- [ ] Old commands deprecated
- [ ] Commit: "refactor: Consolidate checkpoint commands"

---

#### Session 6.2: Compaction Consolidation

**Duration**: ~2 hours
**Scope**:

- Analyze /jicm-compact, /smart-compact, /intelligent-compress
- Design unified `/compact [--mode]` command
- Implement consolidated command
- Migrate functionality

**Exit Criteria**:

- [ ] Single `/compact` command with modes
- [ ] JICM integration preserved
- [ ] Old commands deprecated
- [ ] Commit: "refactor: Consolidate compaction commands"

**Milestone Review Trigger**: After Session 6.2 (Milestone 6 Complete)

---

### Milestone 7: Parallel-Dev Foundation (Sessions 14-17)

**Prerequisite**: Milestone 6 complete
**Deliverable**: Parallel-dev skill ported with Wiggum Loop integration

#### Session 7.1: Skill Structure & Config

**Duration**: ~2 hours
**Scope**:

- Create parallel-dev skill directory structure
- Port SKILL.md with Jarvis adaptations
- Port config.json with Jarvis paths
- Port 5 templates

**Exit Criteria**:

- [ ] Skill directory created
- [ ] SKILL.md adapted for Jarvis
- [ ] Config paths updated
- [ ] Commit: "feat: Parallel-dev skill foundation"

---

#### Session 7.2: Core Commands (Part 1)

**Duration**: ~2 hours
**Scope**:

- Port `/parallel-dev:init`
- Port `/parallel-dev:status`
- Port `/parallel-dev:plan`
- Port `/parallel-dev:decompose`
- Test planning workflow

**Exit Criteria**:

- [ ] 4 commands functional
- [ ] Planning workflow tested
- [ ] Task decomposition generating YAML
- [ ] Commit: "feat: Parallel-dev planning commands"

---

#### Session 7.3: Core Commands (Part 2)

**Duration**: ~2 hours
**Scope**:

- Port `/parallel-dev:start`
- Port `/parallel-dev:validate`
- Port `/parallel-dev:merge`
- Port worktree management commands

**Exit Criteria**:

- [ ] Execution commands functional
- [ ] Worktree creation working
- [ ] Validation pipeline running
- [ ] Commit: "feat: Parallel-dev execution commands"

---

#### Session 7.4: Agents & Wiggum Integration

**Duration**: ~2 hours
**Scope**:

- Port 4 parallel-dev agents
- Integrate Wiggum Loop as outer wrapper
- Configure iteration flow
- Test complete workflow

**Exit Criteria**:

- [ ] All 4 agents ported
- [ ] Wiggum Loop wrapping parallel-dev
- [ ] Iteration → review → decision flow working
- [ ] Commit: "feat: Parallel-dev agents with Wiggum integration"

**Milestone Review Trigger**: After Session 7.4 (Milestone 7 Complete)

---

### Milestone 8: Structured Planning (Sessions 18-19)

**Prerequisite**: Milestone 7 complete
**Deliverable**: Structured planning skill with dynamic depth

#### Session 8.1: Skill & Templates

**Duration**: ~2 hours
**Scope**:

- Port structured-planning skill
- Port question-bank.yaml (12KB)
- Port spec templates
- Port TypeScript tools

**Exit Criteria**:

- [ ] Skill structure complete
- [ ] Question bank available
- [ ] Templates working
- [ ] Commit: "feat: Structured planning skill"

---

#### Session 8.2: Commands & Integration

**Duration**: ~2 hours
**Scope**:

- Port `/plan` commands (4)
- Integrate with orchestration
- Test all 3 planning modes
- Configure dynamic depth

**Exit Criteria**:

- [ ] All /plan commands working
- [ ] Mode detection functional
- [ ] Dynamic depth adjusting
- [ ] Commit: "feat: Complete structured planning"

**Milestone Review Trigger**: After Session 8.2 (Milestone 8 Complete)

---

### Milestone 9: TELOS Strategic Framework (Sessions 20-21)

**Prerequisite**: Milestone 8 complete
**Deliverable**: TELOS framework integrated with roadmap

#### Session 9.1: Framework Foundation

**Duration**: ~2 hours
**Scope**:

- Create TELOS directory structure
- Port/adapt TELOS.md
- Create domain templates
- Create goal templates

**Exit Criteria**:

- [ ] TELOS directory structure
- [ ] Adapted for Jarvis/Project Aion
- [ ] Templates functional
- [ ] Commit: "feat: TELOS framework foundation"

---

#### Session 9.2: Integration & Commands

**Duration**: ~2 hours
**Scope**:

- Port `/telos` command
- Link TELOS to roadmap.md
- Integrate with session-start
- Test quarterly workflow

**Exit Criteria**:

- [ ] /telos command working
- [ ] Roadmap integration clear
- [ ] Session-start references TELOS
- [ ] Commit: "feat: Complete TELOS integration"

**Milestone Review Trigger**: After Session 9.2 (Milestone 9 Complete)

---

### Milestone 10: Self-Improvement Unification (Sessions 22-24)

**Prerequisite**: Milestone 9 complete
**Deliverable**: Unified self-improvement system with external discovery

#### Session 10.1: Upgrade Discovery Integration

**Duration**: ~2 hours
**Scope**:

- Integrate AIfred upgrade discovery into AC-07
- Port source monitoring configuration
- Port baselines.json approach
- Test discovery workflow

**Exit Criteria**:

- [ ] External source discovery in AC-07
- [ ] Baselines tracking implemented
- [ ] Discovery report generating
- [ ] Commit: "feat: External upgrade discovery"

---

#### Session 10.2: Scheduled Automation

**Duration**: ~2 hours
**Scope**:

- Implement scheduled job framework
- Create discovery cron job
- Create health check cron job
- Test headless execution

**Exit Criteria**:

- [ ] Scheduled job framework working
- [ ] Permission tiers enforced
- [ ] Jobs running via cron
- [ ] Commit: "feat: Scheduled autonomous execution"

---

#### Session 10.3: Proposal Unification

**Duration**: ~2 hours
**Scope**:

- Unify proposal queue (internal + external)
- Implement risk-based approval
- Integration testing
- Documentation

**Exit Criteria**:

- [ ] Unified proposal queue
- [ ] Risk-based gates working
- [ ] Full workflow tested
- [ ] Commit: "feat: Complete self-improvement unification"

**Milestone Review Trigger**: After Session 10.3 (Milestone 10 Complete)

---

### Milestone 11: Final Integration (Sessions 25-27)

**Prerequisite**: Milestone 10 complete
**Deliverable**: Complete inventory and optimized selection patterns

#### Session 11.1: Component Inventory

**Duration**: ~2 hours
**Scope**:

- Inventory all .claude/ directories
- Generate component matrix
- Identify redundancies
- Create consolidation proposals

**Exit Criteria**:

- [ ] Complete inventory document
- [ ] Redundancy report
- [ ] Consolidation proposals
- [ ] Commit: "docs: Complete component inventory"

---

#### Session 11.2: Selection Optimization

**Duration**: ~2 hours
**Scope**:

- Update selection-intelligence-guide
- Create decision flowcharts
- Document agent-swarming patterns
- Update capability-matrix

**Exit Criteria**:

- [ ] Selection guide updated
- [ ] Flowcharts in place
- [ ] Agent patterns documented
- [ ] Commit: "docs: Optimized selection patterns"

---

#### Session 11.3: Documentation & Cleanup

**Duration**: ~2 hours
**Scope**:

- Update CLAUDE.md
- Archive integration documents
- Final testing of all new features
- Create integration summary

**Exit Criteria**:

- [ ] CLAUDE.md updated
- [ ] All docs archived
- [ ] Final tests passing
- [ ] Commit: "docs: AIfred integration complete"

**Milestone Review Trigger**: After Session 11.3 (Milestone 11 Complete — Integration Done)

---

## Session Summary

| Milestone         | Sessions              | Total Hours      | Cumulative |
| ----------------- | --------------------- | ---------------- | ---------- |
| M1: Security      | 1.1, 1.2              | 3 hrs            | 3 hrs      |
| M2: Analytics     | 2.1, 2.2              | 3 hrs            | 6 hrs      |
| M3: JICM          | 3.1, 3.2              | 3.5 hrs          | 9.5 hrs    |
| M4: Patterns      | 4.1, 4.2              | 3.5 hrs          | 13 hrs     |
| M5: Auto-*        | 5.1, 5.2, 5.3         | 5 hrs            | 18 hrs     |
| M6: Consolidation | 6.1, 6.2              | 4 hrs            | 22 hrs     |
| M7: Parallel-Dev  | 7.1, 7.2, 7.3, 7.4    | 8 hrs            | 30 hrs     |
| M8: Planning      | 8.1, 8.2              | 4 hrs            | 34 hrs     |
| M9: TELOS         | 9.1, 9.2              | 4 hrs            | 38 hrs     |
| M10: Self-Improve | 10.1, 10.2, 10.3      | 6 hrs            | 44 hrs     |
| M11: Final        | 11.1, 11.2, 11.3      | 6 hrs            | 50 hrs     |
| **TOTAL**   | **27 sessions** | **50 hrs** |            |

---

## Milestone Review Protocol

At each milestone boundary:

1. **STOP** work on new features
2. **Technical Review** (1-5 rating):
   - Code quality
   - Test coverage
   - Documentation accuracy
3. **Progress Review** (1-5 rating):
   - Requirements alignment
   - Scope adherence
   - Integration completeness
4. **PROCEED** if ratings >= 4
5. **REMEDIATE** if ratings < 4 (add remediation session before next milestone)

---

*Integration Roadmap v2.1 — Updated 2026-01-21*
*Added: Wiggum + Parallel-Dev architecture analysis, Session-based breakdown*
*Supersedes: adhoc-assessment, code-comparison, comprehensive-analysis, integration-recommendations*
