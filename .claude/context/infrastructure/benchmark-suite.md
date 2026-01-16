# Benchmark Suite Specification

**ID**: PR-13.2
**Version**: 1.0.0
**Status**: implementing
**Created**: 2026-01-16
**Last Modified**: 2026-01-16

---

## Purpose

Define and execute end-to-end benchmarks that measure autonomous behavior quality, performance, and effectiveness. Benchmarks establish baselines, enable comparison across versions, and feed into the scoring and regression detection systems.

---

## Architecture

```
┌─────────────────────────────────────────────────────────────────────┐
│                    BENCHMARK SUITE ARCHITECTURE                      │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  BENCHMARK DEFINITIONS                                               │
│  ┌─────────────┐ ┌─────────────┐ ┌─────────────┐ ┌─────────────┐   │
│  │  Component  │ │  End-to-End │ │ Performance │ │  Quality    │   │
│  │  Benchmarks │ │  Scenarios  │ │  Benchmarks │ │  Benchmarks │   │
│  └──────┬──────┘ └──────┬──────┘ └──────┬──────┘ └──────┬──────┘   │
│         │               │               │               │           │
│         └───────────────┴───────────────┴───────────────┘           │
│                                   │                                  │
│                                   ▼                                  │
│                        ┌─────────────────────┐                      │
│                        │  BENCHMARK RUNNER   │                      │
│                        │                     │                      │
│                        │  • Load definitions │                      │
│                        │  • Execute tests    │                      │
│                        │  • Collect metrics  │                      │
│                        │  • Compare baselines│                      │
│                        └──────────┬──────────┘                      │
│                                   │                                  │
│                                   ▼                                  │
│                        ┌─────────────────────┐                      │
│                        │  RESULTS STORAGE    │                      │
│                        │                     │                      │
│                        │  • Run history      │                      │
│                        │  • Baselines        │                      │
│                        │  • Comparisons      │                      │
│                        └──────────┬──────────┘                      │
│                                   │                                  │
│                    ┌──────────────┴──────────────┐                  │
│                    │                             │                  │
│                    ▼                             ▼                  │
│         ┌─────────────────────┐     ┌─────────────────────┐        │
│         │  PR-13.3 Scoring    │     │  PR-13.5 Regression │        │
│         └─────────────────────┘     └─────────────────────┘        │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Benchmark Categories

### 1. Component Benchmarks

Test individual autonomic components in isolation.

| Benchmark ID | Component | Measures |
|--------------|-----------|----------|
| `BENCH-C01` | AC-01 Self-Launch | Startup time, context load |
| `BENCH-C02` | AC-02 Wiggum Loop | Iteration efficiency, completion rate |
| `BENCH-C03` | AC-03 Milestone Review | Review thoroughness, accuracy |
| `BENCH-C04` | AC-04 JICM | Checkpoint reliability, resume success |
| `BENCH-C05` | AC-05 Self-Reflection | Pattern detection rate |
| `BENCH-C06` | AC-06 Self-Evolution | Implementation success, rollback rate |
| `BENCH-C07` | AC-07 R&D | Discovery rate, relevance filtering |
| `BENCH-C08` | AC-08 Maintenance | Health check accuracy, cleanup efficiency |
| `BENCH-C09` | AC-09 Session Completion | State preservation, handoff quality |

### 2. End-to-End Scenarios

Test complete workflows across multiple components.

| Benchmark ID | Scenario | Components Involved |
|--------------|----------|---------------------|
| `BENCH-E01` | Session lifecycle | AC-01 → AC-02 → AC-09 |
| `BENCH-E02` | Context exhaustion recovery | AC-02 → AC-04 → AC-02 |
| `BENCH-E03` | Self-improvement cycle | AC-05 → AC-06 → AC-08 |
| `BENCH-E04` | R&D to evolution | AC-07 → AC-06 |
| `BENCH-E05` | Milestone review flow | AC-02 → AC-03 → AC-06 |
| `BENCH-E06` | Full /self-improve | All Tier 2 components |

### 3. Performance Benchmarks

Measure resource usage and efficiency.

| Benchmark ID | Metric | Target | Alert |
|--------------|--------|--------|-------|
| `BENCH-P01` | Startup time | < 10s | > 30s |
| `BENCH-P02` | Context efficiency | < 60% avg | > 80% |
| `BENCH-P03` | Token cost per session | < 50K | > 100K |
| `BENCH-P04` | Checkpoint creation | < 5s | > 15s |
| `BENCH-P05` | Evolution validation | < 60s | > 180s |

### 4. Quality Benchmarks

Measure output quality and correctness.

| Benchmark ID | Quality Metric | Target | Alert |
|--------------|----------------|--------|-------|
| `BENCH-Q01` | Loop completion rate | > 95% | < 80% |
| `BENCH-Q02` | Evolution success rate | > 90% | < 70% |
| `BENCH-Q03` | Rollback frequency | < 10% | > 20% |
| `BENCH-Q04` | State preservation | 100% | < 95% |
| `BENCH-Q05` | Pattern detection accuracy | > 80% | < 60% |

---

## Benchmark Definitions

### Definition Format

```yaml
# .claude/benchmarks/BENCH-C01-self-launch.yaml
id: BENCH-C01
name: Self-Launch Startup
category: component
component: AC-01
version: 1.0.0

