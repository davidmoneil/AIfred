#!/usr/bin/env node
/**
 * Port Conflict Detector Hook
 *
 * Checks for port conflicts before starting containers:
 * - Detects if port is already in use
 * - Shows which process/container is using the port
 * - Prevents failed deployments due to port conflicts
 *
 * Profile: homelab
 * Event: PreToolUse (Bash)
 * Priority: RECOMMENDED
 * Created: 2025-12-06
 * Adapted for AIfred: 2026-02-05
 */

const { execFile } = require('child_process');
const util = require('util');
const execFileAsync = util.promisify(execFile);
const fs = require('fs').promises;

function extractPortsFromRun(command) {
  const ports = [];
  const portPattern = /-p\s+(?:[\d.]+:)?(\d+)(?::\d+)?/gi;
  let match;
  while ((match = portPattern.exec(command)) !== null) {
    ports.push(parseInt(match[1]));
  }
  return ports;
}

async function extractPortsFromCompose(composePath) {
  const ports = [];
  try {
    const content = await fs.readFile(composePath, 'utf-8');
    const portPattern = /["']?(\d+)(?::\d+)?["']?/g;
    const portsSection = content.match(/ports:\s*\n((?:\s+-[^\n]+\n?)+)/g);
    if (portsSection) {
      portsSection.forEach(section => {
        let match;
        while ((match = portPattern.exec(section)) !== null) {
          const port = parseInt(match[1]);
          if (port > 0 && port < 65536) ports.push(port);
        }
      });
    }
  } catch { /* file not readable */ }
  return [...new Set(ports)];
}

async function checkPort(port) {
  try {
    const { stdout } = await execFileAsync('ss', ['-tlnp', `sport = :${port}`]);
    if (stdout.includes(`:${port}`)) {
      const lines = stdout.trim().split('\n').slice(1);
      if (lines.length > 0) {
        const processMatch = lines[0].match(/users:\(\("([^"]+)",/);
        return { inUse: true, process: processMatch ? processMatch[1] : 'unknown' };
      }
    }
  } catch { /* ss not available or failed */ }
  return { inUse: false };
}

async function checkDockerPort(port) {
  try {
    const { stdout } = await execFileAsync('docker', ['ps', '--format', '{{.Names}}', '--filter', `publish=${port}`]);
    if (stdout.trim()) return { inUse: true, container: stdout.trim().split('\n')[0] };
  } catch { /* Docker check failed */ }
  return { inUse: false };
}

async function main() {
  let input = '';
  for await (const chunk of process.stdin) input += chunk;
  const context = JSON.parse(input);

  const { tool_name, tool_input } = context;
  if (tool_name !== 'Bash') {
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  const command = tool_input?.command || '';

  // Check for docker run with ports
  if (command.includes('docker run') && command.includes('-p')) {
    const ports = extractPortsFromRun(command);
    if (ports.length > 0) {
      console.error('\n[port-conflict-detector] Checking port availability...');
      const conflicts = [];
      for (const port of ports) {
        const portStatus = await checkPort(port);
        const dockerStatus = await checkDockerPort(port);
        if (portStatus.inUse) conflicts.push({ port, process: portStatus.process });
        else if (dockerStatus.inUse) conflicts.push({ port, container: dockerStatus.container });
      }
      if (conflicts.length > 0) {
        console.error('  PORT CONFLICTS DETECTED:');
        conflicts.forEach(c => {
          if (c.container) console.error(`    Port ${c.port} used by container: ${c.container}`);
          else console.error(`    Port ${c.port} used by process: ${c.process}`);
        });
        console.log(JSON.stringify({ proceed: false, reason: `Port conflict: ${conflicts.map(c => c.port).join(', ')}` }));
        return;
      }
      console.error('  All ports available\n');
    }
  }

  // Check for docker-compose up
  const composeMatch = command.match(/docker(?:-compose| compose)\s+(?:-f\s+["']?([^"'\s]+)["']?\s+)?up/i);
  if (composeMatch) {
    const composePath = composeMatch[1] || 'docker-compose.yml';
    const ports = await extractPortsFromCompose(composePath);
    if (ports.length > 0) {
      console.error('\n[port-conflict-detector] Checking compose ports...');
      const conflicts = [];
      for (const port of ports) {
        const portStatus = await checkPort(port);
        if (portStatus.inUse) {
          const dockerStatus = await checkDockerPort(port);
          if (!dockerStatus.inUse) conflicts.push({ port, process: portStatus.process });
        }
      }
      if (conflicts.length > 0) {
        console.error('  POTENTIAL PORT CONFLICTS:');
        conflicts.forEach(c => console.error(`    Port ${c.port} may be used by: ${c.process}`));
      } else {
        console.error(`  Checked ${ports.length} ports - no conflicts\n`);
      }
    }
  }

  console.log(JSON.stringify({ proceed: true }));
}

main().catch(err => {
  console.error(`[port-conflict-detector] Fatal: ${err.message}`);
  console.log(JSON.stringify({ proceed: true }));
});
