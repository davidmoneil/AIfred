# Experiment 3: Context Volume Effect on Compression Time (Revised)

**Project**: Jarvis JICM v6.1 — Regression Analysis
**Date**: 2026-02-13/14
**Branch**: Project_Aion
**Predecessor**: Experiment 2 (0/4 JICM-high failures due to emergency handler preemption at 73%)
**Status**: COMPLETE
**Wiggum Loops**: 6 blocks, 24 trials attempted, 18 successful

---

## 1. Executive Summary

This revised experiment tested whether context window token count affects compression processing time, using 40% and 70% context levels (down from Experiment 2's 45%/75%). The lower high bound (70%) stays within the JICM operational envelope (below the 73% EMERGENCY_PCT ceiling discovered in Experiment 2's root cause analysis).

| Finding | Result | Significance |
|---------|--------|-------------|
| Treatment effect | /compact 3.8x faster than JICM | F=197.1, p<0.001, eta-sq=0.934 |
| Context volume effect (H0.1) | No significant main effect | F=2.33, p=0.149, eta-sq=0.143 |
| Differential scaling (H0.2) | No significant interaction | F=2.02, p=0.178, eta-sq=0.126 |
| JICM at 70% context | **100% success (4/4)** | First ever JICM success above 70% |
| JICM volume trend | Negative slope (faster at high) | Spearman rho=-0.706, p=0.034 |

**Bottom line**: Context volume does NOT significantly affect compression time. Both treatments are mechanism-bound. JICM succeeds reliably at 70% (within the 72% operational ceiling). JICM may trend slightly faster at higher context volumes, though this is not significant in the parametric test.

---

## 2. Background

### Motivation

Experiment 2 established that JICM fails 100% at >=74% context, but could not test whether volume affects JICM duration because all JICM-high trials failed. Root cause analysis confirmed the emergency /compact handler (EMERGENCY_PCT=73%) preempts the JICM cycle. This experiment lowers the high level to 70% (3 points below emergency) to properly fill the JICM-high cell.

### Hypotheses

**H0.1**: Context window token count has no significant effect on compression processing time.
**H0.2**: The effect of context token count on compression time does not differ between /compact and JICM.

### Design

2x2 between-subjects factorial: Treatment (/compact vs JICM) x Context Level (Low ~40% vs High ~70%).

| | Low (~40%, 84-87K tokens) | High (~70%, 134-145K tokens) |
|---|---|---|
| **/compact** | n=4, all success | n=5, all success |
| **JICM** | n=5, all success | n=4, all success |

**Planned**: 24 trials (6 per cell) across 6 blocks.
**Actual**: 18 successful out of 24 attempted. 6 failures due to context fill issues (stale pane readings), not treatment failures. All 18 completed trials succeeded.

---

## 3. Descriptive Statistics

### Per Cell

| Cell | n | Mean (s) | Median (s) | SD (s) | Min | Max |
|------|---|----------|------------|--------|-----|-----|
| /compact-low | 4 | 77.8 | 78.5 | 5.1 | 72 | 82 |
| /compact-high | 5 | 75.8 | 75.0 | 9.3 | 66 | 88 |
| JICM-low | 5 | 309.6 | 316.0 | 27.2 | 274 | 347 |
| JICM-high | 4 | 261.2 | 282.5 | 56.5 | 179 | 301 |

### Token Counts at Trigger

| Cell | Mean Tokens | Median | Range |
|------|-------------|--------|-------|
| /compact-low | 86,352 | 86,288 | 86,078 - 86,752 |
| /compact-high | 138,638 | 138,355 | 134,011 - 143,460 |
| JICM-low | 85,916 | 85,991 | 84,793 - 86,659 |
| JICM-high | 140,239 | 140,882 | 134,502 - 144,691 |

Token counts cluster in two clear bands (~86K for low, ~139K for high), confirming the context fill produced well-separated experimental conditions.

---

## 4. Primary Analysis: Factorial ANCOVA

Model: `duration_s ~ C(treatment) * start_tokens`

| Term | SS | df | F | p | Partial eta-sq |
|------|----|----|---|---|----------------|
| C(treatment) | 194,939.9 | 1 | 197.08 | <0.001 | 0.934 |
| start_tokens | 2,305.8 | 1 | 2.33 | 0.149 | 0.143 |
| C(treatment):start_tokens | 1,993.0 | 1 | 2.02 | 0.178 | 0.126 |
| Residual | 13,848.2 | 14 | — | — | — |

