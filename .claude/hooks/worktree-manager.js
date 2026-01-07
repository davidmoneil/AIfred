/**
 * Worktree Manager Hook
 *
 * Tracks when you're in a git worktree and adjusts behavior:
 * - Detects worktree vs main repo
 * - Warns about cross-worktree file operations
 * - Tracks worktree-specific context
 *
 * Created: 2026-01-03
 * Source: my-claude-code-setup research project
 */

const { execFile } = require('child_process');
const { promisify } = require('util');
const path = require('path');
const fs = require('fs').promises;

const execFileAsync = promisify(execFile);

// Project root
const PROJECT_ROOT = path.join(__dirname, '..', '..');
const LOG_DIR = path.join(__dirname, '..', 'logs');
const WORKTREE_STATE_FILE = path.join(LOG_DIR, '.worktree-state.json');

/**
 * Check if current directory is a git worktree
 */
async function getWorktreeInfo() {
  try {
    // Get git toplevel
    const { stdout: toplevel } = await execFileAsync('git', ['rev-parse', '--show-toplevel'], {
      cwd: PROJECT_ROOT,
      timeout: 5000
    });

    // Get git common dir (shared .git for worktrees)
    const { stdout: commonDir } = await execFileAsync('git', ['rev-parse', '--git-common-dir'], {
      cwd: PROJECT_ROOT,
      timeout: 5000
    });

    // Get current branch
    const { stdout: branch } = await execFileAsync('git', ['branch', '--show-current'], {
      cwd: PROJECT_ROOT,
      timeout: 5000
    });

    const toplevelPath = toplevel.trim();
    const commonDirPath = commonDir.trim();
    const isWorktree = !commonDirPath.endsWith('.git');

    return {
      isWorktree,
      toplevel: toplevelPath,
      commonDir: commonDirPath,
      branch: branch.trim(),
      mainRepo: isWorktree ? path.dirname(commonDirPath) : toplevelPath
    };
  } catch {
    return null;
  }
}

/**
 * List all worktrees for the repo
 */
async function listWorktrees() {
  try {
    const { stdout } = await execFileAsync('git', ['worktree', 'list', '--porcelain'], {
      cwd: PROJECT_ROOT,
      timeout: 5000
    });

    const worktrees = [];
    let current = {};

    for (const line of stdout.split('\n')) {
      if (line.startsWith('worktree ')) {
        if (current.path) worktrees.push(current);
        current = { path: line.substring(9) };
      } else if (line.startsWith('HEAD ')) {
        current.head = line.substring(5);
      } else if (line.startsWith('branch ')) {
        current.branch = line.substring(7).replace('refs/heads/', '');
      } else if (line === 'bare') {
        current.bare = true;
      }
    }
    if (current.path) worktrees.push(current);

    return worktrees;
  } catch {
    return [];
  }
}

/**
 * Save worktree state for context
 */
async function saveWorktreeState(info, worktrees) {
  try {
    await fs.mkdir(LOG_DIR, { recursive: true });

    const state = {
      timestamp: new Date().toISOString(),
      current: info,
      allWorktrees: worktrees
    };

    await fs.writeFile(WORKTREE_STATE_FILE, JSON.stringify(state, null, 2));
  } catch (err) {
    console.error(`[worktree-manager] Failed to save state: ${err.message}`);
  }
}

/**
 * Check if a file operation targets a different worktree
 */
function checkCrossWorktreeAccess(filePath, currentWorktree, allWorktrees) {
  if (!filePath || !currentWorktree) return null;

  const absolutePath = path.isAbsolute(filePath)
    ? filePath
    : path.join(PROJECT_ROOT, filePath);

  for (const wt of allWorktrees) {
    if (wt.path === currentWorktree.toplevel) continue; // Skip current

    if (absolutePath.startsWith(wt.path)) {
      return {
        targetWorktree: wt.path,
        targetBranch: wt.branch,
        warning: `File is in worktree '${wt.branch}', not current worktree '${currentWorktree.branch}'`
      };
    }
  }

  return null;
}

/**
 * PostToolUse Hook - Worktree awareness
 */
module.exports = {
  name: 'worktree-manager',
  description: 'Track git worktree context and warn about cross-worktree access',
  event: 'PostToolUse',

  async handler(context) {
    const { tool, parameters, result } = context;

    // Only check file operations
    const fileTools = ['Read', 'Write', 'Edit', 'Glob', 'Grep'];
    if (!fileTools.includes(tool)) {
      return { proceed: true };
    }

    try {
      // Get worktree info
      const info = await getWorktreeInfo();
      if (!info) {
        return { proceed: true }; // Not a git repo
      }

      // Get all worktrees
      const worktrees = await listWorktrees();

      // Save state for other hooks/commands
      await saveWorktreeState(info, worktrees);

      // Check for cross-worktree access
      const filePath = parameters?.file_path || parameters?.path || parameters?.pattern;
      if (filePath) {
        const crossAccess = checkCrossWorktreeAccess(filePath, info, worktrees);

        if (crossAccess) {
          console.log(`[worktree-manager] ⚠️ ${crossAccess.warning}`);

          // Return warning context
          return {
            proceed: true,
            hookSpecificOutput: {
              warning: crossAccess.warning,
              currentBranch: info.branch,
              targetBranch: crossAccess.targetBranch
            }
          };
        }
      }

      // If in a worktree, add context
      if (info.isWorktree && worktrees.length > 1) {
        const otherWorktrees = worktrees
          .filter(wt => wt.path !== info.toplevel)
          .map(wt => wt.branch)
          .join(', ');

        // Only log occasionally to avoid spam
        const now = Date.now();
        const lastLog = global._worktreeLastLog || 0;
        if (now - lastLog > 300000) { // 5 minutes
          console.log(`[worktree-manager] 📍 In worktree: ${info.branch} (other: ${otherWorktrees})`);
          global._worktreeLastLog = now;
        }
      }

    } catch (err) {
      console.error(`[worktree-manager] Error: ${err.message}`);
    }

    return { proceed: true };
  }
};
