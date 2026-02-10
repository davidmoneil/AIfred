/**
 * Docker Post-Operation Health Hook
 *
 * Verifies container health after Docker modification commands.
 *
 * Priority: LOW (Workflow Enhancement)
 * Ported from: AIfred baseline (docker-health-check.js)
 * Renamed for: Jarvis v2.1.0 (2026-01-22) - docker-post-op-health for clarity
 */

const { execSync } = require('child_process');

// Commands that modify Docker state
const DOCKER_MODIFY_PATTERNS = [
  'docker restart',
  'docker stop',
  'docker start',
  'docker-compose up',
  'docker-compose down',
  'docker-compose restart',
  'docker compose up',
  'docker compose down',
  'docker compose restart'
];

/**
 * Extract container name from command
 */
function extractContainerName(command) {
  // Try to extract container name from command
  const parts = command.split(/\s+/);

  for (let i = 0; i < parts.length; i++) {
    if (parts[i] === 'restart' || parts[i] === 'stop' || parts[i] === 'start') {
      if (parts[i + 1] && !parts[i + 1].startsWith('-')) {
        return parts[i + 1];
      }
    }
  }

  return null;
}

/**
 * Check container health status
 */
function checkContainerHealth(containerName) {
  try {
    const status = execSync(
      `docker inspect --format='{{.State.Status}}:{{.State.Health.Status}}' ${containerName} 2>/dev/null`,
      { encoding: 'utf8' }
    ).trim();

    const [state, health] = status.split(':');

    return {
      running: state === 'running',
      healthy: health === 'healthy' || health === ''  // Empty means no healthcheck
    };
  } catch {
    return { running: false, healthy: false };
  }
}

/**
 * Handler function for post-operation health check
 */
async function handler(context) {
  const { tool, tool_input } = context;
  const parameters = tool_input || context.parameters || {};

  if (tool !== 'Bash') return { proceed: true };

  const command = parameters?.command || '';

  // Check if this is a Docker modification command
  const isDockerModify = DOCKER_MODIFY_PATTERNS.some(p => command.includes(p));
  if (!isDockerModify) return { proceed: true };

  const containerName = extractContainerName(command);
  if (!containerName) return { proceed: true };

  // Wait a moment for container to stabilize
  await new Promise(resolve => setTimeout(resolve, 2000));

  const health = checkContainerHealth(containerName);

  if (!health.running) {
    console.error(`\n[docker-post-op-health] Container '${containerName}' is not running after operation.`);
    console.error('   Check logs with: docker logs ' + containerName + '\n');
  } else if (!health.healthy) {
    console.error(`\n[docker-post-op-health] Container '${containerName}' is running but may not be healthy.`);
    console.error('   Verify with: docker inspect ' + containerName + '\n');
  } else {
    console.error(`\n[docker-post-op-health] Container '${containerName}' is running and healthy.\n`);
  }

  return { proceed: true };
}

// Export for require() usage
module.exports = {
  name: 'docker-post-op-health',
  description: 'Verify container health after Docker changes',
  event: 'PostToolUse',
  handler
};

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
      console.error(`[docker-post-op-health] Parse error: ${err.message}`);
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
