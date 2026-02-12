#!/usr/bin/env node
/**
 * Context Usage Tracker Hook
 *
 * Estimates token usage per tool call and tracks cumulative session usage.
 * Creates daily summary files for analysis.
 *
 * Useful for non-Max users to understand context/token consumption.
 *
 * Log location: .claude/logs/context-usage/
 *
 * Created: 2025-12-26
 * Converted to stdin/stdout executable hook with file persistence
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const LOG_DIR = path.join(__dirname, '..', 'logs', 'context-usage');
const SESSION_FILE = path.join(__dirname, '..', 'logs', '.current-session');

// Simple token estimation (roughly 4 chars per token)
const CHARS_PER_TOKEN = 4;

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
 * Load or create session stats
 */
async function loadStats() {
  try {
    await fs.mkdir(LOG_DIR, { recursive: true });
    const sessionName = await getSessionName();
    const dateStr = getDateString();
    const fileName = `${dateStr}-${sessionName}.json`;
    const filePath = path.join(LOG_DIR, fileName);

    const data = await fs.readFile(filePath, 'utf8');
    return { stats: JSON.parse(data), filePath };
  } catch {
    return {
      stats: {
        startTime: new Date().toISOString(),
        toolCalls: 0,
        estimatedTokensIn: 0,
        estimatedTokensOut: 0,
        toolBreakdown: {}
      },
      filePath: null
    };
  }
}

/**
 * Save stats to file
 */
async function saveStats(stats) {
  try {
    await fs.mkdir(LOG_DIR, { recursive: true });
    const sessionName = await getSessionName();
    const dateStr = getDateString();
    const fileName = `${dateStr}-${sessionName}.json`;
    const filePath = path.join(LOG_DIR, fileName);

    stats.endTime = new Date().toISOString();
    stats.sessionName = sessionName;

    const startMs = new Date(stats.startTime).getTime();
    const endMs = new Date(stats.endTime).getTime();
    stats.durationMinutes = Math.round((endMs - startMs) / 60000);

    await fs.writeFile(filePath, JSON.stringify(stats, null, 2));
  } catch (err) {
    console.error(`[context-usage-tracker] Failed to save: ${err.message}`);
  }
}

/**
 * Main handler
 */
async function handleHook(context) {
  const { tool, parameters } = context;

  try {
    const { stats } = await loadStats();

    // Estimate tokens for this call
    const inputTokens = estimateTokens(parameters);

    // Update stats
    stats.toolCalls++;
    stats.estimatedTokensIn += inputTokens;

    // Track per-tool breakdown
    if (!stats.toolBreakdown[tool]) {
      stats.toolBreakdown[tool] = { calls: 0, tokens: 0 };
    }
    stats.toolBreakdown[tool].calls++;
    stats.toolBreakdown[tool].tokens += inputTokens;

    // Save stats every 10 calls to avoid excessive I/O
    if (stats.toolCalls % 10 === 0) {
      await saveStats(stats);
    }

  } catch (err) {
    console.error(`[context-usage-tracker] Error: ${err.message}`);
  }

  return { proceed: true };
}

/**
 * Main function - reads from stdin, processes, outputs to stdout
 */
async function main() {
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const input = Buffer.concat(chunks).toString('utf8');

  let context;
  try {
    context = JSON.parse(input);
  } catch {
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  const result = await handleHook(context);
  console.log(JSON.stringify(result));
}

main().catch(err => {
  console.error(`[context-usage-tracker] Fatal error: ${err.message}`);
  console.log(JSON.stringify({ proceed: true }));
});
