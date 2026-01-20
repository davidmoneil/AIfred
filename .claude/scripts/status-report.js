#!/usr/bin/env node
/**
 * Status Report Generator - PR-13.4
 *
 * Generates a combined status report from benchmarks, scores, and telemetry.
 * Used by /status command.
 */

const fs = require('fs');
const path = require('path');

// Load modules
const benchmarkRunner = require('./benchmark-runner');
const scoringEngine = require('./scoring-engine');
let telemetryQuery;
try {
  telemetryQuery = require('./telemetry-query');
} catch {
  telemetryQuery = null;
}

const COMPONENT_NAMES = {
  'AC-01': 'Self-Launch',
  'AC-02': 'Wiggum Loop',
  'AC-03': 'Milestone Review',
  'AC-04': 'JICM',
  'AC-05': 'Self-Reflection',
  'AC-06': 'Self-Evolution',
  'AC-07': 'R&D Cycles',
  'AC-08': 'Maintenance',
  'AC-09': 'Session Complete'
};

/**
 * Get component state from state files
 */
function getComponentStates() {
  const stateDir = path.join(__dirname, '..', 'state', 'components');
  const states = {};

  for (const compId of Object.keys(COMPONENT_NAMES)) {
    const stateFile = path.join(stateDir, `${compId.replace('-', '-').toLowerCase()}-${compId.split('-')[1]}.json`);
    // Try various naming conventions
    const possibleFiles = [
      path.join(stateDir, `AC-${compId.split('-')[1]}-${COMPONENT_NAMES[compId].toLowerCase().replace(/\s+/g, '')}.json`),
      path.join(stateDir, `${compId}-launch.json`),
      path.join(stateDir, `${compId}-wiggum.json`),
      path.join(stateDir, `${compId}-review.json`),
      path.join(stateDir, `${compId}-jicm.json`),
      path.join(stateDir, `${compId}-reflection.json`),
      path.join(stateDir, `${compId}-evolution.json`),
      path.join(stateDir, `${compId}-rd.json`),
      path.join(stateDir, `${compId}-maintenance.json`),
      path.join(stateDir, `${compId}-session.json`)
    ];

    for (const file of possibleFiles) {
      if (fs.existsSync(file)) {
        try {
          const content = JSON.parse(fs.readFileSync(file, 'utf8'));
          states[compId] = {
            status: content.status || 'idle',
            last_updated: content.last_updated
          };
          break;
        } catch {
          // Continue to next file
        }
      }
    }

    if (!states[compId]) {
      states[compId] = { status: 'unknown' };
    }
  }

  return states;
}

/**
 * Get recent telemetry activity
 */
function getRecentActivity(limit = 5) {
  if (!telemetryQuery) return [];

  try {
    const events = telemetryQuery.queryEvents({
      startDate: new Date(Date.now() - 24 * 60 * 60 * 1000).toISOString().split('T')[0],
      endDate: new Date().toISOString().split('T')[0],
      limit: limit * 2  // Get more, filter interesting ones
    });

    // Filter to interesting events
    const interesting = events.filter(e =>
      !['test_emit', 'benchmark_test'].includes(e.event_type)
    ).slice(-limit);

    return interesting.map(e => ({
      time: e.timestamp,
      component: e.component,
      event: e.event_type,
      summary: summarizeEvent(e)
    }));
  } catch {
    return [];
  }
}

/**
 * Summarize an event for display
 */
function summarizeEvent(event) {
  switch (event.event_type) {
    case 'iteration_start':
      return `Iteration ${event.data?.iteration || '?'} started`;
    case 'context_warning':
      return `Context at ${event.data?.percentage || '?'}%`;
    case 'context_checkpoint':
      return `Checkpoint triggered at ${event.data?.percentage || '?'}%`;
    case 'correction_logged':
      return `Correction captured (${event.data?.severity || 'unknown'})`;
    case 'milestone_detected':
      return 'Milestone completion detected';
    case 'component_start':
      return 'Started';
    case 'component_end':
      return 'Completed';
    default:
      return event.event_type.replace(/_/g, ' ');
  }
}

/**
 * Generate status bar
 */
function generateBar(score, width = 12) {
  const filled = Math.round((score / 100) * width);
  return '█'.repeat(filled) + '░'.repeat(width - filled);
}

/**
 * Format status for a component
 */
function formatComponentLine(compId, name, score, grade, state) {
  const bar = generateBar(score.weighted_score);
  const stateStr = state.status.charAt(0).toUpperCase() + state.status.slice(1);
  return `  ${compId} ${name.padEnd(16)} [${bar}] ${grade.padStart(2)} | ${stateStr}`;
}

/**
 * Generate full status report
 */
function generateReport() {
  // Get data
  const benchmarks = benchmarkRunner.runAllBenchmarks();
  const sessionScore = scoringEngine.calculateSessionScore(1);
  const states = getComponentStates();
  const activity = getRecentActivity(5);

  // Count operational
  const operational = benchmarks.summary.passing_components;
  const total = benchmarks.summary.total_components;

  // Build report
  const lines = [];

  // Header
  lines.push('');
  lines.push('╔' + '═'.repeat(62) + '╗');
  lines.push('║' + '              JARVIS AUTONOMIC SYSTEM STATUS'.padEnd(62) + '║');
  lines.push('╠' + '═'.repeat(62) + '╣');
  lines.push('║' + `  Session Score: ${sessionScore.summary.average_score.toFixed(1)}% (${sessionScore.summary.grade})`.padEnd(62) + '║');
  lines.push('║' + `  Components: ${operational}/${total} operational`.padEnd(62) + '║');
  lines.push('╚' + '═'.repeat(62) + '╝');
  lines.push('');

  // Component status
  lines.push('Component Status:');
  for (const compScore of sessionScore.components) {
    const compId = compScore.component;
    const name = COMPONENT_NAMES[compId] || compId;
    const state = states[compId] || { status: 'unknown' };
    lines.push(formatComponentLine(compId, name, compScore, compScore.grade, state));
  }
  lines.push('');

  // Recent activity
  lines.push('Recent Activity:');
  if (activity.length > 0) {
    for (const act of activity) {
      const time = act.time.split('T')[1].split('.')[0];
      lines.push(`  - [${time}] ${act.component}: ${act.summary}`);
    }
  } else {
    lines.push('  (no recent activity)');
  }
  lines.push('');

  // Alerts
  lines.push('Alerts:');
  const alerts = [];

  // Check for failing components
  for (const comp of benchmarks.components) {
    if (comp.summary.failed > 0) {
      alerts.push(`  ⚠️  ${comp.component}: ${comp.summary.failed} test(s) failing`);
    }
  }

  if (alerts.length > 0) {
    lines.push(...alerts);
  } else {
    lines.push('  (none)');
  }
  lines.push('');

  return lines.join('\n');
}

/**
 * Main
 */
function main() {
  const args = process.argv.slice(2);

  if (args.includes('--json')) {
    const benchmarks = benchmarkRunner.runAllBenchmarks();
    const sessionScore = scoringEngine.calculateSessionScore(1);
    const states = getComponentStates();
    const activity = getRecentActivity(10);

    console.log(JSON.stringify({
      benchmarks,
      sessionScore,
      states,
      activity,
      generated: new Date().toISOString()
    }, null, 2));
  } else {
    console.log(generateReport());
  }
}

// Export for module use
module.exports = {
  generateReport,
  getComponentStates,
  getRecentActivity
};

// Run if called directly
if (require.main === module) {
  main();
}
