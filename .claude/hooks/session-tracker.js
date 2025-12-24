/**
 * Session Tracker Hook
 *
 * Tracks session lifecycle events (start, end, errors).
 *
 * Created: AIfred v1.0
 */

const fs = require('fs').promises;
const path = require('path');

const LOG_DIR = path.join(__dirname, '..', 'logs');
const LOG_FILE = path.join(LOG_DIR, 'audit.jsonl');

async function ensureLogDir() {
  try {
    await fs.mkdir(LOG_DIR, { recursive: true });
  } catch (err) {
    if (err.code !== 'EEXIST') throw err;
  }
}

module.exports = {
  name: 'session-tracker',
  description: 'Track session lifecycle events',
  event: 'Notification',

  async handler(context) {
    const { type, message } = context;

    try {
      await ensureLogDir();

      const entry = {
        timestamp: new Date().toISOString(),
        who: 'system',
        type: 'session_event',
        event_type: type,
        message: message
      };

      await fs.appendFile(LOG_FILE, JSON.stringify(entry) + '\n');

    } catch (err) {
      console.error(`[session-tracker] Failed to log: ${err.message}`);
    }

    return { proceed: true };
  }
};