**R-squared**: 0.937 | **Adjusted R-squared**: 0.923

### Interpretation

1. **Treatment main effect** (F=197.1, p<0.001, eta-sq=0.934): **SIGNIFICANT**. /compact is ~3.8x faster than JICM (77s vs 285s). Confirms Experiments 1 and 2 — treatment mechanism is the dominant factor, explaining 93.4% of variance.

2. **Token count main effect** (F=2.33, p=0.149, eta-sq=0.143): **NOT SIGNIFICANT**. Fails to reject H0.1. Context volume does not significantly affect compression time at alpha=0.05. The eta-squared (0.143) suggests a medium effect that might reach significance with more power, but the practical magnitude is small.

3. **Interaction** (F=2.02, p=0.178, eta-sq=0.126): **NOT SIGNIFICANT**. Fails to reject H0.2. Both treatments respond similarly to volume changes. No evidence that one treatment scales with volume while the other doesn't.

---

## 5. Within-Treatment Regressions

### /compact: token_count -> compression_time

| Metric | Value |
|--------|-------|
| n | 9 |
| Slope | -0.15s per 10K tokens |
| R-squared | 0.003 |
| p-value | 0.884 |
| Spearman rho | 0.213 (p=0.582) |

/compact shows essentially zero relationship between token count and compression time. Slope is -0.15s per 10K tokens — effectively flat. R-squared of 0.003 means token count explains 0.3% of variance.

### JICM: token_count -> compression_time

| Metric | Value |
|--------|-------|
| n | 9 |
| Slope | -8.05s per 10K tokens |
| R-squared | 0.243 |
| p-value | 0.178 |
| Spearman rho | **-0.706 (p=0.034)** |

JICM shows a negative trend: higher token count is associated with *shorter* compression time. The Spearman correlation is significant (rho=-0.706, p=0.034), though the parametric regression is not (p=0.178). This suggests a monotonic (possibly non-linear) relationship where the compression agent completes faster with more context.

**Possible explanations**: (1) More context = more summarizable redundancy, so the agent's checkpoint is faster to produce. (2) Larger conversations have more structure (headings, sections) that the agent can leverage for efficient summarization. (3) Trial 5-1 (179s outlier) may be pulling the trend.

### Correlation Comparison (Fisher z-test)

| Metric | Value |
|--------|-------|
| z | 1.897 |
| p-value | 0.058 |
| Significant? | No (marginal) |

The difference between the two correlations (rho=0.213 for /compact, rho=-0.706 for JICM) approaches significance (p=0.058). This suggests the treatments may scale differently with volume — /compact is flat while JICM trends negative — but the evidence is not conclusive.

---

## 6. JICM Phase-Level Analysis

| Phase | n | Slope (s/10K tokens) | R-squared | p-value |
|-------|---|---------------------|-----------|---------|
| Halt | 9 | -2.36 | 0.108 | 0.387 |
| Compress | 8 | -4.99 | 0.115 | 0.412 |
| Clear | 8 | +0.05 | 0.191 | 0.279 |
| Restore | 8 | -0.22 | 0.104 | 0.437 |

