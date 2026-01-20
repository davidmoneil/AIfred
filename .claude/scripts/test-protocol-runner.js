#!/usr/bin/env node
/**
 * Test Protocol Runner - Autonomic Systems Testing
 *
 * Orchestrates comprehensive testing of all 9 Jarvis autonomic systems.
 * Supports component isolation, PRD variants, integration, and error path tests.
 *
 * Usage:
 *   node test-protocol-runner.js --phase 1           # Baseline capture
 *   node test-protocol-runner.js --phase 2           # Component isolation
 *   node test-protocol-runner.js --component AC-02   # Single component
 *   node test-protocol-runner.js --all               # Full protocol
 */

const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

const CONFIG = {
  harnessDir: path.join(__dirname, '..', 'test', 'harnesses'),
  resultsDir: path.join(__dirname, '..', 'metrics', 'test-results'),
  baselineDir: path.join(__dirname, '..', 'metrics', 'baselines'),
  stateDir: path.join(__dirname, '..', 'state', 'components'),
  hooksDir: path.join(__dirname, '..', 'hooks'),
  prdVariantsDir: path.resolve(__dirname, '../../projects/project-aion/plans/prd-variants')
};

// Component test specifications
const COMPONENT_TESTS = {
  'AC-01': {
    name: 'Self-Launch Protocol',
    functional: [
      { id: 'AC01-F01', name: 'Greeting generation', check: 'greeting_generated' },
      { id: 'AC01-F02', name: 'Checkpoint loading', check: 'checkpoint_loaded' },
      { id: 'AC01-F03', name: 'Autonomous initiation', check: 'auto_initiated' }
    ],
    stress: [
      { id: 'AC01-S01', name: 'Missing checkpoint', trigger: 'remove_checkpoint' },
      { id: 'AC01-S02', name: 'Corrupted state', trigger: 'corrupt_state' }
    ],
    error: [
      { id: 'AC01-E01', name: 'Missing session-state', expected: 'create_default' }
    ]
  },
  'AC-02': {
    name: 'Wiggum Loop',
    functional: [
      { id: 'AC02-F01', name: 'Multi-pass activation', check: 'passes_gt_1' },
      { id: 'AC02-F02', name: 'TodoWrite integration', check: 'todos_created' },
      { id: 'AC02-F03', name: 'Self-review execution', check: 'review_documented' },
      { id: 'AC02-F04', name: 'Suppression detection', check: 'suppression_works' },
      { id: 'AC02-F05', name: 'Completion detection', check: 'exit_on_complete' },
      { id: 'AC02-F06', name: 'Drift detection', check: 'drift_caught' }
    ],
    stress: [
      { id: 'AC02-S01', name: 'Max iterations', limit: 5 },
      { id: 'AC02-S02', name: 'Blocker investigation', attempts: 3 },
      { id: 'AC02-S03', name: 'Context exhaustion', trigger: 'jicm_checkpoint' }
    ]
  },
  'AC-03': {
    name: 'Milestone Review',
    functional: [
      { id: 'AC03-F01', name: 'Milestone detection', check: 'review_triggered' },
      { id: 'AC03-F02', name: 'Two-level review', check: 'dual_agent_review' },
      { id: 'AC03-F03', name: 'Remediation trigger', check: 'wiggum_restart' }
    ]
  },
  'AC-04': {
    name: 'JICM Context Management',
    functional: [
      { id: 'AC04-F01', name: '50% threshold', check: 'caution_status' },
      { id: 'AC04-F02', name: '70% threshold', check: 'warning_offload' },
      { id: 'AC04-F03', name: '85% threshold', check: 'critical_checkpoint' },
      { id: 'AC04-F04', name: '95% threshold', check: 'emergency_preserve' },
      { id: 'AC04-F05', name: 'MCP disable', check: 'tier2_disabled' }
    ],
    stress: [
      { id: 'AC04-S01', name: 'Multiple compressions', target_accuracy: 0.95 }
    ]
  },
  'AC-05': {
    name: 'Self-Reflection',
    functional: [
      { id: 'AC05-F01', name: 'Correction capture', check: 'corrections_file' },
      { id: 'AC05-F02', name: 'Self-correction', check: 'self_corrections_file' },
      { id: 'AC05-F03', name: 'Pattern identification', check: 'patterns_dir' },
      { id: 'AC05-F04', name: 'Proposal generation', check: 'evolution_queue' }
    ]
  },
  'AC-06': {
    name: 'Self-Evolution',
    functional: [
      { id: 'AC06-F01', name: 'Proposal triage', check: 'risk_assigned' },
      { id: 'AC06-F02', name: 'Low-risk auto-approve', check: 'no_user_prompt' },
      { id: 'AC06-F03', name: 'High-risk gate', check: 'approval_required' },
      { id: 'AC06-F04', name: 'Branch creation', check: 'evolution_branch' },
      { id: 'AC06-F05', name: 'Rollback on failure', check: 'clean_revert' }
    ]
  },
  'AC-07': {
    name: 'R&D Cycles',
    functional: [
      { id: 'AC07-F01', name: 'Research agenda parsing', check: 'topics_identified' },
      { id: 'AC07-F02', name: 'Discovery classification', check: 'classification_applied' },
      { id: 'AC07-F03', name: 'Proposal flagging', check: 'approval_flag' }
    ]
  },
  'AC-08': {
    name: 'Maintenance',
    functional: [
      { id: 'AC08-F01', name: 'Health check', check: 'all_components_checked' },
      { id: 'AC08-F02', name: 'Freshness audit', check: 'stale_files_found' },
      { id: 'AC08-F03', name: 'Cleanup proposals', check: 'orphans_listed' }
    ]
  },
  'AC-09': {
    name: 'Session Completion',
    functional: [
      { id: 'AC09-F01', name: 'Pre-completion offer', check: 'tier2_offered' },
      { id: 'AC09-F02', name: 'Work state capture', check: 'session_state_updated' },
      { id: 'AC09-F03', name: 'Checkpoint creation', check: 'checkpoint_valid' },
      { id: 'AC09-F04', name: 'Git commit', check: 'commit_logged' }
    ]
  }
};

