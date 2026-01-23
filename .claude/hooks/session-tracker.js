#!/usr/bin/env node
/**
 * Session Tracker Hook
 *
 * Tracks session lifecycle events (start, stop, errors, notifications).
 * Records events to audit log for analysis and self-reflection input.
 *
 * Data stored in: .claude/logs/session-events.jsonl
 *
 * Ported from AIfred baseline: 2026-01-23
 * Original: AIfred v1.0
 *
 * Event: Notification
 * Triggers: On system notifications
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const WORKSPACE_ROOT = '/Users/aircannon/Claude/Jarvis';
const LOG_DIR = path.join(WORKSPACE_ROOT, '.claude/logs');
const LOG_FILE = path.join(LOG_DIR, 'session-events.jsonl');

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
async function logEvent(eventType, message, metadata = {}) {
  await ensureLogDir();

  const entry = {
    timestamp: new Date().toISOString(),
    who: 'system',
    type: 'session_event',
    event_type: eventType,
    message: message,
    ...metadata
  };

  await fs.appendFile(LOG_FILE, JSON.stringify(entry) + '\n');
}

/**
 * Main handler logic
 */
async function handleHook(context) {
  // Extract notification details
  // Context may have different structures based on notification type
  const notificationType = context.type || context.notification_type || 'unknown';
  const message = context.message || context.content || '';

  // Additional metadata we might want to capture
  const metadata = {};
  if (context.session_id) metadata.session_id = context.session_id;
  if (context.tool_name) metadata.tool_name = context.tool_name;
  if (context.error) metadata.error = context.error;

  try {
    await logEvent(notificationType, message, metadata);
  } catch (err) {
    // Silent failure - don't disrupt workflow
    // console.error(`[session-tracker] Failed to log: ${err.message}`);
  }

  return { proceed: true };
}

/**
 * Main function - reads from stdin, processes, outputs to stdout
 */
async function main() {
  // Read JSON from stdin
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const input = Buffer.concat(chunks).toString('utf8');

  let context;
  try {
    context = JSON.parse(input);
  } catch (err) {
    // If we can't parse input, just allow to proceed
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  const result = await handleHook(context);
  console.log(JSON.stringify(result));
}

main().catch(err => {
  // Silent failure - don't disrupt workflow
  console.log(JSON.stringify({ proceed: true }));
});
