/**
 * Session Tracker Hook
 *
 * Tracks session lifecycle events and maintains session state.
 * Works with audit-logger to provide session context.
 *
 * Created: 2025-12-06
 */

const fs = require('fs').promises;
const path = require('path');

const LOG_DIR = path.join(__dirname, '..', 'logs');
const SESSION_FILE = path.join(LOG_DIR, '.current-session');
const LOG_FILE = path.join(LOG_DIR, 'audit.jsonl');

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
 * Log a session event
 */
async function logSessionEvent(eventType, details = {}) {
  try {
    await ensureLogDir();

    let sessionName = 'unknown';
    try {
      sessionName = (await fs.readFile(SESSION_FILE, 'utf8')).trim();
    } catch {}

    const entry = {
      timestamp: new Date().toISOString(),
      session: sessionName,
      who: 'system',
      type: 'session_event',
      event: eventType,
      ...details
    };

    await fs.appendFile(LOG_FILE, JSON.stringify(entry) + '\n');
  } catch (err) {
    console.error(`[session-tracker] Failed to log: ${err.message}`);
  }
}

module.exports = {
  name: 'session-tracker',
  description: 'Track session lifecycle and provide session context',
  event: 'Notification',

  async handler(context) {
    const { type, message } = context;

    switch (type) {
      case 'session_start':
        await logSessionEvent('start', { message });
        break;
      case 'session_end':
        await logSessionEvent('end', { message });
        break;
      case 'error':
        await logSessionEvent('error', { error: message });
        break;
    }

    return { proceed: true };
  }
};
