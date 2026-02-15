# JICM Compression Optimization — Experimental Protocols

**Project**: Jarvis JICM v6.1 — Compression Pipeline Optimization
**Date**: 2026-02-14
**Branch**: Project_Aion
**Predecessors**: Experiments 1-3 (compression timing, context volume regression)
**Status**: INFRASTRUCTURE COMPLETE — Ready for Execution

---

## 1. Background and Motivation

### What We Know (from Experiments 1-3)

| Finding | Result | Source |
|---------|--------|--------|
| JICM is 2.3-3.8x slower than /compact | p<0.001, eta-sq=0.934 | Exp 1, 2, 3 |
| Context volume does NOT affect compression time | F=2.33, p=0.149 | Exp 2, 3 |
| Compression phase = ~75% of JICM cycle time | 210-235s of ~285s total | Exp 1 |
| JICM operational ceiling at 72% context | Emergency handler preempts at 73% | Exp 2 RCA |
| JICM-high succeeds reliably below 72% | 4/4 at 67-72% | Exp 3 |
| Compression time is mechanism-bound, not data-bound | Both treatments constant across volumes | Exp 2, 3 |

### The Compression Pipeline Bottleneck

The JICM compression pipeline works through **indirect spawning**:

```
Watcher (bash) → tmux_send_prompt → Jarvis (main session)
  → /intelligent-compress skill → Task tool
    → compression-agent (sonnet, 30 turns, background)
      → Reads 10-17 files (12-17 Read calls @ ~7-10s each = 84-170s I/O)
      → Applies observation masking
      → Writes checkpoint (5-15K tokens)
      → Writes signal file
    → Watcher polls for signal → /clear → restore
```

**Files the compression agent reads** (~1,637 lines across 10 foundation files):

| File | Lines | Purpose | Static? |
|------|-------|---------|---------|
| `CLAUDE.md` | 97 | Guardrails, architecture | Yes |
| `jarvis-identity.md` | 227 | Persona specification | Yes |
| `capability-map.yaml` | 363 | Manifest router (full) | Mostly |
| `compaction-essentials.md` | 122 | Recovery knowledge | Yes |
| `patterns/_index.md` | 227 | Pattern catalog | Yes |
| `agents/README.md` | 63 | Agent list | Yes |
| `commands/README.md` | 56 | Command list | Yes |
| `skills/_index.md` | 134 | Skill list | Yes |
| `session-state.md` | 113 | Current work status | No |
| `current-priorities.md` | 235 | Task backlog | No |
| Chat export | 200-600 | Raw terminal history | No |
| Prior checkpoint | ~253 | Previous compression | No |
| **Total** | **~2,100+** | | |

**Key insight**: 8 of 12 files (~1,289 lines) are essentially **static** — they rarely change between compression cycles. The agent re-reads and re-compresses them every time.

### Three Optimization Hypotheses

1. **Model selection**: A faster model (Haiku) may compress adequately in less time
2. **Thinking mode**: Extended thinking may be unnecessary for a formulaic compression task
3. **Preprocessing**: Pre-assembling all files into one reduces I/O turns from 12-17 to 1

These are **orthogonal** — each can be tested independently, and if all three yield improvements, they can be combined for a multiplicative effect.

---

## 2. Experiment 4: Model Selection Effect on Compression Time

### 2.1 Hypothesis

**H0.4**: The LLM model used for the compression agent has no significant effect on compression processing time.

**H1.4**: Different models produce significantly different compression times.

**Directional expectation**: Haiku < Sonnet < Opus in processing time; checkpoint quality may decrease correspondingly.

### 2.2 Design

**Type**: 1-way between-subjects factorial with /compact baseline
**Independent variable**: Model (4 levels)
**Dependent variables**: Compression time (s), checkpoint quality score (0-5)

| Cell | Treatment | Model | Expected Speed | Notes |
|------|-----------|-------|---------------|-------|
| A | /compact | N/A (built-in) | ~77s | Native CC, no agent |
| B | JICM-Haiku | haiku | ~100-150s? | Fastest, cheapest |
| C | JICM-Sonnet | sonnet | ~285s | Current baseline |
| D | JICM-Opus | opus | ~350-500s? | Slowest, highest quality |

**Context level**: Fixed at ~45% (low). Volume doesn't affect time (Exp 3).
**Thinking mode**: Default (on). Isolated as separate variable (Exp 5).
**Preprocessing**: None (current pipeline). Isolated as separate variable (Exp 6).

