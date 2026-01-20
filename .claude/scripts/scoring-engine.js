#!/usr/bin/env node
/**
 * Scoring Engine - PR-13.3
 *
 * Calculates component scores, session composites, and grades.
 * Based on telemetry data and benchmark results.
 *
 * Usage:
 *   node scoring-engine.js --component AC-01
 *   node scoring-engine.js --session
 *   node scoring-engine.js --all --days 7
 */

const fs = require('fs');
const path = require('path');

// Load telemetry query
let telemetryQuery;
try {
  telemetryQuery = require('./telemetry-query');
} catch {
  telemetryQuery = null;
}

const CONFIG = {
  benchmarksDir: path.join(__dirname, '..', 'metrics', 'benchmarks'),
  scoresDir: path.join(__dirname, '..', 'metrics', 'scores'),
  aggregatesDir: path.join(__dirname, '..', 'metrics', 'aggregates')
};

// Scoring weights by component
const COMPONENT_WEIGHTS = {
  'AC-01': { reliability: 0.4, performance: 0.3, completeness: 0.3 },
  'AC-02': { reliability: 0.3, iterations: 0.3, completion_rate: 0.4 },
  'AC-03': { reliability: 0.3, quality: 0.4, timeliness: 0.3 },
  'AC-04': { accuracy: 0.4, proactivity: 0.3, efficiency: 0.3 },
  'AC-05': { capture_rate: 0.4, insight_quality: 0.3, pattern_detection: 0.3 },
  'AC-06': { safety: 0.4, success_rate: 0.3, risk_management: 0.3 },
  'AC-07': { relevance: 0.4, novelty: 0.3, actionability: 0.3 },
  'AC-08': { thoroughness: 0.4, timeliness: 0.3, issue_detection: 0.3 },
  'AC-09': { completeness: 0.4, documentation: 0.3, handoff_quality: 0.3 }
};

// Grade thresholds
const GRADE_THRESHOLDS = {
  'A+': 97, 'A': 93, 'A-': 90,
  'B+': 87, 'B': 83, 'B-': 80,
  'C+': 77, 'C': 73, 'C-': 70,
  'D+': 67, 'D': 63, 'D-': 60,
  'F': 0
};

/**
 * Get letter grade from numeric score
 */
function getGrade(score) {
  for (const [grade, threshold] of Object.entries(GRADE_THRESHOLDS)) {
    if (score >= threshold) return grade;
  }
  return 'F';
}

/**
 * Ensure directories exist
 */
function ensureDirs() {
  [CONFIG.scoresDir].forEach(dir => {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  });
}

/**
 * Load latest benchmark results
 */
function loadLatestBenchmark() {
  if (!fs.existsSync(CONFIG.benchmarksDir)) return null;

  const files = fs.readdirSync(CONFIG.benchmarksDir)
    .filter(f => f.startsWith('all-components-'))
    .sort()
    .reverse();

  if (files.length === 0) return null;

  try {
    const content = fs.readFileSync(path.join(CONFIG.benchmarksDir, files[0]), 'utf8');
    return JSON.parse(content);
  } catch {
    return null;
  }
}

/**
 * Calculate component score from benchmark + telemetry
 */
function calculateComponentScore(componentId, days = 7) {
  const weights = COMPONENT_WEIGHTS[componentId] || { reliability: 1.0 };
  const score = {
    component: componentId,
    calculated_at: new Date().toISOString(),
    dimensions: {},
    weighted_score: 0,
    grade: 'N/A',
    data_sources: []
  };

  // Get benchmark data
  const benchmark = loadLatestBenchmark();
  if (benchmark) {
    const compBenchmark = benchmark.components?.find(c => c.component === componentId);
    if (compBenchmark) {
      // Reliability = benchmark pass rate
      const passRate = compBenchmark.summary.total > 0
        ? (compBenchmark.summary.passed / compBenchmark.summary.total) * 100
        : 0;
      score.dimensions.reliability = passRate;
      score.data_sources.push('benchmark');
    }
  }

  // Get telemetry data if available
  if (telemetryQuery) {
    try {
      const health = telemetryQuery.getComponentHealth(componentId, days);
      if (health && health.executions > 0) {
        // Parse success rate
        const successRate = parseFloat(health.success_rate) || 0;
        score.dimensions.performance = successRate;
        score.dimensions.executions = health.executions;
        score.data_sources.push('telemetry');
      }
    } catch {
      // Telemetry not available
    }
  }

  // Calculate weighted score
  let totalWeight = 0;
  let weightedSum = 0;

  for (const [dimension, weight] of Object.entries(weights)) {
    if (score.dimensions[dimension] !== undefined) {
      weightedSum += score.dimensions[dimension] * weight;
      totalWeight += weight;
    }
  }

  // If we have reliability from benchmark, use it as base
  if (score.dimensions.reliability !== undefined && totalWeight === 0) {
    score.weighted_score = score.dimensions.reliability;
  } else if (totalWeight > 0) {
    score.weighted_score = weightedSum / totalWeight;
  } else {
    // No data - estimate based on file existence
    score.weighted_score = 75; // Default passing score
    score.data_sources.push('estimated');
  }

  score.grade = getGrade(score.weighted_score);

  return score;
}

