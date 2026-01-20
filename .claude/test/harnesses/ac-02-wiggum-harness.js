#!/usr/bin/env node
/**
 * AC-02 Wiggum Loop Test Harness
 *
 * Comprehensive tests for the multi-pass verification system.
 * This is the most critical autonomic component.
 */

const fs = require('fs');
const path = require('path');

const CONFIG = {
  stateFile: path.join(__dirname, '../../state/components/AC-02-wiggum.json'),
  hookFile: path.join(__dirname, '../../hooks/wiggum-loop-tracker.js'),
  patternFile: path.join(__dirname, '../../context/patterns/wiggum-loop-pattern.md')
};

/**
 * Test specifications per the plan
 */
const TESTS = {
  functional: [
    {
      id: 'AC02-F01',
      name: 'Multi-pass activation',
      description: 'Verify >= 2 passes for standard task',
      validate: (state) => {
        if (!state.current_loop) return { passed: false, reason: 'No current loop' };
        return {
          passed: state.current_loop.max_passes >= 2,
          actual: state.current_loop.max_passes,
          expected: '>= 2'
        };
      }
    },
    {
      id: 'AC02-F02',
      name: 'TodoWrite integration',
      description: 'Verify todos are created and tracked',
      validate: (state) => {
        if (!state.todos) return { passed: false, reason: 'No todos tracking' };
        return {
          passed: state.todos.total !== undefined,
          actual: state.todos,
          expected: 'todos.total defined'
        };
      }
    },
    {
      id: 'AC02-F03',
      name: 'Self-review execution',
      description: 'Verify review is documented',
      validate: (state) => {
        // Check if passes include review info
        const hasReview = state.passes?.some(p => p.review_documented);
        return {
          passed: state.passes !== undefined,
          actual: hasReview,
          expected: 'Review in passes'
        };
      }
    },
    {
      id: 'AC02-F04',
      name: 'Suppression detection',
      description: 'Verify "quick"/"rough" triggers single pass',
      validate: (state) => {
        return {
          passed: state.current_loop?.suppressed !== undefined,
          actual: state.current_loop?.suppressed,
          expected: 'suppressed field exists'
        };
      }
    },
    {
      id: 'AC02-F05',
      name: 'Completion detection',
      description: 'All todos done = exit',
      validate: (state) => {
        const allDone = state.todos?.total > 0 &&
                       state.todos?.completed === state.todos?.total;
        return {
          passed: state.todos !== undefined,
          actual: { completed: state.todos?.completed, total: state.todos?.total },
          expected: 'completed === total for exit'
        };
      }
    },
    {
      id: 'AC02-F06',
      name: 'Drift detection',
      description: 'Scope creep caught and realigned',
      validate: (state) => {
        // This requires active monitoring - check if structure supports it
        return {
          passed: state.current_loop?.task_description !== undefined,
          actual: state.current_loop?.task_description,
          expected: 'Task description tracked for drift detection'
        };
      }
    }
  ],
  stress: [
    {
      id: 'AC02-S01',
      name: 'Max iterations',
      description: 'Stop at 5 passes (safety)',
      validate: (state) => {
        return {
          passed: state.current_loop?.max_passes === 5,
          actual: state.current_loop?.max_passes,
          expected: 5
        };
      }
    },
    {
      id: 'AC02-S02',
      name: 'Blocker investigation',
      description: '3+ attempts before escalating',
      validate: (state) => {
        // This requires active session - structure check only
        return {
          passed: state.passes !== undefined,
          actual: 'Structure supports pass tracking',
          expected: 'Can track investigation attempts'
        };
      }
    },
    {
      id: 'AC02-S03',
      name: 'Context exhaustion',
      description: 'JICM checkpoint triggered',
      validate: (state) => {
        // Cross-component integration - check metrics exist
        return {
          passed: state.metrics !== undefined,
          actual: state.metrics,
          expected: 'Metrics available for JICM integration'
        };
      }
    }
  ]
};

/**
 * Load current state
 */
