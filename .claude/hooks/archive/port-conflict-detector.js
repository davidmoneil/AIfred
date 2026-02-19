/**
 * Port Conflict Detector Hook
 *
 * Checks for port conflicts before starting containers:
 * - Detects if port is already in use
 * - Shows which process/container is using the port
 * - Prevents failed deployments due to port conflicts
 *
 * Priority: MEDIUM (Infrastructure Safety)
 * Created: 2025-12-06
 */

const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);
const fs = require('fs').promises;
const path = require('path');

/**
 * Extract ports from docker run command
 */
function extractPortsFromRun(command) {
  const ports = [];
  const portPattern = /-p\s+(?:[\d.]+:)?(\d+)(?::\d+)?/gi;
  let match;

  while ((match = portPattern.exec(command)) !== null) {
    ports.push(parseInt(match[1]));
  }

  return ports;
}

/**
 * Extract ports from compose file
 */
async function extractPortsFromCompose(composePath) {
  const ports = [];

  try {
    const content = await fs.readFile(composePath, 'utf-8');

    // Match port mappings like "8080:80" or "- 8080:80"
    const portPattern = /["']?(\d+)(?::\d+)?["']?/g;
    const portsSection = content.match(/ports:\s*\n((?:\s+-[^\n]+\n?)+)/g);

    if (portsSection) {
      portsSection.forEach(section => {
        let match;
        while ((match = portPattern.exec(section)) !== null) {
          const port = parseInt(match[1]);
          if (port > 0 && port < 65536) {
            ports.push(port);
          }
        }
      });
    }
  } catch {
    // File not readable
  }

  return [...new Set(ports)];
}

/**
 * Check if port is in use
 */
async function checkPort(port) {
  try {
    // Try with ss first (faster)
    const { stdout } = await execAsync(`ss -tlnp 'sport = :${port}' 2>/dev/null`);

    if (stdout.includes(`:${port}`)) {
      // Port is in use, get process info
      const lines = stdout.trim().split('\n').slice(1);
      if (lines.length > 0) {
        const processMatch = lines[0].match(/users:\(\("([^"]+)",/);
        const process = processMatch ? processMatch[1] : 'unknown';
        return { inUse: true, process };
      }
    }
  } catch {
    // Try netstat as fallback
    try {
      const { stdout } = await execAsync(`netstat -tlnp 2>/dev/null | grep :${port}`);
      if (stdout.trim()) {
        const processMatch = stdout.match(/(\d+)\/(\S+)/);
        const process = processMatch ? processMatch[2] : 'unknown';
        return { inUse: true, process };
      }
    } catch {
      // Port check failed, assume free
    }
  }

  return { inUse: false };
}

/**
 * Check if port is used by another container
 */
async function checkDockerPort(port) {
  try {
    const { stdout } = await execAsync(
      `docker ps --format '{{.Names}}' --filter "publish=${port}" 2>/dev/null`
    );

    if (stdout.trim()) {
      return { inUse: true, container: stdout.trim().split('\n')[0] };
    }
  } catch {
    // Docker check failed
  }

  return { inUse: false };
}

module.exports = {
  name: 'port-conflict-detector',
  description: 'Check for port conflicts before starting containers',
  event: 'PreToolUse',

  async handler(context) {
    const { tool, parameters } = context;

    if (tool !== 'Bash') return { proceed: true };

    const command = parameters?.command || '';

    // Check for docker run with ports
    if (command.includes('docker run') && command.includes('-p')) {
      const ports = extractPortsFromRun(command);

      if (ports.length > 0) {
        console.log('\n[port-conflict-detector] Checking port availability...');

        const conflicts = [];

        for (const port of ports) {
          const portStatus = await checkPort(port);
          const dockerStatus = await checkDockerPort(port);

          if (portStatus.inUse) {
            conflicts.push({ port, process: portStatus.process });
          } else if (dockerStatus.inUse) {
            conflicts.push({ port, container: dockerStatus.container });
          }
        }

        if (conflicts.length > 0) {
          console.log('─'.repeat(50));
          console.log('❌ PORT CONFLICTS DETECTED:');
          conflicts.forEach(c => {
            if (c.container) {
              console.log(`  • Port ${c.port} used by container: ${c.container}`);
            } else {
              console.log(`  • Port ${c.port} used by process: ${c.process}`);
            }
          });
          console.log('─'.repeat(50));
          console.log('\nOptions:');
          console.log('  1. Stop the conflicting service/container');
          console.log('  2. Use a different port with -p NEW_PORT:CONTAINER_PORT');
          console.log('  3. Remove the port mapping if not needed\n');

          return {
            proceed: false,
            message: `Port conflict: ${conflicts.map(c => c.port).join(', ')}`
          };
        }

        console.log('✓ All ports available\n');
      }
    }

    // Check for docker-compose up
    const composeMatch = command.match(/docker(?:-compose| compose)\s+(?:-f\s+["']?([^"'\s]+)["']?\s+)?up/i);

    if (composeMatch) {
      const composePath = composeMatch[1] || 'docker-compose.yml';
      const ports = await extractPortsFromCompose(composePath);

      if (ports.length > 0) {
        console.log('\n[port-conflict-detector] Checking compose ports...');

        const conflicts = [];

        for (const port of ports) {
          const portStatus = await checkPort(port);

          if (portStatus.inUse) {
            // Check if it's the same service (would be fine)
            const dockerStatus = await checkDockerPort(port);
            if (!dockerStatus.inUse) {
              // Port used by non-Docker process
              conflicts.push({ port, process: portStatus.process });
            }
          }
        }

        if (conflicts.length > 0) {
          console.log('─'.repeat(50));
          console.log('⚠️  POTENTIAL PORT CONFLICTS:');
          conflicts.forEach(c => {
            console.log(`  • Port ${c.port} may be used by: ${c.process}`);
          });
          console.log('─'.repeat(50));
          console.log('Note: These ports are in use. Deployment may fail if not by the same service.\n');
        } else if (ports.length > 0) {
          console.log(`✓ Checked ${ports.length} ports - no conflicts\n`);
        }
      }
    }

    return { proceed: true };
  }
};
