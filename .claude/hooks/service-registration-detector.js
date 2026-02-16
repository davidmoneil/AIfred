/**
 * Service Registration Detector Hook
 *
 * Detects when new docker-compose files or services are created/modified
 * and suggests registering them in the service registry.
 *
 * Triggers:
 * - Write/Edit to docker-compose*.yml files
 * - docker run/docker-compose up commands
 * - New project directories with service patterns
 *
 * Created: 2026-01-19
 * Part of: Unified Service Monitoring System
 */

const fs = require('fs');
const path = require('path');

// Configuration
const REGISTRY_FILE = path.join(__dirname, '..', '..', '.claude', 'context', 'registries', 'service-registry.yaml');
const COOLDOWN_FILE = path.join(__dirname, '..', 'logs', '.service-registration-cooldown.json');
const COOLDOWN_HOURS = 24; // Don't suggest for same file within 24 hours

// Patterns that indicate a new service
const SERVICE_PATTERNS = {
  composeFiles: /docker-compose(\.[\w-]+)?\.ya?ml$/,
  dockerRun: /docker\s+run\s+.*--name\s+(\S+)/,
  composeUp: /docker[-\s]compose\s+.*up/,
};

/**
 * Load cooldown state
 */
function loadCooldown() {
  try {
    if (fs.existsSync(COOLDOWN_FILE)) {
      return JSON.parse(fs.readFileSync(COOLDOWN_FILE, 'utf8'));
    }
  } catch {
    // Ignore errors
  }
  return { suggestions: {} };
}

/**
 * Save cooldown state
 */
function saveCooldown(state) {
  try {
    const dir = path.dirname(COOLDOWN_FILE);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    fs.writeFileSync(COOLDOWN_FILE, JSON.stringify(state, null, 2));
  } catch {
    // Ignore errors
  }
}

/**
 * Check if file is in cooldown
 */
function isInCooldown(filePath, state) {
  const lastSuggested = state.suggestions[filePath];
  if (!lastSuggested) return false;

  const hoursSince = (Date.now() - lastSuggested) / (1000 * 60 * 60);
  return hoursSince < COOLDOWN_HOURS;
}

/**
 * Check if service is already registered
 */
function isServiceRegistered(serviceName) {
  try {
    if (!fs.existsSync(REGISTRY_FILE)) return false;

    const content = fs.readFileSync(REGISTRY_FILE, 'utf8');
    // Simple check - look for service ID in registry
    const serviceId = serviceName.toLowerCase().replace(/\s+/g, '-');
    return content.includes(`${serviceId}:`) || content.includes(`container_name: ${serviceName}`);
  } catch {
    return false;
  }
}

/**
 * Extract service name from docker-compose file path
 */
function getServiceNameFromPath(filePath) {
  const dir = path.dirname(filePath);
  const dirName = path.basename(dir);

  // If it's in /mydocker, use the subdirectory name
  if (dir.includes('mydocker') || dir.includes('docker')) {
    return dirName;
  }

  // Otherwise use the filename base
  const fileName = path.basename(filePath);
  const match = fileName.match(/docker-compose(?:\.([^.]+))?\.ya?ml$/);
  if (match && match[1]) {
    return match[1];
  }

  return dirName;
}

/**
 * Extract container name from docker run command
 */
function getContainerFromDockerRun(command) {
  const match = command.match(/--name\s+["']?(\S+?)["']?(?:\s|$)/);
  return match ? match[1] : null;
}

/**
 * PostToolUse Hook Handler
 */
module.exports = {
  name: 'service-registration-detector',
  description: 'Suggests registering new services in the monitoring registry',
  event: 'PostToolUse',

  async handler(context) {
    const { tool, parameters, result } = context;

    let suggestion = null;
    let serviceName = null;
    let filePath = null;
    let registrationCommand = null;

    // Check for Write/Edit to docker-compose files
    if ((tool === 'Write' || tool === 'Edit') && parameters?.file_path) {
      filePath = parameters.file_path;

      if (SERVICE_PATTERNS.composeFiles.test(filePath)) {
        serviceName = getServiceNameFromPath(filePath);
        registrationCommand = `/register-service ${filePath}`;
      }
    }

    // Check for Bash commands that create services
    if (tool === 'Bash' && parameters?.command) {
      const command = parameters.command;

      // docker run with --name
      if (SERVICE_PATTERNS.dockerRun.test(command)) {
        const containerName = getContainerFromDockerRun(command);
        if (containerName) {
          serviceName = containerName;
          registrationCommand = `/register-service --container ${containerName}`;
          filePath = `container:${containerName}`;
        }
      }

      // docker-compose up (might be creating new services)
      if (SERVICE_PATTERNS.composeUp.test(command)) {
        // Extract the compose file path if specified
        const fileMatch = command.match(/-f\s+["']?(\S+?)["']?(?:\s|$)/);
        if (fileMatch) {
          filePath = fileMatch[1];
          serviceName = getServiceNameFromPath(filePath);
          registrationCommand = `/register-service ${filePath}`;
        }
      }
    }

    // If we detected a potential new service
    if (serviceName && registrationCommand) {
      // Check if already registered
      if (isServiceRegistered(serviceName)) {
        return {}; // Already registered, no action needed
      }

      // Check cooldown
      const cooldownState = loadCooldown();
      if (isInCooldown(filePath, cooldownState)) {
        return {}; // Recently suggested, don't nag
      }

      // Update cooldown
      cooldownState.suggestions[filePath] = Date.now();
      saveCooldown(cooldownState);

      // Return suggestion
      suggestion = `
🔔 **New Service Detected**: ${serviceName}

This service is not registered in the service monitoring system.
Register it to enable:
- Automated health checks
- Issue detection and priority escalation
- Integration with weekly health reports

**Register now:**
\`\`\`
${registrationCommand}
\`\`\`

Or dismiss this suggestion (won't ask again for 24 hours).
`;

      return {
        hookSpecificOutput: {
          hookEventName: 'ServiceRegistrationDetector',
          additionalContext: suggestion
        }
      };
    }

    return {};
  }
};
