#!/usr/bin/env python3
"""
analyze-compression-data.py — Statistical analysis for compression timing experiment.

Reads compression-timing-data.jsonl, runs Wilcoxon signed-rank test on matched pairs,
computes descriptive statistics, and outputs results.

Usage:
    python3 analyze-compression-data.py [--data FILE] [--report FILE] [--verbose]

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
    ".claude/reports/testing/compression-timing-data.jsonl"
)

DEFAULT_REPORT = os.path.join(
    os.environ.get("CLAUDE_PROJECT_DIR", os.path.expanduser("~/Claude/Jarvis")),
    ".claude/reports/testing/compression-experiment-report.md"
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


def pair_trials(trials):
    """Group trials into matched pairs by pair_id."""
    pairs = defaultdict(dict)
    for t in trials:
        pair_id = t.get("pair_id")
        treatment = t.get("treatment")
        if pair_id is not None and treatment:
            pairs[pair_id][treatment] = t
    # Filter to complete pairs only
    complete = {k: v for k, v in pairs.items()
                if "compact" in v and "jicm" in v}
    return complete


def descriptive_stats(values):
    """Compute descriptive statistics for a list of numbers."""
    if not values:
        return {"n": 0, "mean": 0, "median": 0, "sd": 0, "min": 0, "max": 0, "iqr": 0}
    n = len(values)
    mean = sum(values) / n
    sorted_v = sorted(values)
    median = sorted_v[n // 2] if n % 2 else (sorted_v[n // 2 - 1] + sorted_v[n // 2]) / 2
    variance = sum((x - mean) ** 2 for x in values) / max(n - 1, 1)
    sd = variance ** 0.5
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


def wilcoxon_test(compact_times, jicm_times):
    """
    Run Wilcoxon signed-rank test on paired observations.
    Returns (statistic, p_value, effect_size_r) or None if scipy unavailable.
    """
    try:
        from scipy.stats import wilcoxon as scipy_wilcoxon
    except ImportError:
        return None

    if len(compact_times) != len(jicm_times):
        return None
    if len(compact_times) < 6:
        print("WARNING: n < 6 pairs — Wilcoxon test has very low power", file=sys.stderr)

    differences = [j - c for c, j in zip(compact_times, jicm_times)]

    # Check for zero differences (ties at zero)
    nonzero_diffs = [d for d in differences if d != 0]
    if len(nonzero_diffs) < 2:
        return {"statistic": 0, "p_value": 1.0, "effect_size_r": 0.0,
                "note": "Too few non-zero differences"}

    try:
        stat, p_value = scipy_wilcoxon(compact_times, jicm_times, alternative="less")
    except Exception as e:
        return {"statistic": 0, "p_value": 1.0, "effect_size_r": 0.0,
                "note": f"Test failed: {e}"}

    # Effect size: r = Z / sqrt(n)
    # Approximate Z from p-value (for reporting)
    n = len(nonzero_diffs)
    try:
        from scipy.stats import norm
        z = norm.ppf(1 - p_value)
        r = abs(z) / (n ** 0.5)
    except Exception:
        r = 0.0

    return {
        "statistic": float(stat),
        "p_value": round(p_value, 6),
        "effect_size_r": round(r, 3),
        "n_pairs": len(compact_times),
        "n_nonzero": len(nonzero_diffs),
        "mean_difference": round(sum(differences) / len(differences), 1),
        "median_difference": round(sorted(differences)[len(differences) // 2], 1),
    }


def paired_t_test(compact_times, jicm_times):
    """Run paired t-test as secondary analysis."""
    try:
        from scipy.stats import ttest_rel
        stat, p_value = ttest_rel(compact_times, jicm_times)
        return {"t_statistic": round(float(stat), 3), "p_value": round(p_value, 6)}
    except ImportError:
        return None
    except Exception:
        return None


def spearman_correlation(pcts, durations):
    """Context % vs duration correlation."""
    try:
        from scipy.stats import spearmanr
        rho, p_value = spearmanr(pcts, durations)
        return {"rho": round(rho, 3), "p_value": round(p_value, 6)}
    except ImportError:
        return None
    except Exception:
        return None


def generate_report(trials, pairs, compact_stats, jicm_stats, wilcoxon_result,
                    t_test_result, correlation_result, report_path):
    """Generate markdown report."""
    lines = [
        "# Compression Timing Experiment — Results",
        "",
        f"**Generated**: {datetime.utcnow().strftime('%Y-%m-%d %H:%M UTC')}",
        f"**Total trials**: {len(trials)}",
        f"**Complete pairs**: {len(pairs)}",
        "",
        "---",
        "",
        "## Descriptive Statistics",
        "",
        "| Metric | /compact | JICM |",
        "|--------|----------|------|",
    ]
    for key in ["n", "mean", "median", "sd", "min", "max", "iqr"]:
        label = key.upper() if key in ("n", "sd", "iqr") else key.capitalize()
        c_val = compact_stats.get(key, "—")
        j_val = jicm_stats.get(key, "—")
        unit = "s" if key != "n" else ""
        lines.append(f"| {label} | {c_val}{unit} | {j_val}{unit} |")

    lines += ["", "---", "", "## Primary Analysis: Wilcoxon Signed-Rank Test", ""]
    if len(pairs) < 2:
        lines.append(f"*Insufficient data — need ≥ 2 matched pairs for test (have {len(pairs)})*")
    elif wilcoxon_result:
        lines.append(f"- **Test statistic**: {wilcoxon_result.get('statistic', '—')}")
        lines.append(f"- **p-value**: {wilcoxon_result.get('p_value', '—')}")
        lines.append(f"- **Effect size (r)**: {wilcoxon_result.get('effect_size_r', '—')}")
        lines.append(f"- **Mean difference (JICM - compact)**: {wilcoxon_result.get('mean_difference', '—')}s")
        lines.append(f"- **Median difference**: {wilcoxon_result.get('median_difference', '—')}s")
        lines.append(f"- **Pairs analyzed**: {wilcoxon_result.get('n_pairs', '—')}")
        p = wilcoxon_result.get("p_value", 1.0)
        if p < 0.05:
            lines.append(f"\n**Result**: Statistically significant (p = {p} < 0.05).")
            r = wilcoxon_result.get("effect_size_r", 0)
            size = "large" if r > 0.5 else "medium" if r > 0.3 else "small"
            lines.append(f"Effect size is **{size}** (r = {r}).")
        else:
            lines.append(f"\n**Result**: Not statistically significant (p = {p} >= 0.05).")
            lines.append("Fail to reject H₀ — no significant difference detected.")
        if wilcoxon_result.get("note"):
            lines.append(f"\n*Note: {wilcoxon_result['note']}*")
    else:
        lines.append("*scipy not available — install with `pip3 install scipy` to run test*")

    lines += ["", "---", "", "## Secondary Analyses", ""]
    if t_test_result:
        lines.append(f"**Paired t-test**: t = {t_test_result['t_statistic']}, p = {t_test_result['p_value']}")
    if correlation_result:
        lines.append(f"**Context % vs duration (Spearman)**: ρ = {correlation_result['rho']}, p = {correlation_result['p_value']}")

    # Success rates
    compact_trials = [t for t in trials if t.get("treatment") == "compact"]
    jicm_trials = [t for t in trials if t.get("treatment") == "jicm"]
    compact_success = sum(1 for t in compact_trials if t.get("outcome") == "success")
    jicm_success = sum(1 for t in jicm_trials if t.get("outcome") == "success")
    lines += [
        "", "### Reliability",
        f"- **/compact success rate**: {compact_success}/{len(compact_trials)} ({100*compact_success//max(len(compact_trials),1)}%)",
        f"- **JICM success rate**: {jicm_success}/{len(jicm_trials)} ({100*jicm_success//max(len(jicm_trials),1)}%)",
    ]

    # JICM phase breakdown
    jicm_with_phases = [t for t in jicm_trials if "halt_time_s" in t]
    if jicm_with_phases:
        lines += ["", "### JICM Phase Breakdown (successful cycles)", ""]
        lines.append("| Phase | Mean | Median | Min | Max |")
        lines.append("|-------|------|--------|-----|-----|")
        for phase in ["halt_time_s", "compress_time_s", "clear_time_s", "restore_time_s"]:
            vals = [t[phase] for t in jicm_with_phases if t.get(phase, 0) > 0]
            if vals:
                stats = descriptive_stats(vals)
                label = phase.replace("_time_s", "").capitalize()
                lines.append(f"| {label} | {stats['mean']}s | {stats['median']}s | {stats['min']}s | {stats['max']}s |")

    lines += [
        "", "---", "",
        "## Paired Data",
        "",
        "| Pair | Context % | /compact (s) | JICM (s) | Diff (s) |",
        "|------|-----------|-------------|----------|----------|",
    ]
    for pair_id in sorted(pairs.keys()):
        p = pairs[pair_id]
        c = p["compact"]
        j = p["jicm"]
        diff = j.get("duration_s", 0) - c.get("duration_s", 0)
        lines.append(
            f"| {pair_id} | {c.get('start_pct', '?')}% | "
            f"{c.get('duration_s', '?')} | {j.get('duration_s', '?')} | {diff:+.0f} |"
        )

    lines += ["", "---", "", "*Generated by analyze-compression-data.py*", ""]

    report_text = "\n".join(lines)
    if report_path:
        with open(report_path, "w") as f:
            f.write(report_text)
        print(f"Report written to {report_path}", file=sys.stderr)
    return report_text


def main():
    parser = argparse.ArgumentParser(description="Analyze compression timing data")
    parser.add_argument("--data", default=DEFAULT_DATA, help="Path to JSONL data file")
    parser.add_argument("--report", default=None, help="Path to write markdown report")
    parser.add_argument("--verbose", action="store_true", help="Show detailed output")
    args = parser.parse_args()

    if not os.path.exists(args.data):
        print(f"ERROR: Data file not found: {args.data}", file=sys.stderr)
        print("Run trials first to generate data.", file=sys.stderr)
        sys.exit(1)

    trials = load_data(args.data)
    if not trials:
        print("ERROR: No valid trials in data file", file=sys.stderr)
        sys.exit(1)

    print(f"Loaded {len(trials)} trials from {args.data}", file=sys.stderr)

    # Separate by treatment
    compact_trials = [t for t in trials if t.get("treatment") == "compact" and t.get("outcome") == "success"]
    jicm_trials = [t for t in trials if t.get("treatment") == "jicm" and t.get("outcome") == "success"]

    compact_durations = [t["duration_s"] for t in compact_trials]
    jicm_durations = [t["duration_s"] for t in jicm_trials]

    compact_stats = descriptive_stats(compact_durations)
    jicm_stats = descriptive_stats(jicm_durations)

    print("\n=== Descriptive Statistics ===")
    print(f"/compact: n={compact_stats['n']}, M={compact_stats['mean']}s, "
          f"Mdn={compact_stats['median']}s, SD={compact_stats['sd']}s")
    print(f"JICM:     n={jicm_stats['n']}, M={jicm_stats['mean']}s, "
          f"Mdn={jicm_stats['median']}s, SD={jicm_stats['sd']}s")

    # Pair matching
    pairs = pair_trials(trials)
    print(f"\nComplete matched pairs: {len(pairs)}")

    # Extract paired durations (successful only)
    paired_compact = []
    paired_jicm = []
    for pair_id in sorted(pairs.keys()):
        p = pairs[pair_id]
        c = p["compact"]
        j = p["jicm"]
        if c.get("outcome") == "success" and j.get("outcome") == "success":
            paired_compact.append(c["duration_s"])
            paired_jicm.append(j["duration_s"])

    print(f"Pairs with both successful: {len(paired_compact)}")

    # Primary analysis
    wilcoxon_result = None
    t_test_result = None
    correlation_result = None

    if len(paired_compact) >= 2:
        print("\n=== Wilcoxon Signed-Rank Test ===")
        wilcoxon_result = wilcoxon_test(paired_compact, paired_jicm)
        if wilcoxon_result:
            print(f"W = {wilcoxon_result['statistic']}, p = {wilcoxon_result['p_value']}, "
                  f"r = {wilcoxon_result['effect_size_r']}")
            if wilcoxon_result['p_value'] < 0.05:
                print("=> SIGNIFICANT: JICM takes significantly longer")
            else:
                print("=> NOT SIGNIFICANT: No difference detected")
        else:
            print("scipy not available — cannot run test")

        print("\n=== Paired t-test (secondary) ===")
        t_test_result = paired_t_test(paired_compact, paired_jicm)
        if t_test_result:
            print(f"t = {t_test_result['t_statistic']}, p = {t_test_result['p_value']}")

    # Correlation: context % vs duration
    all_pcts = [t["start_pct"] for t in trials if "start_pct" in t and t.get("outcome") == "success"]
    all_durs = [t["duration_s"] for t in trials if "start_pct" in t and t.get("outcome") == "success"]
    if len(all_pcts) >= 3:
        correlation_result = spearman_correlation(all_pcts, all_durs)
        if correlation_result:
            print(f"\n=== Context % vs Duration (Spearman) ===")
            print(f"ρ = {correlation_result['rho']}, p = {correlation_result['p_value']}")

    # Generate report
    report_path = args.report or DEFAULT_REPORT
    report = generate_report(trials, pairs, compact_stats, jicm_stats,
                             wilcoxon_result, t_test_result, correlation_result, report_path)
    if args.verbose:
        print("\n" + report)


if __name__ == "__main__":
    main()