/**
 * Calculate session composite score
 */
function calculateSessionScore(days = 1) {
  const session = {
    calculated_at: new Date().toISOString(),
    period_days: days,
    components: [],
    summary: {
      total_score: 0,
      average_score: 0,
      grade: 'N/A',
      components_scored: 0
    }
  };

  let totalScore = 0;
  let count = 0;

  for (const componentId of Object.keys(COMPONENT_WEIGHTS)) {
    const componentScore = calculateComponentScore(componentId, days);
    session.components.push(componentScore);

    if (componentScore.weighted_score > 0) {
      totalScore += componentScore.weighted_score;
      count++;
    }
  }

  session.summary.components_scored = count;
  session.summary.total_score = totalScore;
  session.summary.average_score = count > 0 ? totalScore / count : 0;
  session.summary.grade = getGrade(session.summary.average_score);

  return session;
}

/**
 * Save score to file
 */
function saveScore(score, name) {
  ensureDirs();
  const filename = `${name}-${new Date().toISOString().split('T')[0]}.json`;
  const filepath = path.join(CONFIG.scoresDir, filename);
  fs.writeFileSync(filepath, JSON.stringify(score, null, 2));
  return filepath;
}

/**
 * Print score card
 */
function printScoreCard(score) {
  console.log('\n' + '='.repeat(60));
  console.log('AUTONOMIC SYSTEM SCORE CARD');
  console.log('='.repeat(60));

  if (score.components) {
    // Session score
    console.log(`\nSession Score: ${score.summary.average_score.toFixed(1)}% (${score.summary.grade})`);
    console.log(`Components Scored: ${score.summary.components_scored}\n`);

    console.log('Component Breakdown:');
    console.log('-'.repeat(50));

    for (const comp of score.components) {
      const bar = '█'.repeat(Math.floor(comp.weighted_score / 5));
      console.log(`${comp.component}: ${comp.weighted_score.toFixed(1).padStart(5)}% ${comp.grade.padStart(3)} ${bar}`);
    }
  } else {
    // Single component
    console.log(`\n${score.component}: ${score.weighted_score.toFixed(1)}% (${score.grade})\n`);

    console.log('Dimensions:');
    for (const [dim, value] of Object.entries(score.dimensions)) {
      console.log(`  ${dim}: ${typeof value === 'number' ? value.toFixed(1) + '%' : value}`);
    }

    console.log(`\nData Sources: ${score.data_sources.join(', ')}`);
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
Scoring Engine

Usage:
  node scoring-engine.js [options]

Options:
  --component <id>   Score a specific component
  --session          Calculate session composite score
  --all              Score all components individually
  --days <n>         Days of data to consider (default: 7)
  --json             Output as JSON
  --save             Save results to file
  --help             Show this help

Examples:
  node scoring-engine.js --session
  node scoring-engine.js --component AC-02 --days 30
  node scoring-engine.js --all --save
`);
    process.exit(0);
  }

  const jsonOutput = args.includes('--json');
  const saveOutput = args.includes('--save');

  let days = 7;
  const daysIdx = args.indexOf('--days');
  if (daysIdx !== -1) {
    days = parseInt(args[daysIdx + 1], 10) || 7;
  }

  let result;
  let name;

  if (args.includes('--session') || args.includes('--all')) {
    result = calculateSessionScore(days);
    name = 'session';
  } else if (args.includes('--component')) {
    const idx = args.indexOf('--component');
    const componentId = args[idx + 1];
    result = calculateComponentScore(componentId, days);
    name = `component-${componentId}`;
  } else {
    // Default: session score
    result = calculateSessionScore(days);
    name = 'session';
  }

  if (saveOutput) {
    const filepath = saveScore(result, name);
    console.log(`Score saved to: ${filepath}`);
  }

  if (jsonOutput) {
    console.log(JSON.stringify(result, null, 2));
  } else {
    printScoreCard(result);
  }
}

// Export for module use
module.exports = {
  calculateComponentScore,
  calculateSessionScore,
  getGrade,
  COMPONENT_WEIGHTS,
  GRADE_THRESHOLDS
};

// Run if called directly
if (require.main === module) {
  main();
}
