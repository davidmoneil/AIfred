# Regression Detection Specification

**ID**: PR-13.5
**Version**: 1.0.0
**Status**: implementing
**Created**: 2026-01-16
**Last Modified**: 2026-01-16

---

## Purpose

Automatically detect performance regressions, quality degradation, and behavioral changes by comparing current metrics against established baselines. Regression detection serves as a safety gate for the self-evolution process (AC-06) and provides early warning of issues.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                 REGRESSION DETECTION ARCHITECTURE                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  DATA SOURCES                                                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │
│  │ Telemetry   │ │ Benchmarks  │ │  Scores     │ │ Baselines   │   │
│  │ (PR-13.1)   │ │ (PR-13.2)   │ │ (PR-13.3)   │ │             │   │
│  └──────┬──────┘ └──────┬──────┘ └──────┬──────┘ └──────┬──────┘   │
│         │               │               │               │           │
│         └───────────────┴───────────────┴───────────────┘           │
│                                   │                                  │
│                                   ▼                                  │
│                        ┌─────────────────────┐                      │
│                        │  REGRESSION DETECTOR │                      │
│                        │                      │                      │
│                        │  • Compare to baseline│                     │
│                        │  • Statistical analysis│                    │
│                        │  • Trend detection    │                     │
│                        │  • Anomaly detection  │                     │
│                        └──────────┬───────────┘                      │
│                                   │                                  │
│              ┌────────────────────┼────────────────────┐            │
│              │                    │                    │            │
│              ▼                    ▼                    ▼            │
│       ┌─────────────┐     ┌─────────────┐     ┌─────────────┐      │
│       │ Regression  │     │  Evolution  │     │  Dashboard  │      │
│       │  Alerts     │     │   Gates     │     │  (PR-13.4)  │      │
│       └─────────────┘     └─────────────┘     └─────────────┘      │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Detection Methods

### 1. Baseline Comparison

Compare current metrics against established baselines.

```javascript
function compareToBaseline(current, baseline, thresholds) {
  const results = [];

  for (const metric of Object.keys(current)) {
    const currentValue = current[metric];
    const baselineValue = baseline[metric];
    const delta = currentValue - baselineValue;
    const deltaPercent = (delta / baselineValue) * 100;

    let status = 'normal';
    if (Math.abs(deltaPercent) > thresholds.warning) {
      status = 'warning';
    }
    if (Math.abs(deltaPercent) > thresholds.regression) {
      status = 'regression';
    }

    results.push({
      metric,
      baseline: baselineValue,
      current: currentValue,
      delta,
      delta_percent: deltaPercent,
      status,
      direction: delta > 0 ? 'increase' : 'decrease'
    });
  }

  return results;
}
```

### 2. Statistical Analysis

Detect anomalies using statistical methods.

```javascript
function detectStatisticalAnomaly(values, current) {
  const mean = average(values);
  const stdDev = standardDeviation(values);

  // Z-score calculation
  const zScore = (current - mean) / stdDev;

  // Anomaly if > 2 standard deviations
  const isAnomaly = Math.abs(zScore) > 2;

  return {
    mean,
    stdDev,
    zScore,
    isAnomaly,
    severity: Math.abs(zScore) > 3 ? 'severe' : 'moderate'
  };
}
```

### 3. Trend Analysis

Detect gradual degradation over time.

```javascript
function detectTrendRegression(history, windowSize = 7) {
  const recent = history.slice(-windowSize);
  const previous = history.slice(-windowSize * 2, -windowSize);

  const recentTrend = calculateTrend(recent);
  const previousTrend = calculateTrend(previous);

  // Regression if trend changed from stable/improving to declining
  const isRegression =
    previousTrend.direction !== 'declining' &&
    recentTrend.direction === 'declining' &&
    Math.abs(recentTrend.slope) > thresholds.trend_change;

  return {
    isRegression,
    previousTrend,
    recentTrend,
    severity: calculateTrendSeverity(recentTrend)
  };
}
```

