# Plan: Context Volume Effect on Compression Time — Regression Experiment

## Context

The first compression timing experiment (Experiment 1) established that JICM is 2.3x slower than native /compact (p=0.03125). A secondary finding was that context percentage showed no correlation with compression duration (Spearman rho=-0.059, p=0.864). However, that test was underpowered: only 11 data points across a narrow range (52-64%). This follow-up experiment uses widely separated context levels (45% vs 75%) with sufficient replication to properly test whether context volume affects compression time, and whether that effect differs between /compact and JICM.

**Experiment 1 data**: `.claude/reports/testing/compression-timing-data.jsonl` (12 records)
**Experiment 1 report**: `.claude/reports/testing/compression-experiment-report.md`

---

## Hypotheses

**H₀.1**: Context window token count has no significant effect on compression processing time (main effect of context level).

**H₀.2**: The effect of context window token count on compression time does not differ between /compact and JICM (no treatment x context interaction).

**Directional expectations**:
- /compact might scale with context volume (more text to summarize -> longer)
- JICM's compress phase might scale (more conversation to analyze -> longer agent work)
- JICM's clear (71s fixed) and restore (10s fixed) phases should NOT scale
- If neither scales, both treatments are API-bound (model thinking time) not data-bound

---

## Experimental Design

### 2x2 Between-Subjects Factorial

| | 45% (Low) | 75% (High) |
|---|-----------|-----------|
| **/compact** | Cell A: n=8 | Cell B: n=8 |
| **JICM** | Cell C: n=8 | Cell D: n=8 |

**Total**: 32 trials (8 per cell)

### Variables

| Variable | Type | Description |
|----------|------|-------------|
| **Treatment** (IV1) | Categorical | /compact vs JICM |
| **Context level** (IV2) | Categorical (2 levels) | Low (~45%) vs High (~75%) |
| **Token count** (covariate) | Continuous | Actual ground truth tokens at trigger (varies within band) |
| **Compression time** (DV) | Continuous (seconds) | Wall-clock from trigger to completion |
| **End tokens** (DV2) | Continuous | Post-compression token count (for ratio analysis) |
| **Trial order** (nuisance) | Ordinal | Randomized to prevent systematic effects |

### Context Level Specifications

| Level | Target | Tolerance | Token Range (approx) | Safety Margin to Lockout |
|-------|--------|-----------|---------------------|--------------------------|
| **Low** | 45% | +/-2% (43-47%) | ~86,000 - 94,000 | 33.5% (safe) |
| **High** | 75% | +/-1% (74-76%) | ~148,000 - 152,000 | 3.5% (tight) |

### High-Range Safety Protocol (75%)

The 78.5% lockout ceiling makes 75% trials high-risk. Mitigations:
1. **Watcher threshold at 80%** -- prevents JICM from auto-triggering during fill
2. **Tight tolerance +/-1%** -- fill script stops at 74-76%, never overshooting to 77%+
3. **Pre-fill validation** -- verify watcher state is WATCHING and threshold is 80% before each high trial
4. **Abort procedure** -- if fill reaches 76%, stop immediately; if 77%, send /clear
5. **JICM trigger method** -- for JICM-high trials, lower threshold to 70% (triggers at 75%), not to 74% (too close to emergency)

### Trial Execution Order

Pre-randomized block design (each block = 4 trials, one per cell):

| Block | Trial 1 | Trial 2 | Trial 3 | Trial 4 |
|-------|---------|---------|---------|---------|
| 1 | C-low | A-high | D-low | B-high |
| 2 | B-low | D-high | A-low | C-high |
| 3 | A-low | C-high | B-low | D-high |
| 4 | D-low | B-high | C-low | A-high |
| 5 | C-high | A-low | D-high | B-low |
| 6 | B-high | D-low | A-high | C-low |
| 7 | A-high | C-low | B-high | D-low |
| 8 | D-high | B-low | C-high | A-low |

(A=/compact-low, B=/compact-high, C=JICM-low, D=JICM-high)

**Blocking rationale**: Each block contains one trial per cell, randomized within block. Controls for time-of-day and API load variation. If experiment is interrupted, complete blocks provide balanced partial data.

### Timing Estimate

