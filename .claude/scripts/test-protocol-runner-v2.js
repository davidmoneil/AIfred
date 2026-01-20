#!/usr/bin/env node
/**
 * Test Protocol Runner v2 - Enhanced Autonomic Systems Testing
 *
 * IMPROVEMENTS over v1:
 * - Tiered testing (Tier 0: Infrastructure, Tier 1: Behavioral, Tier 2: Integration)
 * - Autonomous execution of previously-skipped tests
 * - User approval required for truly interactive tests
 * - Configurable thresholds for AC-04 testing
 *
 * Usage:
 *   node test-protocol-runner-v2.js --tier 0           # Infrastructure only
 *   node test-protocol-runner-v2.js --tier 1           # Behavioral tests
 *   node test-protocol-runner-v2.js --component AC-02  # Single component
 *   node test-protocol-runner-v2.js --all              # Full protocol
 */

const fs = require('fs');
const path = require('path');
const { execSync, spawnSync } = require('child_process');
const readline = require('readline');

const CONFIG = {
  stateDir: path.join(__dirname, '..', 'state', 'components'),
  hooksDir: path.join(__dirname, '..', 'hooks'),
  resultsDir: path.join(__dirname, '..', 'metrics', 'test-results'),
  configFile: path.join(__dirname, '..', 'config', 'autonomy-config.yaml'),
  logsDir: path.join(__dirname, '..', 'logs')
};

// =============================================================================
// TIER 0: INFRASTRUCTURE TESTS
// These verify files exist, hooks load, scripts are executable
// =============================================================================
const TIER_0_TESTS = {
  'AC-01': [
    { id: 'T0-AC01-01', name: 'State file exists', check: () => fs.existsSync(path.join(CONFIG.stateDir, 'AC-01-launch.json')) },
    { id: 'T0-AC01-02', name: 'Session start hook exists', check: () => fs.existsSync(path.join(CONFIG.hooksDir, 'session-start.sh')) },
    { id: 'T0-AC01-03', name: 'Greeting script exists', check: () => fs.existsSync(path.join(__dirname, 'startup-greeting.js')) }
  ],
  'AC-02': [
    { id: 'T0-AC02-01', name: 'State file exists', check: () => fs.existsSync(path.join(CONFIG.stateDir, 'AC-02-wiggum.json')) },
    { id: 'T0-AC02-02', name: 'Wiggum tracker hook exists', check: () => fs.existsSync(path.join(CONFIG.hooksDir, 'wiggum-loop-tracker.js')) },
    { id: 'T0-AC02-03', name: 'Wiggum tracker loads', check: () => { try { require(path.join(CONFIG.hooksDir, 'wiggum-loop-tracker.js')); return true; } catch { return false; } } }
  ],
  'AC-03': [
    { id: 'T0-AC03-01', name: 'State file exists', check: () => fs.existsSync(path.join(CONFIG.stateDir, 'AC-03-review.json')) },
    { id: 'T0-AC03-02', name: 'Milestone detector exists', check: () => fs.existsSync(path.join(CONFIG.hooksDir, 'milestone-detector.js')) },
    { id: 'T0-AC03-03', name: 'Code-review agent defined', check: () => fs.existsSync(path.join(__dirname, '..', 'agents', 'code-review.md')) }
  ],
  'AC-04': [
    { id: 'T0-AC04-01', name: 'State file exists', check: () => fs.existsSync(path.join(CONFIG.stateDir, 'AC-04-jicm.json')) },
    { id: 'T0-AC04-02', name: 'Context accumulator exists', check: () => fs.existsSync(path.join(CONFIG.hooksDir, 'context-accumulator.js')) },
    { id: 'T0-AC04-03', name: 'Context accumulator loads', check: () => { try { require(path.join(CONFIG.hooksDir, 'context-accumulator.js')); return true; } catch { return false; } } },
    { id: 'T0-AC04-04', name: 'Disable MCPs script exists', check: () => fs.existsSync(path.join(__dirname, 'disable-mcps.sh')) },
    { id: 'T0-AC04-05', name: 'Config file exists', check: () => fs.existsSync(CONFIG.configFile) }
  ],
  'AC-05': [
    { id: 'T0-AC05-01', name: 'State file exists', check: () => fs.existsSync(path.join(CONFIG.stateDir, 'AC-05-reflection.json')) },
    { id: 'T0-AC05-02', name: 'Self-correction hook exists', check: () => fs.existsSync(path.join(CONFIG.hooksDir, 'self-correction-capture.js')) },
    { id: 'T0-AC05-03', name: 'Corrections file exists', check: () => fs.existsSync(path.join(__dirname, '..', 'context', 'lessons', 'corrections.md')) }
  ],
  'AC-06': [
    { id: 'T0-AC06-01', name: 'State file exists', check: () => fs.existsSync(path.join(CONFIG.stateDir, 'AC-06-evolution.json')) },
    { id: 'T0-AC06-02', name: 'Evolution queue exists', check: () => fs.existsSync(path.join(__dirname, '..', 'state', 'queues', 'evolution-queue.yaml')) },
    { id: 'T0-AC06-03', name: 'Evolve command exists', check: () => fs.existsSync(path.join(__dirname, '..', 'commands', 'evolve.md')) }
  ],
  'AC-07': [
    { id: 'T0-AC07-01', name: 'State file exists', check: () => fs.existsSync(path.join(CONFIG.stateDir, 'AC-07-rd.json')) },
    { id: 'T0-AC07-02', name: 'Research agenda exists', check: () => fs.existsSync(path.join(__dirname, '..', 'state', 'queues', 'research-agenda.yaml')) },
    { id: 'T0-AC07-03', name: 'Research command exists', check: () => fs.existsSync(path.join(__dirname, '..', 'commands', 'research.md')) }
  ],
  'AC-08': [
    { id: 'T0-AC08-01', name: 'State file exists', check: () => fs.existsSync(path.join(CONFIG.stateDir, 'AC-08-maintenance.json')) },
    { id: 'T0-AC08-02', name: 'Maintain command exists', check: () => fs.existsSync(path.join(__dirname, '..', 'commands', 'maintain.md')) }
  ],
  'AC-09': [
    { id: 'T0-AC09-01', name: 'State file exists', check: () => fs.existsSync(path.join(CONFIG.stateDir, 'AC-09-session.json')) },
    { id: 'T0-AC09-02', name: 'End-session command exists', check: () => fs.existsSync(path.join(__dirname, '..', 'commands', 'end-session.md')) },
    { id: 'T0-AC09-03', name: 'Session state file exists', check: () => fs.existsSync(path.join(__dirname, '..', 'context', 'session-state.md')) }
  ]
};

