/**
 * Session Start Hook
 *
 * Auto-loads context when Claude Code starts:
 * - Current git branch and uncommitted changes count
 * - Session state (truncated to 2000 chars)
 * - Current priorities (truncated to 1500 chars)
 * - AIfred baseline status check
 *
 * Priority: HIGH (Context Loading)
 * Created: 2026-01-06
 * Source: AIfred baseline af66364 (implemented for Jarvis)
 */

const fs = require('fs').promises;
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const WORKSPACE_ROOT = '/Users/aircannon/Claude/Jarvis';
const SESSION_STATE_PATH = path.join(WORKSPACE_ROOT, '.claude/context/session-state.md');
const PRIORITIES_PATH = path.join(WORKSPACE_ROOT, '.claude/context/projects/current-priorities.md');
const AIFRED_BASELINE = '/Users/aircannon/Claude/AIfred';

const SESSION_STATE_MAX_CHARS = 2000;
const PRIORITIES_MAX_CHARS = 1500;

/**
 * Truncate text to max chars, preserving complete lines
 */
function truncateText(text, maxChars) {
  if (text.length <= maxChars) return text;

  // Find last newline before maxChars
  const truncated = text.substring(0, maxChars);
  const lastNewline = truncated.lastIndexOf('\n');

  if (lastNewline > maxChars * 0.5) {
    return truncated.substring(0, lastNewline) + '\n\n[... truncated ...]';
  }
  return truncated + '\n\n[... truncated ...]';
}

/**
 * Get git branch and status info
 */
function getGitInfo() {
  try {
    const branch = execSync('git rev-parse --abbrev-ref HEAD', {
      cwd: WORKSPACE_ROOT,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe']
    }).trim();

    const statusOutput = execSync('git status --porcelain', {
      cwd: WORKSPACE_ROOT,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe']
    }).trim();

    const uncommittedCount = statusOutput ? statusOutput.split('\n').length : 0;

    return {
      branch,
      uncommittedCount,
      status: uncommittedCount === 0 ? 'clean' : `${uncommittedCount} uncommitted changes`
    };
  } catch (err) {
    return {
      branch: 'unknown',
      uncommittedCount: 0,
      status: 'git info unavailable'
    };
  }
}

/**
 * Check AIfred baseline status
 */
function checkBaselineStatus() {
  try {
    // Fetch latest from origin
    execSync('git fetch origin', {
      cwd: AIFRED_BASELINE,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe']
    });

    // Check if behind
    const behindCount = execSync('git rev-list HEAD..origin/main --count', {
      cwd: AIFRED_BASELINE,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe']
    }).trim();

    const count = parseInt(behindCount, 10);
    if (count > 0) {
      return `⚠️ ${count} commit(s) behind → run /sync-aifred-baseline`;
    }
    return '✅ Up to date';
  } catch (err) {
    return '❓ Unable to check (network or path issue)';
  }
}

/**
 * Read file safely
 */
async function readFileSafe(filePath, maxChars) {
  try {
    const content = await fs.readFile(filePath, 'utf8');
    return truncateText(content, maxChars);
  } catch (err) {
    return `[Unable to read: ${err.message}]`;
  }
}

/**
 * Format the context injection message
 */
function formatContextMessage(gitInfo, sessionState, priorities, baselineStatus) {
  const lines = [
    '',
    '╔══════════════════════════════════════════════════════════════╗',
    '║                    JARVIS SESSION START                      ║',
    '╚══════════════════════════════════════════════════════════════╝',
    '',
    `📍 Branch: ${gitInfo.branch} (${gitInfo.status})`,
    `📦 AIfred Baseline: ${baselineStatus}`,
    '',
    '─────────────────── Session State ───────────────────',
    '',
    sessionState,
    '',
    '─────────────────── Current Priorities ───────────────────',
    '',
    priorities,
    '',
    '══════════════════════════════════════════════════════════════',
    ''
  ];

  return lines.join('\n');
}

module.exports = {
  name: 'session-start',
  description: 'Auto-load context when Claude Code starts',
  event: 'SessionStart',

  async handler(context) {
    try {
      // Gather all context in parallel
      const [sessionState, priorities] = await Promise.all([
        readFileSafe(SESSION_STATE_PATH, SESSION_STATE_MAX_CHARS),
        readFileSafe(PRIORITIES_PATH, PRIORITIES_MAX_CHARS)
      ]);

      const gitInfo = getGitInfo();
      const baselineStatus = checkBaselineStatus();

      // Output the context
      const message = formatContextMessage(gitInfo, sessionState, priorities, baselineStatus);
      console.log(message);

    } catch (err) {
      console.log(`[session-start] Error loading context: ${err.message}`);
    }

    return { proceed: true };
  }
};
