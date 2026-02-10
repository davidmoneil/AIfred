---
description: Unleash Ulfhedthnar — activate berserker problem-solving override
allowed-tools: [Read, Write, Edit, Glob, Grep, Bash, Task, Skill, TaskCreate, TaskUpdate, TaskList, TaskGet, WebSearch, WebFetch, EnterPlanMode]
---

# /unleash — Ulfhedthnar Override Command

**Purpose**: Directly activate AC-10 Ulfhedthnar berserker problem-solving mode.

**Usage**: `/unleash [--problem <description>] [--intensity low|medium|high]`

---

## Overview

The `/unleash` command bypasses signal detection and directly activates Ulfhedthnar, the wolf-warrior Neuros override system. Use when normal problem-solving approaches have failed and aggressive, parallel, multi-strategy attack is needed.

## Options

| Option | Values | Default | Description |
|--------|--------|---------|-------------|
| `--problem` | text | current task | Describe the specific problem to solve |
| `--intensity` | low, medium, high | medium | Controls parallelism and strategy aggressiveness |

## Examples

```
# Activate with current task context
/unleash

# Target a specific problem
/unleash --problem "Docker container keeps crashing on startup"

# Maximum intensity
/unleash --intensity high --problem "Cannot resolve circular dependency"
```

## AC-10 Telemetry: Activation

Emit telemetry at activation:

```bash
echo '{"component":"AC-10","event_type":"unleash_manual","data":{"trigger":"command"}}' | node .claude/hooks/telemetry-emitter.js
```

## Activation Protocol

When unleashed, execute these steps:

### 1. Problem Assessment
- Read current task context (TodoList, session-state.md)
- Identify what approaches have already been tried
- Classify barrier: knowledge gap, tool limitation, complexity wall, or ambiguity
- Decompose the problem into atomic sub-problems

### 2. Engage Frenzy Mode (if intensity >= medium)
- Spawn up to 4 parallel agents on decomposed sub-problems
- Each agent gets a different attack vector:
  - **Agent 1**: Direct approach (try the obvious with fresh perspective)
  - **Agent 2**: Research approach (WebSearch + documentation lookup)
  - **Agent 3**: Decomposition (break into smallest possible pieces)
  - **Agent 4**: Creative approach (lateral thinking, unconventional methods)
- Aggregate results after all agents complete

### 3. Berserker Wiggum Loop (minimum 5 iterations)
```
for iteration in 1..N (minimum 5):
  1. EXECUTE current approach
  2. CHECK results against success criteria
  3. REFRAME — what assumption was wrong?
  4. ROTATE to next approach strategy
  5. RETRY with reframed understanding
  6. ANCHOR progress — save partial solutions, never discard
```

### 4. Approach Rotation Order
| Order | Strategy | Description |
|-------|----------|-------------|
| 1 | Direct | Most obvious approach, fresh perspective |
| 2 | Decompose | Break into smallest possible sub-problems |
| 3 | Analogize | Find similar solved problems in codebase or web |
| 4 | Invert | Solve the opposite/complementary problem |
| 5 | Brute-force | Enumerate all possibilities systematically |
| 6 | Creative | Lateral thinking, unconventional methods |

### 5. Escalation Ladder
If approach rotation doesn't resolve:
1. **Local**: Search codebase, read docs, check patterns
2. **Web**: WebSearch + WebFetch for solutions
3. **Agents**: Spawn deep-research or code-analyzer agents
4. **Tools**: ToolSearch for undiscovered capabilities
5. **User**: Consultation (absolute last resort)

### 6. Progress Anchoring
After each iteration, write to `.claude/state/ulfhedthnar-progress.json`:
- Approaches tried and outcomes
- Partial solutions found
- Insights and reframings
- What to try next

### 7. Auto-Disengage
Return to normal Hippocrenae operation when:
- Problem is solved (success criteria met)
- User cancels ("stand down" or "disengage")
- All 6 strategies exhausted across 5+ iterations
- Write resolution report to `.claude/reports/ulfhedthnar/`

## Safety Constraints (ABSOLUTE)

- Cannot bypass destructive action confirmations (rm, force-push, reset)
- AIfred baseline remains read-only (no exceptions)
- Respects JICM context thresholds — Frenzy Mode delegates to agents
- 30-minute cooldown between frenzy activations
- Cannot override user denial of activation

## Disengagement

To return to normal operation:
- Say "stand down" or "disengage"
- Problem solved triggers auto-disengage
- All strategies exhausted triggers graceful disengage with report

## Integration

- **AC-02**: Enhanced Wiggum Loop (Berserker variant with Reframe step)
- **AC-04**: JICM awareness (delegates heavy work to agents)
- **AC-09**: Session completion includes Ulfhedthnar activity report
- **Skill**: Load via `Skill("ulfhedthnar")` for full protocol reference

---

*Part of Jarvis AC-10 Ulfhedthnar — Neuros Override System*
