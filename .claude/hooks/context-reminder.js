/**
 * Context Reminder Hook
 *
 * Prompts for documentation updates after significant discoveries.
 *
 * Created: AIfred v1.0
 */

// Track discoveries that might need documentation
const DISCOVERY_PATTERNS = {
  'docker inspect': 'Docker service details discovered',
  'docker logs': 'Service logs reviewed',
  'systemctl status': 'System service checked',
  'cat /etc': 'Configuration file read'
};

// Cooldown to avoid spamming (5 minutes)
let lastReminder = 0;
const COOLDOWN_MS = 5 * 60 * 1000;

module.exports = {
  name: 'context-reminder',
  description: 'Prompt for documentation after discoveries',
  event: 'PostToolUse',

  async handler(context) {
    const { tool, parameters } = context;

    if (tool !== 'Bash') return { proceed: true };

    const command = parameters?.command || '';
    const now = Date.now();

    // Check if command matches discovery patterns
    for (const [pattern, description] of Object.entries(DISCOVERY_PATTERNS)) {
      if (command.includes(pattern)) {
        // Check cooldown
        if (now - lastReminder < COOLDOWN_MS) {
          return { proceed: true };
        }

        lastReminder = now;

        console.log(`\n💡 ${description}`);
        console.log('   Consider updating context files if you learned something new.');
        console.log('   Use /discover <service> to auto-document.\n');

        break;
      }
    }

    return { proceed: true };
  }
};
