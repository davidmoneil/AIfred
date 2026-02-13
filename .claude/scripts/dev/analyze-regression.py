#!/usr/bin/env python3
"""
analyze-regression.py — Statistical analysis for Experiment 2: Context Volume Effect.

2x2 factorial ANCOVA: compression_time ~ treatment * token_count
Tests whether context volume affects compression time and whether
the effect differs between /compact and JICM.

Usage:
    python3 analyze-regression.py [--data FILE] [--verbose] [--report FILE]

Part of compression timing experiment infrastructure.
"""

import json
import sys
import os
import argparse
from collections import defaultdict
from datetime import datetime

# ─── Configuration ──────────────────────────────────────────────────────────

DEFAULT_DATA = os.path.join(
    os.environ.get("CLAUDE_PROJECT_DIR", os.path.expanduser("~/Claude/Jarvis")),
    ".claude/reports/testing/compression-regression-data.jsonl"
)

DEFAULT_REPORT = os.path.join(
    os.environ.get("CLAUDE_PROJECT_DIR", os.path.expanduser("~/Claude/Jarvis")),
    ".claude/reports/testing/compression-regression-report.md"
)

JICM_METRICS = os.path.join(
    os.environ.get("CLAUDE_PROJECT_DIR", os.path.expanduser("~/Claude/Jarvis")),
    ".claude/logs/telemetry/jicm-metrics.jsonl"
)


def load_data(path):
    """Load JSONL trial data."""
    trials = []
    with open(path) as f:
        for line_num, line in enumerate(f, 1):
            line = line.strip()
            if not line:
                continue
            try:
                trials.append(json.loads(line))
            except json.JSONDecodeError as e:
                print(f"WARNING: Invalid JSON on line {line_num}: {e}", file=sys.stderr)
    return trials


