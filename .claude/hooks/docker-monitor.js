#!/usr/bin/env node
/**
 * Docker Monitor — Consolidated PostToolUse Hook
 *
 * Merges 3 Docker monitoring hooks into one process:
 *   1. checkHealth()        — docker-health-monitor.js
 *   2. checkRestartLoops()  — docker-restart-loop-detector.js
 *   3. postOpHealthCheck()  — docker-post-op-health.js
 *
 * Key optimization: Single docker ps call shared across checks.
 * Note: Runs as ephemeral process (stdin/stdout), so in-memory state
 * tracking from originals was non-functional. This version uses
 * current-state checks only.
 *
 * Registered: PostToolUse, matcher: ^Bash$
 * Always returns { proceed: true } (monitoring only, never blocks).
 *
 * Created: 2026-02-09 (B.3 Hook Consolidation, Merge 2)
 * Source hooks: docker-health-monitor.js, docker-restart-loop-detector.js,
 *              docker-post-op-health.js
 */

const { exec, execSync } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);

// Critical containers that should always be healthy
const CRITICAL_CONTAINERS = process.env.CRITICAL_CONTAINERS
  ? process.env.CRITICAL_CONTAINERS.split(',').map(s => s.trim())
  : ['caddy', 'n8n', 'loki', 'grafana', 'promtail'];

// Restart thresholds
const RESTART_WARNING = 3;
const RESTART_CRITICAL = 5;

// Docker modification commands that trigger post-op health check
const DOCKER_MODIFY_PATTERNS = [
  'docker restart', 'docker stop', 'docker start',
  'docker-compose up', 'docker-compose down', 'docker-compose restart',
  'docker compose up', 'docker compose down', 'docker compose restart'
];

// ============================================================
// SHARED: Docker state fetcher
// ============================================================

async function getDockerState() {
  try {
    // Single docker ps call — shared data source
    const { stdout: psOutput } = await execAsync(
      'docker ps --format "{{.Names}}|{{.Status}}|{{.State}}" 2>/dev/null'
    );

    const containers = {};
    psOutput.trim().split('\n').filter(l => l).forEach(line => {
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
    return null; // Docker not available
  }
}

async function getRestartCounts() {
  try {
    const { stdout } = await execAsync(
      'docker inspect --format "{{.Name}}|{{.RestartCount}}" $(docker ps -aq) 2>/dev/null'
    );

    const counts = {};
    stdout.trim().split('\n').filter(l => l).forEach(line => {
      const [name, count] = line.split('|');
      counts[name.replace(/^\//, '')] = parseInt(count) || 0;
    });

    return counts;
  } catch {
    return {};
  }
}

// ============================================================
// CHECK 1: Health status (critical containers)
// ============================================================

function checkHealth(containers) {
  const unhealthy = CRITICAL_CONTAINERS.filter(name => {
    const info = containers[name];
    return info && (!info.healthy || !info.running);
  });

  const missing = CRITICAL_CONTAINERS.filter(name => !(name in containers));

  if (unhealthy.length > 0 || missing.length > 0) {
    const lines = ['[docker-monitor/health] Container health issues:'];
    unhealthy.forEach(name => lines.push(`  [WARN] ${name}: ${containers[name].status}`));
    missing.forEach(name => lines.push(`  [STOP] ${name}: not running`));
    console.error(lines.join('\n'));
  }
}

// ============================================================
// CHECK 2: Restart loops
// ============================================================

async function checkRestartLoops() {
  const counts = await getRestartCounts();

  const critical = [];
  const warning = [];

  for (const [name, count] of Object.entries(counts)) {
    if (count >= RESTART_CRITICAL) critical.push({ name, count });
    else if (count >= RESTART_WARNING) warning.push({ name, count });
  }

  if (critical.length > 0 || warning.length > 0) {
    const lines = ['[docker-monitor/restarts] Container restart issues:'];
    critical.forEach(c => lines.push(`  [CRITICAL] ${c.name}: ${c.count} restarts`));
    warning.forEach(w => lines.push(`  [WARNING] ${w.name}: ${w.count} restarts`));
    const sample = (critical[0] || warning[0])?.name;
    if (sample) lines.push(`  Debug: docker logs ${sample} --tail 100`);
    console.error(lines.join('\n'));
  }
}

// ============================================================
// CHECK 3: Post-operation health
// ============================================================

function extractContainerName(command) {
  const parts = command.split(/\s+/);
  for (let i = 0; i < parts.length; i++) {
    if (['restart', 'stop', 'start'].includes(parts[i])) {
      if (parts[i + 1] && !parts[i + 1].startsWith('-')) {
        return parts[i + 1];
      }
    }
  }
  return null;
}

async function postOpHealthCheck(command) {
  const isModify = DOCKER_MODIFY_PATTERNS.some(p => command.includes(p));
  if (!isModify) return;

  const containerName = extractContainerName(command);
  if (!containerName) return;

  // Wait for container to stabilize
  await new Promise(resolve => setTimeout(resolve, 2000));

  try {
    const status = execSync(
      `docker inspect --format='{{.State.Status}}:{{if .State.Health}}{{.State.Health.Status}}{{else}}none{{end}}' ${containerName} 2>/dev/null`,
      { encoding: 'utf8' }
    ).trim();

    const [state, health] = status.split(':');

    if (state !== 'running') {
      console.error(`[docker-monitor/post-op] ${containerName} is NOT running after operation`);
      console.error(`  Debug: docker logs ${containerName} --tail 50`);
    } else if (health === 'unhealthy') {
      console.error(`[docker-monitor/post-op] ${containerName} is running but UNHEALTHY`);
      console.error(`  Debug: docker inspect ${containerName}`);
    }
    // Healthy → silent (no noise)
  } catch {
    // Container might not exist (e.g., after docker stop + rm)
  }
}

// ============================================================
// MAIN HANDLER
// ============================================================

async function handler(context) {
  const { tool, tool_input } = context;
  const parameters = tool_input || context.parameters || {};

  if (tool !== 'Bash') return { proceed: true };

  const command = parameters?.command || '';
  if (!command.includes('docker')) return { proceed: true };

  try {
    // Run checks in parallel where possible
    const containers = await getDockerState();

    if (containers === null) {
      // Docker not available — skip silently
      return { proceed: true };
    }

    // Check 1: Health status (uses shared container state)
    checkHealth(containers);

    // Check 2 + 3: Run restart loop check and post-op check concurrently
    await Promise.all([
      checkRestartLoops(),
      postOpHealthCheck(command)
    ]);
  } catch {
    // Silent failure — don't interrupt workflow
  }

  return { proceed: true };
}

// Export for require() usage
module.exports = {
  name: 'docker-monitor',
  description: 'Consolidated Docker monitoring (health, restarts, post-op)',
  event: 'PostToolUse',
  handler
};

// ============================================================
// STDIN/STDOUT HANDLER — Required for Claude Code hooks
// ============================================================
if (require.main === module) {
  const chunks = [];
  process.stdin.on('data', chunk => chunks.push(chunk));
  process.stdin.on('end', async () => {
    let context;
    try {
      context = JSON.parse(Buffer.concat(chunks).toString('utf8'));
    } catch (err) {
      console.error(`[docker-monitor] Parse error: ${err.message}`);
      console.log(JSON.stringify({ proceed: true }));
      return;
    }

    try {
      const result = await handler(context);
      console.log(JSON.stringify(result));
    } catch (err) {
      console.error(`[docker-monitor] Handler error: ${err.message}`);
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
