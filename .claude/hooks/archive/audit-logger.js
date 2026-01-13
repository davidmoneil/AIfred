/**
 * Audit Logger Hook
 *
 * Automatically logs all Claude Code tool executions to JSONL format.
 * Ready for log aggregation tools (Loki, ELK, etc.)
 *
 * Log location: .claude/logs/audit.jsonl
 *
 * Created: AIfred v1.0
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const LOG_DIR = path.join(__dirname, '..', 'logs');
const LOG_FILE = path.join(LOG_DIR, 'audit.jsonl');
const SESSION_FILE = path.join(LOG_DIR, '.current-session');

// Verbosity: 'minimal', 'standard', 'full'
const VERBOSITY = process.env.CLAUDE_AUDIT_VERBOSITY || 'standard';

/**
 * Get current session name
 */
async function getSessionName() {
  try {
    const session = await fs.readFile(SESSION_FILE, 'utf8');
    return session.trim();
  } catch {
    return 'default-session';
  }
}

/**
 * Ensure log directory exists
 */
async function ensureLogDir() {
  try {
    await fs.mkdir(LOG_DIR, { recursive: true });
  } catch (err) {
    if (err.code !== 'EEXIST') throw err;
  }
}

/**
 * Format parameters based on verbosity
 */
function formatParameters(params, verbosity) {
  if (!params) return undefined;

  switch (verbosity) {
    case 'minimal':
      return undefined;
    case 'standard':
      const truncated = {};
      for (const [key, value] of Object.entries(params)) {
        if (typeof value === 'string' && value.length > 200) {
          truncated[key] = value.substring(0, 200) + '...[truncated]';
        } else {
          truncated[key] = value;
        }
      }
      return truncated;
    case 'full':
      return params;
    default:
      return params;
  }
}

/**
 * PreToolUse Hook
 */
module.exports = {
  name: 'audit-logger',
  description: 'Automatic audit logging for all tool executions',
  event: 'PreToolUse',

  async handler(context) {
    const { tool, parameters } = context;

    try {
      await ensureLogDir();
      const sessionName = await getSessionName();

      const entry = {
        timestamp: new Date().toISOString(),
        session: sessionName,
        who: 'claude',
        type: 'tool_execution',
        tool: tool,
        parameters: formatParameters(parameters, VERBOSITY),
        verbosity: VERBOSITY
      };

      await fs.appendFile(LOG_FILE, JSON.stringify(entry) + '\n');

    } catch (err) {
      // Don't block on logging failures
      console.error(`[audit-logger] Failed to log: ${err.message}`);
    }

    return { proceed: true };
  }
};