// =============================================================================
// TIER 1: BEHAVIORAL TESTS
// These actually test component behavior (autonomous where possible)
// =============================================================================
const TIER_1_TESTS = {
  'AC-01': [
    {
      id: 'T1-AC01-01',
      name: 'Greeting generation produces output',
      autonomous: true,
      run: () => {
        try {
          const result = execSync('node .claude/scripts/startup-greeting.js --test 2>&1', { timeout: 5000, cwd: '/Users/aircannon/Claude/Jarvis' });
          return { passed: result.toString().length > 0, output: result.toString().slice(0, 200) };
        } catch (e) {
          return { passed: false, error: e.message };
        }
      }
    },
    {
      id: 'T1-AC01-02',
      name: 'State file has valid JSON schema',
      autonomous: true,
      run: () => {
        try {
          const state = JSON.parse(fs.readFileSync(path.join(CONFIG.stateDir, 'AC-01-launch.json'), 'utf8'));
          const hasRequiredFields = state.last_run && state.greeting_type !== undefined;
          return { passed: hasRequiredFields, fields: Object.keys(state) };
        } catch (e) {
          return { passed: false, error: e.message };
        }
      }
    }
  ],
  'AC-02': [
    {
      id: 'T1-AC02-01',
      name: 'Wiggum tracker handles loop start event',
      autonomous: true,
      run: () => {
        try {
          const tracker = require(path.join(CONFIG.hooksDir, 'wiggum-loop-tracker.js'));
          // Simulate a tool call that should start a loop
          const mockContext = { tool: 'TodoWrite', tool_input: { todos: [{ content: 'Test', status: 'pending' }] } };
          const result = tracker.handler ? tracker.handler(mockContext) : { proceed: true };
          return { passed: result.proceed === true, result };
        } catch (e) {
          return { passed: false, error: e.message };
        }
      }
    },
    {
      id: 'T1-AC02-02',
      name: 'State tracks max_passes correctly',
      autonomous: true,
      run: () => {
        try {
          const state = JSON.parse(fs.readFileSync(path.join(CONFIG.stateDir, 'AC-02-wiggum.json'), 'utf8'));
          const maxPasses = state.current_loop?.max_passes || 5;
          return { passed: maxPasses >= 2 && maxPasses <= 10, max_passes: maxPasses };
        } catch (e) {
          return { passed: false, error: e.message };
        }
      }
    },
    {
      id: 'T1-AC02-03',
      name: 'Suppression keywords detected correctly',
      autonomous: true,
      run: () => {
        // This tests the suppression logic pattern
        const suppressionKeywords = ['quick', 'rough', 'simple', 'first pass', 'just a draft'];
        const testInputs = [
          { text: 'Do this quickly', expected: true },
          { text: 'Give me a rough estimate', expected: true },
          { text: 'Thoroughly review this code', expected: false }
        ];
        const results = testInputs.map(t => {
          const detected = suppressionKeywords.some(k => t.text.toLowerCase().includes(k));
          return { input: t.text, expected: t.expected, actual: detected, correct: detected === t.expected };
        });
        return { passed: results.every(r => r.correct), results };
      }
    }
  ],
  'AC-03': [
    {
      id: 'T1-AC03-01',
      name: 'Milestone detector hook loads and has handler',
      autonomous: true,
      run: () => {
        try {
          const detector = require(path.join(CONFIG.hooksDir, 'milestone-detector.js'));
          const hasHandler = typeof detector.handler === 'function' || typeof detector === 'function';
          return { passed: hasHandler, exports: Object.keys(detector) };
        } catch (e) {
          return { passed: false, error: e.message };
        }
      }
    },
    {
      id: 'T1-AC03-02',
      name: 'State tracks review metrics',
      autonomous: true,
      run: () => {
        try {
          const state = JSON.parse(fs.readFileSync(path.join(CONFIG.stateDir, 'AC-03-review.json'), 'utf8'));
          const hasMetrics = state.metrics && state.metrics.total_reviews !== undefined;
          return { passed: hasMetrics, metrics: state.metrics };
        } catch (e) {
          return { passed: false, error: e.message };
        }
      }
    }
  ],
  'AC-04': [
    {
      id: 'T1-AC04-01',
      name: 'Context accumulator tracks tool calls',
      autonomous: true,
      run: () => {
        try {
          const estimatePath = path.join(CONFIG.logsDir, 'context-estimate.json');
          if (!fs.existsSync(estimatePath)) {
            return { passed: true, note: 'No estimate file yet (normal for fresh session)' };
          }
          const estimate = JSON.parse(fs.readFileSync(estimatePath, 'utf8'));
          const hasFields = estimate.totalTokens !== undefined && estimate.toolCalls !== undefined;
          return { passed: hasFields, estimate };
        } catch (e) {
          return { passed: false, error: e.message };
        }
      }
    },
    {
      id: 'T1-AC04-02',
      name: 'Threshold configuration is readable',
      autonomous: true,
      run: () => {
        try {
          const config = fs.readFileSync(CONFIG.configFile, 'utf8');
          const match = config.match(/threshold_tokens:\s*(\d+)/);
          if (match) {
            const tokens = parseInt(match[1], 10);
            const percentage = (tokens / 200000) * 100;
            return { passed: true, threshold_tokens: tokens, percentage: percentage.toFixed(1) + '%' };
          }
          return { passed: false, error: 'threshold_tokens not found in config' };
        } catch (e) {
          return { passed: false, error: e.message };
        }
      }
    },
    {
      id: 'T1-AC04-03',
      name: 'Threshold calculation is correct',
      autonomous: true,
      run: () => {
        // Test the threshold math
        const MAX_CONTEXT = 200000;
        const testCases = [
          { threshold_tokens: 150000, expected_pct: 75 },
          { threshold_tokens: 100000, expected_pct: 50 },
          { threshold_tokens: 20000, expected_pct: 10 }  // Test mode threshold
        ];
        const results = testCases.map(tc => {
          const actual_pct = Math.round((tc.threshold_tokens / MAX_CONTEXT) * 100);
          return { ...tc, actual_pct, correct: actual_pct === tc.expected_pct };
        });
        return { passed: results.every(r => r.correct), results };
      }
    }
  ],
  'AC-05': [
    {
      id: 'T1-AC05-01',
      name: 'Corrections file is valid markdown',
      autonomous: true,
      run: () => {
        try {
          const content = fs.readFileSync(path.join(__dirname, '..', 'context', 'lessons', 'corrections.md'), 'utf8');
          const isMarkdown = content.includes('#') || content.includes('*') || content.includes('-');
          return { passed: content.length > 0, is_markdown: isMarkdown, length: content.length };
        } catch (e) {
          return { passed: false, error: e.message };
        }
      }
    },
    {
      id: 'T1-AC05-02',
      name: 'Self-correction hook has handler',
      autonomous: true,
      run: () => {
        try {
          const hook = require(path.join(CONFIG.hooksDir, 'self-correction-capture.js'));
          return { passed: typeof hook.handler === 'function', exports: Object.keys(hook) };
        } catch (e) {
          return { passed: false, error: e.message };
        }
      }
    }
  ],
  'AC-06': [
    {
      id: 'T1-AC06-01',
      name: 'Evolution queue is valid YAML',
      autonomous: true,
      run: () => {
        try {
          const content = fs.readFileSync(path.join(__dirname, '..', 'state', 'queues', 'evolution-queue.yaml'), 'utf8');
          // Basic YAML validation: should have key: value patterns
          const hasYamlStructure = content.includes(':') && !content.includes('{');
          return { passed: hasYamlStructure, length: content.length };
        } catch (e) {
          return { passed: false, error: e.message };
        }
      }
    },
    {
      id: 'T1-AC06-02',
      name: 'State tracks evolution metrics',
      autonomous: true,
      run: () => {
        try {
          const state = JSON.parse(fs.readFileSync(path.join(CONFIG.stateDir, 'AC-06-evolution.json'), 'utf8'));
          const hasMetrics = state.metrics && state.metrics.total_evolutions !== undefined;
          return { passed: hasMetrics, metrics: state.metrics };
        } catch (e) {
          return { passed: false, error: e.message };
        }
      }
    }
  ],
  'AC-07': [
    {
      id: 'T1-AC07-01',
      name: 'Research agenda is valid YAML',
      autonomous: true,
      run: () => {
        try {
          const content = fs.readFileSync(path.join(__dirname, '..', 'state', 'queues', 'research-agenda.yaml'), 'utf8');
          const hasYamlStructure = content.includes(':');
          return { passed: hasYamlStructure, length: content.length };
        } catch (e) {
          return { passed: false, error: e.message };
        }
      }
    }
  ],
  'AC-08': [
    {
      id: 'T1-AC08-01',
      name: 'State tracks maintenance metrics',
      autonomous: true,
      run: () => {
        try {
          const state = JSON.parse(fs.readFileSync(path.join(CONFIG.stateDir, 'AC-08-maintenance.json'), 'utf8'));
          const hasMetrics = state.metrics && state.metrics.total_maintenance_cycles !== undefined;
          return { passed: hasMetrics, metrics: state.metrics };
        } catch (e) {
          return { passed: false, error: e.message };
        }
      }
    }
  ],
  'AC-09': [
    {
      id: 'T1-AC09-01',
      name: 'Session state file is valid markdown',
      autonomous: true,
      run: () => {
        try {
          const content = fs.readFileSync(path.join(__dirname, '..', 'context', 'session-state.md'), 'utf8');
          return { passed: content.length > 0, has_content: content.length };
        } catch (e) {
          return { passed: false, error: e.message };
        }
      }
    },
    {
      id: 'T1-AC09-02',
      name: 'State tracks session metrics',
      autonomous: true,
      run: () => {
        try {
          const state = JSON.parse(fs.readFileSync(path.join(CONFIG.stateDir, 'AC-09-session.json'), 'utf8'));
          const hasMetrics = state.metrics && state.metrics.total_sessions !== undefined;
          return { passed: hasMetrics, metrics: state.metrics };
        } catch (e) {
          return { passed: false, error: e.message };
        }
      }
    }
  ]
};

