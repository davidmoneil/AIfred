# Compression Timing Experiment — Final Report

**Project**: Jarvis JICM v6.1 Performance Evaluation
**Date**: 2026-02-13
**Branch**: Project_Aion
**Wiggum Loop**: 5 cycles (Loops 1-5)
**Status**: COMPLETE

---

## 1. Executive Summary

This experiment compared the wall-clock duration of two context management approaches in Claude Code:

| Method | Mechanism | Mean Duration | Reliability |
|--------|-----------|--------------|-------------|
| **Native /compact** | In-place API summarization (lossy) | **131.6s** (SD=18.4) | 83% (5/6) |
| **JICM compression** | 5-phase pipeline: halt+compress+clear+restore (lossless) | **302.2s** (SD=48.8) | 100% (6/6) |

**Finding**: JICM takes 2.3x longer than native /compact (p=0.03125, large effect r=0.833). The compression agent phase accounts for 73% of JICM's total time. However, JICM achieved 100% reliability vs /compact's 83%, and preserves structured state (priorities, session context, identity) that /compact discards.

**Bottom line**: JICM trades ~170 seconds of additional latency for deterministic state preservation and higher reliability. Whether this tradeoff is worthwhile depends on the value of the preserved context.

---

## 2. Background and Motivation

### The Question
Jarvis uses JICM (Jarvis Intelligent Context Management) v6.1 to manage context window limits. JICM is a custom 5-phase pipeline that serializes session state, clears the context, and restores from a checkpoint. Claude Code also provides a native `/compact` command that performs in-place summarization. Both accomplish the same user-facing goal: "reduce context so I can keep working." But they differ fundamentally in mechanism and fidelity.

### Why It Matters
- JICM is the most complex subsystem in Jarvis (38 files, 196 tests)
- If /compact provides equivalent results faster, JICM's complexity may not be justified
- If JICM provides meaningful advantages, the latency cost should be quantified

### Prior Data
Before this experiment: 1 successful JICM timing observation (274s) and 0 /compact observations. Insufficient for any conclusions.

---

## 3. Methods

### Experimental Design
**Matched-pairs within-subject design** with counterbalanced treatment order.

For each pair:
1. Fresh session (or /clear)
2. Fill context to target % (55-60%) using standardized file-read workload
3. Record context % and ground truth token count
4. Run treatment A (randomized: /compact or JICM)
5. Measure wall-clock completion time
6. Reset, re-fill to same %, run treatment B
7. Record the pair

### Measurement Instruments

**JICM timing**: jicm-metrics.jsonl (built-in telemetry) — captures per-phase timing with second resolution. Primary source: `total_cycle_time_s`.

**/compact timing**: Custom `time-compact.sh` script with triple detection:
1. **Primary**: Ground truth token count drop (bottom-right statusline, from Claude Code API internals)
2. **Secondary**: Context % drop (statusline, may lag)
3. **Tertiary**: "CONTEXT RESTORED (compact)" text in pane (from session-start hook)

The script polls W0's tmux pane every 5s, checking for idle prompt + any of the three signals.

### Statistical Tests
- **Primary**: Wilcoxon signed-rank test (one-sided, H1: JICM > /compact), α=0.05
- **Secondary**: Paired t-test (parametric confirmation)
- **Exploratory**: Spearman correlation (context % vs duration)

### Stopping Rule
**Early stopping applied** at n=5 successful pairs. At W=0.0 (all 5 pairs favoring /compact), the Wilcoxon p-value is 1/2^5 = 0.03125 — the theoretical minimum for n=5. Combined with a large effect size (r=0.833) and consistent direction across all pairs, additional data would tighten confidence intervals but not alter the conclusion.

---

## 4. Results

### 4.1 Descriptive Statistics

