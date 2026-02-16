#!/usr/bin/env node
/**
 * Docker Health Check Hook
 *
 * After Docker service modifications (restart, stop, start, etc.),
 * automatically verifies the service came back healthy.
 *
 * Created: 2025-12-06
 * Fixed: 2026-01-21 - Converted to stdin/stdout executable hook
 */

const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);

// Docker commands that modify service state
const DOCKER_MODIFY_COMMANDS = [
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
 * Check if this is a Docker modification command
 */
function isDockerModifyCommand(tool_name, tool_input) {
  if (tool_name !== 'Bash') return false;

  const command = tool_input?.command || '';
  return DOCKER_MODIFY_COMMANDS.some(cmd => command.startsWith(cmd));
}

/**
 * Extract container name from command
 */
function extractContainerName(command) {
  // Match patterns like "docker restart container_name" or "docker-compose -f ... restart service"
  const patterns = [
    /docker (?:restart|stop|start) (\S+)/,
    /docker-compose.*(?:restart|stop|start|up|down)\s+(\S+)?/,
    /docker compose.*(?:restart|stop|start|up|down)\s+(\S+)?/
  ];

  for (const pattern of patterns) {
    const match = command.match(pattern);
    if (match && match[1]) {
      return match[1];
    }
  }
  return null;
}

// Health check configuration
const HEALTH_CHECK_CONFIG = {
  initialWait: 2000,      // Initial wait before first check (2s)
  pollInterval: 3000,     // Poll every 3 seconds
  maxWait: 30000,         // Maximum total wait time (30s)
  maxRetries: 10          // Max polling attempts
};

/**
 * Check container health with polling
 */
async function checkContainerHealth(containerName) {
  if (!containerName) return { healthy: true, message: 'No specific container to check' };

  try {
    // Initial wait for container to start
    await new Promise(resolve => setTimeout(resolve, HEALTH_CHECK_CONFIG.initialWait));

    let attempts = 0;
    let lastStatus = null;
    let lastHealth = null;
    const startTime = Date.now();

    while (attempts < HEALTH_CHECK_CONFIG.maxRetries) {
      attempts++;

      const { stdout } = await execAsync(
        `docker inspect --format='{{.State.Status}} {{.State.Health.Status}}' ${containerName} 2>/dev/null || echo "not_found"`
      );

      const output = stdout.trim();

      if (output === 'not_found') {
        return { healthy: false, message: `Container ${containerName} not found` };
      }

      const [status, health] = output.split(' ');
      lastStatus = status;
      lastHealth = health;

      // Not running - fail immediately
      if (status !== 'running') {
        return { healthy: false, message: `Container ${containerName} is ${status}` };
      }

      // No health check defined - container is running, that's good enough
      if (!health || health === '' || health === '<no value>') {
        return { healthy: true, message: `Container ${containerName} is running (no health check defined)` };
      }

      // Healthy - success
      if (health === 'healthy') {
        const elapsed = ((Date.now() - startTime) / 1000).toFixed(1);
        return { healthy: true, message: `Container ${containerName} is healthy (${elapsed}s)` };
      }

      // Starting - keep polling
      if (health === 'starting') {
        const elapsed = Date.now() - startTime;
        if (elapsed >= HEALTH_CHECK_CONFIG.maxWait) {
          return {
            healthy: false,
            message: `Container ${containerName} still starting after ${(elapsed / 1000).toFixed(1)}s`
          };
        }
        console.error(`[docker-health-check] Container ${containerName} starting... (attempt ${attempts})`);
        await new Promise(resolve => setTimeout(resolve, HEALTH_CHECK_CONFIG.pollInterval));
        continue;
      }

      // Unhealthy - fail
      if (health === 'unhealthy') {
        return { healthy: false, message: `Container ${containerName} is unhealthy` };
      }

      // Unknown state - continue polling briefly
      await new Promise(resolve => setTimeout(resolve, HEALTH_CHECK_CONFIG.pollInterval));
    }

    // Exhausted retries
    return {
      healthy: false,
      message: `Container ${containerName} health check timed out (status: ${lastStatus}, health: ${lastHealth})`
    };

  } catch (err) {
    return { healthy: false, message: `Health check failed: ${err.message}` };
  }
}

/**
 * Main handler logic
 */
async function handleHook(context) {
  const { tool_name, tool_input } = context;

  // Only run for Docker modification commands
  if (!isDockerModifyCommand(tool_name, tool_input)) {
    return { proceed: true };
  }

  const command = tool_input?.command || '';
  const containerName = extractContainerName(command);

  // Skip health check for 'down' commands
  if (command.includes('down') || command.includes('stop')) {
    console.error(`[docker-health-check] Skipping health check for stop/down command`);
    return { proceed: true };
  }

  const healthResult = await checkContainerHealth(containerName);

  if (!healthResult.healthy) {
    console.error(`[docker-health-check] WARNING: ${healthResult.message}`);
  } else {
    console.error(`[docker-health-check] ${healthResult.message}`);
  }

  return { proceed: true };
}

/**
 * Main function - reads from stdin, processes, outputs to stdout
 */
async function main() {
  // Read JSON from stdin
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const input = Buffer.concat(chunks).toString('utf8');

  let context;
  try {
    context = JSON.parse(input);
  } catch (err) {
    // If we can't parse input, just allow to proceed
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  const result = await handleHook(context);
  console.log(JSON.stringify(result));
}

main().catch(err => {
  console.error(`[docker-health-check] Fatal error: ${err.message}`);
  console.log(JSON.stringify({ proceed: true }));
});