| Cell | Fill time | Treatment time | Reset | Total per trial |
|------|-----------|---------------|-------|----------------|
| /compact-low | ~5 min | ~2.5 min | ~2 min | **~10 min** |
| /compact-high | ~12 min | ~2.5 min | ~2 min | **~17 min** |
| JICM-low | ~5 min | ~5 min | ~2 min | **~12 min** |
| JICM-high | ~12 min | ~5 min | ~2 min | **~19 min** |

**Average**: ~14.5 min/trial x 32 trials = **~7.7 hours** total

This is longer than Experiment 1 (~2 hours). The increased duration is justified by the need for sufficient per-cell replication (n=8) to detect medium effects. Can be run across 2-3 sessions (blocks are resumable).

---

## Analysis Plan

### Primary Analysis: Factorial ANCOVA with Interaction

```python
from statsmodels.formula.api import ols
import statsmodels.api as sm

# Model: compression_time = treatment + token_count + treatment:token_count
model = ols('compression_time ~ C(treatment) * token_count', data=df).fit()
anova_table = sm.stats.anova_lm(model, typ=2)  # Type II SS
```

This yields three F-tests:
1. **C(treatment)**: Main effect of treatment (expected significant, from Exp 1)
2. **token_count**: Main effect of context volume -> **tests H0.1**
3. **C(treatment):token_count**: Interaction -> **tests H0.2**

**Effect size**: Partial eta-squared for each term.
**Thresholds**: eta-sq < 0.01 negligible, 0.01-0.06 small, 0.06-0.14 medium, > 0.14 large.
**Alpha**: 0.05 (no correction needed -- 2 planned contrasts within omnibus ANOVA).

### Secondary Analyses

1. **Within-treatment regression** (per user request):
   ```python
   # Separate linear regressions: token_count -> compression_time
   from scipy.stats import linregress, spearmanr
   slope, intercept, r, p, se = linregress(compact_df['token_count'], compact_df['compression_time'])
   ```
   Reports: slope (seconds per 10,000 tokens), R-squared, p-value, 95% CI on slope.

2. **Spearman correlation** (non-parametric robustness check):
   - Within /compact: rho, p
   - Within JICM: rho, p
   - Fisher z-test to compare the two correlations

3. **JICM phase-level analysis**:
   - Separate regression for each phase: compress_time ~ token_count, clear_time ~ token_count
   - Tests whether the bottleneck (compress phase) scales with context while fixed phases don't

4. **Compression ratio analysis**:
   - /compact ratio at 45% vs 75% (new data from hardened end_tokens capture)
   - JICM ratio at 45% vs 75% (from existing metrics)

### Assumption Checks

- **Normality**: Shapiro-Wilk on residuals per cell (n=8 is marginal; use Q-Q plots)
- **Homoscedasticity**: Levene's test across cells
- **Linearity**: Residual vs fitted plot
- **If violations**: Fall back to non-parametric alternatives (Kruskal-Wallis, permutation test for interaction)

### Decision Criteria

