# Experiment 3: Context Volume Effect — Revised (40% vs 70%)

**Project**: Jarvis JICM v6.1 — Regression Analysis (Revised)
**Date**: 2026-02-13
**Branch**: Project_Aion
**Predecessor**: Experiment 2 (failed at 75% due to emergency handler preemption)
**Status**: PROTOCOL REVIEW

---

## 1. Motivation

Experiment 2 found JICM 100% failure at >=74% context. Root cause: the emergency /compact handler (EMERGENCY_PCT=73%) preempts the JICM cycle. This revised experiment uses 70% as the high level — safely below EMERGENCY_PCT, within JICM's operational envelope [0%, 72%].

## 2. Hypotheses

**H0.1**: Context window token count has no significant effect on compression processing time.

**H0.2**: The effect of context token count on compression time does not differ between /compact and JICM (no interaction).

**Prior from Exp 2**: No main effect of volume found (F=1.31, p=0.277), but JICM-high cell was empty (all failures). This experiment fills that gap.

## 3. Design

### 2x2 Factorial

| | Low (~40%) | High (~70%) |
|---|-----------|-----------|
| **/compact** | Cell A: n=6 | Cell B: n=6 |
| **JICM** | Cell C: n=6 | Cell D: n=6 |

**Total**: 24 trials (6 per cell), organized in 6 blocks of 4.

### Context Level Specifications

| Level | Target | Tolerance | Token Range (approx) | Safety Margin |
|-------|--------|-----------|---------------------|---------------|
| **Low** | 40% | ±2% (38-42%) | ~76,000 - 84,000 | 33% to emergency |
| **High** | 70% | ±1% (69-71%) | ~138,000 - 142,000 | 3% to emergency (73%) |

### High-Level Safety Protocol (70%)

- Fill ceiling: 72% (2 points below EMERGENCY_PCT=73%)
- Fill tolerance: ±1% (tight, prevents overshoot to 72%+)
- Watcher threshold during fill: 80% (prevents premature JICM trigger)
- JICM trigger: restart watcher at threshold=65% (70% >= 65% triggers cycle)
- Emergency safeguard: 70% < 73%, so emergency handler does NOT fire
- If fill reaches 72%: script auto-aborts (ceiling protection)
- If fill reaches 73%+: should be impossible with ceiling=72; if it happens, watcher at 80% won't trigger, but next restart could emergency-fire

### Trial Execution Order

Pre-randomized balanced block design:

| Block | Trial 1 | Trial 2 | Trial 3 | Trial 4 |
|-------|---------|---------|---------|---------|
| 1 | C-low (JICM 40%) | B-high (/compact 70%) | A-low (/compact 40%) | D-high (JICM 70%) |
| 2 | A-high (/compact 70%) | D-low (JICM 40%) | B-low (/compact 40%) | C-high (JICM 70%) |
| 3 | D-high (JICM 70%) | A-low (/compact 40%) | C-high (JICM 70%) | B-low (/compact 40%) |
| 4 | B-high (/compact 70%) | C-low (JICM 40%) | D-low (JICM 40%) | A-high (/compact 70%) |
| 5 | C-high (JICM 70%) | B-low (/compact 40%) | A-high (/compact 70%) | D-low (JICM 40%) |
| 6 | A-low (/compact 40%) | D-high (JICM 70%) | B-high (/compact 70%) | C-low (JICM 40%) |

### Timing Estimates

| Cell | Fill time | Treatment time | Reset | Total per trial |
|------|-----------|---------------|-------|----------------|
| /compact-low | ~3 min | ~1.5 min | ~0.5 min | **~5 min** |
| /compact-high | ~10 min | ~1.5 min | ~0.5 min | **~12 min** |
| JICM-low | ~3 min | ~5 min | ~0.5 min | **~9 min** |
| JICM-high | ~10 min | ~5 min | ~0.5 min | **~16 min** |

**Average**: ~10.5 min/trial x 24 trials = **~4.2 hours**

## 4. Analysis Plan

### Primary: Factorial ANCOVA

```
compression_time ~ C(treatment) * token_count
```

Three F-tests:
1. C(treatment): Treatment main effect (expected significant from Exp 1+2)
2. token_count: Main effect of context volume (tests H0.1)
3. C(treatment):token_count: Interaction (tests H0.2)

### Secondary Analyses

1. Within-treatment linear regression: token_count -> compression_time (per treatment)
2. Spearman correlation + Fisher z-test comparing the two correlations
3. JICM phase-level regression: phase_time ~ token_count
4. Compression ratio analysis per cell

### Assumption Checks

- Shapiro-Wilk on residuals
- Per-cell normality
- Levene's test for homoscedasticity
- If violated: Kruskal-Wallis fallback

## 5. Infrastructure

### Scripts

| Script | Role |
|--------|------|
| `run-experiment-3.sh` | Master orchestration — runs all 24 trials |
| `run-compression-trial.sh` | Single trial execution (--single mode) |
| `context-fill.sh` | Deterministic context filling |
| `time-compact.sh` | /compact timing |
| `restart-watcher.sh` | Watcher threshold control |
| `watch-jicm.sh` | JICM state monitoring |
| `analyze-regression.py` | Statistical analysis (reused from Exp 2) |

### Data Files

| File | Purpose |
|------|---------|
| `.claude/reports/testing/compression-exp3-data.jsonl` | Trial data (append-only) |
| `.claude/reports/testing/experiment-3-report.md` | Final analysis report |

### Stopping Rules

- **Futility**: If both 70% JICM trials in Block 1 timeout (emergency fires), STOP — 70% is still above effective ceiling
- **Early success**: If results are clearly significant/null after Block 4 (n=4/cell), stop early
- **Safety**: If any trial reaches 73%+ context, abort that trial and investigate

## 6. Risks

| Risk | Mitigation |
|------|-----------|
| Fill overshoots to 73%+ | Ceiling=72%, tolerance=±1% |
| Emergency handler fires at 70% | Impossible: 70% < 73%. Verified in watcher code. |
| JICM timeout at 70% | Budget for 1-2 timeouts per cell (record as censored) |
| CC auto-compact during fill | Watcher at 80% prevents JICM; CC native at ~85% (safe) |
| Context not reproducible | Same fill file sequence, tight tolerance |

---

*Protocol version 1.0 — Experiment 3*