No phase shows a significant relationship with token count. The compress phase has the largest negative slope (-4.99s per 10K tokens), consistent with the overall JICM trend. Clear time (+0.05s) is effectively constant regardless of volume, as expected (it's a fixed /clear operation). Restore time is similarly constant.

---

## 7. Compression Ratio Analysis

| Cell | n | Mean Ratio | Median Ratio | SD |
|------|---|------------|--------------|-----|
| /compact-low | 4 | 1.5:1 | 1.5:1 | 0.0 |
| /compact-high | 4 | 2.4:1 | 2.4:1 | 0.1 |
| JICM-low | 4 | 2.3:1 | 2.4:1 | 0.3 |
| JICM-high | 4 | 3.8:1 | 3.9:1 | 0.4 |

Higher context volume produces better compression ratios for both treatments. JICM achieves higher ratios than /compact at both levels. JICM-high achieves the best ratio (3.8:1), meaning 144K tokens compress to ~38K.

---

## 8. Assumption Checks

| Check | Result | Status |
|-------|--------|--------|
| Shapiro-Wilk (residuals) | W=0.832, p=0.004 | **VIOLATED** |
| Per-cell normality | All cells p>0.12 | OK |
| Levene's test | F=1.69, p=0.215 | OK (homoscedastic) |
| Kruskal-Wallis (non-parametric) | H=13.59, p=0.004 | Significant (confirms treatment effect) |

Residual normality is violated (driven by the JICM-high 179s outlier). Per-cell normality and homoscedasticity are fine. The non-parametric Kruskal-Wallis confirms the treatment effect is real.

---

## 9. Comparison with Experiment 2

| Metric | Experiment 2 | Experiment 3 |
|--------|-------------|-------------|
| Context levels | 45% vs 75% | 40% vs 70% |
| JICM-high success | 0/4 (0%) | 4/4 (100%) |
| Treatment effect (eta-sq) | 0.917 | 0.934 |
| Volume effect (p) | 0.277 | 0.149 |
| JICM mean (low) | ~313s | 310s |
| JICM mean (high) | N/A (all failed) | 261s |
| /compact mean | ~77s | 77s |

**Key difference**: By staying below the 73% EMERGENCY_PCT ceiling, all JICM-high trials succeeded. The JICM duration at 70% context is actually *shorter* than at 40%, though this trend is not statistically significant in the parametric analysis.

---

## 10. Conclusions

1. **H0.1 NOT REJECTED**: Context volume has no significant effect on compression time (F=2.33, p=0.149). Both treatments are mechanism-bound, not data-bound. This replicates Experiment 2's finding.

2. **H0.2 NOT REJECTED**: No significant interaction between treatment and volume (F=2.02, p=0.178). Both treatments scale similarly.

3. **Treatment effect confirmed**: /compact is 3.8x faster than JICM (eta-sq=0.934), replicating Experiments 1 and 2 with all four cells populated.

4. **JICM operational envelope validated**: 4/4 success at 67-72% context, confirming the 72% ceiling (EMERGENCY_PCT - 1) identified in Experiment 2's root cause analysis. JICM works reliably up to 72%.

5. **Suggestive negative trend for JICM**: The Spearman correlation (rho=-0.706, p=0.034) suggests JICM may be slightly faster at higher context. This could be an efficiency gain from more summarizable content, but needs replication.

6. **Compression ratios scale with volume**: Both treatments achieve better compression ratios at higher context (more redundancy to compress). JICM achieves 3.8:1 at 70% vs 2.3:1 at 40%.

### Recommendations

1. **Keep JICM threshold at 55%** — provides 17-point safety margin below operational ceiling, confirmed by 100% success rate across both experiments at levels below 72%.
2. **No volume-based optimization needed** — compression time is treatment-bound, not volume-bound. Optimizing the mechanism (agent speed, /clear latency) matters more than triggering earlier.
3. **Consider Haiku for compression agent** — the ~210-235s compress phase dominates JICM duration. Model choice affects this, not data volume.
4. **Investigate the negative JICM trend** — if JICM is genuinely faster at higher context, the optimal trigger might be higher (not lower) than 55%.

---

## 11. Trial Failures

6 of 24 trials failed due to context fill infrastructure issues (not treatment failures):

| Trial | Issue | Root Cause |
|-------|-------|------------|
| 1-3 | Stuck at 28% after 30 prompts | Stale context % in tmux pane; CC statusline not refreshing |
| 1-4 | Context reported 93% after /clear | Residual state from Trial 1-3's 78-min failure |
| 6-1 through 6-4 | Various fill failures | Late-session pane staleness (0% reported despite active context) |

All failures are in the measurement infrastructure (tmux pane scraping), not the compression mechanisms being tested. The 18 successful trials provide balanced per-cell coverage (4-5 per cell).

---

## 12. Files

| File | Purpose |
|------|---------|
| `.claude/reports/testing/compression-exp3-data.jsonl` | 18 trial records |
| `.claude/reports/testing/experiment-3-protocol.md` | Pre-registered protocol |
| `.claude/scripts/dev/run-experiment-3.sh` | Orchestration script |
| `.claude/scripts/dev/analyze-regression.py` | Statistical analysis (reused) |
| `.claude/logs/experiment-3.log` | Execution log |

---

*Experiment 3 — Context Volume Effect (Revised) — 2026-02-13/14*
*18/24 trials successful, all 4 cells populated, JICM-high validated*
