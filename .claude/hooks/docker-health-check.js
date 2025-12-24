/**
 * Docker Health Check Hook
 *
 * Verifies container health after Docker modification commands.
 *
 * Created: AIfred v1.0
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

module.exports = {
  name: 'docker-health-check',
  description: 'Verify container health after Docker changes',
  event: 'PostToolUse',

  async handler(context) {
    const { tool, parameters } = context;

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
      console.log(`\n⚠️  Container '${containerName}' is not running after operation.`);
      console.log('   Check logs with: docker logs ' + containerName + '\n');
    } else if (!health.healthy) {
      console.log(`\n⚠️  Container '${containerName}' is running but may not be healthy.`);
      console.log('   Verify with: docker inspect ' + containerName + '\n');
    } else {
      console.log(`\n✅ Container '${containerName}' is running and healthy.\n`);
    }

    return { proceed: true };
  }
};
