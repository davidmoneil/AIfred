/**
 * Context Usage Tracker Hook
 *
 * Estimates token usage per tool call and tracks cumulative session usage.
 * Creates daily summary files for analysis.
 *
 * Log location: .claude/logs/context-usage/
 *
 * Created: 2025-12-26
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const LOG_DIR = path.join(__dirname, '..', 'logs', 'context-usage');
const SESSION_FILE = path.join(__dirname, '..', 'logs', '.current-session');

// Simple token estimation (roughly 4 chars per token)
const CHARS_PER_TOKEN = 4;

// Track session stats in memory
let sessionStats = {
  startTime: new Date().toISOString(),
  toolCalls: 0,
  estimatedTokensIn: 0,
  estimatedTokensOut: 0,
  toolBreakdown: {}
};

/**
 * Estimate tokens from a string or object
 */
function estimateTokens(data) {
  if (!data) return 0;
  const str = typeof data === 'string' ? data : JSON.stringify(data);
  return Math.ceil(str.length / CHARS_PER_TOKEN);
}

/**
 * Get session name
 */
async function getSessionName() {
  try {
    const session = await fs.readFile(SESSION_FILE, 'utf8');
    return session.trim().replace(/[^a-zA-Z0-9-_]/g, '-');
  } catch {
    return 'default-session';
  }
}

/**
 * Get today's date string
 */
function getDateString() {
  return new Date().toISOString().split('T')[0];
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
 * Save current stats to file
 */
async function saveStats() {
  try {
    await ensureLogDir();
    const sessionName = await getSessionName();
    const dateStr = getDateString();
    const fileName = `${dateStr}-${sessionName}.json`;
    const filePath = path.join(LOG_DIR, fileName);

    // Update end time
    sessionStats.endTime = new Date().toISOString();
    sessionStats.sessionName = sessionName;

    // Calculate duration
    const startMs = new Date(sessionStats.startTime).getTime();
    const endMs = new Date(sessionStats.endTime).getTime();
    sessionStats.durationMinutes = Math.round((endMs - startMs) / 60000);

    await fs.writeFile(filePath, JSON.stringify(sessionStats, null, 2));
  } catch (err) {
    console.error(`[context-usage-tracker] Failed to save: ${err.message}`);
  }
}

module.exports = {
  name: 'context-usage-tracker',
  description: 'Track estimated token/context usage per session',
  event: 'PreToolUse',

  async handler(context) {
    const { tool, parameters } = context;

    try {
      // Estimate tokens for this call
      const inputTokens = estimateTokens(parameters);

      // Update session stats
      sessionStats.toolCalls++;
      sessionStats.estimatedTokensIn += inputTokens;

      // Track per-tool breakdown
      if (!sessionStats.toolBreakdown[tool]) {
        sessionStats.toolBreakdown[tool] = { calls: 0, tokens: 0 };
      }
      sessionStats.toolBreakdown[tool].calls++;
      sessionStats.toolBreakdown[tool].tokens += inputTokens;

      // Save stats every 10 calls (to avoid excessive I/O)
      if (sessionStats.toolCalls % 10 === 0) {
        await saveStats();
      }

    } catch (err) {
      // Don't block on tracking failures
      console.error(`[context-usage-tracker] Error: ${err.message}`);
    }

    return { proceed: true };
  }
};