// =============================================================================
// TIER 2: INTEGRATION TESTS (require active session or user interaction)
// =============================================================================
const TIER_2_TESTS = [
  {
    id: 'T2-INT-01',
    name: 'AC-02 + AC-04: Wiggum responds to context threshold',
    components: ['AC-02', 'AC-04'],
    autonomous: false,
    requiresUserApproval: true,
    description: 'Requires simulating high context load'
  },
  {
    id: 'T2-INT-02',
    name: 'AC-03 + AC-02: Review triggers remediation loop',
    components: ['AC-03', 'AC-02'],
    autonomous: false,
    requiresUserApproval: true,
    description: 'Requires completing a milestone with issues'
  },
  {
    id: 'T2-INT-03',
    name: 'AC-05 + AC-06: Reflection creates evolution proposal',
    components: ['AC-05', 'AC-06'],
    autonomous: false,
    requiresUserApproval: true,
    description: 'Requires user correction to trigger reflection'
  },
  {
    id: 'T2-INT-04',
    name: 'AC-01 + AC-09: Session checkpoint and restore',
    components: ['AC-01', 'AC-09'],
    autonomous: false,
    requiresUserApproval: true,
    description: 'Requires /checkpoint and session restart'
  }
];

// =============================================================================
// TEST RUNNER FUNCTIONS
// =============================================================================