### 2.3 Sample Size

**Trials per cell**: 6
**Total trials**: 24 (6 blocks × 4 cells)
**Blocking**: Each block contains one trial per cell, randomized within block.

**Power analysis**: With n=6/cell, alpha=0.05, and the expected effect sizes from Experiments 1-3 (eta-sq > 0.90 for treatment), power exceeds 0.99. Even medium effects (eta-sq ~0.10) would have power ~0.60.

### 2.4 Block Schedule

| Block | Trial 1 | Trial 2 | Trial 3 | Trial 4 |
|-------|---------|---------|---------|---------|
| 1 | C-Sonnet | A-compact | D-Opus | B-Haiku |
| 2 | B-Haiku | D-Opus | A-compact | C-Sonnet |
| 3 | A-compact | C-Sonnet | B-Haiku | D-Opus |
| 4 | D-Opus | B-Haiku | C-Sonnet | A-compact |
| 5 | C-Sonnet | A-compact | B-Haiku | D-Opus |
| 6 | B-Haiku | D-Opus | A-compact | C-Sonnet |

### 2.5 Implementation

**Signal file mechanism**: The experiment script writes `.jicm-model-override` with the model name before triggering JICM. The watcher reads this file in `do_compress()` and passes the model to the spawn prompt.

**Modified watcher `do_compress()`** (line ~802):
```bash
# Read model override
local model="sonnet"  # default
if [[ -f "$PROJECT_DIR/.claude/context/.jicm-model-override" ]]; then
    model=$(cat "$PROJECT_DIR/.claude/context/.jicm-model-override" | tr -d '[:space:]')
    log JICM "Model override: $model"
fi

local spawn_prompt="[JICM-COMPRESS] Run /intelligent-compress --model $model NOW. Do NOT update session files. Do NOT read additional files. After spawning, say ONLY: Compression spawned."
```

**Modified `/intelligent-compress` command** (step 4):
```
4. Parse --model flag from args (default: sonnet)
   Spawn agent with Task tool:
   subagent_type: compression-agent
   model: [parsed model]
   run_in_background: true
   max_turns: 30
```

### 2.6 Measurements

| Metric | Source | Capture Method |
|--------|--------|---------------|
| Duration (s) | Watcher telemetry | `COMPRESS_START_TIME` to `CLEAR_START_TIME` |
| Tokens at trigger | tmux statusline | Pre-existing extraction |
| Tokens after restore | tmux statusline | Post-restore extraction |
| Checkpoint size (bytes) | `wc -c` on checkpoint | After compression |
| Checkpoint token estimate | `wc -w * 1.3` | Rough estimate |
| Phase times | Watcher metrics JSONL | halt/compress/clear/restore breakdown |

### 2.7 Quality Analysis (Post-Hoc)

After all 24 trials, score each JICM checkpoint (18 checkpoints, 6 per JICM model) on:

| Section | Weight | Scoring (0-5) |
|---------|--------|--------------|
| Foundation Context | 2 | 0=missing, 3=partial, 5=complete |
| Session Objective | 1 | 0=missing, 3=vague, 5=specific |
| Current Task | 2 | 0=missing, 3=partial, 5=actionable |
| Decisions Made | 1 | 0=missing, 3=some, 5=all with rationale |
| Next Steps | 1 | 0=missing, 3=generic, 5=specific+numbered |
| Resume Instructions | 1 | 0=missing, 3=partial, 5=complete |
| Key Files | 1 | 0=missing, 3=some paths, 5=all absolute paths |
| **Total** | **9** | **Max 45** |

**Scoring method**: Blind review — checkpoint filenames are anonymized before scoring.

### 2.8 Analysis Plan

**Primary**: 1-way ANOVA: `duration_s ~ C(model)` (3 JICM levels only)
- If significant: Tukey HSD post-hoc pairwise comparisons
- Effect size: Partial eta-squared

**Including /compact**: 1-way ANOVA with all 4 levels
- Expected to be significant (from Experiments 1-3)
- Interest is in JICM model comparisons, not JICM vs /compact

**Non-parametric**: Kruskal-Wallis (robustness check if normality violated)

**Quality**: Kruskal-Wallis on quality scores across 3 models

**Decision criteria**:

