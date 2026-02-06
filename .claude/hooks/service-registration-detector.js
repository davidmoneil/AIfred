#!/usr/bin/env node
/**
 * Service Registration Detector Hook
 *
 * Detects when new docker-compose files or services are created/modified
 * and suggests registering them in the service registry.
 *
 * Profile: homelab
 * Event: PostToolUse (*)
 * Priority: OPTIONAL
 * Created: 2026-01-19
 * Adapted for AIfred: 2026-02-05 (generalized paths)
 */

const fs = require('fs');
const path = require('path');

const PROJECT_DIR = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const REGISTRY_FILE = path.join(PROJECT_DIR, '.claude', 'context', 'registries', 'service-registry.yaml');
const COOLDOWN_FILE = path.join(PROJECT_DIR, '.claude', 'logs', '.service-registration-cooldown.json');
const COOLDOWN_HOURS = 24;

const SERVICE_PATTERNS = {
  composeFiles: /docker-compose(\.[\w-]+)?\.ya?ml$/,
  dockerRun: /docker\s+run\s+.*--name\s+(\S+)/,
  composeUp: /docker[-\s]compose\s+.*up/,
};

function loadCooldown() {
  try {
    if (fs.existsSync(COOLDOWN_FILE)) {
      return JSON.parse(fs.readFileSync(COOLDOWN_FILE, 'utf8'));
    }
  } catch { /* ignore */ }
  return { suggestions: {} };
}

function saveCooldown(state) {
  try {
    const dir = path.dirname(COOLDOWN_FILE);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(COOLDOWN_FILE, JSON.stringify(state, null, 2));
  } catch { /* ignore */ }
}

function isInCooldown(filePath, state) {
  const lastSuggested = state.suggestions[filePath];
  if (!lastSuggested) return false;
  return (Date.now() - lastSuggested) / (1000 * 60 * 60) < COOLDOWN_HOURS;
}

function isServiceRegistered(serviceName) {
  try {
    if (!fs.existsSync(REGISTRY_FILE)) return false;
    const content = fs.readFileSync(REGISTRY_FILE, 'utf8');
    const serviceId = serviceName.toLowerCase().replace(/\s+/g, '-');
    return content.includes(`${serviceId}:`) || content.includes(`container_name: ${serviceName}`);
  } catch { return false; }
}

function getServiceNameFromPath(filePath) {
  const dir = path.dirname(filePath);
  const dirName = path.basename(dir);
  if (dir.includes('docker')) return dirName;
  const fileName = path.basename(filePath);
  const match = fileName.match(/docker-compose(?:\.([^.]+))?\.ya?ml$/);
  if (match && match[1]) return match[1];
  return dirName;
}

function getContainerFromDockerRun(command) {
  const match = command.match(/--name\s+["']?(\S+?)["']?(?:\s|$)/);
  return match ? match[1] : null;
}

async function main() {
  let input = '';
  for await (const chunk of process.stdin) input += chunk;
  const context = JSON.parse(input);

  const { tool_name, tool_input } = context;

  let serviceName = null;
  let filePath = null;
  let registrationCommand = null;

  // Check for Write/Edit to docker-compose files
  if ((tool_name === 'Write' || tool_name === 'Edit') && tool_input?.file_path) {
    filePath = tool_input.file_path;
    if (SERVICE_PATTERNS.composeFiles.test(filePath)) {
      serviceName = getServiceNameFromPath(filePath);
      registrationCommand = `/register-service ${filePath}`;
    }
  }

  // Check for Bash commands that create services
  if (tool_name === 'Bash' && tool_input?.command) {
    const command = tool_input.command;
    if (SERVICE_PATTERNS.dockerRun.test(command)) {
      const containerName = getContainerFromDockerRun(command);
      if (containerName) {
        serviceName = containerName;
        registrationCommand = `/register-service --container ${containerName}`;
        filePath = `container:${containerName}`;
      }
    }
    if (SERVICE_PATTERNS.composeUp.test(command)) {
      const fileMatch = command.match(/-f\s+["']?(\S+?)["']?(?:\s|$)/);
      if (fileMatch) {
        filePath = fileMatch[1];
        serviceName = getServiceNameFromPath(filePath);
        registrationCommand = `/register-service ${filePath}`;
      }
    }
  }

  if (serviceName && registrationCommand) {
    if (isServiceRegistered(serviceName)) {
      console.log(JSON.stringify({}));
      return;
    }

    const cooldownState = loadCooldown();
    if (isInCooldown(filePath, cooldownState)) {
      console.log(JSON.stringify({}));
      return;
    }

    cooldownState.suggestions[filePath] = Date.now();
    saveCooldown(cooldownState);

    const suggestion = `New service detected: ${serviceName}. Register with: ${registrationCommand}`;
    console.error(`\n[service-registration-detector] ${suggestion}\n`);

    console.log(JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'ServiceRegistrationDetector',
        additionalContext: suggestion
      }
    }));
    return;
  }

  console.log(JSON.stringify({}));
}

main().catch(err => {
  console.error(`[service-registration-detector] Fatal: ${err.message}`);
  console.log(JSON.stringify({}));
});