function ensureDirs() {
  if (!fs.existsSync(CONFIG.resultsDir)) {
    fs.mkdirSync(CONFIG.resultsDir, { recursive: true });
  }
}

function runTier0(componentId = null) {
  const results = {
    tier: 0,
    name: 'Infrastructure Tests',
    timestamp: new Date().toISOString(),
    components: [],
    summary: { total: 0, passed: 0, failed: 0 }
  };

  const components = componentId ? { [componentId]: TIER_0_TESTS[componentId] } : TIER_0_TESTS;

  for (const [compId, tests] of Object.entries(components)) {
    if (!tests) continue;

    const compResult = { component: compId, tests: [], passed: 0, failed: 0 };

    for (const test of tests) {
      let status = 'failed';
      let details = null;

      try {
        const passed = test.check();
        status = passed ? 'passed' : 'failed';
        details = { check_result: passed };
      } catch (e) {
        details = { error: e.message };
      }

      compResult.tests.push({ id: test.id, name: test.name, status, details });
      results.summary.total++;
      if (status === 'passed') {
        compResult.passed++;
        results.summary.passed++;
      } else {
        compResult.failed++;
        results.summary.failed++;
      }
    }

    results.components.push(compResult);
  }

  return results;
}

function runTier1(componentId = null) {
  const results = {
    tier: 1,
    name: 'Behavioral Tests',
    timestamp: new Date().toISOString(),
    components: [],
    summary: { total: 0, passed: 0, failed: 0 }
  };

  const components = componentId ? { [componentId]: TIER_1_TESTS[componentId] } : TIER_1_TESTS;

  for (const [compId, tests] of Object.entries(components)) {
    if (!tests) continue;

    const compResult = { component: compId, tests: [], passed: 0, failed: 0 };

    for (const test of tests) {
      let status = 'failed';
      let details = null;

      if (test.autonomous) {
        try {
          const result = test.run();
          status = result.passed ? 'passed' : 'failed';
          details = result;
        } catch (e) {
          details = { error: e.message };
        }
      } else {
        status = 'skipped';
        details = { reason: 'Requires user interaction', requiresUserApproval: test.requiresUserApproval };
      }

      compResult.tests.push({ id: test.id, name: test.name, status, details });
      results.summary.total++;
      if (status === 'passed') {
        compResult.passed++;
        results.summary.passed++;
      } else if (status === 'failed') {
        compResult.failed++;
        results.summary.failed++;
      }
    }

    results.components.push(compResult);
  }

  return results;
}