def descriptive_stats(values):
    """Compute descriptive statistics for a list of numbers."""
    if not values:
        return {"n": 0, "mean": 0, "median": 0, "sd": 0, "min": 0, "max": 0, "iqr": 0}
    import math
    n = len(values)
    mean = sum(values) / n
    sorted_v = sorted(values)
    median = sorted_v[n // 2] if n % 2 else (sorted_v[n // 2 - 1] + sorted_v[n // 2]) / 2
    variance = sum((x - mean) ** 2 for x in values) / max(n - 1, 1)
    sd = math.sqrt(variance)
    q1_idx = n // 4
    q3_idx = (3 * n) // 4
    iqr = sorted_v[q3_idx] - sorted_v[q1_idx] if n >= 4 else 0
    return {
        "n": n,
        "mean": round(mean, 1),
        "median": round(median, 1),
        "sd": round(sd, 1),
        "min": round(min(values), 1),
        "max": round(max(values), 1),
        "iqr": round(iqr, 1),
    }


# ─── Primary Analysis: Factorial ANCOVA ─────────────────────────────────────

def factorial_ancova(df):
    """
    Run 2x2 factorial ANCOVA: compression_time ~ C(treatment) * token_count.
    Returns ANOVA table with F-tests for main effects and interaction.
    """
    try:
        import pandas as pd
        from statsmodels.formula.api import ols
        import statsmodels.api as sm
    except ImportError as e:
        return None, f"Missing dependency: {e}"

    # Check minimum sample size for ANOVA
    min_cell_size = df.groupby(['treatment']).size().min()
    if min_cell_size < 2:
        return None, f"Insufficient data: min cell size is {min_cell_size} (need ≥ 2)"
    if len(df) < 5:
        return None, f"Insufficient data: only {len(df)} observations (need ≥ 5)"

    try:
        model = ols('duration_s ~ C(treatment) * start_tokens', data=df).fit()
        anova_table = sm.stats.anova_lm(model, typ=2)
    except Exception as e:
        return None, f"ANOVA failed: {e}"

    # Compute partial eta-squared for each term
    ss_residual = anova_table.loc['Residual', 'sum_sq']
    eta_sq = {}
    for idx in anova_table.index:
        if idx == 'Residual':
            continue
        ss_effect = anova_table.loc[idx, 'sum_sq']
        denom = ss_effect + ss_residual
        eta_sq[idx] = round(ss_effect / denom, 4) if denom > 0 else 0

    return {
        "anova_table": anova_table,
        "model": model,
        "eta_squared": eta_sq,
        "r_squared": round(model.rsquared, 4),
        "adj_r_squared": round(model.rsquared_adj, 4),
    }, None


# ─── Secondary: Within-Treatment Regressions ────────────────────────────────

def within_treatment_regression(tokens, durations, label=""):
    """Linear regression: token_count -> compression_time for one treatment."""
    try:
        from scipy.stats import linregress, spearmanr
    except ImportError:
        return None

    if len(tokens) < 3:
        return {"note": f"Insufficient data (n={len(tokens)})"}

    slope, intercept, r_value, p_value, std_err = linregress(tokens, durations)

    # Spearman for non-parametric robustness
    rho, rho_p = spearmanr(tokens, durations)

    # 95% CI on slope (t-based)
    from scipy.stats import t as t_dist
    n = len(tokens)
    dof = n - 2
    t_crit = t_dist.ppf(0.975, dof)
    ci_low = slope - t_crit * std_err
    ci_high = slope + t_crit * std_err

    # Slope per 10K tokens (more interpretable)
    slope_per_10k = slope * 10000

    return {
        "label": label,
        "n": n,
        "slope": round(slope, 6),
        "slope_per_10k_tokens": round(slope_per_10k, 2),
        "intercept": round(intercept, 2),
        "r_squared": round(r_value ** 2, 4),
        "p_value": round(p_value, 6),
        "std_err": round(std_err, 6),
        "ci_95": (round(ci_low, 6), round(ci_high, 6)),
        "spearman_rho": round(rho, 3),
        "spearman_p": round(rho_p, 6),
    }


# ─── Secondary: Fisher Z-Test ───────────────────────────────────────────────

def fisher_z_test(rho1, n1, rho2, n2):
    """Compare two Spearman correlations using Fisher z-transformation."""
    import math
    try:
        from scipy.stats import norm
    except ImportError:
        return None

    # Fisher z-transform
    z1 = 0.5 * math.log((1 + rho1) / (1 - rho1)) if abs(rho1) < 1 else 0
    z2 = 0.5 * math.log((1 + rho2) / (1 - rho2)) if abs(rho2) < 1 else 0

    # Standard error of difference
    se = math.sqrt(1 / (n1 - 3) + 1 / (n2 - 3))
    z_diff = (z1 - z2) / se if se > 0 else 0
    p_value = 2 * (1 - norm.cdf(abs(z_diff)))

    return {
        "z_diff": round(z_diff, 3),
        "p_value": round(p_value, 6),
        "significant": p_value < 0.05,
    }


# ─── Secondary: JICM Phase Analysis ─────────────────────────────────────────

def jicm_phase_analysis(jicm_trials):
    """Regression for each JICM phase: phase_time ~ token_count."""
    phases = ["halt_time_s", "compress_time_s", "clear_time_s", "restore_time_s"]
    results = {}

    for phase in phases:
        tokens = []
        times = []
        for t in jicm_trials:
            if t.get(phase, 0) > 0 and t.get("start_tokens", 0) > 0:
                tokens.append(t["start_tokens"])
                times.append(t[phase])

        if len(tokens) >= 3:
            reg = within_treatment_regression(tokens, times, label=phase)
            if reg:
                results[phase] = reg

    return results


# ─── Assumption Checks ──────────────────────────────────────────────────────

def assumption_checks(df):
    """Run normality and homoscedasticity tests."""
    results = {}
    try:
        from scipy.stats import shapiro, levene
        import pandas as pd
        from statsmodels.formula.api import ols
    except ImportError:
        return {"error": "Missing scipy or statsmodels"}

    # Fit model to get residuals
    model = ols('duration_s ~ C(treatment) * start_tokens', data=df).fit()
    residuals = model.resid

    # Overall normality of residuals
    if len(residuals) >= 3:
        w_stat, w_p = shapiro(residuals)
        results["shapiro_wilk"] = {
            "statistic": round(float(w_stat), 4),
            "p_value": round(float(w_p), 6),
            "normal": w_p > 0.05,
        }

    # Per-cell normality
    cells = {}
    for treatment in df['treatment'].unique():
        for level in df['context_level'].unique():
            mask = (df['treatment'] == treatment) & (df['context_level'] == level)
            cell_data = df.loc[mask, 'duration_s']
            if len(cell_data) >= 3:
                w, p = shapiro(cell_data)
                cells[f"{treatment}-{level}"] = {
                    "n": len(cell_data),
                    "shapiro_p": round(float(p), 6),
                    "normal": p > 0.05,
                }
    results["per_cell_normality"] = cells

    # Levene's test for homoscedasticity across cells
    groups = []
    for treatment in df['treatment'].unique():
        for level in df['context_level'].unique():
            mask = (df['treatment'] == treatment) & (df['context_level'] == level)
            cell_data = df.loc[mask, 'duration_s'].values
            if len(cell_data) >= 2:
                groups.append(cell_data)

    if len(groups) >= 2:
        lev_stat, lev_p = levene(*groups)
        results["levene"] = {
            "statistic": round(float(lev_stat), 4),
            "p_value": round(float(lev_p), 6),
            "homoscedastic": lev_p > 0.05,
        }

    return results


# ─── Compression Ratio Analysis ─────────────────────────────────────────────

def compression_ratio_analysis(trials):
    """Analyze compression ratios by treatment and context level."""
    results = {}
    for treatment in ["compact", "jicm"]:
        for level in ["low", "high"]:
            subset = [t for t in trials
                      if t.get("treatment") == treatment
                      and t.get("context_level") == level
                      and t.get("outcome") == "success"
                      and t.get("start_tokens", 0) > 0
                      and t.get("end_tokens", 0) > 0]
            if subset:
                ratios = [t["start_tokens"] / t["end_tokens"] for t in subset]
                results[f"{treatment}-{level}"] = descriptive_stats(ratios)
    return results


# ─── Non-parametric Fallbacks ────────────────────────────────────────────────

def nonparametric_fallbacks(df):
    """Kruskal-Wallis and permutation tests as ANCOVA alternatives."""
    results = {}
    try:
        from scipy.stats import kruskal
    except ImportError:
        return results

    # Kruskal-Wallis across 4 cells
    groups = []
    labels = []
    for treatment in df['treatment'].unique():
        for level in df['context_level'].unique():
            mask = (df['treatment'] == treatment) & (df['context_level'] == level)
            cell_data = df.loc[mask, 'duration_s'].values
            if len(cell_data) >= 2:
                groups.append(cell_data)
                labels.append(f"{treatment}-{level}")

    if len(groups) >= 2:
        h_stat, h_p = kruskal(*groups)
        results["kruskal_wallis"] = {
            "statistic": round(float(h_stat), 4),
            "p_value": round(float(h_p), 6),
            "groups": labels,
        }

    return results


# ─── Report Generation ──────────────────────────────────────────────────────

def generate_report(trials, ancova_result, compact_reg, jicm_reg, fisher_result,
                    phase_results, assumptions, ratio_analysis, nonparam,
                    report_path, verbose=False):
    """Generate comprehensive markdown report."""
    import pandas as pd

    successful = [t for t in trials if t.get("outcome") == "success"]
    n_total = len(trials)
    n_success = len(successful)

    lines = [
        "# Experiment 2: Context Volume Effect on Compression Time",
        "",
        f"**Generated**: {datetime.utcnow().strftime('%Y-%m-%d %H:%M UTC')}",
        f"**Total trials**: {n_total} ({n_success} successful)",
        "",
        "---",
        "",
        "## 1. Design Summary",
        "",
        "2x2 between-subjects factorial: Treatment (/compact vs JICM) x Context Level (Low ~45% vs High ~75%)",
        "",
        "| Cell | Treatment | Context | n |",
        "|------|-----------|---------|---|",
    ]

    for treatment in ["compact", "jicm"]:
        for level in ["low", "high"]:
            n = len([t for t in successful
                     if t.get("treatment") == treatment and t.get("context_level") == level])
            lines.append(f"| {treatment}-{level} | {treatment} | {level} | {n} |")

    # Descriptive statistics per cell
    lines += ["", "## 2. Descriptive Statistics", "", "### Per Cell", "",
              "| Cell | n | Mean (s) | Median (s) | SD (s) | Min | Max |",
              "|------|---|----------|------------|--------|-----|-----|"]

    for treatment in ["compact", "jicm"]:
        for level in ["low", "high"]:
            durations = [t["duration_s"] for t in successful
                        if t.get("treatment") == treatment and t.get("context_level") == level]
            stats = descriptive_stats(durations)
            lines.append(f"| {treatment}-{level} | {stats['n']} | {stats['mean']} | "
                        f"{stats['median']} | {stats['sd']} | {stats['min']} | {stats['max']} |")

    # Token count distributions
    lines += ["", "### Token Counts at Trigger", "",
              "| Cell | Mean Tokens | Median Tokens | Min | Max |",
              "|------|-------------|---------------|-----|-----|"]

    for treatment in ["compact", "jicm"]:
        for level in ["low", "high"]:
            tokens = [t["start_tokens"] for t in successful
                      if t.get("treatment") == treatment and t.get("context_level") == level
                      and t.get("start_tokens", 0) > 0]
            stats = descriptive_stats(tokens)
            lines.append(f"| {treatment}-{level} | {stats['mean']:,.0f} | {stats['median']:,.0f} | "
                        f"{stats['min']:,.0f} | {stats['max']:,.0f} |")

    # Primary analysis: ANCOVA
    lines += ["", "---", "", "## 3. Primary Analysis: Factorial ANCOVA", "",
              "Model: `duration_s ~ C(treatment) * start_tokens`", ""]

    if ancova_result and not isinstance(ancova_result, str):
        result, err = ancova_result if isinstance(ancova_result, tuple) else (ancova_result, None)
        if err:
            lines.append(f"*Error: {err}*")
        elif result:
            anova_table = result["anova_table"]
            eta_sq = result["eta_squared"]

            lines += ["| Term | SS | df | F | p | Partial eta-sq |",
                      "|------|----|----|---|---|----------------|"]
            for idx in anova_table.index:
                ss = round(anova_table.loc[idx, 'sum_sq'], 2)
                df_val = int(anova_table.loc[idx, 'df'])
                f_val = round(anova_table.loc[idx, 'F'], 3) if idx != 'Residual' else "—"
                p_val = round(anova_table.loc[idx, 'PR(>F)'], 6) if idx != 'Residual' else "—"
                eta = eta_sq.get(idx, "—")
                lines.append(f"| {idx} | {ss} | {df_val} | {f_val} | {p_val} | {eta} |")

            lines += [
                "",
                f"**R-squared**: {result['r_squared']}",
                f"**Adjusted R-squared**: {result['adj_r_squared']}",
                "",
                "### Interpretation",
                "",
            ]

            # Interpret each term
            for term, label, hypothesis in [
                ("C(treatment)", "Treatment main effect", None),
                ("start_tokens", "Token count main effect", "H0.1"),
                ("C(treatment):start_tokens", "Interaction", "H0.2"),
            ]:
                if term in eta_sq:
                    p = anova_table.loc[term, 'PR(>F)']
                    eta = eta_sq[term]
                    size = "large" if eta > 0.14 else "medium" if eta > 0.06 else "small" if eta > 0.01 else "negligible"
                    sig = "significant" if p < 0.05 else "not significant"
                    hyp_str = f" (**tests {hypothesis}**)" if hypothesis else ""
                    lines.append(f"- **{label}**{hyp_str}: F={anova_table.loc[term, 'F']:.3f}, "
                                f"p={p:.6f}, eta-sq={eta} ({size}). **{sig.upper()}**.")
                    if hypothesis and p < 0.05:
                        lines.append(f"  - Reject {hypothesis}: {label} is statistically significant.")
                    elif hypothesis:
                        lines.append(f"  - Fail to reject {hypothesis}: No significant {label.lower()} detected.")
    else:
        lines.append("*ANCOVA could not be computed — check dependencies.*")

    # Within-treatment regressions
    lines += ["", "---", "", "## 4. Within-Treatment Regressions", ""]

    for reg, label in [(compact_reg, "/compact"), (jicm_reg, "JICM")]:
        lines.append(f"### {label}")
        if reg and "note" not in reg:
            lines += [
                f"- **n**: {reg['n']}",
                f"- **Slope**: {reg['slope_per_10k_tokens']}s per 10K tokens",
                f"- **R-squared**: {reg['r_squared']}",
                f"- **p-value**: {reg['p_value']}",
                f"- **95% CI on slope**: [{reg['ci_95'][0]}, {reg['ci_95'][1]}]",
                f"- **Spearman rho**: {reg['spearman_rho']} (p={reg['spearman_p']})",
                "",
            ]
        elif reg and "note" in reg:
            lines.append(f"*{reg['note']}*\n")
        else:
            lines.append("*Could not compute.*\n")

    # Fisher z-test
    if fisher_result:
        lines += [
            "### Correlation Comparison (Fisher z-test)",
            f"- **z**: {fisher_result['z_diff']}",
            f"- **p-value**: {fisher_result['p_value']}",
            f"- **Significant difference**: {'Yes' if fisher_result['significant'] else 'No'}",
            "",
        ]

    # JICM phase analysis
    if phase_results:
        lines += ["---", "", "## 5. JICM Phase-Level Analysis", "",
                  "Separate regressions: phase_time ~ token_count", "",
                  "| Phase | n | Slope (s/10K tokens) | R-squared | p-value |",
                  "|-------|---|---------------------|-----------|---------|"]
        for phase, reg in phase_results.items():
            if "note" not in reg:
                label = phase.replace("_time_s", "").capitalize()
                lines.append(f"| {label} | {reg['n']} | {reg['slope_per_10k_tokens']} | "
                            f"{reg['r_squared']} | {reg['p_value']} |")
        lines.append("")

    # Compression ratio analysis
    if ratio_analysis:
        lines += ["---", "", "## 6. Compression Ratio Analysis", "",
                  "| Cell | n | Mean Ratio | Median Ratio | SD |",
                  "|------|---|------------|--------------|-----|"]
        for cell, stats in sorted(ratio_analysis.items()):
            lines.append(f"| {cell} | {stats['n']} | {stats['mean']}:1 | "
                        f"{stats['median']}:1 | {stats['sd']} |")
        lines.append("")

    # Assumption checks
    lines += ["---", "", "## 7. Assumption Checks", ""]
    if assumptions:
        if "shapiro_wilk" in assumptions:
            sw = assumptions["shapiro_wilk"]
            lines.append(f"**Shapiro-Wilk (residuals)**: W={sw['statistic']}, p={sw['p_value']} "
                        f"({'normal' if sw['normal'] else 'NON-NORMAL'})")

        if "per_cell_normality" in assumptions:
            lines += ["", "**Per-cell normality (Shapiro-Wilk)**:", ""]
            for cell, result in sorted(assumptions["per_cell_normality"].items()):
                status = "OK" if result["normal"] else "VIOLATED"
                lines.append(f"- {cell}: n={result['n']}, p={result['shapiro_p']} ({status})")

        if "levene" in assumptions:
            lev = assumptions["levene"]
            lines.append(f"\n**Levene's test**: F={lev['statistic']}, p={lev['p_value']} "
                        f"({'homoscedastic' if lev['homoscedastic'] else 'HETEROSCEDASTIC'})")

    # Non-parametric fallbacks
    if nonparam:
        lines += ["", "### Non-parametric Alternatives", ""]
        if "kruskal_wallis" in nonparam:
            kw = nonparam["kruskal_wallis"]
            lines.append(f"**Kruskal-Wallis**: H={kw['statistic']}, p={kw['p_value']}")

    # Raw data table
    lines += ["", "---", "", "## 8. Raw Data", "",
              "| Trial | Treatment | Level | Tokens | Duration (s) | End Tokens | Outcome |",
              "|-------|-----------|-------|--------|-------------|------------|---------|"]
    for i, t in enumerate(trials, 1):
        lines.append(f"| {i} | {t.get('treatment', '?')} | {t.get('context_level', '?')} | "
                    f"{t.get('start_tokens', 0):,} | {t.get('duration_s', '?')} | "
                    f"{t.get('end_tokens', 0):,} | {t.get('outcome', '?')} |")

    lines += ["", "---", "", "*Generated by analyze-regression.py*", ""]

    report_text = "\n".join(lines)
    if report_path:
        with open(report_path, "w") as f:
            f.write(report_text)
        print(f"Report written to {report_path}", file=sys.stderr)
    return report_text


# ─── Main ────────────────────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description="Analyze compression regression data (Exp 2)")
    parser.add_argument("--data", default=DEFAULT_DATA, help="Path to JSONL data file")
    parser.add_argument("--report", default=None, help="Path to write markdown report")
    parser.add_argument("--verbose", action="store_true", help="Show detailed output")
    parser.add_argument("--no-report", action="store_true", help="Skip report generation")
    args = parser.parse_args()

    if not os.path.exists(args.data):
        print(f"ERROR: Data file not found: {args.data}", file=sys.stderr)
        print("Run trials first to generate data.", file=sys.stderr)
        sys.exit(1)

    trials = load_data(args.data)
    if not trials:
        print("ERROR: No valid trials in data file", file=sys.stderr)
        sys.exit(1)

    successful = [t for t in trials if t.get("outcome") == "success"]
    print(f"Loaded {len(trials)} trials ({len(successful)} successful) from {args.data}",
          file=sys.stderr)

    # Separate by treatment
    compact_trials = [t for t in successful if t.get("treatment") == "compact"]
    jicm_trials = [t for t in successful if t.get("treatment") == "jicm"]

    # Descriptive stats
    for label, subset in [("/compact", compact_trials), ("JICM", jicm_trials)]:
        for level in ["low", "high"]:
            durations = [t["duration_s"] for t in subset if t.get("context_level") == level]
            stats = descriptive_stats(durations)
            print(f"\n{label} ({level}): n={stats['n']}, M={stats['mean']}s, "
                  f"Mdn={stats['median']}s, SD={stats['sd']}s")

    # Build pandas DataFrame for ANCOVA
    try:
        import pandas as pd
        df = pd.DataFrame(successful)
        if 'start_tokens' not in df.columns or 'duration_s' not in df.columns:
            print("ERROR: Missing required columns (start_tokens, duration_s)", file=sys.stderr)
            sys.exit(1)
    except ImportError:
        print("ERROR: pandas required — pip3 install pandas", file=sys.stderr)
        sys.exit(1)

    # Primary analysis: Factorial ANCOVA
    print("\n=== Factorial ANCOVA ===")
    ancova_result = factorial_ancova(df)
    result, err = ancova_result
    if err:
        print(f"ANCOVA error: {err}", file=sys.stderr)
    elif result:
        print(result["anova_table"])
        print(f"\nPartial eta-squared: {result['eta_squared']}")
        print(f"R-squared: {result['r_squared']}, Adj R-squared: {result['adj_r_squared']}")

    # Within-treatment regressions
    print("\n=== Within-Treatment Regressions ===")
    compact_reg = within_treatment_regression(
        [t["start_tokens"] for t in compact_trials if t.get("start_tokens", 0) > 0],
        [t["duration_s"] for t in compact_trials if t.get("start_tokens", 0) > 0],
        label="/compact"
    )
    jicm_reg = within_treatment_regression(
        [t["start_tokens"] for t in jicm_trials if t.get("start_tokens", 0) > 0],
        [t["duration_s"] for t in jicm_trials if t.get("start_tokens", 0) > 0],
        label="JICM"
    )

    if compact_reg and "note" not in compact_reg:
        print(f"/compact: slope={compact_reg['slope_per_10k_tokens']}s/10K tokens, "
              f"R²={compact_reg['r_squared']}, p={compact_reg['p_value']}")
    if jicm_reg and "note" not in jicm_reg:
        print(f"JICM:     slope={jicm_reg['slope_per_10k_tokens']}s/10K tokens, "
              f"R²={jicm_reg['r_squared']}, p={jicm_reg['p_value']}")

    # Fisher z-test comparing correlations
    fisher_result = None
    if (compact_reg and "spearman_rho" in compact_reg and
            jicm_reg and "spearman_rho" in jicm_reg):
        fisher_result = fisher_z_test(
            compact_reg["spearman_rho"], compact_reg["n"],
            jicm_reg["spearman_rho"], jicm_reg["n"]
        )
        if fisher_result:
            print(f"\nFisher z-test (comparing correlations): z={fisher_result['z_diff']}, "
                  f"p={fisher_result['p_value']}")

    # JICM phase analysis
    print("\n=== JICM Phase Analysis ===")
    phase_results = jicm_phase_analysis(jicm_trials)
    for phase, reg in phase_results.items():
        if "note" not in reg:
            label = phase.replace("_time_s", "").capitalize()
            print(f"{label}: slope={reg['slope_per_10k_tokens']}s/10K, "
                  f"R²={reg['r_squared']}, p={reg['p_value']}")

    # Assumption checks
    print("\n=== Assumption Checks ===")
    assumptions = assumption_checks(df)
    if "shapiro_wilk" in assumptions:
        sw = assumptions["shapiro_wilk"]
        print(f"Shapiro-Wilk: W={sw['statistic']}, p={sw['p_value']} "
              f"({'OK' if sw['normal'] else 'VIOLATED'})")
    if "levene" in assumptions:
        lev = assumptions["levene"]
        print(f"Levene: F={lev['statistic']}, p={lev['p_value']} "
              f"({'OK' if lev['homoscedastic'] else 'VIOLATED'})")

    # Compression ratio analysis
    ratio_analysis = compression_ratio_analysis(successful)

    # Non-parametric fallbacks
    nonparam = nonparametric_fallbacks(df)

    # Generate report
    if not args.no_report:
        report_path = args.report or DEFAULT_REPORT
        report = generate_report(
            trials, ancova_result, compact_reg, jicm_reg, fisher_result,
            phase_results, assumptions, ratio_analysis, nonparam, report_path, args.verbose
        )
        if args.verbose:
            print("\n" + report)


if __name__ == "__main__":
    main()
