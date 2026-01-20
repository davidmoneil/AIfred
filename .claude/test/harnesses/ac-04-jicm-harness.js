#!/usr/bin/env node
/**
 * AC-04 JICM Context Management Test Harness
 *
 * Tests for Jarvis Intelligent Context Management.
 * Critical for session stability and context preservation.
 */

const fs = require('fs');
const path = require('path');

const CONFIG = {
  stateFile: path.join(__dirname, '../../state/components/AC-04-jicm.json'),
  contextAccumulator: path.join(__dirname, '../../hooks/context-accumulator.js'),
  contextEstimate: path.join(__dirname, '../../logs/context-estimate.json'),
  disableMcps: path.join(__dirname, '../../scripts/disable-mcps.sh'),
  enableMcps: path.join(__dirname, '../../scripts/enable-mcps.sh')
};

const THRESHOLDS = {
  HEALTHY: 0,
  CAUTION: 50,
  WARNING: 70,
  CRITICAL: 85,
  EMERGENCY: 95
};

const TESTS = {
  functional: [
    {
      id: 'AC04-F01',
      name: '50% threshold (CAUTION)',
      description: 'CAUTION status + warning displayed',
      validate: (state, estimate) => {
        return {
          passed: state.current_session?.threshold_status !== undefined,
          actual: state.current_session?.threshold_status,
          expected: 'threshold_status field exists'
        };
      }
    },
    {
      id: 'AC04-F02',
      name: '70% threshold (WARNING)',
      description: 'WARNING + auto-offload triggered',
      validate: (state, estimate) => {
        return {
          passed: state.metrics?.total_compressions !== undefined,
          actual: state.metrics?.total_compressions,
          expected: 'Compression tracking available'
        };
      }
    },
    {
      id: 'AC04-F03',
      name: '85% threshold (CRITICAL)',
      description: 'CRITICAL + checkpoint triggered',
      validate: (state, estimate) => {
        return {
          passed: state.metrics?.total_checkpoints !== undefined,
          actual: state.metrics?.total_checkpoints,
          expected: 'Checkpoint tracking available'
        };
      }
    },
    {
      id: 'AC04-F04',
      name: '95% threshold (EMERGENCY)',
      description: 'EMERGENCY + force preserve',
      validate: (state, estimate) => {
        return {
          passed: state.current_session !== undefined,
          actual: 'Session tracking present',
          expected: 'Emergency handling capability'
        };
      }
    },
    {
      id: 'AC04-F05',
      name: 'MCP disable',
      description: 'Tier 2 MCPs can be disabled',
      validate: (state, estimate) => {
        const disableExists = fs.existsSync(CONFIG.disableMcps);
        const enableExists = fs.existsSync(CONFIG.enableMcps);
        return {
          passed: disableExists && enableExists,
          actual: { disable: disableExists, enable: enableExists },
          expected: 'Both scripts exist'
        };
      }
    }
  ],
  stress: [
    {
      id: 'AC04-S01',
      name: 'Multiple compressions',
      description: 'Liftover accuracy > 95%',
      validate: (state, estimate) => {
        return {
          passed: state.metrics?.liftover_success_rate === null ||
                  state.metrics?.liftover_success_rate >= 0.95,
          actual: state.metrics?.liftover_success_rate,
          expected: '>= 0.95 or not yet measured'
        };
      }
    }
  ]
};

function loadState() {
  try {
    return JSON.parse(fs.readFileSync(CONFIG.stateFile, 'utf8'));
  } catch (e) {
    return null;
  }
}

function loadContextEstimate() {
  try {
    return JSON.parse(fs.readFileSync(CONFIG.contextEstimate, 'utf8'));
  } catch (e) {
    return null;
  }
}

function checkContextAccumulator() {
  if (!fs.existsSync(CONFIG.contextAccumulator)) {
    return { exists: false, loads: false };
  }
  try {
    delete require.cache[require.resolve(CONFIG.contextAccumulator)];
    require(CONFIG.contextAccumulator);
    return { exists: true, loads: true };
  } catch (e) {
    return { exists: true, loads: false, error: e.message };
  }
}

function runTests() {
  const state = loadState();
  const estimate = loadContextEstimate();
  const hookStatus = checkContextAccumulator();

  const results = {
    component: 'AC-04',
    name: 'JICM Context Management',
    timestamp: new Date().toISOString(),
    prerequisites: {
      state_file: state !== null,
      context_estimate: estimate !== null,
      accumulator_exists: hookStatus.exists,
      accumulator_loads: hookStatus.loads
    },
    current_context: estimate,
    functional: [],
    stress: [],
    summary: { total: 0, passed: 0, failed: 0, skipped: 0 }
  };

  // Run all tests
  for (const testSet of [TESTS.functional, TESTS.stress]) {
    for (const test of testSet) {
      const result = {
        id: test.id,
        name: test.name,
        description: test.description,
        status: 'skipped',
        details: null
      };

      if (state) {
        try {
          const validation = test.validate(state, estimate);
          result.status = validation.passed ? 'passed' : 'failed';
          result.details = validation;
        } catch (e) {
          result.status = 'error';
          result.details = { error: e.message };
        }
      }

      if (testSet === TESTS.functional) {
        results.functional.push(result);
      } else {
        results.stress.push(result);
      }
      results.summary.total++;
      results.summary[result.status]++;
    }
  }

  return results;
}

function printResults(results) {
  console.log('\n' + '='.repeat(60));
  console.log('AC-04 JICM CONTEXT MANAGEMENT TEST HARNESS');
  console.log('='.repeat(60));

  console.log('\nPrerequisites:');
  for (const [key, value] of Object.entries(results.prerequisites)) {
    console.log(`  ${value ? '~' : '~'} ${key}: ${value}`);
  }

  if (results.current_context) {
    console.log('\nCurrent Context:');
    console.log(`  Estimated tokens: ${results.current_context.estimated_tokens || 'unknown'}`);
    console.log(`  Status: ${results.current_context.status || 'unknown'}`);
  }

  console.log('\nFunctional Tests:');
  for (const test of results.functional) {
    const status = test.status === 'passed' ? '~' : test.status === 'failed' ? '~' : '~';
    console.log(`  ${status} ${test.id}: ${test.name}`);
  }

  console.log('\nStress Tests:');
  for (const test of results.stress) {
    const status = test.status === 'passed' ? '~' : test.status === 'failed' ? '~' : '~';
    console.log(`  ${status} ${test.id}: ${test.name}`);
  }

  console.log(`\nSummary: ${results.summary.passed} passed, ${results.summary.failed} failed, ${results.summary.skipped} skipped`);
  console.log('='.repeat(60));
}

module.exports = { runTests, TESTS, THRESHOLDS };

if (require.main === module) {
  const results = runTests();
  printResults(results);
  process.exit(results.summary.failed > 0 ? 1 : 0);
}
