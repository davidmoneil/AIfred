#!/usr/bin/env node
/**
 * File Access Tracker Hook
 *
 * Tracks when context files are read to enable data-driven consolidation decisions.
 * Records: file path, read count, first/last access, sessions referenced.
 *
 * Data stored in: .claude/logs/file-access.json
 *
 * Priority: LOW (Background Tracking)
 * Created: 2026-01-07
 * Fixed: 2026-01-21 - Converted to stdin/stdout executable hook
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const ACCESS_LOG_FILE = path.join(__dirname, '..', 'logs', 'file-access.json');
const SESSION_FILE = path.join(__dirname, '..', 'logs', '.current-session');
const TRACKED_PATHS = [
  '.claude/context/',
  '.claude/commands/',
  '.claude/agents/',
  '.claude/skills/',
  'knowledge/',
  'paths-registry.yaml'
];

/**
 * Check if file path should be tracked
 */
function shouldTrack(filePath) {
  if (!filePath) return false;

  // Normalize path
  const normalized = filePath.replace(/\\/g, '/');

  // Check if it's in a tracked directory
  return TRACKED_PATHS.some(tracked => normalized.includes(tracked));
}

/**
 * Get relative path from hub root
 */
function getRelativePath(filePath) {
  // Get project root dynamically (hook lives at .claude/hooks/)
  const projectRoot = path.resolve(__dirname, '..', '..') + '/';
  if (filePath.startsWith(projectRoot)) {
    return filePath.substring(projectRoot.length);
  }
  return filePath;
}

/**
 * Get current session name
 */
async function getCurrentSession() {
  try {
    const content = await fs.readFile(SESSION_FILE, 'utf8');
    // Try to parse as JSON (new format)
    try {
      const parsed = JSON.parse(content);
      return parsed.name || parsed.slug || 'default-session';
    } catch {
      return content.trim() || 'default-session';
    }
  } catch {
    return 'default-session';
  }
}

/**
 * Load access log
 */
async function loadAccessLog() {
  try {
    const content = await fs.readFile(ACCESS_LOG_FILE, 'utf8');
    return JSON.parse(content);
  } catch {
    return {
      version: '1.0',
      created: new Date().toISOString(),
      last_updated: new Date().toISOString(),
      files: {},
      sessions: {}
    };
  }
}

/**
 * Save access log
 */
async function saveAccessLog(log) {
  const dir = path.dirname(ACCESS_LOG_FILE);
  try {
    await fs.mkdir(dir, { recursive: true });
  } catch (err) {
    if (err.code !== 'EEXIST') throw err;
  }

  log.last_updated = new Date().toISOString();
  await fs.writeFile(ACCESS_LOG_FILE, JSON.stringify(log, null, 2));
}

/**
 * Record a file access
 */
async function recordAccess(filePath) {
  const relativePath = getRelativePath(filePath);
  const session = await getCurrentSession();
  const today = new Date().toISOString().split('T')[0];
  const now = new Date().toISOString();

  const log = await loadAccessLog();

  // Initialize file record if needed
  if (!log.files[relativePath]) {
    log.files[relativePath] = {
      first_read: now,
      last_read: now,
      read_count: 0,
      sessions: [],
      daily_history: []
    };
  }

  const fileRecord = log.files[relativePath];
  fileRecord.last_read = now;
  fileRecord.read_count++;

  // Track unique sessions
  if (!fileRecord.sessions.includes(session)) {
    fileRecord.sessions.push(session);
    // Keep last 20 sessions
    if (fileRecord.sessions.length > 20) {
      fileRecord.sessions.shift();
    }
  }

  // Track daily history (last 30 days)
  if (!fileRecord.daily_history.includes(today)) {
    fileRecord.daily_history.push(today);
    if (fileRecord.daily_history.length > 30) {
      fileRecord.daily_history.shift();
    }
  }

  // Track session totals
  if (!log.sessions[session]) {
    log.sessions[session] = {
      started: now,
      file_reads: 0,
      unique_files: []
    };
  }
  log.sessions[session].file_reads++;
  if (!log.sessions[session].unique_files.includes(relativePath)) {
    log.sessions[session].unique_files.push(relativePath);
  }

  await saveAccessLog(log);
}

/**
 * Main handler logic
 */
async function handleHook(context) {
  const { tool_name, tool_input, tool_result } = context;

  // Only track Read tool calls
  if (tool_name !== 'Read') {
    return { proceed: true };
  }

  // Skip if read failed
  if (tool_result?.error) {
    return { proceed: true };
  }

  // Get file path from parameters
  const filePath = tool_input?.file_path;

  // Check if this file should be tracked
  if (!shouldTrack(filePath)) {
    return { proceed: true };
  }

  try {
    await recordAccess(filePath);
  } catch (err) {
    // Silent failure - don't disrupt workflow
    console.error(`[file-access-tracker] Error: ${err.message}`);
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
  console.error(`[file-access-tracker] Fatal error: ${err.message}`);
  console.log(JSON.stringify({ proceed: true }));
});