### 4. Composite Regression Score

Combine multiple signals into single regression risk score.

```javascript
function calculateRegressionRisk(comparisons, anomalies, trends) {
  let risk = 0;
  let factors = [];

  // Baseline comparison contribution (40%)
  const regressionCount = comparisons.filter(c => c.status === 'regression').length;
  const comparisonRisk = (regressionCount / comparisons.length) * 40;
  risk += comparisonRisk;

  // Anomaly contribution (30%)
  const anomalyCount = anomalies.filter(a => a.isAnomaly).length;
  const anomalyRisk = (anomalyCount / anomalies.length) * 30;
  risk += anomalyRisk;

  // Trend contribution (30%)
  const decliningCount = trends.filter(t => t.isRegression).length;
  const trendRisk = (decliningCount / trends.length) * 30;
  risk += trendRisk;

  return {
    risk: Math.min(100, risk),
    level: risk > 70 ? 'high' : risk > 40 ? 'medium' : 'low',
    factors: {
      baseline: comparisonRisk,
      anomaly: anomalyRisk,
      trend: trendRisk
    }
  };
}
```

---

## Detection Triggers

### When to Run Detection

| Trigger | Scope | Threshold |
|---------|-------|-----------|
| After benchmark run | All metrics | Standard |
| After evolution | Changed components | Strict |
| Session end | Session metrics | Standard |
| Daily scheduled | All metrics | Standard |
| Score drop | Affected component | Immediate |

### Trigger Configuration

```yaml
regression_detection:
  triggers:
    # After benchmarks
    post_benchmark: true
    post_benchmark_threshold: standard

    # After evolution
    post_evolution: true
    post_evolution_threshold: strict

    # Session boundary
    session_end: true
    session_threshold: standard

    # Scheduled
    daily_check: true
    daily_time: "00:00"

    # Real-time
    score_drop_trigger: true
    score_drop_percent: 10
```

---

## Thresholds

### Standard Thresholds

| Metric Type | Warning | Regression | Critical |
|-------------|---------|------------|----------|
| Performance | 10% | 20% | 30% |
| Quality | 5% | 10% | 20% |
| Scores | 5 points | 10 points | 15 points |
| Success rate | 3% | 5% | 10% |

### Strict Thresholds (Post-Evolution)

| Metric Type | Warning | Regression | Critical |
|-------------|---------|------------|----------|
| Performance | 5% | 10% | 20% |
| Quality | 3% | 5% | 10% |
| Scores | 3 points | 5 points | 10 points |
| Success rate | 2% | 3% | 5% |

### Custom Thresholds

```yaml
# Per-component threshold overrides
thresholds:
  AC-01:
    startup_time:
      warning: 15%
      regression: 25%
  AC-06:
    success_rate:
      warning: 2%
      regression: 5%
```

---

## Regression Report Format

### Detection Output

```json
{
  "detection_id": "reg-2026-01-16-001",
  "timestamp": "2026-01-16T20:00:00.000Z",
  "trigger": "post_evolution",
  "baseline_version": "2.0.0",
  "current_run": "bench-2026-01-16-002",
  "regression_risk": {
    "risk": 45,
    "level": "medium",
    "factors": {
      "baseline": 20,
      "anomaly": 15,
      "trend": 10
    }
  },
  "regressions": [
    {
      "component": "AC-02",
      "metric": "completion_rate",
      "baseline": 96,
      "current": 89,
      "delta": -7,
      "delta_percent": -7.3,
      "severity": "warning",
      "detection_method": "baseline_comparison"
    }
  ],
  "anomalies": [
    {
      "component": "AC-04",
      "metric": "checkpoint_time_ms",
      "value": 8500,
      "mean": 4200,
      "z_score": 2.8,
      "severity": "moderate"
    }
  ],
  "trend_alerts": [
    {
      "component": "AC-07",
      "metric": "discovery_rate",
      "trend": "declining",
      "slope": -0.5,
      "window_days": 7
    }
  ],
  "recommendation": "Review AC-02 completion rate before approving evolution",
  "gate_action": "block"
}
```

