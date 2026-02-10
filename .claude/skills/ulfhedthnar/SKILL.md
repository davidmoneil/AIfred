---
name: ulfhedthnar
model: opus
version: 1.0.0
description: |
  AC-10 Ulfhedthnar — Neuros Override System (LOCKED SKILL).
  Berserker problem-solving mode. NOT for standard skill discovery.
  Activated ONLY by: detection hook threshold OR /unleash command.
  Use when: defeat signals detected, barriers encountered, normal approaches exhausted.
  Keywords: ulfhedthnar, unleash, berserker, frenzy, override, wolf-warrior
category: autonomy
tags: [ac-10, neuros, override, berserker]
discoverable: false
created: 2026-02-10
---

# Ulfhedthnar — The Wolf-Warrior

> *Beyond the Nine Muses exists a hidden 10th: the wolf-warrior who awakens when harmony fails.*

## Activation Conditions

This skill activates ONLY when:
1. **Detection hook threshold reached** — cumulative defeat signals >= 7 weight
2. **User runs /unleash** — direct manual activation
3. **User confirms emergence prompt** — responds "unleash" to the detector's prompt

**NEVER activate autonomously without user confirmation.**

## Intensity Levels

| Level | Frenzy Agents | Berserker Min | Approach Strategies | Escalation |
|-------|---------------|---------------|---------------------|------------|
| **low** | 0 (skip Frenzy) | 3 iterations | Direct, Decompose, Analogize | Local only |
| **medium** (default) | 2-3 agents | 5 iterations | All 6 strategies | Up to Agents |
| **high** | 4 agents | 5+ iterations, no early exit | All 6 + loop back | Full ladder incl. User |

When activated via detection hook (auto), intensity defaults to **medium**.
When activated via `/unleash --intensity <level>`, use the specified level.

## Override Protocol 1: Frenzy Mode

Decompose the current problem and spawn maximum parallel agents:

```
Agent 1: DIRECT — Try the most obvious approach with fresh perspective
Agent 2: RESEARCH — WebSearch + documentation + similar problems
Agent 3: DECOMPOSE — Break into atomic sub-problems, solve individually
Agent 4: CREATIVE — Lateral thinking, unconventional methods, analogies
```

**Execution:**
1. Read `.claude/state/components/AC-10-ulfhedthnar.json` → check `trigger_signals` for context
2. Clearly define the problem and success criteria
3. Decompose into 2-4 independent sub-problems
4. Spawn agents using Task tool (one per approach):
   - `subagent_type: "general-purpose"` for Direct
   - `subagent_type: "Explore"` for Research
   - `subagent_type: "code-analyzer"` for Decompose
   - `subagent_type: "general-purpose"` for Creative (with specific prompt)
5. Aggregate results — synthesize partial solutions
6. If all agents fail, proceed to Berserker Loop

**JICM Safety**: Frenzy Mode delegates heavy work to agents, protecting main context.
Each agent runs in isolated context — main session context is preserved.

## Override Protocol 2: Berserker Wiggum Loop

Enhanced Wiggum Loop with mandatory minimum iterations and forced reframing:

```
for iteration in 1..N (MINIMUM 5, no early exit):
  1. EXECUTE — Apply current strategy to the problem
  2. CHECK — Evaluate result against success criteria
  3. REFRAME — Ask: "What assumption am I making that's wrong?"
     - Challenge each constraint individually
     - Consider if the problem is misstated
     - Ask if there's a simpler version of this problem
  4. ROTATE — Move to next approach strategy
  5. RETRY — Apply new strategy with reframed understanding
  6. ANCHOR — Save partial solutions, insights, and progress
     Write to .claude/state/ulfhedthnar-progress.json
```

**Key differences from standard AC-02 Wiggum Loop:**
- No early exit before 5 iterations (standard allows 2-3)
- Mandatory REFRAME step forces perspective shifts
- Progress ANCHORING prevents discarding partial solutions
- Approach ROTATION ensures strategy diversity

## Override Protocol 3: Approach Rotation

Systematic strategy cycling, one per iteration:

