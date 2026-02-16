/**
 * Context Reminder Hook
 *
 * Prompts for documentation updates after significant discoveries:
 * - New service configurations
 * - Troubleshooting solutions
 * - Pattern changes
 *
 * Priority: MEDIUM (Documentation Quality)
 * Created: 2025-12-06
 */

// Track discoveries made this session (with caps to prevent memory leaks)
const MAX_SOLUTIONS = 20;
const MAX_PATTERNS = 20;  // Reserved for future pattern discovery tracking
const MAX_SERVICES = 50;

const discoveries = {
  services: new Set(),
  solutions: [],
  patterns: [],
  lastReminder: null
};

// Minimum time between reminders (5 minutes)
const REMINDER_COOLDOWN = 5 * 60 * 1000;

/**
 * Add item to capped array (circular buffer pattern)
 */
function addCapped(array, item, maxSize) {
  array.push(item);
  if (array.length > maxSize) {
    array.shift(); // Remove oldest
  }
}

// Patterns that indicate discoveries
const DISCOVERY_PATTERNS = {
  service_config: [
    /docker-compose.*(?:up|start|restart)/i,
    /docker\s+(?:run|create)\s+/i,
    /caddy.*(?:reload|restart)/i,
    /systemctl\s+(?:start|enable|restart)/i
  ],
  troubleshooting: [
    /(?:fix|fixed|solved|solution|workaround)/i,
    /(?:the\s+issue\s+was|problem\s+was|root\s+cause)/i,
    /(?:this\s+resolved|that\s+fixed)/i
  ],
  pattern_discovery: [
    /(?:I\s+found|discovered|learned|realized)/i,
    /(?:turns\s+out|actually|instead)/i,
    /(?:the\s+pattern|the\s+convention|the\s+approach)/i
  ]
};

// Map service names to context files
const SERVICE_CONTEXT_MAP = {
  'caddy': '.claude/context/systems/docker/caddy.md',
  'n8n': '.claude/context/systems/docker/n8n.md',
  'loki': '.claude/context/systems/docker/logging-stack.md',
  'grafana': '.claude/context/systems/docker/logging-stack.md',
  'promtail': '.claude/context/systems/docker/logging-stack.md',
  'openwebui': '.claude/context/systems/docker/open-webui.md',
  'open-webui': '.claude/context/systems/docker/open-webui.md',
  'homepage': '.claude/context/systems/docker/homepage.md',
  'watchtower': '.claude/context/systems/docker/watchtower.md',
  'ollama': '.claude/context/systems/docker/ollama.md',
  'neo4j': '.claude/context/systems/docker/neo4j.md',
  'misp': '.claude/context/systems/docker/misp.md',
  'postgres': '.claude/context/systems/docker/postgres-mcp.md'
};

/**
 * Extract service name from command
 */
function extractServiceName(command) {
  // Match common patterns
  const patterns = [
    /docker(?:-compose)?\s+(?:logs|restart|stop|start|up|down)\s+(?:-[a-z]+\s+)*(\S+)/i,
    /docker\s+(?:exec|attach)\s+(\S+)/i,
    /systemctl\s+\w+\s+(\S+)/i
  ];

  for (const pattern of patterns) {
    const match = command.match(pattern);
    if (match) {
      return match[1].toLowerCase().replace(/[_-].*$/, '');
    }
  }

  return null;
}

/**
 * Check if reminder should be shown
 */
function shouldShowReminder() {
  if (!discoveries.lastReminder) return true;
  return Date.now() - discoveries.lastReminder > REMINDER_COOLDOWN;
}

/**
 * Get context file for service
 */
function getContextFile(serviceName) {
  return SERVICE_CONTEXT_MAP[serviceName] || null;
}

/**
 * Format reminder message
 */
function formatReminder() {
  const lines = ['\n[context-reminder] 📝 DOCUMENTATION UPDATE SUGGESTED'];
  lines.push('─'.repeat(50));

  if (discoveries.services.size > 0) {
    lines.push('\nServices modified:');
    discoveries.services.forEach(service => {
      const contextFile = getContextFile(service);
      if (contextFile) {
        lines.push(`  • ${service} → ${contextFile}`);
      } else {
        lines.push(`  • ${service} (no context file mapped)`);
      }
    });
  }

  if (discoveries.solutions.length > 0) {
    lines.push('\nSolutions discovered:');
    discoveries.solutions.slice(-3).forEach(s => {
      lines.push(`  • ${s.substring(0, 60)}...`);
    });
  }

  lines.push('\nConsider:');
  lines.push('  1. Updating relevant context files');
  lines.push('  2. Adding to session-state.md');
  lines.push('  3. Creating session notes if significant');
  lines.push('─'.repeat(50) + '\n');

  return lines.join('\n');
}

module.exports = {
  name: 'context-reminder',
  description: 'Prompt for documentation updates after discoveries',
  event: 'PostToolUse',

  async handler(context) {
    const { tool, parameters, result } = context;

    // Track Bash commands for service discoveries
    if (tool === 'Bash') {
      const command = parameters?.command || '';

      // Check for service-related commands
      DISCOVERY_PATTERNS.service_config.forEach(pattern => {
        if (pattern.test(command)) {
          const service = extractServiceName(command);
          if (service && discoveries.services.size < MAX_SERVICES) {
            discoveries.services.add(service);
          }
        }
      });
    }

    // Check result content for troubleshooting discoveries
    if (result && typeof result === 'string') {
      DISCOVERY_PATTERNS.troubleshooting.forEach(pattern => {
        if (pattern.test(result)) {
          addCapped(discoveries.solutions, result.substring(0, 200), MAX_SOLUTIONS);
        }
      });
    }

    // Show reminder periodically if discoveries exist
    const hasDiscoveries = discoveries.services.size > 0 ||
                          discoveries.solutions.length > 0 ||
                          discoveries.patterns.length > 0;

    if (hasDiscoveries && shouldShowReminder()) {
      // Only show after significant activity (every 5 service interactions)
      if (discoveries.services.size >= 3 || discoveries.solutions.length >= 2) {
        console.log(formatReminder());
        discoveries.lastReminder = Date.now();
      }
    }

    return { proceed: true };
  }
};

// Export for external use
module.exports.getDiscoveries = () => ({ ...discoveries });
module.exports.clearDiscoveries = () => {
  discoveries.services.clear();
  discoveries.solutions = [];
  discoveries.patterns = [];
};