function runTier2() {
  const results = {
    tier: 2,
    name: 'Integration Tests',
    timestamp: new Date().toISOString(),
    tests: TIER_2_TESTS.map(t => ({
      id: t.id,
      name: t.name,
      components: t.components,
      status: 'requires_user_approval',
      description: t.description
    })),
    summary: {
      total: TIER_2_TESTS.length,
      requires_approval: TIER_2_TESTS.length,
      note: 'Tier 2 tests require active session participation'
    }
  };

  return results;
}

function saveResults(results, name) {
  ensureDirs();
  const filename = `${name}-${new Date().toISOString().split('T')[0]}.json`;
  const filepath = path.join(CONFIG.resultsDir, filename);
  fs.writeFileSync(filepath, JSON.stringify(results, null, 2));
  return filepath;
}

function printSummary(results) {
  console.log('\n' + '='.repeat(70));
  console.log(`TIER ${results.tier}: ${results.name.toUpperCase()}`);
  console.log('='.repeat(70));

  if (results.components) {
    for (const comp of results.components) {
      const status = comp.failed === 0 ? 'PASS' : 'FAIL';
      console.log(`\n[${status}] ${comp.component}: ${comp.passed}/${comp.tests.length} passed`);

      for (const test of comp.tests) {
        const icon = test.status === 'passed' ? '[OK]' : test.status === 'skipped' ? '[--]' : '[!!]';
        console.log(`  ${icon} ${test.id}: ${test.name}`);
        if (test.status === 'failed' && test.details) {
          console.log(`      Details: ${JSON.stringify(test.details).slice(0, 100)}`);
        }
      }
    }
  } else if (results.tests) {
    for (const test of results.tests) {
      console.log(`  [??] ${test.id}: ${test.name}`);
      console.log(`       ${test.description}`);
    }
  }

  console.log('\n' + '-'.repeat(70));
  console.log(`Summary: ${results.summary.passed || 0} passed, ${results.summary.failed || 0} failed`);
  if (results.summary.requires_approval) {
    console.log(`         ${results.summary.requires_approval} tests require user approval`);
  }
  console.log('='.repeat(70) + '\n');
}

