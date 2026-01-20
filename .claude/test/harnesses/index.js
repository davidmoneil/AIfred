#!/usr/bin/env node
/**
 * Test Harness Index
 *
 * Central registry of all component test harnesses.
 * Run with: node index.js [component]
 */

const path = require('path');
const fs = require('fs');

const HARNESSES = {
  'AC-02': {
    name: 'Wiggum Loop',
    file: 'ac-02-wiggum-harness.js',
    priority: 'critical'
  },
  'AC-04': {
    name: 'JICM Context Management',
    file: 'ac-04-jicm-harness.js',
    priority: 'critical'
  }
  // Additional harnesses will be added as created
};

/**
 * Run a specific harness
 */
function runHarness(componentId) {
  const harness = HARNESSES[componentId];
  if (!harness) {
    return { error: `No harness defined for ${componentId}` };
  }

  const harnessPath = path.join(__dirname, harness.file);
  if (!fs.existsSync(harnessPath)) {
    return { error: `Harness file not found: ${harness.file}` };
  }

  try {
    const module = require(harnessPath);
    return module.runTests();
  } catch (e) {
    return { error: e.message };
  }
}

/**
 * Run all harnesses
 */
function runAll() {
  const results = {
    timestamp: new Date().toISOString(),
    harnesses: [],
    summary: {
      total: 0,
      passed: 0,
      failed: 0,
      errors: 0
    }
  };

  for (const [componentId, harness] of Object.entries(HARNESSES)) {
    const result = runHarness(componentId);
    results.harnesses.push({
      component: componentId,
      name: harness.name,
      result
    });

    results.summary.total++;
    if (result.error) {
      results.summary.errors++;
    } else if (result.summary?.failed > 0) {
      results.summary.failed++;
    } else {
      results.summary.passed++;
    }
  }

  return results;
}

/**
 * List available harnesses
 */
function listHarnesses() {
  console.log('\nAvailable Test Harnesses:');
  console.log('='.repeat(50));
  for (const [id, harness] of Object.entries(HARNESSES)) {
    const exists = fs.existsSync(path.join(__dirname, harness.file));
    const status = exists ? '[ready]' : '[missing]';
    console.log(`  ${id}: ${harness.name} ${status} (${harness.priority})`);
  }
  console.log('='.repeat(50));
}

// Main
if (require.main === module) {
  const args = process.argv.slice(2);

  if (args.includes('--list') || args.includes('-l')) {
    listHarnesses();
  } else if (args.length > 0 && !args[0].startsWith('-')) {
    const componentId = args[0].toUpperCase();
    const result = runHarness(componentId);
    console.log(JSON.stringify(result, null, 2));
  } else {
    const results = runAll();
    console.log(JSON.stringify(results, null, 2));
  }
}

module.exports = { runHarness, runAll, listHarnesses, HARNESSES };
