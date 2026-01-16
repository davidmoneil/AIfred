# Autonomic Testing Framework

**Version**: 1.0.0
**Created**: 2026-01-16
**Status**: Active
**PR**: PR-11.6

---

## Overview

This framework defines how to test autonomic components in isolation, mock their dependencies, integrate with validation harnesses, and run regression tests. Reliable testing is essential for self-evolution safety.

### Core Principles

1. **Isolation**: Each component testable independently
2. **Determinism**: Tests produce consistent results
3. **Coverage**: All trigger paths and failure modes tested
4. **Safety**: Test mode never affects production state

---

## 1. Test Modes

### 1.1 Mode Classification

| Mode | Purpose | Side Effects | State Persistence |
|------|---------|--------------|-------------------|
| **Unit** | Test single component | None | Memory only |
| **Integration** | Test component interactions | Mock files | Temp directory |
| **Sandbox** | Test with real dependencies | Isolated env | Sandbox dir |
| **Regression** | Verify no degradation | None | Comparison only |

### 1.2 Enabling Test Mode

**Environment Variable**:
```bash
export JARVIS_TEST_MODE=unit       # Unit tests
export JARVIS_TEST_MODE=integration
export JARVIS_TEST_MODE=sandbox
export JARVIS_TEST_MODE=regression
```

**Command**:
```bash
jarvis test AC-02 --mode unit
jarvis test AC-02 --mode integration
jarvis test --all --mode regression
```

### 1.3 Test Mode Behavior

When test mode is active:

- **File writes** → Redirect to `.claude/test/sandbox/`
- **MCP calls** → Use mock implementations
- **Events** → Emit to test event log
- **Metrics** → Store in test metrics file
- **External APIs** → Use recorded responses or mocks

---

## 2. Component Isolation Testing

### 2.1 Test Harness Structure

Each component has a test harness:

```
.claude/test/
├── harnesses/
│   ├── AC-01-launch.test.js
│   ├── AC-02-wiggum.test.js
│   ├── AC-03-review.test.js
│   ├── AC-04-jicm.test.js
│   ├── AC-05-reflect.test.js
│   ├── AC-06-evolve.test.js
│   ├── AC-07-rnd.test.js
│   ├── AC-08-maintain.test.js
│   └── AC-09-session.test.js
├── fixtures/
│   ├── context/          # Mock context files
│   ├── state/            # Mock state files
│   └── events/           # Mock event streams
├── mocks/
│   ├── mcps/             # MCP mock implementations
│   └── components/       # Component mocks
└── sandbox/              # Isolated test environment
```

### 2.2 Test Harness Template

