# Scoring Framework Specification

**ID**: PR-13.3
**Version**: 1.0.0
**Status**: implementing
**Created**: 2026-01-16
**Last Modified**: 2026-01-16

---

## Purpose

Calculate meaningful scores that measure autonomous behavior effectiveness across components, sessions, and time periods. The scoring framework transforms raw telemetry and benchmark data into actionable metrics that guide improvement priorities.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    SCORING FRAMEWORK ARCHITECTURE                    │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  DATA SOURCES                                                        │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐                   │
│  │ Telemetry   │ │ Benchmarks  │ │ User        │                   │
│  │ Events      │ │ Results     │ │ Feedback    │                   │
│  └──────┬──────┘ └──────┬──────┘ └──────┬──────┘                   │
│         │               │               │                           │
│         └───────────────┴───────────────┘                           │
│                         │                                            │
│                         ▼                                            │
│              ┌─────────────────────────┐                            │
│              │    SCORE CALCULATOR     │                            │
│              │                         │                            │
│              │  • Component scores     │                            │
│              │  • Session scores       │                            │
│              │  • Aggregate scores     │                            │
│              │  • Trend analysis       │                            │
│              └───────────┬─────────────┘                            │
│                          │                                           │
│         ┌────────────────┼────────────────┐                         │
│         │                │                │                         │
│         ▼                ▼                ▼                         │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐                 │
│  │ Component   │  │ Session     │  │ Overall     │                 │
│  │ Scores      │  │ Scores      │  │ Health      │                 │
│  └──────┬──────┘  └──────┬──────┘  └──────┬──────┘                 │
│         │                │                │                         │
│         └────────────────┴────────────────┘                         │
│                          │                                           │
│                          ▼                                           │
│              ┌─────────────────────────┐                            │
│              │   SCORE STORAGE         │                            │
│              │                         │                            │
│              │  • Per-session          │                            │
│              │  • Daily aggregates     │                            │
│              │  • Trends               │                            │
│              └─────────────────────────┘                            │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Score Types

### 1. Component Scores

Individual scores for each autonomic component (0-100).

| Component | Score ID | Measures |
|-----------|----------|----------|
| AC-01 Self-Launch | `score.ac01` | Startup speed, context load, greeting quality |
| AC-02 Wiggum Loop | `score.ac02` | Completion rate, drift handling, efficiency |
| AC-03 Milestone Review | `score.ac03` | Thoroughness, accuracy, actionability |
| AC-04 JICM | `score.ac04` | Checkpoint reliability, resume success, efficiency |
| AC-05 Self-Reflection | `score.ac05` | Pattern detection, insight quality, coverage |
| AC-06 Self-Evolution | `score.ac06` | Success rate, validation rate, rollback rate |
| AC-07 R&D | `score.ac07` | Discovery rate, relevance, adoption rate |
| AC-08 Maintenance | `score.ac08` | Health accuracy, cleanup efficiency, freshness |
| AC-09 Session Completion | `score.ac09` | State preservation, handoff quality, completeness |

### 2. Session Scores

Composite scores for entire sessions.

| Score ID | Description | Components |
|----------|-------------|------------|
| `score.session.efficiency` | Resource usage efficiency | AC-01, AC-04 |
| `score.session.effectiveness` | Work output quality | AC-02, AC-03 |
| `score.session.improvement` | Self-improvement value | AC-05, AC-06, AC-07, AC-08 |
| `score.session.handoff` | Continuity quality | AC-09 |
| `score.session.overall` | Weighted composite | All |

### 3. Aggregate Scores

Higher-level scores over time periods.

| Score ID | Period | Purpose |
|----------|--------|---------|
| `score.daily` | 24 hours | Daily health check |
| `score.weekly` | 7 days | Trend visibility |
| `score.monthly` | 30 days | Long-term trends |
| `score.version` | Per release | Version comparison |

---

## Scoring Algorithms

### Component Score Calculation

```javascript
// Generic component score calculation
function calculateComponentScore(component, metrics) {
  const weights = getComponentWeights(component);
  const normalized = normalizeMetrics(metrics);

  let score = 0;
  let totalWeight = 0;

  for (const [metric, weight] of Object.entries(weights)) {
    if (normalized[metric] !== undefined) {
      score += normalized[metric] * weight;
      totalWeight += weight;
    }
  }

  return Math.round((score / totalWeight) * 100);
}
```

### AC-01 Self-Launch Score

```javascript
// AC-01 specific scoring
const AC01_WEIGHTS = {
  startup_time: 0.3,      // Lower is better
  context_efficiency: 0.2, // Lower is better
  greeting_quality: 0.2,   // Higher is better
  orientation_complete: 0.3 // Boolean
};

function scoreAC01(metrics) {
  const scores = {
    startup_time: scoreInverse(metrics.startup_ms, 5000, 30000),
    context_efficiency: scoreInverse(metrics.context_percent, 10, 40),
    greeting_quality: scoreLinear(metrics.greeting_score, 0, 100),
    orientation_complete: metrics.orientation_done ? 100 : 0
  };

  return weightedAverage(scores, AC01_WEIGHTS);
}
```