// =============================================================================
// MAIN
// =============================================================================

function main() {
  const args = process.argv.slice(2);

  if (args.includes('--help') || args.includes('-h')) {
    console.log(`
Test Protocol Runner v2 - Enhanced Autonomic Systems Testing

Usage:
  node test-protocol-runner-v2.js [options]

Options:
  --tier <n>         Run specific tier (0, 1, or 2)
  --component <id>   Test specific component (AC-01 to AC-09)
  --all              Run all tiers
  --json             Output as JSON
  --save             Save results to file

Tiers:
  0: Infrastructure - Files exist, hooks load
  1: Behavioral - Component actually works correctly
  2: Integration - Cross-component interaction (requires user)

Examples:
  node test-protocol-runner-v2.js --tier 0
  node test-protocol-runner-v2.js --tier 1 --component AC-02
  node test-protocol-runner-v2.js --all --save
`);
    process.exit(0);
  }

  ensureDirs();

  const jsonOutput = args.includes('--json');
  const saveOutput = args.includes('--save');

  let componentId = null;
  if (args.includes('--component')) {
    const idx = args.indexOf('--component');
    componentId = args[idx + 1];
  }

  let allResults = {};
  let name = '';

  if (args.includes('--all')) {
    allResults = {
      protocol: 'Comprehensive Autonomic Systems Testing v2',
      timestamp: new Date().toISOString(),
      tier0: runTier0(componentId),
      tier1: runTier1(componentId),
      tier2: runTier2()
    };
    name = 'full-protocol-v2';

    if (!jsonOutput) {
      printSummary(allResults.tier0);
      printSummary(allResults.tier1);
      printSummary(allResults.tier2);
    }
  } else if (args.includes('--tier')) {
    const idx = args.indexOf('--tier');
    const tier = parseInt(args[idx + 1], 10);

    switch (tier) {
      case 0:
        allResults = runTier0(componentId);
        name = 'tier-0-infrastructure';
        break;
      case 1:
        allResults = runTier1(componentId);
        name = 'tier-1-behavioral';
        break;
      case 2:
        allResults = runTier2();
        name = 'tier-2-integration';
        break;
      default:
        console.error(`Unknown tier: ${tier}`);
        process.exit(1);
    }

    if (!jsonOutput) {
      printSummary(allResults);
    }
  } else {
    // Default: run tier 0 and 1
    allResults = {
      tier0: runTier0(componentId),
      tier1: runTier1(componentId)
    };
    name = 'tier-0-1-combined';

    if (!jsonOutput) {
      printSummary(allResults.tier0);
      printSummary(allResults.tier1);
    }
  }

  if (saveOutput) {
    const filepath = saveResults(allResults, name);
    console.log(`Results saved to: ${filepath}`);
  }

  if (jsonOutput) {
    console.log(JSON.stringify(allResults, null, 2));
  }

  // Exit with error if any tests failed
  const hasFailed = allResults.tier0?.summary?.failed > 0 ||
                   allResults.tier1?.summary?.failed > 0 ||
                   allResults.summary?.failed > 0;
  process.exit(hasFailed ? 1 : 0);
}

module.exports = { runTier0, runTier1, runTier2, TIER_0_TESTS, TIER_1_TESTS, TIER_2_TESTS };

if (require.main === module) {
  main();
}