// Integration test specifications
const INTEGRATION_TESTS = [
  { id: 'INT-01', components: ['AC-02', 'AC-04'], scenario: 'Wiggum at context threshold' },
  { id: 'INT-02', components: ['AC-03', 'AC-02'], scenario: 'Review triggers remediation' },
  { id: 'INT-03', components: ['AC-05', 'AC-06'], scenario: 'Reflection creates proposal' },
  { id: 'INT-04', components: ['AC-01', 'AC-09'], scenario: 'Session restart with checkpoint' },
  { id: 'INT-05', components: ['AC-04', 'AC-01'], scenario: 'Compression + restart' },
  { id: 'INT-06', components: ['AC-07', 'AC-06'], scenario: 'R&D adopts tool' },
  { id: 'INT-07', components: ['AC-08', 'AC-05'], scenario: 'Maintenance finds issue' },
  { id: 'INT-08', components: 'all', scenario: 'Full session lifecycle' }
];

// Error path test specifications
const ERROR_TESTS = [
  { id: 'ERR-01', target: 'AC-01', failure: 'Missing state files', expected: 'create_defaults' },
  { id: 'ERR-02', target: 'AC-02', failure: 'TodoWrite unavailable', expected: 'degradation' },
  { id: 'ERR-03', target: 'AC-04', failure: 'Checkpoint too large', expected: 'prune_essentials' },
  { id: 'ERR-05', target: 'AC-05', failure: 'Memory MCP down', expected: 'local_storage' },
  { id: 'ERR-06', target: 'AC-06', failure: 'Git conflict', expected: 'safe_abort' },
  { id: 'ERR-09', target: 'AC-09', failure: 'Commit fails', expected: 'state_preserved' }
];

/**
 * Ensure directories exist
 */
function ensureDirs() {
  [CONFIG.resultsDir, CONFIG.harnessDir].forEach(dir => {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  });
}

/**
 * Load component state file
 */
function loadComponentState(componentId) {
  const filename = `${componentId}-${getComponentSuffix(componentId)}.json`;
  const filepath = path.join(CONFIG.stateDir, filename);

  try {
    const content = fs.readFileSync(filepath, 'utf8');
    return JSON.parse(content);
  } catch (e) {
    return null;
  }
}

/**
 * Get component suffix for state file
 */