description: |
  Measures self-launch performance including context loading,
  environmental awareness, and greeting generation.

preconditions:
  - clean_session: true
  - context_usage: < 5%
  - required_files:
    - .claude/context/session-state.md
    - .claude/config/autonomy-config.yaml

steps:
  - trigger: session_start
  - wait_for: component_end
  - collect_metrics: true

metrics:
  - name: startup_duration_ms
    type: timing
    target: < 10000
    alert: > 30000

  - name: context_loaded_percent
    type: gauge
    target: < 20
    alert: > 40

  - name: greeting_quality_score
    type: score
    target: > 80
    alert: < 50

validation:
  - check: session_state_updated
    expected: true
  - check: greeting_present
    expected: true
  - check: next_action_proposed
    expected: true

tags:
  - startup
  - critical-path
  - fast
```

### End-to-End Scenario Definition

```yaml
# .claude/benchmarks/BENCH-E01-session-lifecycle.yaml
id: BENCH-E01
name: Full Session Lifecycle
category: end-to-end
version: 1.0.0

description: |
  Tests complete session from start through work to completion.
  Exercises AC-01, AC-02, and AC-09 in sequence.

scenario:
  - phase: startup
    trigger: session_start
    expected_component: AC-01
    timeout: 30000

  - phase: work
    trigger: user_task
    task: "Complete a simple documentation update"
    expected_component: AC-02
    timeout: 300000

  - phase: completion
    trigger: end_session
    expected_component: AC-09
    timeout: 60000

metrics:
  - name: total_session_time_ms
    type: timing

  - name: context_peak_usage
    type: gauge
    target: < 70
    alert: > 90

  - name: work_completed
    type: boolean
    target: true

  - name: state_preserved
    type: boolean
    target: true

  - name: handoff_quality
    type: score
    target: > 90
    alert: < 70

validation:
  - check: session_summary_created
    expected: true
  - check: checkpoint_created
    expected: true
  - check: git_commit_made
    expected: true

tags:
  - end-to-end
  - critical-path
  - slow
```

---

## Benchmark Runner

### Runner Interface

```javascript
// benchmark-runner.js

class BenchmarkRunner {
  constructor(config) {
    this.config = config;
    this.results = [];
  }

  // Run a single benchmark
  async run(benchmarkId) {
    const definition = loadBenchmark(benchmarkId);
    const result = await execute(definition);
    this.results.push(result);
    return result;
  }

  // Run all benchmarks in a category
  async runCategory(category) {
    const benchmarks = getBenchmarksByCategory(category);
    for (const bench of benchmarks) {
      await this.run(bench.id);
    }
    return this.results;
  }

