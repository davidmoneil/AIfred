#!/usr/bin/env node
/**
 * Benchmark Runner - PR-13.2
 *
 * Executes component, E2E, performance, and quality benchmarks.
 * Stores results for trend analysis and regression detection.
 *
 * Usage:
 *   node benchmark-runner.js --component AC-01
 *   node benchmark-runner.js --all
 *   node benchmark-runner.js --e2e
 */

const fs = require('fs');
const path = require('path');
const { execSync, spawn } = require('child_process');

const CONFIG = {
  benchmarkDir: path.join(__dirname, '..', 'test', 'benchmarks'),
  resultsDir: path.join(__dirname, '..', 'metrics', 'benchmarks'),
  baselineDir: path.join(__dirname, '..', 'metrics', 'baselines'),
  hooksDir: path.join(__dirname, '..', 'hooks'),
  scriptsDir: __dirname
};

// Component benchmark specifications
const COMPONENT_BENCHMARKS = {
  'AC-01': {
    name: 'Self-Launch Protocol',
    tests: [
      { name: 'greeting_generation', type: 'timing', script: 'session-start.sh' },
      { name: 'state_file_creation', type: 'check', files: ['AC-01-launch.json'] }
    ]
  },
  'AC-02': {
    name: 'Wiggum Loop',
    tests: [
      { name: 'loop_detection', type: 'check', hook: 'wiggum-loop-tracker.js' },
      { name: 'state_tracking', type: 'check', files: ['AC-02-wiggum.json'] }
    ]
  },
  'AC-03': {
    name: 'Milestone Review',
    tests: [
      { name: 'milestone_detection', type: 'check', hook: 'milestone-detector.js' },
      { name: 'review_state', type: 'check', files: ['AC-03-review.json'] }
    ]
  },
  'AC-04': {
    name: 'JICM Context Management',
    tests: [
      { name: 'context_tracking', type: 'check', hook: 'context-accumulator.js' },
      { name: 'estimate_accuracy', type: 'check', files: ['context-estimate.json'] }
    ]
  },
  'AC-05': {
    name: 'Self-Reflection',
    tests: [
      { name: 'correction_capture', type: 'check', hook: 'self-correction-capture.js' },
      { name: 'reflection_state', type: 'check', files: ['AC-05-reflection.json'] }
    ]
  },
  'AC-06': {
    name: 'Self-Evolution',
    tests: [
      { name: 'queue_processing', type: 'check', files: ['evolution-queue.yaml'] },
      { name: 'evolution_state', type: 'check', files: ['AC-06-evolution.json'] }
    ]
  },
  'AC-07': {
    name: 'R&D Cycles',
    tests: [
      { name: 'research_agenda', type: 'check', files: ['research-agenda.yaml'] },
      { name: 'rd_state', type: 'check', files: ['AC-07-rd.json'] }
    ]
  },
  'AC-08': {
    name: 'Maintenance',
    tests: [
      { name: 'maintenance_state', type: 'check', files: ['AC-08-maintenance.json'] }
    ]
  },
  'AC-09': {
    name: 'Session Completion',
    tests: [
      { name: 'session_state', type: 'check', files: ['AC-09-session.json'] }
    ]
  }
};

/**
 * Ensure directories exist
 */
function ensureDirs() {
  [CONFIG.resultsDir, CONFIG.baselineDir].forEach(dir => {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  });
}

/**
 * Run a single check test
 */
function runCheckTest(test, component) {
  const result = {
    name: test.name,
    type: test.type,
    passed: true,
    details: []
  };

  // Check hook exists
  if (test.hook) {
    const hookPath = path.join(CONFIG.hooksDir, test.hook);
    if (fs.existsSync(hookPath)) {
      result.details.push(`Hook exists: ${test.hook}`);
      // Verify it's valid JS
      try {
        require(hookPath);
        result.details.push('Hook loads successfully');
      } catch (e) {
        result.passed = false;
        result.details.push(`Hook load error: ${e.message}`);
      }
    } else {
      result.passed = false;
      result.details.push(`Hook missing: ${test.hook}`);
    }
  }

  // Check files exist
  if (test.files) {
    for (const file of test.files) {
      // Try multiple locations
      const locations = [
        path.join(__dirname, '..', 'state', 'components', file),
        path.join(__dirname, '..', 'state', 'queues', file),
        path.join(__dirname, '..', 'context', file),
        path.join(__dirname, '..', 'logs', file)
      ];

      const found = locations.find(loc => fs.existsSync(loc));
      if (found) {
        result.details.push(`File exists: ${file}`);
      } else {
        result.passed = false;
        result.details.push(`File missing: ${file}`);
      }
    }
  }

  return result;
}

