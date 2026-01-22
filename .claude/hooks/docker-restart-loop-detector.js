/**
 * Docker Restart Loop Detector Hook
 *
 * Detects containers stuck in restart loops:
 * - Monitors container restart counts
 * - Alerts when restart count is too high
 * - Provides debugging suggestions
 *
 * Priority: LOW (Workflow Enhancement)
 * Ported from: AIfred baseline (restart-loop-detector.js, 2025-12-06)
 * Renamed for: Jarvis v2.1.0 (2026-01-22) - docker-* prefix for clarity
 */

const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);

// Thresholds
const RESTART_WARNING_THRESHOLD = 3;
const RESTART_CRITICAL_THRESHOLD = 5;

// Track restart counts
const restartHistory = new Map();

// Check interval
let lastCheck = 0;
const CHECK_INTERVAL = 60000; // 1 minute

/**
 * Get container restart counts
 */
async function getRestartCounts() {
  try {
    const { stdout } = await execAsync(
      'docker inspect --format "{{.Name}}|{{.RestartCount}}|{{.State.StartedAt}}" $(docker ps -aq) 2>/dev/null'
    );

    const containers = {};
    stdout.trim().split('\n').filter(l => l).forEach(line => {
      const [name, count, startedAt] = line.split('|');
      const cleanName = name.replace(/^\//, '');
      containers[cleanName] = {
        restartCount: parseInt(count) || 0,
        startedAt: new Date(startedAt)
      };
    });

    return containers;
  } catch {
    return {};
  }
}

/**
 * Calculate restart rate (restarts per hour)
 */
function calculateRestartRate(current, previous) {
  if (!previous) return 0;

  const countDiff = current.restartCount - previous.restartCount;
  const timeDiff = Date.now() - previous.checkedAt;
  const hoursDiff = timeDiff / (1000 * 60 * 60);

  if (hoursDiff < 0.01) return 0; // Too short interval

  return countDiff / hoursDiff;
}

/**
 * Find containers with high restart counts
 */
function findProblematicContainers(current) {
  const problems = {
    critical: [],
    warning: []
  };

  for (const [name, info] of Object.entries(current)) {
    const previous = restartHistory.get(name);

    if (info.restartCount >= RESTART_CRITICAL_THRESHOLD) {
      problems.critical.push({
        name,
        restartCount: info.restartCount,
        rate: calculateRestartRate(info, previous)
      });
    } else if (info.restartCount >= RESTART_WARNING_THRESHOLD) {
      problems.warning.push({
        name,
        restartCount: info.restartCount,
        rate: calculateRestartRate(info, previous)
      });
    }

    // Update history
    restartHistory.set(name, {
      restartCount: info.restartCount,
      startedAt: info.startedAt,
      checkedAt: Date.now()
    });
  }

  return problems;
}

/**
 * Format restart loop alert
 */
function formatAlert(problems) {
  const lines = ['\n[docker-restart-loop-detector] CONTAINER RESTART ISSUES'];
  lines.push('-'.repeat(50));

  if (problems.critical.length > 0) {
    lines.push('\n[CRITICAL] High restart count:');
    problems.critical.forEach(p => {
      lines.push(`  - ${p.name}: ${p.restartCount} restarts`);
      if (p.rate > 1) {
        lines.push(`    Rate: ~${p.rate.toFixed(1)} restarts/hour`);
      }
    });
  }

  if (problems.warning.length > 0) {
    lines.push('\n[WARNING] Elevated restarts:');
    problems.warning.forEach(p => {
      lines.push(`  - ${p.name}: ${p.restartCount} restarts`);
    });
  }

  lines.push('\nDiagnostic Commands:');
  const container = (problems.critical[0] || problems.warning[0])?.name;
  if (container) {
    lines.push(`  docker logs ${container} --tail 100`);
    lines.push(`  docker inspect ${container} --format '{{.State.Error}}'`);
    lines.push(`  docker events --filter container=${container} --since 1h`);
  }

  lines.push('\nPossible Causes:');
  lines.push('  - Application crash (check logs)');
  lines.push('  - Resource exhaustion (memory, disk)');
  lines.push('  - Dependency unavailable (database, network)');
  lines.push('  - Configuration error');

  lines.push('-'.repeat(50) + '\n');

  return lines.join('\n');
}

/**
 * Handler function for restart loop detector
 */
async function handler(context) {
  const { tool, tool_input } = context;
  const parameters = tool_input || context.parameters || {};

  // Only check after Docker operations or periodically
  const command = parameters?.command || '';
  const isDockerOp = tool === 'Bash' && command.includes('docker');

  const now = Date.now();
  const shouldCheck = isDockerOp || (now - lastCheck > CHECK_INTERVAL);

  if (!shouldCheck) return { proceed: true };

  lastCheck = now;

  try {
    const current = await getRestartCounts();
    const problems = findProblematicContainers(current);

    // Only alert if there are problems
    if (problems.critical.length > 0 || problems.warning.length > 0) {
      console.error(formatAlert(problems));
    }

  } catch (err) {
    // Silent failure
  }

  return { proceed: true };
}

// Export for require() usage
module.exports = {
  name: 'docker-restart-loop-detector',
  description: 'Detect containers stuck in restart loops',
  event: 'PostToolUse',
  handler
};

// Export helpers for external use
module.exports.getRestartHistory = () => Object.fromEntries(restartHistory);
module.exports.checkNow = getRestartCounts;
module.exports.resetHistory = () => restartHistory.clear();

// ============================================================
// STDIN/STDOUT HANDLER - Required for Claude Code hooks
// ============================================================
if (require.main === module) {
  let inputData = '';

  process.stdin.setEncoding('utf8');
  process.stdin.on('data', chunk => { inputData += chunk; });
  process.stdin.on('end', async () => {
    try {
      const context = JSON.parse(inputData || '{}');
      const result = await handler(context);
      console.log(JSON.stringify(result));
    } catch (err) {
      console.error(`[docker-restart-loop-detector] Parse error: ${err.message}`);
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