  // Run all benchmarks
  async runAll() {
    const benchmarks = getAllBenchmarks();
    for (const bench of benchmarks) {
      await this.run(bench.id);
    }
    return this.results;
  }

  // Compare against baseline
  compareToBaseline(baselineId) {
    const baseline = loadBaseline(baselineId);
    return compare(this.results, baseline);
  }

  // Save results
  saveResults(runId) {
    const path = `.claude/benchmarks/results/${runId}.json`;
    writeResults(path, this.results);
  }

  // Set new baseline
  setBaseline(runId) {
    const results = loadResults(runId);
    saveBaseline(results);
  }
}
```

### Execution Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                    BENCHMARK EXECUTION FLOW                          │
├─────────────────────────────────────────────────────────────────────┤
│                                                                      │
│  1. LOAD                                                             │
│     ├── Parse benchmark definition                                  │
│     ├── Verify preconditions                                        │
│     └── Initialize metrics collection                               │
│                                                                      │
│  2. SETUP                                                            │
│     ├── Create isolated environment (if needed)                     │
│     ├── Reset state files                                           │
│     └── Clear telemetry for clean measurement                       │
│                                                                      │
│  3. EXECUTE                                                          │
│     ├── Trigger benchmark scenario                                  │
│     ├── Monitor progress via telemetry                              │
│     ├── Collect metrics at checkpoints                              │
│     └── Wait for completion or timeout                              │
│                                                                      │
│  4. VALIDATE                                                         │
│     ├── Run validation checks                                       │
│     ├── Compare metrics to targets                                  │
│     └── Determine pass/fail status                                  │
│                                                                      │
│  5. RECORD                                                           │
│     ├── Store results with timestamp                                │
│     ├── Calculate deltas from baseline                              │
│     └── Emit benchmark_complete event                               │
│                                                                      │
└─────────────────────────────────────────────────────────────────────┘
```

---

## Results Storage

### Results Format

```json
{
  "run_id": "bench-2026-01-16-001",
  "timestamp": "2026-01-16T18:00:00.000Z",
  "version": "2.0.0",
  "benchmarks": [
    {
      "id": "BENCH-C01",
      "name": "Self-Launch Startup",
      "status": "pass",
      "duration_ms": 8500,
      "metrics": {
        "startup_duration_ms": {
          "value": 8500,
          "target": 10000,
          "status": "pass"
        },
        "context_loaded_percent": {
          "value": 15,
          "target": 20,
          "status": "pass"
        }
      },
      "validations": {
        "session_state_updated": true,
        "greeting_present": true,
        "next_action_proposed": true
      }
    }
  ],
  "summary": {
    "total": 15,
    "passed": 14,
    "failed": 1,
    "skipped": 0,
    "pass_rate": 93.3
  }
}
```

### Storage Location

```
.claude/benchmarks/
├── definitions/
│   ├── BENCH-C01-self-launch.yaml
│   ├── BENCH-C02-wiggum-loop.yaml
│   └── ...
├── results/
│   ├── bench-2026-01-16-001.json
│   ├── bench-2026-01-15-001.json
│   └── ...
├── baselines/
│   ├── baseline-v2.0.0.json
│   ├── baseline-v1.9.5.json
│   └── current.json -> baseline-v2.0.0.json
└── comparisons/
    ├── compare-2026-01-16.json
    └── ...
```

---

## Baselines

### Baseline Establishment

```javascript
// Create baseline from benchmark run
async function establishBaseline(runId, version) {
  const results = loadResults(runId);

  const baseline = {
    version,
    established: new Date().toISOString(),
    run_id: runId,
    metrics: extractMetricBaselines(results),
    thresholds: calculateThresholds(results)
  };

  saveBaseline(baseline, version);
  updateCurrentBaseline(version);
}
```

### Baseline Format

