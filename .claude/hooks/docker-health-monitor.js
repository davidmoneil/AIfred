/**
 * Docker Health Monitor Hook
 *
 * Monitors Docker service health and alerts on degradation:
 * - Tracks container health status changes
 * - Alerts on unhealthy containers
 * - Provides quick diagnostics
 *
 * Priority: LOW (Workflow Enhancement)
 * Ported from: AIfred baseline (health-monitor.js, 2025-12-06)
 * Renamed for: Jarvis v2.1.0 (2026-01-22) - docker-* prefix for clarity
 */

const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);

// Track known container states
const containerStates = new Map();

// Check interval (don't check too frequently)
let lastCheck = 0;
const CHECK_INTERVAL = 30000; // 30 seconds

// Critical containers that should always be healthy
// Can be customized via environment variable CRITICAL_CONTAINERS (comma-separated)
// Default: Common infrastructure services
const CRITICAL_CONTAINERS = process.env.CRITICAL_CONTAINERS
  ? process.env.CRITICAL_CONTAINERS.split(',').map(s => s.trim())
  : [
      'caddy',
      'n8n',
      'loki',
      'grafana',
      'promtail'
    ];

/**
 * Get all container health status
 */
async function getContainerHealth() {
  try {
    const { stdout } = await execAsync(
      'docker ps --format "{{.Names}}|{{.Status}}|{{.State}}" 2>/dev/null'
    );

    const containers = {};
    stdout.trim().split('\n').filter(l => l).forEach(line => {
      const [name, status, state] = line.split('|');
      containers[name] = {
        status,
        state,
        healthy: !status.toLowerCase().includes('unhealthy'),
        running: state === 'running'
      };
    });

    return containers;
  } catch {
    return {};
  }
}

/**
 * Compare with previous state and find changes
 */
function findStateChanges(current) {
  const changes = [];

  // Check for degraded containers
  for (const [name, info] of Object.entries(current)) {
    const previous = containerStates.get(name);

    if (previous) {
      // Container was healthy, now unhealthy
      if (previous.healthy && !info.healthy) {
        changes.push({
          container: name,
          type: 'degraded',
          message: `${name} became unhealthy`
        });
      }

      // Container was running, now stopped
      if (previous.running && !info.running) {
        changes.push({
          container: name,
          type: 'stopped',
          message: `${name} stopped unexpectedly`
        });
      }

      // Container recovered
      if (!previous.healthy && info.healthy) {
        changes.push({
          container: name,
          type: 'recovered',
          message: `${name} is now healthy`
        });
      }
    }

    // Update state
    containerStates.set(name, info);
  }

  // Check for missing containers
  for (const [name] of containerStates) {
    if (!(name in current) && CRITICAL_CONTAINERS.includes(name)) {
      changes.push({
        container: name,
        type: 'missing',
        message: `${name} is no longer running`
      });
    }
  }

  return changes;
}

/**
 * Check for unhealthy critical containers
 */
function findUnhealthyCritical(current) {
  return CRITICAL_CONTAINERS.filter(name => {
    const info = current[name];
    return info && (!info.healthy || !info.running);
  });
}

/**
 * Format health alert
 */
function formatAlert(changes, unhealthyCritical) {
  const lines = ['\n[docker-health-monitor] CONTAINER HEALTH ALERT'];
  lines.push('-'.repeat(50));

  if (changes.length > 0) {
    lines.push('\nState Changes:');
    changes.forEach(c => {
      const icon = c.type === 'recovered' ? '[OK]' :
                   c.type === 'degraded' ? '[WARN]' :
                   c.type === 'stopped' ? '[STOP]' : '[?]';
      lines.push(`  ${icon} ${c.message}`);
    });
  }

  if (unhealthyCritical.length > 0) {
    lines.push('\nCritical Containers Unhealthy:');
    unhealthyCritical.forEach(name => {
      lines.push(`  [X] ${name}`);
    });
  }

  lines.push('\nQuick Diagnostics:');
  lines.push('  docker ps -a | grep -E "unhealthy|exited"');
  lines.push('  docker logs <container> --tail 50');
  lines.push('-'.repeat(50) + '\n');

  return lines.join('\n');
}

/**
 * Handler function for docker health monitor
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
    const current = await getContainerHealth();

    // First run - just populate state
    if (containerStates.size === 0) {
      for (const [name, info] of Object.entries(current)) {
        containerStates.set(name, info);
      }
      return { proceed: true };
    }

    // Find changes
    const changes = findStateChanges(current);
    const unhealthyCritical = findUnhealthyCritical(current);

    // Only alert on significant changes
    const significantChanges = changes.filter(c =>
      c.type !== 'recovered' || CRITICAL_CONTAINERS.includes(c.container)
    );

    if (significantChanges.length > 0 || unhealthyCritical.length > 0) {
      console.error(formatAlert(significantChanges, unhealthyCritical));
    }

  } catch (err) {
    // Silent failure - don't interrupt workflow
  }

  return { proceed: true };
}

// Export for require() usage
module.exports = {
  name: 'docker-health-monitor',
  description: 'Monitor Docker service health and alert on degradation',
  event: 'PostToolUse',
  handler
};

// Export helpers for external use
module.exports.getContainerStates = () => Object.fromEntries(containerStates);
module.exports.checkNow = getContainerHealth;
module.exports.resetStates = () => containerStates.clear();

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
      console.error(`[docker-health-monitor] Parse error: ${err.message}`);
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