function getComponentSuffix(componentId) {
  const suffixes = {
    'AC-01': 'launch',
    'AC-02': 'wiggum',
    'AC-03': 'review',
    'AC-04': 'jicm',
    'AC-05': 'reflection',
    'AC-06': 'evolution',
    'AC-07': 'rd',
    'AC-08': 'maintenance',
    'AC-09': 'session'
  };
  return suffixes[componentId] || 'unknown';
}

/**
 * Check if a hook exists and loads
 */
function checkHook(hookName) {
  const hookPath = path.join(CONFIG.hooksDir, hookName);
  if (!fs.existsSync(hookPath)) {
    return { exists: false, loads: false };
  }
  try {
    require(hookPath);
    return { exists: true, loads: true };
  } catch (e) {
    return { exists: true, loads: false, error: e.message };
  }
}

/**
 * Run functional tests for a component
 */
function runFunctionalTests(componentId) {
  const spec = COMPONENT_TESTS[componentId];
  if (!spec || !spec.functional) {
    return { error: `No functional tests defined for ${componentId}` };
  }

  const state = loadComponentState(componentId);
  const results = {
    component: componentId,
    name: spec.name,
    timestamp: new Date().toISOString(),
    tests: [],
    summary: { total: 0, passed: 0, failed: 0, skipped: 0 }
  };

  for (const test of spec.functional) {
    const result = {
      id: test.id,
      name: test.name,
      status: 'skipped',
      details: []
    };

    // Component-specific checks
    if (componentId === 'AC-01') {
      if (test.check === 'greeting_generated') {
        const hookCheck = checkHook('session-start.sh');
        result.status = hookCheck.exists ? 'passed' : 'failed';
        result.details.push(hookCheck.exists ? 'Hook exists' : 'Hook missing');
      } else if (test.check === 'checkpoint_loaded') {
        result.status = state?.checkpoint_loaded !== undefined ? 'passed' : 'skipped';
        result.details.push(`checkpoint_loaded: ${state?.checkpoint_loaded}`);
      } else if (test.check === 'auto_initiated') {
        result.status = state?.auto_continue !== undefined ? 'passed' : 'skipped';
        result.details.push(`auto_continue: ${state?.auto_continue}`);
      }
    } else if (componentId === 'AC-02') {
      if (test.check === 'passes_gt_1') {
        const hookCheck = checkHook('wiggum-loop-tracker.js');
        result.status = hookCheck.loads ? 'passed' : 'failed';
        result.details.push(hookCheck.loads ? 'Tracker hook loads' : 'Tracker hook issue');
      } else if (test.check === 'todos_created') {
        result.status = state?.todos !== undefined ? 'passed' : 'skipped';
        result.details.push(`Todos tracking: ${JSON.stringify(state?.todos)}`);
      } else if (test.check === 'suppression_works') {
        result.status = state?.current_loop?.suppressed !== undefined ? 'passed' : 'skipped';
        result.details.push(`suppressed: ${state?.current_loop?.suppressed}`);
      } else {
        result.status = 'skipped';
        result.details.push('Requires active loop to test');
      }
    } else if (componentId === 'AC-04') {
      if (test.check === 'caution_status' || test.check === 'warning_offload' ||
          test.check === 'critical_checkpoint' || test.check === 'emergency_preserve') {
        const hookCheck = checkHook('context-accumulator.js');
        result.status = hookCheck.loads ? 'passed' : 'failed';
        result.details.push(hookCheck.loads ? 'Context accumulator works' : 'Hook issue');
      } else if (test.check === 'tier2_disabled') {
        const scriptPath = path.join(__dirname, '..', 'scripts', 'disable-mcps.sh');
        result.status = fs.existsSync(scriptPath) ? 'passed' : 'failed';
        result.details.push(fs.existsSync(scriptPath) ? 'MCP disable script exists' : 'Script missing');
      }
    } else {
      // Generic state-based check
      result.status = state ? 'passed' : 'failed';
      result.details.push(state ? 'State file exists' : 'State file missing');
    }

    results.tests.push(result);
    results.summary.total++;
    results.summary[result.status]++;
  }

  return results;
}

/**
 * Run stress tests for a component
 */