### Summary Format

```
┌─────────────────────────────────────────────────────────────────────┐
│                    REGRESSION DETECTION REPORT                       │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Trigger: Post-Evolution Check                                       │
│  Baseline: v2.0.0                                                    │
│  Timestamp: 2026-01-16 20:00                                         │
│                                                                      │
│  REGRESSION RISK: MEDIUM (45%)                                       │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  ████████████████████████░░░░░░░░░░░░░░░░░░░░  45%             │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  REGRESSIONS DETECTED (1)                                            │
│  ⚠ AC-02 completion_rate: 96% → 89% (-7.3%)                         │
│                                                                      │
│  ANOMALIES DETECTED (1)                                              │
│  ⚠ AC-04 checkpoint_time: 8500ms (z-score: 2.8)                     │
│                                                                      │
│  TREND ALERTS (1)                                                    │
│  ⚠ AC-07 discovery_rate: Declining trend (-0.5/day)                 │
│                                                                      │
│  RECOMMENDATION                                                      │
│  Review AC-02 completion rate before approving evolution.           │
│  Consider rolling back recent changes if issue persists.            │
│                                                                      │
│  GATE ACTION: BLOCK                                                  │
│  Evolution blocked until regression addressed.                       │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Evolution Gate Integration

### Pre-Implementation Gate

Before AC-06 implements changes:

```javascript
async function preImplementationGate(evolutionId, affectedComponents) {
  // Run benchmarks on affected components
  const benchmarks = await runBenchmarks(affectedComponents);

  // Store pre-implementation metrics
  savePreMetrics(evolutionId, benchmarks);

  // Check baseline health
  const detection = await detectRegressions(benchmarks, 'standard');

  if (detection.regression_risk.level === 'high') {
    return {
      gate: 'block',
      reason: 'Existing regressions detected',
      detection
    };
  }

  return { gate: 'pass' };
}
```

### Post-Implementation Gate

After AC-06 implements changes:

```javascript
async function postImplementationGate(evolutionId) {
  // Run benchmarks
  const benchmarks = await runBenchmarks();

  // Compare to pre-implementation
  const preMetrics = loadPreMetrics(evolutionId);
  const detection = await detectRegressions(benchmarks, 'strict');

  // Also compare to baseline
  const baselineComparison = await compareToBaseline(benchmarks);

  if (detection.regression_risk.level !== 'low') {
    return {
      gate: 'rollback',
      reason: 'Post-implementation regression detected',
      detection,
      action: 'Rollback recommended'
    };
  }

  return { gate: 'pass' };
}
```

### Gate Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    EVOLUTION GATE FLOW                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. PROPOSAL RECEIVED                                                │
│     │                                                                │
│     ▼                                                                │
│  2. PRE-IMPLEMENTATION GATE                                          │
│     ├── Run baseline benchmarks                                     │
│     ├── Check for existing regressions                              │
│     └── Gate: PASS / BLOCK                                          │
│         │                                                            │
│         ▼ (if PASS)                                                  │
│  3. IMPLEMENT CHANGES                                                │
│     │                                                                │
│     ▼                                                                │
│  4. POST-IMPLEMENTATION GATE                                         │
│     ├── Run strict benchmarks                                       │
│     ├── Compare to pre-implementation                               │
│     ├── Compare to baseline                                         │
│     └── Gate: PASS / ROLLBACK                                       │
│         │                                                            │
│         ├── (if PASS) → MERGE to branch                             │
│         └── (if ROLLBACK) → REVERT changes                          │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Alerts

### Regression Alert Types

| Alert Type | Trigger | Severity | Action |
|------------|---------|----------|--------|
| `baseline_regression` | Metric > threshold below baseline | Medium-High | Review |
| `statistical_anomaly` | Z-score > 2 | Medium | Investigate |
| `trend_regression` | Declining trend detected | Low-Medium | Monitor |
| `evolution_regression` | Post-evolution decline | High | Rollback |
| `composite_risk` | Risk score > 70 | High | Block evolution |

### Alert Format

```json
{
  "alert_id": "reg-alert-2026-01-16-001",
  "type": "baseline_regression",
  "severity": "high",
  "timestamp": "2026-01-16T20:00:00.000Z",
  "component": "AC-02",
  "metric": "completion_rate",
  "details": {
    "baseline": 96,
    "current": 89,
    "threshold": 5,
    "exceeded_by": 2.3
  },
  "recommendation": "Investigate AC-02 loop completion. Check for timeout issues.",
  "auto_action": "block_evolution",
  "acknowledged": false
}
```

---

## Commands

### `/regression` Command

```
Usage: /regression [options]