```javascript
// .claude/test/harnesses/AC-XX-component.test.js

const { TestHarness } = require('../lib/test-harness');
const { MockMCP, MockEvent, MockState } = require('../mocks');

describe('AC-XX ComponentName', () => {
  let harness;

  beforeEach(async () => {
    harness = new TestHarness('AC-XX');
    await harness.setup({
      mockMCPs: ['memory', 'datetime'],
      mockState: 'fixtures/state/AC-XX-initial.json',
      mockContext: 'fixtures/context/standard/'
    });
  });

  afterEach(async () => {
    await harness.teardown();
  });

  describe('Trigger: Automatic', () => {
    it('should activate on session start', async () => {
      const result = await harness.trigger('session_start');
      expect(result.activated).toBe(true);
      expect(result.events).toContain('ac.XX.start');
    });

    it('should respect suppression conditions', async () => {
      harness.setCondition('quick_mode', true);
      const result = await harness.trigger('session_start');
      expect(result.activated).toBe(false);
      expect(result.reason).toBe('suppressed');
    });
  });

  describe('Execution', () => {
    it('should complete successfully with valid inputs', async () => {
      const result = await harness.execute({
        input: { /* test input */ }
      });
      expect(result.status).toBe('success');
      expect(result.metrics.token_total).toBeLessThan(10000);
    });

    it('should handle missing dependency gracefully', async () => {
      harness.disableMock('memory');
      const result = await harness.execute();
      expect(result.status).toBe('degraded');
      expect(result.error.level).toBe('recoverable');
    });
  });

  describe('Output', () => {
    it('should emit correct events', async () => {
      await harness.execute();
      const events = harness.getEmittedEvents();
      expect(events).toMatchEventSequence([
        'ac.XX.start',
        'ac.XX.complete'
      ]);
    });

    it('should update state correctly', async () => {
      await harness.execute();
      const state = harness.getState();
      expect(state.status).toBe('complete');
      expect(state.history.total_runs).toBe(1);
    });
  });

  describe('Failure Modes', () => {
    it('should recover from timeout', async () => {
      harness.setCondition('slow_response', true);
      const result = await harness.execute({ timeout: 100 });
      expect(result.status).toBe('failure');
      expect(result.error.code).toBe('TIMEOUT');
      expect(result.recovery.action).toBe('retry');
    });

    it('should abort on fatal error', async () => {
      harness.injectError('fatal', 'CORRUPT_STATE');
      const result = await harness.execute();
      expect(result.status).toBe('aborted');
      expect(result.events).toContain('ac.XX.fail');
    });
  });

  describe('Metrics', () => {
    it('should emit all required metrics', async () => {
      await harness.execute();
      const metrics = harness.getMetrics();

      // Common metrics
      expect(metrics.common).toHaveProperty('execution_time');
      expect(metrics.common).toHaveProperty('token_total');
      expect(metrics.common).toHaveProperty('status');

      // Component-specific metrics
      expect(metrics.specific).toHaveProperty('component_specific_metric');
    });
  });
});
```

### 2.3 Running Isolation Tests

```bash
# Test single component
jarvis test AC-02

# Test with verbose output
jarvis test AC-02 --verbose

# Test specific scenario
jarvis test AC-02 --scenario "timeout_recovery"

# Test all components
jarvis test --all
```

---

## 3. Mock Patterns

### 3.1 MCP Mocks

Mock implementations for MCP dependencies:

```javascript
// .claude/test/mocks/mcps/memory.mock.js

class MockMemoryMCP {
  constructor() {
    this.entities = new Map();
    this.relations = new Map();
  }

  async create_entities(entities) {
    for (const entity of entities) {
      this.entities.set(entity.name, entity);
    }
    return { success: true, created: entities.length };
  }

  async search_nodes(query) {
    const results = [];
    for (const [name, entity] of this.entities) {
      if (name.includes(query) || entity.observations?.some(o => o.includes(query))) {
        results.push(entity);
      }
    }
    return results;
  }

  async read_graph() {
    return {
      entities: Array.from(this.entities.values()),
      relations: Array.from(this.relations.values())
    };
  }

  // Test helpers
  _reset() {
    this.entities.clear();
    this.relations.clear();
  }

  _seed(data) {
    for (const entity of data.entities || []) {
      this.entities.set(entity.name, entity);
    }
  }
}

module.exports = { MockMemoryMCP };
```

### 3.2 Component Mocks

Mock other autonomic components for integration tests:

```javascript
// .claude/test/mocks/components/AC-04-jicm.mock.js

class MockJICM {
  constructor(options = {}) {
    this.triggered = false;
    this.checkpointCreated = false;
    this.forceResult = options.forceResult || 'success';
  }

  async checkContextThreshold() {
    return { exceeded: false, current: 50000, threshold: 150000 };
  }

  async createCheckpoint(data) {
    this.checkpointCreated = true;
    return {
      success: this.forceResult === 'success',
      path: '.claude/test/sandbox/checkpoint.json'
    };
  }

  async triggerContinuation() {
    this.triggered = true;
    return { success: true };
  }

  // Test helpers
  _setForceResult(result) {
    this.forceResult = result;
  }

  _wasTriggered() {
    return this.triggered;
  }
}

module.exports = { MockJICM };
```

### 3.3 Event Mocks

Mock event emission and consumption:

```javascript
// .claude/test/mocks/event-bus.mock.js

class MockEventBus {
  constructor() {
    this.events = [];
    this.listeners = new Map();
  }

  emit(event, data) {
    const record = {
      timestamp: new Date().toISOString(),
      event,
      data
    };
    this.events.push(record);

    const callbacks = this.listeners.get(event) || [];
    callbacks.forEach(cb => cb(data));
  }

  on(event, callback) {
    if (!this.listeners.has(event)) {
      this.listeners.set(event, []);
    }
    this.listeners.get(event).push(callback);
  }

  // Test helpers
  getEvents(filter) {
    if (!filter) return this.events;
    return this.events.filter(e => e.event.includes(filter));
  }

  _reset() {
    this.events = [];
    this.listeners.clear();
  }
}

module.exports = { MockEventBus };
```

### 3.4 File System Mocks

Mock file operations:

```javascript
// .claude/test/mocks/filesystem.mock.js

class MockFileSystem {
  constructor() {
    this.files = new Map();
    this.writeLog = [];
  }

  read(path) {
    if (!this.files.has(path)) {
      throw new Error(`ENOENT: ${path}`);
    }
    return this.files.get(path);
  }

  write(path, content) {
    this.files.set(path, content);
    this.writeLog.push({ path, content, timestamp: Date.now() });
  }

  exists(path) {
    return this.files.has(path);
  }

  // Test helpers
  _seed(files) {
    for (const [path, content] of Object.entries(files)) {
      this.files.set(path, content);
    }
  }

  _getWrites() {
    return this.writeLog;
  }

  _reset() {
    this.files.clear();
    this.writeLog = [];
  }
}

module.exports = { MockFileSystem };
```

---

## 4. Integration Testing

### 4.1 Component Interaction Tests

Test how components work together:

```javascript
// .claude/test/integration/wiggum-jicm.test.js

describe('Wiggum Loop + JICM Integration', () => {
  let harness;

  beforeEach(async () => {
    harness = new IntegrationHarness(['AC-02', 'AC-04']);
  });

  it('should pause Wiggum when JICM triggers', async () => {
    // Start Wiggum Loop
    const wiggum = harness.getComponent('AC-02');
    wiggum.start({ iterations: 5 });

    // Simulate context threshold during iteration 2
    await harness.waitForEvent('ac.wiggum.start.pass2');
    harness.triggerComponent('AC-04', 'threshold_exceeded');

    // Verify Wiggum yielded
    const wiggumState = wiggum.getState();
    expect(wiggumState.status).toBe('paused');
    expect(wiggumState.current.iteration).toBe(2);

    // Verify JICM completed
    await harness.waitForEvent('ac.jicm.complete');

    // Verify Wiggum resumed
    expect(wiggum.getState().status).toBe('active');
  });
});
```

### 4.2 Event Flow Tests

Verify correct event sequences:

```javascript
// .claude/test/integration/event-flow.test.js

describe('Session Lifecycle Event Flow', () => {
  it('should follow correct event sequence', async () => {
    const harness = new IntegrationHarness(['AC-01', 'AC-02', 'AC-09']);

    // Simulate full session
    await harness.simulateSession({
      duration: 'short',
      tasks: ['single-task'],
      endTrigger: 'user-request'
    });

    const events = harness.getEventSequence();

    expect(events).toMatchSequence([
      'ac.launch.start',
      'ac.launch.complete',
      'ac.wiggum.start',
      'ac.wiggum.complete',
      'ac.session.start',
      'ac.session.complete'
    ]);
  });
});
```

---

## 5. Validation Harness Integration

### 5.1 Harness API