| Result | Interpretation | Action |
|--------|---------------|--------|
| H0.1 rejected (p<0.05, eta-sq>0.06) | Context volume affects compression time | Quantify: how many seconds per 10K tokens? |
| H0.1 not rejected | No evidence of scaling | Report equivalence bounds; confirm API-bound |
| H0.2 rejected (p<0.05) | Effect differs between treatments | Identify which treatment scales more |
| H0.2 not rejected | Both treatments scale (or don't) similarly | Unified model for predicting compression time |

---

## Wiggum Loop Mapping

### Loop 1: Instrumentation and Validation (3-5 tests)

**Goal**: Extend existing scripts to handle 75% safely, validate timing capture at both levels.

| Test | Method | Pass Criteria |
|------|--------|--------------|
| T1.1: Fill to 75% safely | context-fill.sh --target 75 --tolerance 1 | Reaches 74-76% without exceeding 76% |
| T1.2: /compact at 75% with end_tokens | time-compact.sh | end_tokens > 0 (model-turn probe works) |
| T1.3: JICM at 45% triggered via threshold | restart-watcher + fill | JICM cycle completes, metrics recorded |
| T1.4: JICM at 75% triggered safely | threshold=70, fill to 75% | Cycle completes without lockout |
| T1.5: New analysis script validates | analyze-regression.py on pilot data | ANOVA table + interaction term computed |

**Deliverables**: Updated scripts, pilot data (4 trials), validated measurement at both levels.

### Loop 2: Blocks 1-2 Data Collection (8 trials)

**Goal**: First 2 balanced blocks (8 trials, 2 per cell).

**Deliverables**: 8 trial records in JSONL, interim descriptive stats.

### Loop 3: Blocks 3-4 Data Collection (8 trials)

**Goal**: Blocks 3-4 (8 more trials), reaching n=4 per cell.

**Interim analysis**: Run preliminary ANOVA at n=4/cell. If effect is very large (eta-sq>0.25) or clearly absent (eta-sq<0.01), consider stopping early.

**Deliverables**: 16 cumulative trials, preliminary ANOVA results.

### Loop 4: Blocks 5-8 Data Collection (16 trials)

**Goal**: Final 4 blocks, completing n=8 per cell.

**Deliverables**: 32 total trials, all data collected.

### Loop 5: Analysis and Reporting (3-5 tests)

**Goal**: Run full statistical analysis, generate report, compare with Experiment 1.

| Test | Method | Pass Criteria |
|------|--------|--------------|
| T5.1: ANCOVA analysis | analyze-regression.py --verbose | p-values, effect sizes, interaction plot |
| T5.2: Within-treatment regressions | Separate slopes, R-squared | Regression tables for both treatments |
| T5.3: JICM phase breakdown | Phase-level regression | Identifies which phase(s) scale |
| T5.4: Assumption checks | Shapiro-Wilk, Levene, Q-Q | Document any violations + fallbacks |
| T5.5: Final report | Write to compression-regression-report.md | Complete with methods, results, discussion |

**Deliverables**: Final report, comparison with Experiment 1, optimization recommendations.

---

## Files to Create/Modify

| Action | File | Purpose |
|--------|------|---------|
| **Create** | `.claude/scripts/dev/analyze-regression.py` | Factorial ANCOVA, within-treatment regressions, phase analysis |
| **Create** | `.claude/reports/testing/compression-regression-data.jsonl` | Raw trial data (separate from Exp 1) |
| **Create** | `.claude/reports/testing/compression-regression-report.md` | Final report |
| **Modify** | `.claude/scripts/dev/context-fill.sh` | Add --tolerance 1 support for tight 75% fills |
| **Modify** | `.claude/scripts/dev/run-compression-trial.sh` | Add safety checks for high-range trials, block scheduling |

**Existing files used (read-only)**:
- `.claude/scripts/dev/time-compact.sh` -- /compact timing (already hardened)
- `.claude/scripts/jicm-watcher.sh` -- watcher mechanics
- `.claude/scripts/dev/restart-watcher.sh` -- threshold control
- `.claude/logs/telemetry/jicm-metrics.jsonl` -- JICM phase timing
- `.claude/context/workflows/wiggum-loop.md` -- loop structure

---

## Risks and Mitigations

| Risk | Impact | Mitigation |
|------|--------|------------|
| 75% fill overshoots to 78%+ | **LOCKOUT** -- session unrecoverable | +/-1% tolerance, abort at 76%, pre-validate watcher |
| /compact eaten as text at 75% | Invalid trial, wasted 17 min | Hardened delivery (ESC+Ctrl-U+pause), retry once |
| JICM timeout at 75% | Missing data point | Record as censored; budget for 10-20% failure rate |
| Insufficient power (n=8/cell) | Can't detect medium effects | Adaptive: extend to blocks 9-10 (n=10/cell) if needed |
| API rate limiting inflates times | Confounded DV | Randomize trial order, include time-of-day as covariate |
| Context fill not reproducible at 75% | Confounded across cells | Verify ground truth tokens before trigger; tight tolerance |
| Experiment spans multiple sessions | State loss | Block design is resumable; JSONL append-only; progress tracker |
| statsmodels not installed | Can't run ANCOVA | pip3 install statsmodels in Loop 1; scipy already validated |

---

## Verification

After experiment completion:
1. `wc -l .claude/reports/testing/compression-regression-data.jsonl` -- should have >= 32 records
2. `python3 .claude/scripts/dev/analyze-regression.py --verbose` -- should produce ANOVA table with 3 F-tests
3. All 4 cells should have >= 6 successful trials (allowing for up to 2 failures per cell)
4. Token counts should cluster in two distinct bands (~86-94K for low, ~148-152K for high)
5. Both /compact and JICM trials should have non-zero end_tokens (validation of hardened capture)
6. JICM trials should have phase breakdown (halt, compress, clear, restore times)
7. Final report should contain: ANOVA table, regression slopes, interaction plot, comparison with Experiment 1
