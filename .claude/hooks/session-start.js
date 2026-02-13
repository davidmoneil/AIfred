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
 * Get Claude Code CLI version
 */
async function getClaudeCodeVersion() {
  try {
    const { execFile } = require('child_process');
    const { promisify } = require('util');
    const execFileAsync = promisify(execFile);

    const { stdout } = await execFileAsync('claude', ['--version'], {
      timeout: 5000
    });
    // Output is like "2.1.39 (Claude Code)" — extract the version number
    const match = stdout.trim().match(/^([\d.]+)/);
    return match ? match[1] : null;
  } catch {
    return null;
  }
}

/**
 * Get AIfred version from VERSION file (single source of truth)
 */
async function getAifredVersion() {
  try {
    const versionPath = path.join(PROJECT_ROOT, 'VERSION');
    const content = await fs.readFile(versionPath, 'utf8');
    const version = content.trim();
    return version || null;
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
 * Check AIfred update cache for session notification.
 * Reads .aifred-check-result.json (written by aifred-update.sh check).
 * Returns a notification string or null.
 */
async function checkAifredUpdates() {
  try {
    // Check if notifications are disabled
    const manifestPath = path.join(PROJECT_ROOT, '.aifred.yaml');
    const manifest = await fs.readFile(manifestPath, 'utf8');
    if (/^notify:\s*false/m.test(manifest)) {
      return null;
    }

    const cachePath = path.join(PROJECT_ROOT, '.aifred-check-result.json');
    const content = await fs.readFile(cachePath, 'utf8');
    const cache = JSON.parse(content);

    const checkedAt = new Date(cache.checked_at);
    const now = new Date();
    const daysAgo = Math.floor((now - checkedAt) / (1000 * 60 * 60 * 24));

    if (cache.update_count > 0) {
      const staleNote = daysAgo > 7 ? ` (checked ${daysAgo}d ago)` : '';
      return `\u26A1 ${cache.update_count} AIfred update(s) available (${cache.local_version} \u2192 ${cache.upstream_version})${staleNote} \u2014 run /stay-current update`;
    }

    if (daysAgo > 14) {
      return `\u23F0 Last AIfred update check was ${daysAgo} days ago \u2014 run /stay-current check`;
    }

    return null; // All current, stay quiet
  } catch {
    // No cache file or manifest — check if manifest exists to distinguish init vs not-yet
    try {
      await fs.access(path.join(PROJECT_ROOT, '.aifred.yaml'));
      // Manifest exists but no cache — suggest a check
      return '\u2139\uFE0F AIfred update tracking initialized but never checked \u2014 run /stay-current check';
    } catch {
      return null; // No manifest — update system not initialized, stay silent
    }
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
      // Load versions and git status in parallel
      const [claudeVersion, aifredVersion, branch, changes] = await Promise.all([
        getClaudeCodeVersion(),
        getAifredVersion(),
        getGitBranch(),
        getGitChanges()
      ]);

      // Version banner
      const ccLabel = claudeVersion ? `Claude Code v${claudeVersion}` : 'Claude Code';
      const afLabel = aifredVersion ? `AIfred v${aifredVersion}` : 'AIfred';
      contextParts.push(`${ccLabel}  |  ${afLabel}`);

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

      // Check for AIfred upstream updates
      const updateNotice = await checkAifredUpdates();
      if (updateNotice) {
        contextParts.push(updateNotice);
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
