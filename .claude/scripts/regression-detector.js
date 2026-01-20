#!/usr/bin/env node
/**
 * Regression Detector - PR-13.5
 *
 * Detects performance regressions by comparing current metrics against baselines.
 * Supports baseline, statistical, trend, and composite detection.
 *
 * Usage:
 *   node regression-detector.js --check
 *   node regression-detector.js --baseline --save
 *   node regression-detector.js --trend --days 30
 */

const fs = require('fs');
const path = require('path');

const CONFIG = {
  baselineDir: path.join(__dirname, '..', 'metrics', 'baselines'),
  benchmarksDir: path.join(__dirname, '..', 'metrics', 'benchmarks'),
  scoresDir: path.join(__dirname, '..', 'metrics', 'scores'),
  thresholds: {
    score_drop: 10,        // Alert if score drops more than 10%
    test_failure: 1,       // Alert on any test failure
    trend_decline: 3       // Alert if 3+ consecutive declines
  }
};

/**
 * Ensure directories exist
 */
function ensureDirs() {
  if (!fs.existsSync(CONFIG.baselineDir)) {
    fs.mkdirSync(CONFIG.baselineDir, { recursive: true });
  }
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
 * Load baseline
 */
function loadBaseline() {
  const baselinePath = path.join(CONFIG.baselineDir, 'current-baseline.json');
  if (!fs.existsSync(baselinePath)) return null;

  try {
    return JSON.parse(fs.readFileSync(baselinePath, 'utf8'));
  } catch {
    return null;
  }
}

/**
 * Save baseline
 */
function saveBaseline(benchmark) {
  ensureDirs();

  const baseline = {
    created: new Date().toISOString(),
    source: 'benchmark',
    components: {},
    summary: benchmark.summary
  };

  for (const comp of benchmark.components) {
    baseline.components[comp.component] = {
      pass_rate: comp.summary.total > 0
        ? comp.summary.passed / comp.summary.total
        : 0,
      test_count: comp.summary.total
    };
  }

  const baselinePath = path.join(CONFIG.baselineDir, 'current-baseline.json');
  fs.writeFileSync(baselinePath, JSON.stringify(baseline, null, 2));

  // Also save dated copy
  const datedPath = path.join(CONFIG.baselineDir, `baseline-${new Date().toISOString().split('T')[0]}.json`);
  fs.writeFileSync(datedPath, JSON.stringify(baseline, null, 2));

  return baselinePath;
}

/**
 * Compare current to baseline
 */
function compareToBaseline(current, baseline) {
  const regressions = [];
  const improvements = [];

  // Compare summary
  const currentPassRate = current.summary.total_tests > 0
    ? current.summary.passed_tests / current.summary.total_tests
    : 0;
  const baselinePassRate = baseline.summary.total_tests > 0
    ? baseline.summary.passed_tests / baseline.summary.total_tests
    : 0;

  const overallDiff = (currentPassRate - baselinePassRate) * 100;

  if (overallDiff < -CONFIG.thresholds.score_drop) {
    regressions.push({
      type: 'overall',
      message: `Overall pass rate dropped by ${Math.abs(overallDiff).toFixed(1)}%`,
      severity: 'high',
      current: currentPassRate * 100,
      baseline: baselinePassRate * 100
    });
  } else if (overallDiff > CONFIG.thresholds.score_drop) {
    improvements.push({
      type: 'overall',
      message: `Overall pass rate improved by ${overallDiff.toFixed(1)}%`,
      current: currentPassRate * 100,
      baseline: baselinePassRate * 100
    });
  }

  // Compare components
  for (const comp of current.components) {
    const baselineComp = baseline.components[comp.component];
    if (!baselineComp) continue;

    const currentRate = comp.summary.total > 0
      ? comp.summary.passed / comp.summary.total
      : 0;
    const baseRate = baselineComp.pass_rate;

    const diff = (currentRate - baseRate) * 100;

    if (diff < -CONFIG.thresholds.score_drop) {
      regressions.push({
        type: 'component',
        component: comp.component,
        message: `${comp.component} pass rate dropped by ${Math.abs(diff).toFixed(1)}%`,
        severity: 'medium',
        current: currentRate * 100,
        baseline: baseRate * 100
      });
    }

    // Check for new test failures
    if (comp.summary.failed > 0 && baselineComp.pass_rate === 1) {
      regressions.push({
        type: 'test_failure',
        component: comp.component,
        message: `${comp.component} has ${comp.summary.failed} failing test(s) (was passing)`,
        severity: 'high'
      });
    }
  }

  return { regressions, improvements };
}

/**
 * Load historical scores for trend analysis
 */
function loadScoreHistory(days = 30) {
  if (!fs.existsSync(CONFIG.scoresDir)) return [];

  const files = fs.readdirSync(CONFIG.scoresDir)
    .filter(f => f.startsWith('session-'))
    .sort()
    .slice(-days);

  const history = [];
  for (const file of files) {
    try {
      const content = JSON.parse(fs.readFileSync(path.join(CONFIG.scoresDir, file), 'utf8'));
      history.push({
        date: file.match(/session-(\d{4}-\d{2}-\d{2})/)?.[1] || 'unknown',
        score: content.summary?.average_score || 0,
        grade: content.summary?.grade || 'N/A'
      });
    } catch {
      // Skip invalid files
    }
  }

  return history;
}

/**
 * Detect trend-based regressions
 */
function detectTrendRegressions(history) {
  const regressions = [];

  if (history.length < 3) {
    return { regressions, message: 'Insufficient history for trend analysis' };
  }

  // Check for consecutive declines
  let declineCount = 0;
  for (let i = 1; i < history.length; i++) {
    if (history[i].score < history[i - 1].score) {
      declineCount++;
    } else {
      declineCount = 0;
    }
  }

  if (declineCount >= CONFIG.thresholds.trend_decline) {
    regressions.push({
      type: 'trend',
      message: `Score has declined for ${declineCount} consecutive measurements`,
      severity: 'medium',
      trend: history.slice(-5).map(h => ({ date: h.date, score: h.score }))
    });
  }

  // Check for significant drop from peak
  const maxScore = Math.max(...history.map(h => h.score));
  const currentScore = history[history.length - 1]?.score || 0;
  const dropFromPeak = maxScore - currentScore;

  if (dropFromPeak > CONFIG.thresholds.score_drop * 2) {
    regressions.push({
      type: 'peak_drop',
      message: `Score is ${dropFromPeak.toFixed(1)}% below peak`,
      severity: 'low',
      peak: maxScore,
      current: currentScore
    });
  }

  return { regressions };
}

/**
 * Run full regression check
 */
function runRegressionCheck() {
  const result = {
    timestamp: new Date().toISOString(),
    status: 'ok',
    regressions: [],
    improvements: [],
    summary: {}
  };

  // Load current benchmark
  const current = loadLatestBenchmark();
  if (!current) {
    result.status = 'no_data';
    result.message = 'No benchmark data available. Run benchmarks first.';
    return result;
  }

  // Compare to baseline
  const baseline = loadBaseline();
  if (baseline) {
    const comparison = compareToBaseline(current, baseline);
    result.regressions.push(...comparison.regressions);
    result.improvements.push(...comparison.improvements);
  } else {
    result.summary.baseline = 'No baseline available. Consider running --baseline --save';
  }

  // Trend analysis
  const history = loadScoreHistory(30);
  const trendResult = detectTrendRegressions(history);
  result.regressions.push(...trendResult.regressions);

  // Set overall status
  if (result.regressions.length > 0) {
    const hasHigh = result.regressions.some(r => r.severity === 'high');
    result.status = hasHigh ? 'regression' : 'warning';
  }

  result.summary = {
    regressions_found: result.regressions.length,
    improvements_found: result.improvements.length,
    history_days: history.length,
    baseline_available: !!baseline
  };

  return result;
}

/**
 * Print regression report
 */
function printReport(result) {
  console.log('\n' + '='.repeat(60));
  console.log('REGRESSION DETECTION REPORT');
  console.log('='.repeat(60));

  const statusEmoji = {
    ok: '✅',
    warning: '⚠️',
    regression: '🔴',
    no_data: '❓'
  };

  console.log(`\nStatus: ${statusEmoji[result.status]} ${result.status.toUpperCase()}`);
  console.log(`Timestamp: ${result.timestamp}`);

  if (result.message) {
    console.log(`\n${result.message}`);
  }

  if (result.regressions.length > 0) {
    console.log('\nRegressions Detected:');
    for (const reg of result.regressions) {
      const severity = { high: '🔴', medium: '🟡', low: '🟢' }[reg.severity] || '⚪';
      console.log(`  ${severity} ${reg.message}`);
    }
  }

  if (result.improvements.length > 0) {
    console.log('\nImprovements:');
    for (const imp of result.improvements) {
      console.log(`  ✅ ${imp.message}`);
    }
  }

  if (result.summary.baseline_available === false) {
    console.log('\nTip: Run with --baseline --save to establish a baseline');
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
Regression Detector

Usage:
  node regression-detector.js [options]

Options:
  --check              Run full regression check (default)
  --baseline           Show current baseline
  --baseline --save    Save current benchmark as new baseline
  --trend              Analyze score trends
  --days <n>           Days of history for trend (default: 30)
  --json               Output as JSON
  --help               Show this help

Examples:
  node regression-detector.js --check
  node regression-detector.js --baseline --save
  node regression-detector.js --trend --days 14
`);
    process.exit(0);
  }

  const jsonOutput = args.includes('--json');

  if (args.includes('--baseline')) {
    if (args.includes('--save')) {
      const benchmark = loadLatestBenchmark();
      if (benchmark) {
        const path = saveBaseline(benchmark);
        console.log(`Baseline saved to: ${path}`);
      } else {
        console.log('No benchmark data available. Run benchmarks first.');
      }
    } else {
      const baseline = loadBaseline();
      if (baseline) {
        console.log(JSON.stringify(baseline, null, 2));
      } else {
        console.log('No baseline available.');
      }
    }
    return;
  }

  if (args.includes('--trend')) {
    let days = 30;
    const daysIdx = args.indexOf('--days');
    if (daysIdx !== -1) {
      days = parseInt(args[daysIdx + 1], 10) || 30;
    }

    const history = loadScoreHistory(days);
    const trendResult = detectTrendRegressions(history);

    if (jsonOutput) {
      console.log(JSON.stringify({ history, ...trendResult }, null, 2));
    } else {
      console.log('\nScore History:');
      for (const h of history) {
        console.log(`  ${h.date}: ${h.score.toFixed(1)}% (${h.grade})`);
      }
      if (trendResult.regressions.length > 0) {
        console.log('\nTrend Issues:');
        for (const r of trendResult.regressions) {
          console.log(`  ⚠️ ${r.message}`);
        }
      }
    }
    return;
  }

  // Default: run check
  const result = runRegressionCheck();

  if (jsonOutput) {
    console.log(JSON.stringify(result, null, 2));
  } else {
    printReport(result);
  }

  // Exit with error if regressions found
  process.exit(result.status === 'regression' ? 1 : 0);
}

// Export for module use
module.exports = {
  runRegressionCheck,
  compareToBaseline,
  detectTrendRegressions,
  saveBaseline,
  loadBaseline,
  loadScoreHistory
};

// Run if called directly
if (require.main === module) {
  main();
}