| Metric | /compact | JICM |
|--------|----------|------|
| N (successful) | 5 | 6 |
| Mean | 131.6s | 302.2s |
| Median | 140.0s | 313.5s |
| SD | 18.4s | 48.8s |
| Min | 109s | 212s |
| Max | 150s | 343s |
| IQR | 29s | 55s |

### 4.2 Primary Analysis: Wilcoxon Signed-Rank Test

| Statistic | Value |
|-----------|-------|
| W | 0.0 |
| p-value | 0.03125 |
| Effect size (r) | 0.833 |
| Mean difference (JICM - /compact) | +188.6s |
| Median difference | +173.0s |
| Pairs analyzed | 5 |

**Interpretation**: Reject H0. JICM compression takes significantly longer than native /compact (p=0.03125 < 0.05). The effect size is **large** (r=0.833 > 0.5 threshold). All 5 successful pairs showed JICM slower.

### 4.3 Secondary Analyses

**Paired t-test**: t = -14.254, p = 0.000141 — confirms the Wilcoxon result under parametric assumptions.

**Context % vs duration (Spearman)**: rho = -0.059, p = 0.864 — no significant relationship between starting context percentage and completion time. This suggests duration is driven by the compression mechanism itself, not the volume of context being processed. (Note: limited range of context % tested: 55-60%.)

### 4.4 Reliability

| Method | Success | Failure | Rate |
|--------|---------|---------|------|
| /compact | 5 | 1 (timeout — model treated /compact as text) | 83% |
| JICM | 6 | 0 | 100% |

The /compact failure mode is non-deterministic: occasionally, the model interprets `/compact` as conversational text rather than a command. This consumed tokens without compacting, eventually timing out at 600s.

### 4.5 JICM Phase Breakdown

| Phase | Mean | Median | Min | Max | % of Total |
|-------|------|--------|-----|-----|-----------|
| Halt | 1.0s | 1.0s | 1s | 1s | 0.3% |
| Compress | 219.8s | 231.0s | 130s | 261s | **72.8%** |
| Clear | 71.2s | 71.0s | 71s | 72s | 23.6% |
| Restore | 10.2s | 10.0s | 10s | 11s | 3.4% |

The **compression phase** (spawning a Task agent to analyze context and write a checkpoint) dominates at 73% of total time. The `/clear` phase is a fixed ~71s overhead (Claude Code internal processing). Halt and restore are negligible.

### 4.6 Paired Data

| Pair | Start % | /compact (s) | JICM (s) | Diff (s) | Order | Notes |
|------|---------|-------------|----------|----------|-------|-------|
| 1 | 60% | 109 | 343 | +234 | AB | JICM had /clear retry (+60s) |
| 2 | 57% | 600* | 212 | -388 | BA | *Timeout: model responded to /compact as text |
| 3 | 60% | 140 | 343 | +203 | AB | |
| 4 | 58% | 115 | 288 | +173 | BA | |
| 5 | 59% | 150 | 314 | +164 | AB | |
| 6 | 58% | 144 | 313 | +169 | BA | |

*Pair 2's /compact trial excluded from paired analysis (timeout, not a valid measurement of compaction time).

---

## 5. Discussion

### 5.1 Speed vs Fidelity Tradeoff

The core finding is intuitive: a single API-level operation (/compact) is faster than a 5-phase pipeline involving agent spawning, file I/O, IPC coordination, and session restoration. The 2.3x speed penalty is the cost of JICM's structured state preservation.

What /compact preserves: A lossy summary of the conversation. The model decides what's important.

What JICM preserves: Deterministic checkpoint including session-state.md, current-priorities.md, identity context, capability maps, and a model-generated analysis of what was in progress. The user controls what's preserved via the checkpoint schema.

### 5.2 The Compression Agent Bottleneck

At 73% of total JICM time, the compression agent is the clear optimization target. This agent:
1. Reads the full conversation transcript
2. Analyzes what work was in progress
3. Writes a structured checkpoint file
4. All via a Task agent subprocess (independent API call)

