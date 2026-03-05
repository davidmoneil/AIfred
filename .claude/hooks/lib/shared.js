/**
 * Shared hook utilities
 *
 * Common patterns extracted from hooks to reduce duplication.
 * Import: const { readStdin, getSessionName, ensureDir, readFileSafe, PROJECT_ROOT, LOG_DIR } = require('./lib/shared');
 */

const fs = require('fs').promises;
const path = require('path');

// Standard paths — uses $CLAUDE_PROJECT_DIR if set, else walks up to .git root
const PROJECT_ROOT = process.env.CLAUDE_PROJECT_DIR || path.join(__dirname, '..', '..', '..');
const LOG_DIR = path.join(__dirname, '..', '..', 'logs');
const SESSION_FILE = path.join(LOG_DIR, '.current-session');

/**
 * Read and parse JSON from stdin (hook input).
 * Uses the modern `for await` streaming pattern.
 */
async function readStdin() {
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const raw = Buffer.concat(chunks).toString('utf8');
  try {
    return JSON.parse(raw);
  } catch {
    return {};
  }
}

/**
 * Get current session name from .current-session file.
 * Handles both JSON format ({name, slug, started}) and plain text.
 */
async function getSessionName() {
  try {
    const content = await fs.readFile(SESSION_FILE, 'utf8');
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
 * Ensure a directory exists (recursive).
 */
async function ensureDir(dirPath) {
  try {
    await fs.mkdir(dirPath, { recursive: true });
  } catch (err) {
    if (err.code !== 'EEXIST') throw err;
  }
}

/**
 * Read a file safely with optional character limit.
 * Returns null if file doesn't exist or can't be read.
 */
async function readFileSafe(filePath, maxChars = Infinity) {
  try {
    const content = await fs.readFile(filePath, 'utf8');
    if (content.length > maxChars) {
      return content.substring(0, maxChars) + '\n...[truncated]';
    }
    return content;
  } catch {
    return null;
  }
}

/**
 * Append a JSON record to a JSONL file (atomic-ish).
 */
async function appendJsonl(filePath, record) {
  await fs.appendFile(filePath, JSON.stringify(record) + '\n');
}

/**
 * Output proceed:true (default safe exit for hooks).
 */
function proceed(extra = {}) {
  console.log(JSON.stringify({ proceed: true, ...extra }));
}

/**
 * Output proceed:false with a block message.
 */
function block(message) {
  console.log(JSON.stringify({ proceed: false, message }));
}

/**
 * Wrap a hook's main function with standard error handling.
 * On error, outputs proceed:true so hooks never break the session.
 */
function runHook(hookName, mainFn) {
  mainFn().catch(err => {
    console.error(`[${hookName}] Fatal error: ${err.message}`);
    console.log(JSON.stringify({ proceed: true }));
  });
}

module.exports = {
  PROJECT_ROOT,
  LOG_DIR,
  SESSION_FILE,
  readStdin,
  getSessionName,
  ensureDir,
  readFileSafe,
  appendJsonl,
  proceed,
  block,
  runHook,
};