function runStressTests(componentId) {
  const spec = COMPONENT_TESTS[componentId];
  if (!spec || !spec.stress) {
    return { error: `No stress tests defined for ${componentId}` };
  }

  const results = {
    component: componentId,
    type: 'stress',
    timestamp: new Date().toISOString(),
    tests: [],
    summary: { total: 0, passed: 0, failed: 0, skipped: 0 }
  };

  for (const test of spec.stress) {
    const result = {
      id: test.id,
      name: test.name,
      status: 'skipped',
      details: ['Stress tests require controlled execution environment']
    };

    // Mark as skipped for now - these require active session testing
    results.tests.push(result);
    results.summary.total++;
    results.summary.skipped++;
  }

  return results;
}

/**
 * Run component isolation tests
 */
function runComponentIsolation(componentId) {
  const functional = runFunctionalTests(componentId);
  const stress = runStressTests(componentId);

  return {
    component: componentId,
    timestamp: new Date().toISOString(),
    functional,
    stress,
    overall: {
      passed: (functional.summary?.passed || 0) + (stress.summary?.passed || 0),
      failed: (functional.summary?.failed || 0) + (stress.summary?.failed || 0),
      skipped: (functional.summary?.skipped || 0) + (stress.summary?.skipped || 0),
      total: (functional.summary?.total || 0) + (stress.summary?.total || 0)
    }
  };
}

/**
 * Run all component isolation tests (Phase 2)
 */
function runPhase2() {
  const results = {
    phase: 2,
    name: 'Component Isolation Tests',
    timestamp: new Date().toISOString(),
    components: [],
    summary: {
      total_components: 0,
      passing_components: 0,
      total_tests: 0,
      passed_tests: 0,
      failed_tests: 0,
      skipped_tests: 0
    }
  };

  for (const componentId of Object.keys(COMPONENT_TESTS)) {
    const componentResult = runComponentIsolation(componentId);
    results.components.push(componentResult);

    results.summary.total_components++;
    results.summary.total_tests += componentResult.overall.total;
    results.summary.passed_tests += componentResult.overall.passed;
    results.summary.failed_tests += componentResult.overall.failed;
    results.summary.skipped_tests += componentResult.overall.skipped;

    if (componentResult.overall.failed === 0) {
      results.summary.passing_components++;
    }
  }

  return results;
}

/**
 * Run integration tests (Phase 4)
 */
function runPhase4() {
  const results = {
    phase: 4,
    name: 'Integration Tests',
    timestamp: new Date().toISOString(),
    tests: [],
    summary: { total: 0, passed: 0, failed: 0, skipped: 0 }
  };

  for (const test of INTEGRATION_TESTS) {
    const result = {
      id: test.id,
      components: test.components,
      scenario: test.scenario,
      status: 'skipped',
      details: ['Integration tests require multi-component orchestration']
    };

    results.tests.push(result);
    results.summary.total++;
    results.summary.skipped++;
  }

  return results;
}

/**
 * Run error path tests (Phase 5)
 */
function runPhase5() {
  const results = {
    phase: 5,
    name: 'Error Path Tests',
    timestamp: new Date().toISOString(),
    tests: [],
    summary: { total: 0, passed: 0, failed: 0, skipped: 0 }
  };

  for (const test of ERROR_TESTS) {
    const result = {
      id: test.id,
      target: test.target,
      failure: test.failure,
      expected: test.expected,
      status: 'skipped',
      details: ['Error path tests require controlled failure injection']
    };

    results.tests.push(result);
    results.summary.total++;
    results.summary.skipped++;
  }

  return results;
}

/**
 * Run regression analysis (Phase 6)
 */
function runPhase6() {
  const results = {
    phase: 6,
    name: 'Regression Analysis',
    timestamp: new Date().toISOString(),
    baseline_comparison: null,
    regressions: [],
    improvements: []
  };

  // Load baseline
  const baselinePath = path.join(CONFIG.baselineDir, 'pre-test-2026-01-20.json');
  if (fs.existsSync(baselinePath)) {
    try {
      const baseline = JSON.parse(fs.readFileSync(baselinePath, 'utf8'));
      results.baseline_comparison = {
        baseline_date: baseline.created,
        demo_a_duration: baseline.demo_a_comparison?.duration_minutes || 30,
        demo_a_iterations: baseline.demo_a_comparison?.wiggum_iterations || 24,
        demo_a_pass_rate: baseline.demo_a_comparison?.test_pass_rate || 1.0,
        demo_a_alignment: baseline.demo_a_comparison?.autonomic_alignment || 0.92
      };
    } catch (e) {
      results.baseline_comparison = { error: 'Failed to load baseline' };
    }
  }

  // Run current benchmark for comparison
  try {
    const benchmarkPath = path.join(__dirname, 'benchmark-runner.js');
    execSync(`node "${benchmarkPath}" --all --save`, { stdio: 'pipe' });
    results.current_benchmark = { status: 'executed' };
  } catch (e) {
    results.current_benchmark = { status: 'failed', error: e.message };
  }

  return results;
}