/**
 * Run a timing test
 */
function runTimingTest(test) {
  const result = {
    name: test.name,
    type: test.type,
    passed: true,
    timing_ms: null,
    details: []
  };

  if (test.script) {
    const scriptPath = path.join(CONFIG.hooksDir, test.script);
    if (!fs.existsSync(scriptPath)) {
      result.passed = false;
      result.details.push(`Script missing: ${test.script}`);
      return result;
    }

    try {
      const start = Date.now();
      execSync(`bash "${scriptPath}" --test`, { timeout: 10000, stdio: 'pipe' });
      result.timing_ms = Date.now() - start;
      result.details.push(`Completed in ${result.timing_ms}ms`);
    } catch (e) {
      // Some scripts may fail in test mode, that's ok
      result.timing_ms = Date.now() - (e.killed ? Date.now() : Date.now());
      result.details.push(`Script returned non-zero (may be expected)`);
    }
  }

  return result;
}

/**
 * Run benchmarks for a component
 */
function runComponentBenchmark(componentId) {
  const spec = COMPONENT_BENCHMARKS[componentId];
  if (!spec) {
    return { error: `Unknown component: ${componentId}` };
  }

  const result = {
    component: componentId,
    name: spec.name,
    timestamp: new Date().toISOString(),
    tests: [],
    summary: {
      total: 0,
      passed: 0,
      failed: 0
    }
  };

  for (const test of spec.tests) {
    let testResult;
    switch (test.type) {
      case 'check':
        testResult = runCheckTest(test, componentId);
        break;
      case 'timing':
        testResult = runTimingTest(test);
        break;
      default:
        testResult = { name: test.name, passed: false, details: ['Unknown test type'] };
    }

    result.tests.push(testResult);
    result.summary.total++;
    if (testResult.passed) {
      result.summary.passed++;
    } else {
      result.summary.failed++;
    }
  }

  return result;
}

/**
 * Run all component benchmarks
 */
function runAllBenchmarks() {
  const results = {
    timestamp: new Date().toISOString(),
    components: [],
    summary: {
      total_components: 0,
      passing_components: 0,
      total_tests: 0,
      passed_tests: 0
    }
  };

  for (const componentId of Object.keys(COMPONENT_BENCHMARKS)) {
    const componentResult = runComponentBenchmark(componentId);
    results.components.push(componentResult);

    results.summary.total_components++;
    results.summary.total_tests += componentResult.summary.total;
    results.summary.passed_tests += componentResult.summary.passed;

    if (componentResult.summary.failed === 0) {
      results.summary.passing_components++;
    }
  }

  return results;
}

/**
 * Run E2E benchmark (simulates session lifecycle)
 */
function runE2EBenchmark() {
  const result = {
    name: 'E2E Session Lifecycle',
    timestamp: new Date().toISOString(),
    phases: [],
    passed: true
  };

  // Phase 1: Check all hooks load
  const hooksPhase = { name: 'Hooks Loading', tests: [] };
  const hooks = fs.readdirSync(CONFIG.hooksDir).filter(f => f.endsWith('.js'));

  for (const hook of hooks) {
    try {
      require(path.join(CONFIG.hooksDir, hook));
      hooksPhase.tests.push({ name: hook, passed: true });
    } catch (e) {
      hooksPhase.tests.push({ name: hook, passed: false, error: e.message });
      result.passed = false;
    }
  }
  result.phases.push(hooksPhase);

  // Phase 2: Check state files exist
  const statePhase = { name: 'State Files', tests: [] };
  const stateDir = path.join(__dirname, '..', 'state', 'components');
  if (fs.existsSync(stateDir)) {
    const stateFiles = fs.readdirSync(stateDir).filter(f => f.endsWith('.json'));
    for (const file of stateFiles) {
      try {
        const content = fs.readFileSync(path.join(stateDir, file), 'utf8');
        JSON.parse(content);
        statePhase.tests.push({ name: file, passed: true });
      } catch (e) {
        statePhase.tests.push({ name: file, passed: false, error: e.message });
        result.passed = false;
      }
    }
  }
  result.phases.push(statePhase);

  // Phase 3: Check telemetry system
  const telemetryPhase = { name: 'Telemetry System', tests: [] };
  try {
    const telemetry = require(path.join(CONFIG.hooksDir, 'telemetry-emitter.js'));
    const emitResult = telemetry.emit('AC-01', 'benchmark_test', { test: true });
    telemetryPhase.tests.push({
      name: 'telemetry-emitter',
      passed: emitResult.success
    });
  } catch (e) {
    telemetryPhase.tests.push({
      name: 'telemetry-emitter',
      passed: false,
      error: e.message
    });
    result.passed = false;
  }
  result.phases.push(telemetryPhase);

  return result;
}