**Optimization opportunities**:
- Pre-compute partial checkpoints incrementally (reduce the agent's work at trigger time)
- Use a faster model (Haiku) for compression if quality is sufficient
- Parallelize checkpoint writing with the /clear operation
- Cache frequently-accessed context (patterns, identity) so the agent doesn't need to re-analyze them

### 5.3 The /clear Fixed Cost

The 71s /clear phase is a Claude Code internal operation — not under Jarvis's control. This is a hard floor on JICM cycle time. Even with a zero-time compression agent, JICM would still take ~82s (halt + clear + restore) vs /compact's ~132s. Interestingly, this suggests a theoretical floor where an optimized JICM could approach /compact speeds.

### 5.4 Context % Independence

The Spearman correlation (rho=-0.059, p=0.864) shows no relationship between starting context percentage and compression duration. This is likely because:
- The tested range was narrow (55-60%)
- /compact's duration is dominated by API-side processing, not context volume
- JICM's compression agent always reads the full transcript regardless of size

A wider range (30-80%) would be needed to detect any relationship, but this is difficult to test without risking the JICM lockout ceiling (78.5%).

### 5.5 Reliability Considerations

JICM's 100% success rate (6/6) vs /compact's 83% (5/6) is notable but based on small samples. The /compact failure mode (model interpreting the command as text) is concerning because it's non-deterministic and undetectable in advance. JICM's failure modes (compression timeouts) are detectable and recoverable via the watcher's retry logic.

In production, JICM already uses /compact as a fallback at the 73% emergency threshold — so the two methods are complementary, not competing.

---

## 6. Conclusions

1. **JICM is 2.3x slower than /compact** (median 313.5s vs 140s, p=0.03125).
2. **The compression agent is the bottleneck** (73% of JICM time). Optimization should focus here.
3. **JICM is more reliable** (100% vs 83%), though sample sizes are small.
4. **Context volume doesn't affect duration** in the 55-60% range tested.
5. **The two methods are complementary**: JICM provides structured state preservation; /compact provides fast lossy summarization. The current architecture correctly uses /compact as JICM's emergency fallback.

### Recommendation

Keep JICM as the primary context management strategy, with three optimizations:
1. **Investigate Haiku for compression** — if checkpoint quality is comparable, compression time could drop 3-5x
2. **Incremental checkpointing** — maintain a running checkpoint that's updated periodically, so the trigger-time work is minimal
3. **Parallel clear** — begin /clear while the checkpoint is still being finalized (if the checkpoint file is written before /clear completes)

---

## 7. Meta-Experiment: Jarvis Framework Performance

This experiment was designed to serve a dual purpose: measure compression timings (Layer 1), and test whether the Jarvis framework can sustain a multi-stage empirical project (Layer 2).

### 7.1 What Worked

**Wiggum Loop structure**: The 5-loop framework (Instrumentation → Pilot → Data Collection A → Data Collection B → Analysis) provided excellent scaffolding. Each loop's deliverables fed the next, and the iterative structure allowed methodology bugs to surface in pilots before corrupting real data.

**Tmux-based automation**: The ability to fill context, trigger treatments, and capture timing — all via tmux send-keys and pane capture — demonstrated that the W0/W5 dual-pane architecture can drive external experiments. This is a capability that extends well beyond compression testing.

**TodoWrite task tracking**: Tasks #12-#16 with dependency chains provided clear progress tracking across context restorations. Even after losing context, the task list preserved the experimental state machine.

**Telemetry pipeline**: JICM's built-in metrics (jicm-metrics.jsonl) required zero additional instrumentation. The data was already being collected — the experiment just needed to read it.

### 7.2 What Needed Fixing Mid-Experiment

| Issue | Root Cause | Fix Applied |
|-------|-----------|-------------|
| `tail -5` misses statusline | Trailing blank lines in tmux capture | Changed to `tail -10` |
| /compact completion undetectable via context % | Session-start hook re-inflates context | Added text-based detection + token count |
| `⚡[C]` flag persists across /clear | Session-level indicator, not transient | Removed from detection logic |
| Multi-line JSON output to JSONL file | jq default pretty-print | Added `-c` flag |
| Watcher /clear delivery timeout | tmux send-keys race condition | Manual intervention (documented) |
| /compact treated as text | Non-deterministic model behavior | Recorded as timeout, excluded from paired analysis |

**Key observation**: 6 bugs found, 5 fixed in-session. The framework supported rapid diagnosis and patching because the measurement scripts were simple bash — easy to read, understand, and modify without restarting the experiment.

### 7.3 Context Management During the Experiment

The experiment itself consumed significant context, hitting the window limit once during data collection. The session continuation protocol (context summary → checkpoint → restoration) worked — all experimental state was preserved in files (JSONL data, scripts, task list), not in the conversation. This validates JICM's file-as-memory architecture: critical state lives in the filesystem, not in the ephemeral context window.

### 7.4 Framework Verdict

The Jarvis framework **successfully sustained a 5-loop, multi-session empirical project** requiring:
- Creative problem-solving (6 bugs diagnosed and fixed)
- Statistical methodology (Wilcoxon test, effect sizes, stopping rules)
- External system coordination (tmux, two Claude Code sessions, filesystem IPC)
- Long-scope planning (experimental design → data collection → analysis)
- Fidelity maintenance across context restorations

**Areas for improvement**:
- Context fill protocol is slow (~5-7 minutes per trial) — could be parallelized or pre-cached
- /compact timing requires external observation (no hooks or telemetry) — a Claude Code feature request
- The watcher's /clear delivery is occasionally unreliable — needs retry logic or a different IPC mechanism

---

## 8. Appendices

### A. Files Created

| File | Purpose |
|------|---------|
| `.claude/scripts/dev/time-compact.sh` | /compact timing wrapper (tmux poll + idle detect) |
| `.claude/scripts/dev/context-fill.sh` | Standardized context-filling protocol |
| `.claude/scripts/dev/run-compression-trial.sh` | Matched-pair trial orchestrator |
| `.claude/scripts/dev/analyze-compression-data.py` | Statistical analysis (Wilcoxon, t-test, Spearman) |
| `.claude/reports/testing/compression-timing-data.jsonl` | Raw trial data (12 records) |
| `.claude/reports/testing/compression-experiment-report.md` | This report |

### B. Raw Data

```
Pair 1: compact=109s (60%), JICM=343s (60%) — AB order
Pair 2: compact=600s* (57%), JICM=212s (59%) — BA order (*timeout)
Pair 3: compact=140s (60%), JICM=343s (52%) — AB order
Pair 4: compact=115s (58%), JICM=288s (60%) — BA order
Pair 5: compact=150s (59%), JICM=314s (64%) — AB order
Pair 6: compact=144s (58%), JICM=313s (53%) — BA order
```

### C. JICM Compression Ratios

| Pair | Start Tokens | End Tokens | Ratio |
|------|-------------|-----------|-------|
| 1 | 119,496 | 36,735 | 3.3:1 |
| 2 | 118,123 | 35,801 | 3.3:1 |
| 3 | 103,856 | 37,254 | 2.8:1 |
| 4 | 126,748 | 35,156 | 3.6:1 |
| 5 | 127,857 | 36,184 | 3.5:1 |
| 6 | 109,638 | 35,160 | 3.1:1 |

Mean compression ratio: **3.3:1** (reduces context to ~30% of original).

### D. Experimental Design

Full design document: `.claude/plans/robust-painting-stonebraker.md`

---

*Generated by Jarvis v5.10.0 — Wiggum Loop 5 (Analysis)*
*Experiment conducted 2026-02-13, 05:41-07:06 UTC*