Options:
  --check              Run regression detection now
  --compare=<version>  Compare to specific baseline
  --component=<id>     Check specific component
  --history            Show regression history
  --detail             Show detailed analysis

Examples:
  /regression --check
  /regression --compare=v1.9.5
  /regression --component=ac02 --detail
  /regression --history
```

---

## Storage

### Regression History

```
.claude/metrics/regressions/
├── detections/
│   ├── reg-2026-01-16-001.json
│   └── reg-2026-01-16-002.json
├── alerts/
│   └── regression-alerts.json
├── pre_metrics/
│   ├── evol-001-pre.json
│   └── evol-002-pre.json
└── history.jsonl
```

### History Format (JSONL)

```jsonl
{"timestamp":"2026-01-16T20:00:00.000Z","detection_id":"reg-2026-01-16-001","risk_level":"medium","regressions":1,"anomalies":1,"trends":1}
{"timestamp":"2026-01-15T18:00:00.000Z","detection_id":"reg-2026-01-15-001","risk_level":"low","regressions":0,"anomalies":0,"trends":0}
```

---

## Configuration

### regression-config.yaml

```yaml
regression_detection:
  # Enable/disable
  enabled: true

  # Default thresholds
  thresholds:
    standard:
      warning_percent: 10
      regression_percent: 20
      critical_percent: 30
    strict:
      warning_percent: 5
      regression_percent: 10
      critical_percent: 20

  # Statistical analysis
  statistics:
    anomaly_z_score: 2.0
    severe_z_score: 3.0
    min_samples: 7

  # Trend analysis
  trends:
    window_days: 7
    min_slope_threshold: 0.3

  # Triggers
  triggers:
    post_benchmark: true
    post_evolution: true
    session_end: true
    daily_check: true

  # Evolution gates
  gates:
    pre_implementation: true
    post_implementation: true
    auto_rollback: false  # Require confirmation

  # Alerts
  alerts:
    notify_warning: true
    notify_regression: true
    block_on_high_risk: true

  # Storage
  storage:
    path: .claude/metrics/regressions/
    retention_days: 90
```

---

## Implementation Files

| File | Purpose | Status |
|------|---------|--------|
| `.claude/hooks/regression-detector.js` | Detection logic | planned |
| `.claude/hooks/regression-gate.js` | Evolution gates | planned |
| `.claude/hooks/regression-alert.js` | Alert generation | planned |
| `.claude/commands/regression.md` | Command definition | planned |
| `.claude/config/regression-config.yaml` | Configuration | planned |
| `.claude/metrics/regressions/` | Detection storage | planned |

---

## Validation Checklist

- [ ] Baseline comparison working
- [ ] Statistical anomaly detection working
- [ ] Trend analysis working
- [ ] Composite risk calculation working
- [ ] Pre-implementation gate working
- [ ] Post-implementation gate working
- [ ] Rollback integration working
- [ ] Alerts generating properly
- [ ] `/regression` command operational
- [ ] Dashboard integration working

---

*Regression Detection — PR-13.5 Specification*