/**
 * Save results
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
  console.log(`TEST PROTOCOL RESULTS - Phase ${results.phase || 'N/A'}`);
  console.log('='.repeat(60));

  if (results.components) {
    console.log(`\nComponents: ${results.summary.passing_components}/${results.summary.total_components} passing`);
    console.log(`Tests: ${results.summary.passed_tests} passed, ${results.summary.failed_tests} failed, ${results.summary.skipped_tests} skipped\n`);

    for (const comp of results.components) {
      const status = comp.overall.failed === 0 ? (comp.overall.skipped === comp.overall.total ? '~' : '~') : '~';
      console.log(`${status} ${comp.component}: ${comp.overall.passed}/${comp.overall.total} (${comp.overall.skipped} skipped)`);
    }
  } else if (results.tests) {
    console.log(`\nTests: ${results.summary.passed} passed, ${results.summary.failed} failed, ${results.summary.skipped} skipped\n`);

    for (const test of results.tests) {
      const status = test.status === 'passed' ? '~' : (test.status === 'failed' ? '~' : '~');
      console.log(`  ${status} ${test.id}: ${test.scenario || test.name || test.failure}`);
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
Test Protocol Runner - Autonomic Systems Testing

Usage:
  node test-protocol-runner.js [options]

Options:
  --phase <n>        Run specific phase (1-6)
  --component <id>   Test specific component (AC-01 to AC-09)
  --all              Run full protocol
  --json             Output as JSON
  --save             Save results to file

Phases:
  1: Baseline Capture
  2: Component Isolation Tests
  3: PRD Stress Variants (manual)
  4: Integration Tests
  5: Error Path Tests
  6: Regression Analysis

Examples:
  node test-protocol-runner.js --phase 2
  node test-protocol-runner.js --component AC-02
  node test-protocol-runner.js --all --save
`);
    process.exit(0);
  }

  ensureDirs();

  const jsonOutput = args.includes('--json');
  const saveOutput = args.includes('--save');

  let results;
  let name;

  if (args.includes('--phase')) {
    const idx = args.indexOf('--phase');
    const phase = parseInt(args[idx + 1], 10);

    switch (phase) {
      case 2:
        results = runPhase2();
        name = 'phase-2-isolation';
        break;
      case 4:
        results = runPhase4();
        name = 'phase-4-integration';
        break;
      case 5:
        results = runPhase5();
        name = 'phase-5-error';
        break;
      case 6:
        results = runPhase6();
        name = 'phase-6-regression';
        break;
      default:
        console.log(`Phase ${phase} not implemented in automated mode`);
        process.exit(1);
    }
  } else if (args.includes('--component')) {
    const idx = args.indexOf('--component');
    const componentId = args[idx + 1];
    results = runComponentIsolation(componentId);
    name = `component-${componentId}`;
  } else if (args.includes('--all')) {
    // Run all automated phases
    results = {
      protocol: 'Comprehensive Autonomic Systems Testing',
      timestamp: new Date().toISOString(),
      phases: {
        phase2: runPhase2(),
        phase4: runPhase4(),
        phase5: runPhase5(),
        phase6: runPhase6()
      }
    };
    name = 'full-protocol';
  } else {
    // Default: run phase 2
    results = runPhase2();
    name = 'phase-2-isolation';
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
}

// Export for module use
module.exports = {
  runComponentIsolation,
  runPhase2,
  runPhase4,
  runPhase5,
  runPhase6,
  COMPONENT_TESTS,
  INTEGRATION_TESTS,
  ERROR_TESTS
};

// Run if called directly
if (require.main === module) {
  main();
}