### AC-02 Wiggum Loop Score

```javascript
// AC-02 specific scoring
const AC02_WEIGHTS = {
  completion_rate: 0.35,    // Higher is better
  efficiency: 0.25,         // Fewer iterations = better
  drift_recovery: 0.20,     // Successful corrections
  quality: 0.20             // Work quality
};

function scoreAC02(metrics) {
  const scores = {
    completion_rate: metrics.completed / metrics.total * 100,
    efficiency: scoreInverse(metrics.avg_iterations, 1, 10),
    drift_recovery: metrics.drift_events > 0
      ? (metrics.drift_corrected / metrics.drift_events) * 100
      : 100,
    quality: metrics.review_score || 80
  };

  return weightedAverage(scores, AC02_WEIGHTS);
}
```

### AC-06 Self-Evolution Score

```javascript
// AC-06 specific scoring
const AC06_WEIGHTS = {
  success_rate: 0.40,       // Implementations that succeed
  validation_rate: 0.25,    // Pass validation
  rollback_avoidance: 0.20, // Lower rollbacks = better
  throughput: 0.15          // Proposals processed
};

function scoreAC06(metrics) {
  const scores = {
    success_rate: metrics.implemented > 0
      ? (metrics.successful / metrics.implemented) * 100
      : 100,
    validation_rate: metrics.validated / metrics.total * 100,
    rollback_avoidance: 100 - (metrics.rollbacks / metrics.implemented * 100),
    throughput: Math.min(100, metrics.processed / metrics.target * 100)
  };

  return weightedAverage(scores, AC06_WEIGHTS);
}
```

### Session Score Calculation

```javascript
// Session composite score
const SESSION_WEIGHTS = {
  efficiency: 0.20,
  effectiveness: 0.35,
  improvement: 0.25,
  handoff: 0.20
};

function calculateSessionScore(componentScores) {
  const sessionScores = {
    efficiency: average([componentScores.ac01, componentScores.ac04]),
    effectiveness: average([componentScores.ac02, componentScores.ac03]),
    improvement: average([
      componentScores.ac05,
      componentScores.ac06,
      componentScores.ac07,
      componentScores.ac08
    ]),
    handoff: componentScores.ac09
  };

  return {
    ...sessionScores,
    overall: weightedAverage(sessionScores, SESSION_WEIGHTS)
  };
}
```

---

## Score Thresholds

### Grade Scale

| Grade | Score Range | Status | Action |
|-------|-------------|--------|--------|
| A | 90-100 | Excellent | Maintain |
| B | 80-89 | Good | Minor improvements |
| C | 70-79 | Acceptable | Review needed |
| D | 60-69 | Concerning | Improvement priority |
| F | 0-59 | Critical | Immediate attention |

### Alert Thresholds

| Level | Threshold | Notification |
|-------|-----------|--------------|
| Warning | < 70 | Log + dashboard |
| Alert | < 60 | User notification |
| Critical | < 50 | Block evolution |

---

## Score Storage

### Per-Session Scores

```json
{
  "session_id": "session_2026-01-16_001",
  "timestamp": "2026-01-16T22:00:00.000Z",
  "version": "2.0.0",
  "component_scores": {
    "ac01": 92,
    "ac02": 88,
    "ac03": 85,
    "ac04": 95,
    "ac05": 78,
    "ac06": 82,
    "ac07": 75,
    "ac08": 90,
    "ac09": 94
  },
  "session_scores": {
    "efficiency": 93,
    "effectiveness": 86,
    "improvement": 81,
    "handoff": 94,
    "overall": 87
  },
  "grade": "B"
}
```

### Daily Aggregates

```json
{
  "date": "2026-01-16",
  "sessions_count": 3,
  "component_averages": {
    "ac01": {"avg": 91, "min": 88, "max": 94},
    "ac02": {"avg": 85, "min": 80, "max": 90}
  },
  "session_averages": {
    "efficiency": 90,
    "effectiveness": 84,
    "improvement": 79,
    "handoff": 92,
    "overall": 85
  },
  "trend": {
    "direction": "improving",
    "delta": 2.5
  }
}
```

### Storage Locations

```
.claude/metrics/scores/
├── sessions/
│   ├── session_2026-01-16_001.json
│   └── session_2026-01-16_002.json
├── daily/
│   ├── 2026-01-16.json
│   └── 2026-01-15.json
├── weekly/
│   └── 2026-W03.json
└── monthly/
    └── 2026-01.json
```

---

## Trend Analysis

### Trend Calculation

```javascript
// Calculate trend over time period
function calculateTrend(scores, days = 7) {
  const recentAvg = average(scores.slice(-days));
  const previousAvg = average(scores.slice(-days * 2, -days));

  const delta = recentAvg - previousAvg;
  const deltaPercent = (delta / previousAvg) * 100;

  return {
    direction: delta > 0 ? 'improving' : delta < 0 ? 'declining' : 'stable',
    delta: delta,
    delta_percent: deltaPercent,
    current_avg: recentAvg,
    previous_avg: previousAvg
  };
}
```