| Outcome | Interpretation | Action |
|---------|---------------|--------|
| Haiku significantly faster, quality >= 35/45 | Speed gain without quality loss | Switch to Haiku |
| Haiku faster but quality < 30/45 | Speed-quality tradeoff | Keep Sonnet, consider Haiku for non-critical cycles |
| No significant difference across models | Model doesn't matter | Keep Sonnet (cheapest adequate) |
| Opus faster (unlikely) | Unexpected | Investigate mechanism |

### 2.9 Timing Estimate

| Cell | Fill time | Treatment time | Reset | Per trial |
|------|-----------|---------------|-------|-----------|
| /compact | ~5 min | ~2.5 min | ~2 min | ~10 min |
| JICM-Haiku | ~5 min | ~3-5 min | ~2 min | ~12 min |
| JICM-Sonnet | ~5 min | ~5 min | ~2 min | ~12 min |
| JICM-Opus | ~5 min | ~6-8 min | ~2 min | ~15 min |

**Average**: ~12.25 min/trial × 24 = **~4.9 hours**

---

## 3. Experiment 5: Thinking Mode Effect on Compression Time

### 3.1 Hypothesis

**H0.5**: Disabling extended thinking for the compression agent has no significant effect on compression processing time.

**H1.5**: Disabling thinking significantly reduces compression time.

**Directional expectation**: Thinking-Off should be faster, but compression quality may degrade.

### 3.2 Background: Thinking Mode in Claude Code

Extended thinking adds an internal reasoning phase before output generation. Performance research shows:

| Mode | Latency | Quality (complex tasks) | Quality (simple tasks) |
|------|---------|----------------------|----------------------|
| Thinking On (default) | 10s-300s extra | +30-40% improvement | Minimal improvement |
| Thinking Off | Baseline | Baseline | Baseline |
| Thinking Budget=1024 | +5-10s | +5-10% improvement | Minimal |

**Control mechanisms available**:
- `MAX_THINKING_TOKENS=0` — Env var, disables thinking
- `CLAUDE_CODE_EFFORT_LEVEL=low` — Env var, Opus 4.6 only
- Tab key toggle — Interactive, not scriptable
- `thinking: {type: "disabled"}` — API parameter, not exposed in Task tool

**Challenge**: The Task tool used to spawn the compression agent does not have a `thinking` parameter. Thinking control must propagate via environment variables.

### 3.3 Design

**Type**: 2-level between-subjects
**Independent variable**: Thinking mode (On vs Off)
**Dependent variables**: Compression time (s), checkpoint quality score

| Cell | Treatment | Mechanism |
|------|-----------|-----------|
| A | Thinking-On | Default behavior (current) |
| B | Thinking-Off | `MAX_THINKING_TOKENS=0` set in Jarvis env before JICM trigger |

**Fixed**: Model=Sonnet, Context=~45%, Preprocessing=None

### 3.4 Sample Size

**Trials per cell**: 8
**Total trials**: 16 (8 blocks × 2 cells)
**Blocking**: Each block = 1 thinking-on + 1 thinking-off, randomized order.

### 3.5 Thinking Mode Propagation

The experiment script controls thinking mode via tmux environment injection:

```bash
# For thinking-off trials:
tmux send-keys -t jarvis:0 "export MAX_THINKING_TOKENS=0" Enter
sleep 2

# Trigger JICM cycle...

# After trial completes, cleanup:
tmux send-keys -t jarvis:0 "unset MAX_THINKING_TOKENS" Enter
sleep 2
```

**Validation**: If both cells produce identical timing distributions, propagation failed. The experiment includes a validation check:
1. After first 2 blocks (4 trials), compute interim descriptive stats
2. If means differ by < 5%, investigate propagation
3. If confirmed failure, switch to Solution A (prompt-based directive)

### 3.6 Analysis Plan