```javascript
// .claude/test/lib/validation-harness.js

class ValidationHarness {
  constructor(componentId) {
    this.componentId = componentId;
    this.metrics = [];
    this.validations = [];
  }

  async validate(scenario) {
    const result = await this.run(scenario);

    return {
      passed: this.checkAssertions(result, scenario.assertions),
      metrics: this.collectMetrics(result),
      coverage: this.calculateCoverage(scenario),
      details: result
    };
  }

  checkAssertions(result, assertions) {
    const failures = [];

    for (const assertion of assertions) {
      const actual = this.extractValue(result, assertion.path);
      const passed = this.compare(actual, assertion.expected, assertion.operator);

      if (!passed) {
        failures.push({
          assertion: assertion.name,
          expected: assertion.expected,
          actual,
          path: assertion.path
        });
      }
    }

    return failures.length === 0;
  }

  calculateCoverage(scenario) {
    // Calculate which code paths were exercised
    return {
      triggers: this.getTriggerCoverage(),
      branches: this.getBranchCoverage(),
      errorPaths: this.getErrorPathCoverage()
    };
  }
}

module.exports = { ValidationHarness };
```

### 5.2 Scenario Definitions

```yaml
# .claude/test/scenarios/AC-02-wiggum.yaml

scenarios:
  - name: "happy_path"
    description: "Normal execution with successful verification"
    setup:
      state: "clean"
      context_tokens: 50000
    trigger: "user_request"
    inputs:
      task: "fix typo in README"
    assertions:
      - name: "completes_successfully"
        path: "status"
        expected: "success"
        operator: "equals"
      - name: "within_token_budget"
        path: "metrics.token_total"
        expected: 20000
        operator: "less_than"
      - name: "reasonable_passes"
        path: "metrics.pass_count"
        expected: 3
        operator: "less_than_or_equal"

  - name: "timeout_recovery"
    description: "Recovery from slow verification"
    setup:
      state: "clean"
      inject:
        slow_response: true
    trigger: "user_request"
    assertions:
      - name: "retries_on_timeout"
        path: "metrics.retry_count"
        expected: 0
        operator: "greater_than"
      - name: "eventually_succeeds"
        path: "status"
        expected: "success"
        operator: "equals"

  - name: "suppression"
    description: "Skipped when user says 'quick'"
    setup:
      state: "clean"
      conditions:
        quick_mode: true
    trigger: "user_request"
    assertions:
      - name: "not_activated"
        path: "activated"
        expected: false
        operator: "equals"
      - name: "correct_reason"
        path: "skip_reason"
        expected: "quick_mode"
        operator: "equals"
```

---

## 6. Regression Testing

### 6.1 Baseline Metrics

Store baseline metrics for comparison:

```json
// .claude/test/baselines/AC-02-wiggum.baseline.json
{
  "component": "AC-02",
  "version": "1.0.0",
  "baseline_date": "2026-01-16",
  "scenarios": {
    "happy_path": {
      "avg_execution_time": 15000,
      "avg_token_total": 12000,
      "avg_pass_count": 2.3,
      "success_rate": 0.98
    },
    "timeout_recovery": {
      "avg_execution_time": 45000,
      "avg_token_total": 25000,
      "recovery_rate": 0.95
    }
  },
  "thresholds": {
    "execution_time_regression": 1.2,
    "token_regression": 1.3,
    "success_rate_regression": 0.95
  }
}
```

### 6.2 Regression Detection

```javascript
// .claude/test/lib/regression-detector.js

class RegressionDetector {
  constructor(baseline) {
    this.baseline = baseline;
  }

  detect(current) {
    const regressions = [];

    for (const [scenario, metrics] of Object.entries(current.scenarios)) {
      const baselineMetrics = this.baseline.scenarios[scenario];
      if (!baselineMetrics) continue;

      // Check execution time
      const timeRatio = metrics.avg_execution_time / baselineMetrics.avg_execution_time;
      if (timeRatio > this.baseline.thresholds.execution_time_regression) {
        regressions.push({
          scenario,
          metric: 'execution_time',
          baseline: baselineMetrics.avg_execution_time,
          current: metrics.avg_execution_time,
          ratio: timeRatio,
          severity: this.calculateSeverity(timeRatio, 'time')
        });
      }

      // Check token usage
      const tokenRatio = metrics.avg_token_total / baselineMetrics.avg_token_total;
      if (tokenRatio > this.baseline.thresholds.token_regression) {
        regressions.push({
          scenario,
          metric: 'token_total',
          baseline: baselineMetrics.avg_token_total,
          current: metrics.avg_token_total,
          ratio: tokenRatio,
          severity: this.calculateSeverity(tokenRatio, 'token')
        });
      }

      // Check success rate
      if (metrics.success_rate < this.baseline.thresholds.success_rate_regression) {
        regressions.push({
          scenario,
          metric: 'success_rate',
          baseline: baselineMetrics.success_rate,
          current: metrics.success_rate,
          severity: 'critical'
        });
      }
    }

    return regressions;
  }

  calculateSeverity(ratio, type) {
    if (ratio > 2.0) return 'critical';
    if (ratio > 1.5) return 'major';
    return 'minor';
  }
}

module.exports = { RegressionDetector };
```