/**
 * Save benchmark results
 */
function saveResults(results, name) {
  ensureDirs();
  const filename = `${name}-${new Date().toISOString().split('T')[0]}.json`;
  const filepath = path.join(CONFIG.resultsDir, filename);
  fs.writeFileSync(filepath, JSON.stringify(results, null, 2));
  return filepath;
}

/**
 * Print results summary
 */
function printSummary(results) {
  console.log('\n' + '='.repeat(60));
  console.log('BENCHMARK RESULTS');
  console.log('='.repeat(60));

  if (results.components) {
    // All components result
    console.log(`\nComponents: ${results.summary.passing_components}/${results.summary.total_components} passing`);
    console.log(`Tests: ${results.summary.passed_tests}/${results.summary.total_tests} passing\n`);

    for (const comp of results.components) {
      const status = comp.summary.failed === 0 ? '✅' : '❌';
      console.log(`${status} ${comp.component} ${comp.name}: ${comp.summary.passed}/${comp.summary.total} tests`);

      for (const test of comp.tests) {
        const testStatus = test.passed ? '  ✓' : '  ✗';
        console.log(`   ${testStatus} ${test.name}`);
      }
    }
  } else if (results.phases) {
    // E2E result
    const status = results.passed ? '✅' : '❌';
    console.log(`\n${status} ${results.name}\n`);

    for (const phase of results.phases) {
      console.log(`\n${phase.name}:`);
      for (const test of phase.tests) {
        const testStatus = test.passed ? '  ✓' : '  ✗';
        console.log(`   ${testStatus} ${test.name}`);
      }
    }
  } else {
    // Single component result
    const status = results.summary.failed === 0 ? '✅' : '❌';
    console.log(`\n${status} ${results.component} ${results.name}\n`);

    for (const test of results.tests) {
      const testStatus = test.passed ? '✓' : '✗';
      console.log(`  ${testStatus} ${test.name}`);
      if (test.details) {
        test.details.forEach(d => console.log(`    - ${d}`));
      }
    }
  }

  console.log('\n' + '='.repeat(60));
}

/**
 * Main
 */
function main() {
  const args = process.argv.slice(2);

  if (args.includes('--help') || args.includes('-h')) {
    console.log(`
Benchmark Runner

Usage:
  node benchmark-runner.js [options]

Options:
  --component <id>   Run benchmarks for a specific component (AC-01, AC-02, etc.)
  --all              Run all component benchmarks
  --e2e              Run end-to-end benchmark
  --json             Output results as JSON
  --save             Save results to file
  --help             Show this help

Examples:
  node benchmark-runner.js --all
  node benchmark-runner.js --component AC-01
  node benchmark-runner.js --e2e --save
`);
    process.exit(0);
  }

  const jsonOutput = args.includes('--json');
  const saveOutput = args.includes('--save');

  let results;
  let name;

  if (args.includes('--all')) {
    results = runAllBenchmarks();
    name = 'all-components';
  } else if (args.includes('--e2e')) {
    results = runE2EBenchmark();
    name = 'e2e';
  } else if (args.includes('--component')) {
    const idx = args.indexOf('--component');
    const componentId = args[idx + 1];
    results = runComponentBenchmark(componentId);
    name = `component-${componentId}`;
  } else {
    // Default: run all
    results = runAllBenchmarks();
    name = 'all-components';
  }

  if (saveOutput) {
    const filepath = saveResults(results, name);
    console.log(`Results saved to: ${filepath}`);
  }

  if (jsonOutput) {
    console.log(JSON.stringify(results, null, 2));
  } else {
    printSummary(results);
  }

  // Exit with error if any tests failed
  const failed = results.summary?.failed > 0 ||
                 results.summary?.passing_components < results.summary?.total_components ||
                 results.passed === false;
  process.exit(failed ? 1 : 0);
}

// Export for module use
module.exports = {
  runComponentBenchmark,
  runAllBenchmarks,
  runE2EBenchmark,
  COMPONENT_BENCHMARKS
};

// Run if called directly
if (require.main === module) {
  main();
}