```json
{
  "version": "2.0.0",
  "established": "2026-01-16T18:00:00.000Z",
  "run_id": "bench-2026-01-16-001",
  "metrics": {
    "BENCH-C01": {
      "startup_duration_ms": {
        "baseline": 8500,
        "p50": 8200,
        "p95": 12000,
        "threshold_warn": 10000,
        "threshold_fail": 30000
      }
    }
  }
}
```

---

## Comparison

### Comparison Output

```json
{
  "comparison_id": "compare-2026-01-16",
  "current_run": "bench-2026-01-16-002",
  "baseline": "baseline-v2.0.0",
  "timestamp": "2026-01-16T20:00:00.000Z",
  "results": [
    {
      "benchmark": "BENCH-C01",
      "metric": "startup_duration_ms",
      "baseline_value": 8500,
      "current_value": 9200,
      "delta": 700,
      "delta_percent": 8.2,
      "status": "within_threshold",
      "direction": "worse"
    }
  ],
  "summary": {
    "improved": 5,
    "stable": 8,
    "degraded": 2,
    "regression_detected": false
  }
}
```

---

## Command Interface

### `/benchmark` Command

```
Usage: /benchmark [options]

Options:
  --all                 Run all benchmarks
  --category=<cat>      Run specific category (component, e2e, perf, quality)
  --id=<id>             Run specific benchmark
  --compare             Compare to baseline after run
  --set-baseline        Set current run as new baseline
  --quick               Run only fast benchmarks
  --verbose             Show detailed output

Examples:
  /benchmark --all
  /benchmark --category=component
  /benchmark --id=BENCH-C01
  /benchmark --all --compare
  /benchmark --all --set-baseline
```

---

## Scheduling

### When to Run Benchmarks

| Trigger | Benchmark Scope | Purpose |
|---------|-----------------|---------|
| Version release | All | Establish baseline |
| PR merge | Affected components | Regression check |
| /self-improve end | Quality benchmarks | Validate evolution |
| Weekly | All | Trend monitoring |
| Manual | As specified | Ad-hoc validation |

### Integration with Evolution (AC-06)

```yaml
# Before evolution implementation
pre_implementation:
  - run: affected_component_benchmarks
  - record: pre_metrics

# After evolution implementation
post_implementation:
  - run: affected_component_benchmarks
  - compare: pre_metrics
  - gate: no_regression
```

---

## Implementation Files

| File | Purpose | Status |
|------|---------|--------|
| `.claude/hooks/benchmark-runner.js` | Runner implementation | planned |
| `.claude/hooks/benchmark-compare.js` | Comparison logic | planned |
| `.claude/commands/benchmark.md` | Command definition | planned |
| `.claude/benchmarks/definitions/` | Benchmark definitions | planned |
| `.claude/benchmarks/results/` | Results storage | planned |
| `.claude/benchmarks/baselines/` | Baseline storage | planned |

---

## Initial Benchmark Suite

### Critical Path Benchmarks (Must Pass)

1. `BENCH-C01` - Self-Launch completes successfully
2. `BENCH-C04` - JICM checkpoint/resume works
3. `BENCH-C09` - Session completion preserves state
4. `BENCH-E01` - Full session lifecycle works
5. `BENCH-E02` - Context exhaustion recovery works

### Performance Benchmarks

6. `BENCH-P01` - Startup under 10 seconds
7. `BENCH-P02` - Average context < 60%
8. `BENCH-P04` - Checkpoint under 5 seconds

### Quality Benchmarks

9. `BENCH-Q01` - Loop completion > 95%
10. `BENCH-Q04` - State preservation 100%

---

## Validation Checklist

- [ ] 10+ benchmarks defined
- [ ] Runner executes benchmarks correctly
- [ ] Results stored properly
- [ ] Baseline established for v2.0.0
- [ ] Comparison works
- [ ] `/benchmark` command operational
- [ ] Integration with AC-06 evolution gates
- [ ] Telemetry integration working

---

*Benchmark Suite — PR-13.2 Specification*