### Trend Output

```json
{
  "metric": "score.session.overall",
  "period": "7_days",
  "data": [82, 84, 83, 85, 87, 86, 88],
  "trend": {
    "direction": "improving",
    "delta": 3.5,
    "delta_percent": 4.2,
    "current_avg": 86.3,
    "previous_avg": 82.8
  },
  "forecast": {
    "next_7_days": 89,
    "confidence": 0.75
  }
}
```

---

## Score Display

### Summary Format

```
┌─────────────────────────────────────────────────────────────────────┐
│                    JARVIS HEALTH SCORE                               │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  Overall: 87 (B)  ↑ +2.5 from last week                             │
│                                                                      │
│  Component Scores:                                                   │
│  ┌────────────────────────────────────────────────────────────────┐ │
│  │  AC-01 Self-Launch      ████████████████████░░░░  92 (A)       │ │
│  │  AC-02 Wiggum Loop      █████████████████░░░░░░░  88 (B)       │ │
│  │  AC-03 Milestone Review ████████████████░░░░░░░░  85 (B)       │ │
│  │  AC-04 JICM             █████████████████████░░░  95 (A)       │ │
│  │  AC-05 Self-Reflection  ███████████████░░░░░░░░░  78 (C)       │ │
│  │  AC-06 Self-Evolution   ████████████████░░░░░░░░  82 (B)       │ │
│  │  AC-07 R&D Cycles       ██████████████░░░░░░░░░░  75 (C)       │ │
│  │  AC-08 Maintenance      ██████████████████░░░░░░  90 (A)       │ │
│  │  AC-09 Session Complete ████████████████████░░░░  94 (A)       │ │
│  └────────────────────────────────────────────────────────────────┘ │
│                                                                      │
│  Focus Areas:                                                        │
│  • AC-07 R&D: Below target (75). Consider research agenda review.   │
│  • AC-05 Reflection: Declining trend. Check data source quality.    │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Command Interface

### `/score` Command

```
Usage: /score [options]

Options:
  --session         Show current session scores
  --daily           Show today's aggregate
  --weekly          Show 7-day trend
  --monthly         Show 30-day trend
  --component=<id>  Focus on specific component
  --detail          Show detailed breakdown
  --export          Export to markdown file

Examples:
  /score                     # Quick summary
  /score --session           # Current session detail
  /score --weekly --detail   # 7-day detailed analysis
  /score --component=ac06    # AC-06 focus
```

---

## Integration Points

### With Benchmarks (PR-13.2)

Benchmark results feed into scoring:

```javascript
// After benchmark run
const benchmarkResults = await runBenchmarks();
const benchmarkScores = convertBenchmarksToScores(benchmarkResults);
mergeScores(sessionScores, benchmarkScores);
```

### With Regression Detection (PR-13.5)

Score drops trigger regression alerts:

```javascript
// Check for score regression
if (currentScore < baselineScore - threshold) {
  triggerRegressionAlert(component, currentScore, baselineScore);
}
```

### With Evolution Gates (AC-06)

Scores gate evolution:

```javascript
// Before allowing evolution
if (componentScore < 70) {
  blockEvolution(component, "Score below threshold");
}
```

### With Dashboard (PR-13.4)

Scores displayed on dashboard:

```javascript
// Dashboard data feed
dashboardData.scores = {
  current: getCurrentScores(),
  trend: getTrend('7_days'),
  alerts: getScoreAlerts()
};
```

---

## Configuration

### scoring-config.yaml

```yaml
scoring:
  # Enable/disable scoring
  enabled: true

  # Component weights (must sum to 1.0)
  session_weights:
    efficiency: 0.20
    effectiveness: 0.35
    improvement: 0.25
    handoff: 0.20

  # Alert thresholds
  thresholds:
    warning: 70
    alert: 60
    critical: 50

  # Trend calculation
  trends:
    short_term_days: 7
    long_term_days: 30

  # Storage
  storage:
    path: .claude/metrics/scores/
    retention_days: 365

  # Display
  display:
    show_grades: true
    show_trends: true
    show_recommendations: true
```

---

## Implementation Files

| File | Purpose | Status |
|------|---------|--------|
| `.claude/hooks/score-calculator.js` | Score calculation | planned |
| `.claude/hooks/score-aggregator.js` | Aggregation logic | planned |
| `.claude/hooks/score-trend.js` | Trend analysis | planned |
| `.claude/commands/score.md` | Command definition | planned |
| `.claude/config/scoring-config.yaml` | Configuration | planned |
| `.claude/metrics/scores/` | Score storage | planned |

---

## Validation Checklist

- [ ] All 9 component scores implemented
- [ ] Session composite scores working
- [ ] Daily/weekly/monthly aggregation working
- [ ] Trend analysis accurate
- [ ] Alert thresholds functional
- [ ] `/score` command operational
- [ ] Dashboard integration working
- [ ] Evolution gate integration working

---

*Scoring Framework — PR-13.3 Specification*