**Primary**: Independent samples t-test (or Welch's if variances differ)
**Effect size**: Cohen's d
**Non-parametric**: Mann-Whitney U (robustness check)
**Quality**: Mann-Whitney U on quality scores

**Decision criteria**:

| Outcome | Interpretation | Action |
|---------|---------------|--------|
| Thinking-Off significantly faster, quality >= 35/45 | Thinking unnecessary for compression | Disable thinking for compression agent |
| Thinking-Off faster but quality < 30/45 | Quality tradeoff | Keep thinking; consider budget=1024 as compromise |
| No significant difference | Thinking doesn't affect this task | Keep default (no overhead) |
| Both cells identical (< 5% diff) | Propagation failure | Investigate env var mechanism |

### 3.7 Timing Estimate

2 × 8 = 16 trials. ~10 min/trial avg → **~2.7 hours**

---

## 4. Experiment 6: Preprocessing Effect on Compression Time

### 4.1 Hypothesis

**H0.6**: Pre-assembling compression agent input files into a single document has no significant effect on compression processing time.

**H1.6**: Pre-assembly significantly reduces compression time by eliminating I/O turns.

**Directional expectation**: Pre-assembled should be substantially faster. The compression agent currently uses 12-17 turns for file reads (~84-170s). Pre-assembly reduces this to ~1 read turn (~7-10s). Expected savings: **74-160s** on I/O alone.

### 4.2 Design

**Type**: 2-level between-subjects
**Independent variable**: Input method (Standard vs Pre-Assembled)
**Dependent variables**: Compression time (s), agent turn count, checkpoint quality score

| Cell | Treatment | Agent Input | Expected Turns |
|------|-----------|------------|----------------|
| A | Standard (baseline) | Agent reads 10-17 files individually | ~20-25 |
| B | Pre-Assembled | Agent reads 1 pre-assembled file | ~3-5 |

**Fixed**: Model=Sonnet, Thinking=On, Context=~45%

### 4.3 Preprocessing Script Design

`preassemble-compression-input.sh` creates a single document with all sources pre-concatenated, pre-filtered, and size-capped:

**RTK-inspired filtering strategies applied**:
1. **Index compression**: Grep names only from index files (not full entries)
2. **Capability map reduction**: Extract `id` + `when` pairs only (skip full descriptions)
3. **Chat export truncation**: Keep last 40% only (most recent work)
4. **Whitespace normalization**: Collapse multiple blank lines
5. **Size capping**: Hard limit at 50,000 characters (~12,500 tokens)

**Output structure**:
```markdown
# Compression Input (Pre-Assembled)
Generated: [timestamp]

## Foundation: CLAUDE.md
[full content — 97 lines, rules must be complete]

## Foundation: Identity
[full content — 227 lines, persona must be complete]

## Foundation: Capability Map (IDs + Triggers Only)
[compressed from 363 lines to ~50 lines]

## Foundation: Compaction Essentials
[full content — 122 lines]

## Indexes (Names Only)
### Patterns: [name1, name2, ...]
### Agents: [name1, name2, ...]
### Commands: [name1, name2, ...]
### Skills: [name1, name2, ...]

## Active Tasks
[from .active-tasks.txt or "No active tasks"]

## Recent Chat History (Last 40%)
[truncated chat export]

## Session State
[from session-state.md]

## Current Priorities
[from current-priorities.md]
```

**Estimated size**: ~25,000-35,000 characters (~6,250-8,750 tokens) — well within the agent's context budget.

### 4.4 Modified Compression Agent

`compression-agent-preassembled.md` differs from the standard agent in:

| Aspect | Standard Agent | Pre-Assembled Agent |
|--------|---------------|-------------------|
| Input | 10-17 separate files | 1 pre-assembled file |
| Read calls | 12-17 | 1 |
| max_turns | 30 | 10 |
| Instructions | "Read these files..." | "Read .compression-input-preassembled.md" |
| Output format | Same | Same |
| Quality checklist | Same | Same |

### 4.5 Sample Size

**Trials per cell**: 8
**Total trials**: 16 (8 blocks × 2 cells)

### 4.6 Analysis Plan

**Primary**: Independent samples t-test on compression time
**Effect size**: Cohen's d
**Secondary**: Compare agent turn counts (from telemetry)
**Quality**: Mann-Whitney U on quality scores

**Decision criteria**:

| Outcome | Interpretation | Action |
|---------|---------------|--------|
| Pre-assembled significantly faster, quality >= 35/45 | Preprocessing works | Adopt pre-assembly for all JICM cycles |
| Pre-assembled faster but quality < 30/45 | Quality tradeoff | Investigate which sections degrade; refine preprocessor |
| No significant difference | I/O not the bottleneck | Focus on model/thinking optimization instead |

### 4.7 Timing Estimate

2 × 8 = 16 trials. ~10 min/trial avg → **~2.7 hours**

---

## 5. RTK (Rust Token Killer) — Integration Assessment

### 5.1 What RTK Is

[RTK](https://github.com/rtk-ai/rtk) is a high-performance CLI proxy written in Rust. It intercepts development commands (git, cargo, npm, etc.) and applies intelligent filtering before output reaches the LLM context window.

**Key statistics**:
- **Token savings**: 60-90% on CLI command output (83.7% over 7,061 commands in 15-day real use)
- **Architecture**: 47 Rust source files, ~8-12K LOC, single binary (4.1 MB)
- **License**: MIT (fully forkable)
- **Created**: 2026-01-22 (very new, actively maintained)

### 5.2 RTK's Nine Filtering Strategies

| Strategy | Reduction | How It Works |
|----------|----------|-------------|
| Stats extraction | 90-99% | Summarize to aggregate counts |
| Error-only filtering | 60-80% | Strip stdout, keep stderr |
| Pattern grouping | 40-60% | Categorize with occurrence counts |
| Deduplication | 50-80% | Show once with multiplier "(x127)" |
| Structure-only | 60-80% | Keep signatures, remove bodies |
| Language-aware code filtering | 30-50% | Remove comments, keep docs (9 languages) |
| Failure focus | 70-90% | Show only test/build failures |
| Tree compression | 60-80% | File counts instead of full listings |
| Progress stripping | 90-99% | Remove progress bars and spinners |

### 5.3 RTK vs Our Needs — Gap Analysis

| Aspect | RTK Designed For | Our Compression Needs | Gap |
|--------|-----------------|----------------------|-----|
| **Input type** | CLI command output | Conversation logs, markdown files | Large |
| **Token counting** | 4-char heuristic | Need accurate LLM tokenization | Large |
| **API** | CLI-only | Need library/script API | Large |
| **Filtering** | 9 strategies, language-aware | Text noise removal, dedup | Small |
| **Configuration** | TOML file | Custom rules per file type | Moderate |
| **Deduplication** | Log-line level | Conversation turn level | Moderate |

### 5.4 Verdict: Learn, Don't Fork

**Recommendation**: Borrow RTK's filtering patterns for our bash preprocessing script. Do NOT fork the Rust codebase.

**Rationale**:
1. **Domain mismatch**: RTK is optimized for CLI output; our input is conversation logs and markdown files
2. **Effort disproportionate**: 8-14 days of Rust work to adapt, vs 1 day for a bash preprocessor
3. **No library API**: RTK exposes only CLI interface; we need programmatic integration
4. **Token heuristic inaccurate**: RTK's 4-char-per-token approximation is insufficient for precise context budgeting
5. **Scope creep risk**: Maintaining a Rust fork adds permanent maintenance burden

**What we borrow** (into `preassemble-compression-input.sh`):
- **Smart truncation**: Preserve structural elements (headings, first/last lines), skip middle
- **Index compression**: Extract names only from catalogs
- **Size capping**: Hard character limit to prevent overload
- **Whitespace normalization**: Collapse blank lines
- **Pattern grouping**: Summarize repeated patterns with counts

### 5.5 Future Consideration

If JICM compression becomes a performance-critical path (e.g., compression cycles increase 10x), RTK-style Rust preprocessing could be revisited. The extraction path would be:

1. Fork `rtk-ai/rtk`
2. Extract `filter.rs` + `utils.rs` into standalone `rtk-filters` crate
3. Replace 4-char heuristic with `tiktoken-rs`
4. Add conversation-aware filtering (turn-level dedup, tool output masking)
5. Expose Rust library API callable from bash via `rtk-preprocess` binary
6. Estimated effort: 8-14 days

---

## 6. Combined Optimization Potential

### Multiplicative Effect

If all three optimizations yield improvements, they combine multiplicatively:

| Configuration | Compress Phase (estimated) | Total Cycle (estimated) |
|---------------|--------------------------|------------------------|
| **Current** (Sonnet, Thinking-On, No Preprocessing) | ~220s | ~285s |
| Haiku only | ~100-130s | ~165-195s |
| Thinking-Off only | ~150-180s? | ~215-245s? |
| Preprocessing only | ~60-90s | ~125-155s |
| **Haiku + Thinking-Off + Preprocessing** | **~20-40s?** | **~85-105s?** |

**Best case scenario**: Compress phase drops from ~220s to ~20-40s — a **5-10x improvement**. Total cycle drops from ~285s to ~85-105s, approaching /compact's ~77s.

### Combined Experiment (Future)

After the three individual experiments, if multiple optimizations prove effective, a combined experiment tests the full stack:
- Treatment: Current vs Optimized (Haiku + Thinking-Off + Preprocessing)
- 8 trials per cell = 16 total
- Validates that the multiplicative estimate holds

---

## 7. Execution Plan

### Phase 1: Infrastructure Setup (~2-3 hours implementation)

1. Modify `/intelligent-compress` — Add `--model` and `--preassemble` flags
2. Modify watcher `do_compress()` — Read override signal files
3. Create `preassemble-compression-input.sh` — RTK-inspired preprocessing
4. Create `compression-agent-preassembled.md` — Single-file-input agent variant
5. Create `run-experiment-4.sh`, `run-experiment-5.sh`, `run-experiment-6.sh`
6. Extend `analyze-regression.py` — 1-way ANOVA, quality scoring

### Phase 2: Experiment 4 — Model Selection (~4.9 hours)
- 6 blocks × 4 trials = 24 trials
- Run in W5:Jarvis-dev
- Score checkpoint quality after completion

### Phase 3: Experiment 5 — Thinking Mode (~2.7 hours)
- 8 blocks × 2 trials = 16 trials
- Validate thinking propagation after block 2
- Run in W5:Jarvis-dev

### Phase 4: Experiment 6 — Preprocessing (~2.7 hours)
- 8 blocks × 2 trials = 16 trials
- Compare turn counts and quality
- Run in W5:Jarvis-dev

### Phase 5: Analysis and Report (~1 hour)
- Run all statistical analyses
- Compare effect sizes across experiments
- Identify optimal configuration
- Write final report: `experiment-4-5-6-report.md`
- Update JICM configuration if warranted

**Total**: ~13-14 hours (infrastructure + 3 experiments + analysis)
**Spans**: 3-4 sessions (block design is resumable)

---

## 8. Files

### To Create

| File | Purpose |
|------|---------|
| `.claude/scripts/dev/run-experiment-4.sh` | Model selection experiment orchestrator |
| `.claude/scripts/dev/run-experiment-5.sh` | Thinking mode experiment orchestrator |
| `.claude/scripts/dev/run-experiment-6.sh` | Preprocessing experiment orchestrator |
| `.claude/scripts/dev/preassemble-compression-input.sh` | RTK-inspired input pre-assembly |
| `.claude/agents/compression-agent-preassembled.md` | Single-file compression agent |
| `.claude/reports/testing/experiment-4-data.jsonl` | Model selection trial data |
| `.claude/reports/testing/experiment-5-data.jsonl` | Thinking mode trial data |
| `.claude/reports/testing/experiment-6-data.jsonl` | Preprocessing trial data |
| `.claude/reports/testing/experiment-4-5-6-report.md` | Combined final report |

### To Modify

| File | Change |
|------|--------|
| `.claude/commands/intelligent-compress.md` | Add `--model` and `--preassemble` flags |
| `.claude/scripts/jicm-watcher.sh` | Read override signal files in `do_compress()` |
| `.claude/scripts/dev/analyze-regression.py` | Add 1-way ANOVA, quality scoring |

### Existing (Read-Only)

| File | Used For |
|------|----------|
| `.claude/scripts/dev/context-fill.sh` | Context fill to target % |
| `.claude/scripts/dev/time-compact.sh` | /compact timing |
| `.claude/scripts/dev/restart-watcher.sh` | Watcher control |
| `.claude/agents/compression-agent.md` | Current agent definition |
| `.claude/context/workflows/wiggum-loop.md` | Test methodology |
| `.claude/reports/testing/compression-exp3-data.jsonl` | Exp 3 baseline data |

---

## 9. Risks and Mitigations

| Risk | Impact | Probability | Mitigation |
|------|--------|-------------|------------|
| Haiku checkpoint quality too low | Unusable checkpoint, lost context | Medium | Score quality; keep Sonnet fallback |
| Thinking toggle doesn't propagate | Exp 5 tests same condition twice | Medium | Validate after block 2; switch to prompt-based |
| Preprocessing changes agent output | Different compression quality | Low | Same quality checklist; score blind |
| Env var leakage between trials | Confounded data | Low | Reset vars + signal files between every trial |
| 13-14 hours total runtime | Spans multiple sessions | High | Block design resumable; JSONL append-only |
| Rate limiting inflates times | Confounded DV | Medium | Randomize within blocks; include time-of-day as covariate |
| tmux pane staleness (Exp 3 issue) | Failed trials | Medium | Budget for 20% failure rate; fill script hardened |
| Opus too slow / rate limited | Missing Opus data | Medium | Record as censored; exclude from ANOVA if < 4 trials |

---

*Experiment 4-5-6 Protocol — JICM Compression Optimization*
*14 February 2026 — Infrastructure complete, ready for execution*