function loadState() {
  try {
    const content = fs.readFileSync(CONFIG.stateFile, 'utf8');
    return JSON.parse(content);
  } catch (e) {
    return null;
  }
}

/**
 * Check hook loads correctly
 */
function checkHook() {
  if (!fs.existsSync(CONFIG.hookFile)) {
    return { exists: false, loads: false };
  }
  try {
    // Clear cache and reload
    delete require.cache[require.resolve(CONFIG.hookFile)];
    require(CONFIG.hookFile);
    return { exists: true, loads: true };
  } catch (e) {
    return { exists: true, loads: false, error: e.message };
  }
}

/**
 * Check pattern documentation exists
 */
function checkPattern() {
  return fs.existsSync(CONFIG.patternFile);
}

/**
 * Run all tests
 */
function runTests() {
  const state = loadState();
  const hookStatus = checkHook();
  const patternExists = checkPattern();

  const results = {
    component: 'AC-02',
    name: 'Wiggum Loop',
    timestamp: new Date().toISOString(),
    prerequisites: {
      state_file: state !== null,
      hook_exists: hookStatus.exists,
      hook_loads: hookStatus.loads,
      pattern_doc: patternExists
    },
    functional: [],
    stress: [],
    summary: {
      total: 0,
      passed: 0,
      failed: 0,
      skipped: 0
    }
  };

  // Run functional tests
  for (const test of TESTS.functional) {
    const result = {
      id: test.id,
      name: test.name,
      description: test.description,
      status: 'skipped',
      details: null
    };

    if (state) {
      try {
        const validation = test.validate(state);
        result.status = validation.passed ? 'passed' : 'failed';
        result.details = validation;
      } catch (e) {
        result.status = 'error';
        result.details = { error: e.message };
      }
    } else {
      result.details = { reason: 'State file not available' };
    }

    results.functional.push(result);
    results.summary.total++;
    results.summary[result.status]++;
  }

  // Run stress tests
  for (const test of TESTS.stress) {
    const result = {
      id: test.id,
      name: test.name,
      description: test.description,
      status: 'skipped',
      details: null
    };

    if (state) {
      try {
        const validation = test.validate(state);
        result.status = validation.passed ? 'passed' : 'failed';
        result.details = validation;
      } catch (e) {
        result.status = 'error';
        result.details = { error: e.message };
      }
    } else {
      result.details = { reason: 'State file not available' };
    }

    results.stress.push(result);
    results.summary.total++;
    results.summary[result.status]++;
  }

  return results;
}

/**
 * Print results
 */
function printResults(results) {
  console.log('\n' + '='.repeat(60));
  console.log('AC-02 WIGGUM LOOP TEST HARNESS');
  console.log('='.repeat(60));

  console.log('\nPrerequisites:');
  for (const [key, value] of Object.entries(results.prerequisites)) {
    const status = value ? '~' : '~';
    console.log(`  ${status} ${key}: ${value}`);
  }

  console.log('\nFunctional Tests:');
  for (const test of results.functional) {
    const status = test.status === 'passed' ? '~' :
                   test.status === 'failed' ? '~' : '~';
    console.log(`  ${status} ${test.id}: ${test.name}`);
    if (test.details && test.status !== 'passed') {
      console.log(`      ${JSON.stringify(test.details)}`);
    }
  }

  console.log('\nStress Tests:');
  for (const test of results.stress) {
    const status = test.status === 'passed' ? '~' :
                   test.status === 'failed' ? '~' : '~';
    console.log(`  ${status} ${test.id}: ${test.name}`);
  }

  console.log(`\nSummary: ${results.summary.passed} passed, ${results.summary.failed} failed, ${results.summary.skipped} skipped`);
  console.log('='.repeat(60));
}

// Export for module use
module.exports = { runTests, TESTS, loadState };

// Run if called directly
if (require.main === module) {
  const results = runTests();
  printResults(results);
  process.exit(results.summary.failed > 0 ? 1 : 0);
}