| Order | Strategy | Technique | Example |
|-------|----------|-----------|---------|
| 1 | **Direct** | Most obvious approach, fresh eyes | Re-read error message carefully, try the fix it suggests |
| 2 | **Decompose** | Break into smallest possible pieces | Isolate which specific line/function fails, test each |
| 3 | **Analogize** | Find similar solved problems | Grep codebase for similar patterns, WebSearch the error |
| 4 | **Invert** | Solve the opposite problem | "What would make this definitely fail?" then avoid that |
| 5 | **Brute-force** | Enumerate all possibilities | List every possible cause, test each systematically |
| 6 | **Creative** | Lateral thinking, unusual tools | Use a different tool entirely, rewrite from scratch |

After cycling through all 6, loop back to Direct with accumulated insights.

### Reframe Question Bank

Use these questions during the REFRAME step of each iteration:

**Assumption challenges:**
- "What am I assuming about the input/output format?"
- "Am I solving the right problem, or a problem I invented?"
- "What if the error message is misleading?"

**Constraint challenges:**
- "Which of these constraints are real vs self-imposed?"
- "What if I removed this requirement — would it still be useful?"
- "Is there a 90% solution that avoids the hard part?"

**Perspective shifts:**
- "How would someone with zero context approach this?"
- "What would I tell a user asking me for help with this same problem?"
- "If I had to solve this in 60 seconds, what would I try?"

## Override Protocol 4: Escalation Ladder

Progressive escalation when stuck:

| Level | Action | When |
|-------|--------|------|
| 1 | **Local** | Search codebase, read docs, check patterns |
| 2 | **Web** | WebSearch + WebFetch for external solutions |
| 3 | **Agents** | Spawn deep-research or code-analyzer |
| 4 | **Tools** | ToolSearch for undiscovered capabilities |
| 5 | **User** | Ask user for guidance (LAST RESORT) |

Only escalate when current level is exhausted. Document what was tried at each level.

## Override Protocol 5: Progress Anchoring

Never discard partial progress. After each iteration:

Write to `.claude/state/ulfhedthnar-progress.json`:
```json
{
  "problem": "description",
  "iteration": N,
  "approaches_tried": [
    { "strategy": "direct", "result": "partial", "insight": "..." }
  ],
  "partial_solutions": ["..."],
  "reframings": ["..."],
  "next_strategy": "decompose",
  "cumulative_progress": "description of what we know so far"
}
```

Each iteration builds on ALL previous knowledge. Synthesis across iterations is critical.

## Safety Constraints (ABSOLUTE — NO EXCEPTIONS)

1. **No destructive override**: Cannot bypass rm, force-push, reset --hard confirmations
2. **AIfred baseline inviolate**: Read-only rule absolute, no exceptions, ever
3. **JICM respect**: Frenzy mode MUST delegate to agents to protect main context
4. **Auto-disengage**: Returns to Hippocrenae mode after:
   - Problem solved (success criteria met)
   - User cancels ("stand down", "disengage")
   - All strategies exhausted across 5+ full iterations
5. **Cooldown**: 30-minute minimum between frenzy activations
6. **User sovereignty**: Cannot override user denial of activation
7. **Context budget**: Monitor context via JICM; if approaching threshold, compact or delegate

## Disengagement Protocol

When problem is solved or strategies exhausted:

1. Write resolution report to `.claude/reports/ulfhedthnar/`
2. Update `.claude/state/components/AC-10-ulfhedthnar.json`
3. Clear signal state at `.claude/state/ulfhedthnar-signals.json`
4. Emit telemetry: `{ component: "AC-10", event_type: "disengage" }`
5. Resume normal Hippocrenae operation

## Telemetry Events

| Event | When |
|-------|------|
| `barrier_detected` | Defeat signals exceeded threshold |
| `unleash_manual` | User ran /unleash |
| `unleash_auto` | User confirmed emergence prompt |
| `frenzy_start` | Parallel agents spawned |
| `approach_rotate` | Strategy cycling to next approach |
| `progress_anchor` | Partial solution saved |
| `problem_resolved` | Barrier overcome successfully |
| `disengage` | Returned to normal operation |

## State

- **Signal file**: `.claude/state/ulfhedthnar-signals.json`
- **Progress file**: `.claude/state/ulfhedthnar-progress.json`
- **AC state**: `.claude/state/components/AC-10-ulfhedthnar.json`
- **Reports**: `.claude/reports/ulfhedthnar/`

---

*AC-10 Ulfhedthnar — Neuros Override System*
*The wolf-warrior who fights when the Muses cannot sing*