### 6.3 Running Regression Tests

```bash
# Run regression suite
jarvis test --regression

# Run against specific baseline
jarvis test --regression --baseline v1.0.0

# Update baseline after approved changes
jarvis test --update-baseline

# Report format
jarvis test --regression --report markdown
```

### 6.4 Regression Report

```markdown
# Regression Test Report
**Date**: 2026-01-16
**Component**: AC-02 Wiggum Loop
**Baseline**: v1.0.0 (2026-01-10)

## Summary
- **Scenarios Tested**: 5
- **Regressions Found**: 1
- **Overall Status**: ⚠️ WARNING

## Regressions

### 1. Token Usage Regression (Minor)
- **Scenario**: happy_path
- **Metric**: token_total
- **Baseline**: 12,000 tokens
- **Current**: 15,600 tokens
- **Change**: +30%
- **Severity**: Minor

**Possible Causes**:
- New verification logic added
- Context files grew in size

**Recommendation**: Review if increase is justified

## Passed Scenarios
- timeout_recovery ✅
- suppression ✅
- error_recovery ✅
- multi_pass ✅
```

---

## 7. Test Coverage Requirements

### 7.1 Minimum Coverage

| Category | Required Coverage |
|----------|-------------------|
| Trigger paths | 100% |
| Happy path | 100% |
| Error handling | 80% |
| Edge cases | 70% |
| Integration points | 80% |

### 7.2 Coverage Report

```bash
# Generate coverage report
jarvis test --coverage

# Output
Coverage Report for AC-02:
  Triggers:     4/4   (100%) ✅
  Happy Path:   3/3   (100%) ✅
  Errors:       7/9   (78%)  ⚠️
  Edge Cases:   5/8   (63%)  ❌
  Integration:  6/7   (86%)  ✅

Overall: 82% (Target: 80%) ✅
```

---

## 8. File Structure

```
.claude/test/
├── harnesses/           # Component test harnesses
│   └── AC-XX.test.js
├── integration/         # Integration tests
│   └── component-pairs.test.js
├── fixtures/            # Test data
│   ├── context/
│   ├── state/
│   └── events/
├── mocks/               # Mock implementations
│   ├── mcps/
│   └── components/
├── scenarios/           # Test scenarios (YAML)
│   └── AC-XX.yaml
├── baselines/           # Regression baselines
│   └── AC-XX.baseline.json
├── sandbox/             # Isolated test environment
├── reports/             # Test reports
│   └── YYYY-MM-DD/
└── lib/                 # Test utilities
    ├── test-harness.js
    ├── validation-harness.js
    └── regression-detector.js
```

---

## 9. Implementation Checklist

### Test Infrastructure

- [ ] Create test harness base class
- [ ] Implement mock system for MCPs
- [ ] Implement mock system for components
- [ ] Set up sandbox environment
- [ ] Create test runner CLI

### Per-Component

- [ ] Create test harness for each AC-XX
- [ ] Define test scenarios (YAML)
- [ ] Write unit tests
- [ ] Write integration tests
- [ ] Establish regression baseline

### CI Integration

- [ ] Add test command to pre-commit hook
- [ ] Add regression check to PR workflow
- [ ] Generate coverage reports
- [ ] Archive test results

---

*Autonomic Testing Framework — Jarvis Phase 6 PR-11.6*
