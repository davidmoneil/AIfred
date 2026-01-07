/**
 * Session Start Hook
 *
 * Automatically loads context when Claude Code starts a new session.
 * Injects session-state.md and current-priorities.md content so Claude
 * immediately knows what was being worked on.
 *
 * Created: 2026-01-03
 * Source: hooks-mastery research project
 */

const fs = require('fs').promises;
const path = require('path');

// Context files to auto-load on session start
const CONTEXT_FILES = [
  { path: '.claude/context/session-state.md', maxChars: 2000, label: 'Session State' },
  { path: '.claude/context/projects/current-priorities.md', maxChars: 1500, label: 'Current Priorities' }
];

// Project root (where .claude folder lives)
const PROJECT_ROOT = path.join(__dirname, '..', '..');

/**
 * Read a file safely, returning null if not found
 */
async function readFileSafe(filePath, maxChars) {
  try {
    const fullPath = path.join(PROJECT_ROOT, filePath);
    const content = await fs.readFile(fullPath, 'utf8');

    // Truncate if too long
    if (content.length > maxChars) {
      return content.substring(0, maxChars) + '\n\n...[truncated for context]';
    }
    return content;
  } catch {
    return null;
  }
}

/**
 * Get current git branch
 */
async function getGitBranch() {
  try {
    const { execFile } = require('child_process');
    const { promisify } = require('util');
    const execFileAsync = promisify(execFile);

    const { stdout } = await execFileAsync('git', ['branch', '--show-current'], {
      cwd: PROJECT_ROOT,
      timeout: 5000
    });
    return stdout.trim();
  } catch {
    return null;
  }
}

/**
 * Get count of uncommitted changes
 */
async function getGitChanges() {
  try {
    const { execFile } = require('child_process');
    const { promisify } = require('util');
    const execFileAsync = promisify(execFile);

    const { stdout } = await execFileAsync('git', ['status', '--porcelain'], {
      cwd: PROJECT_ROOT,
      timeout: 5000
    });
    const lines = stdout.trim().split('\n').filter(l => l.length > 0);
    return lines.length;
  } catch {
    return 0;
  }
}

/**
 * SessionStart Hook - Auto-loads context on session start
 */
module.exports = {
  name: 'session-start',
  description: 'Auto-load session context when Claude Code starts',
  event: 'SessionStart',

  async handler(context) {
    const contextParts = [];

    try {
      // Load git status
      const [branch, changes] = await Promise.all([
        getGitBranch(),
        getGitChanges()
      ]);

      if (branch) {
        const changeText = changes > 0 ? `, ${changes} uncommitted changes` : '';
        contextParts.push(`📍 Branch: ${branch}${changeText}`);
      }

      // Load context files
      for (const file of CONTEXT_FILES) {
        const content = await readFileSafe(file.path, file.maxChars);
        if (content) {
          contextParts.push(`\n--- ${file.label} ---\n${content}`);
        }
      }

      // Add session start marker
      contextParts.push('\n--- Session Started ---');
      contextParts.push(`Time: ${new Date().toLocaleString()}`);

    } catch (err) {
      // Don't fail session start on context loading errors
      console.error(`[session-start] Context loading error: ${err.message}`);
    }

    // Return context to inject into session
    if (contextParts.length > 0) {
      return {
        hookSpecificOutput: {
          hookEventName: 'SessionStart',
          additionalContext: contextParts.join('\n')
        }
      };
    }

    return {};
  }
};
