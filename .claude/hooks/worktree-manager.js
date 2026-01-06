/**
 * Worktree Manager Hook
 *
 * Tracks git worktree context:
 * - Detects if working in a worktree vs main repo
 * - Warns about cross-worktree file access
 * - Logs state to .claude/logs/.worktree-state.json
 *
 * Priority: LOW (Context Tracking)
 * Created: 2026-01-06
 * Source: AIfred baseline af66364 (implemented for Jarvis)
 */

const fs = require('fs').promises;
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const WORKSPACE_ROOT = '/Users/aircannon/Claude/Jarvis';
const STATE_FILE = path.join(WORKSPACE_ROOT, '.claude/logs/.worktree-state.json');

/**
 * Detect if current directory is a worktree
 */
function detectWorktree(cwd) {
  try {
    // git rev-parse --git-common-dir returns the main .git dir
    const commonDir = execSync('git rev-parse --git-common-dir', {
      cwd,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe']
    }).trim();

    // git rev-parse --git-dir returns the worktree-specific .git dir
    const gitDir = execSync('git rev-parse --git-dir', {
      cwd,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe']
    }).trim();

    // If they differ, we're in a worktree
    const isWorktree = path.resolve(cwd, commonDir) !== path.resolve(cwd, gitDir);

    // Get worktree list
    const worktreeList = execSync('git worktree list --porcelain', {
      cwd,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe']
    });

    const worktrees = worktreeList
      .split('\n\n')
      .filter(Boolean)
      .map(block => {
        const lines = block.split('\n');
        const worktreePath = lines.find(l => l.startsWith('worktree '))?.replace('worktree ', '');
        const branch = lines.find(l => l.startsWith('branch '))?.replace('branch refs/heads/', '');
        return { path: worktreePath, branch };
      })
      .filter(w => w.path);

    return {
      isWorktree,
      commonDir: path.resolve(cwd, commonDir),
      gitDir: path.resolve(cwd, gitDir),
      worktrees
    };
  } catch (err) {
    return {
      isWorktree: false,
      error: err.message
    };
  }
}

/**
 * Check if file path is in a different worktree
 */
function isInDifferentWorktree(filePath, currentWorktree, worktrees) {
  const absPath = path.resolve(filePath);

  for (const wt of worktrees) {
    if (wt.path !== currentWorktree && absPath.startsWith(wt.path)) {
      return wt;
    }
  }

  return null;
}

/**
 * Load state
 */
async function loadState() {
  try {
    const content = await fs.readFile(STATE_FILE, 'utf8');
    return JSON.parse(content);
  } catch {
    return { initialized: false };
  }
}

/**
 * Save state
 */
async function saveState(state) {
  try {
    const dir = path.dirname(STATE_FILE);
    await fs.mkdir(dir, { recursive: true });
    await fs.writeFile(STATE_FILE, JSON.stringify(state, null, 2));
  } catch (err) {
    // Silent failure
  }
}

module.exports = {
  name: 'worktree-manager',
  description: 'Track git worktree context and warn about cross-worktree access',
  event: 'PostToolUse',

  async handler(context) {
    const { tool, parameters } = context;

    // Only check file operations
    const fileTools = ['Read', 'Write', 'Edit', 'Glob', 'Grep'];
    if (!fileTools.includes(tool)) {
      return { proceed: true };
    }

    // Get file path from parameters
    const filePath = parameters?.file_path || parameters?.path;
    if (!filePath) {
      return { proceed: true };
    }

    try {
      // Load current state
      let state = await loadState();

      // Detect worktree info if not initialized
      if (!state.initialized) {
        const worktreeInfo = detectWorktree(WORKSPACE_ROOT);
        state = {
          initialized: true,
          timestamp: new Date().toISOString(),
          ...worktreeInfo
        };
        await saveState(state);

        // Show initial context if in a worktree
        if (state.isWorktree) {
          console.log(`[worktree-manager] Working in git worktree`);
          console.log(`  Main repo: ${state.commonDir}`);
          console.log(`  Worktrees: ${state.worktrees.length}`);
        }
      }

      // Check for cross-worktree access
      if (state.worktrees && state.worktrees.length > 1) {
        const differentWorktree = isInDifferentWorktree(
          filePath,
          WORKSPACE_ROOT,
          state.worktrees
        );

        if (differentWorktree) {
          console.log('');
          console.log('[worktree-manager] ⚠️ Cross-worktree file access detected');
          console.log('─'.repeat(50));
          console.log(`  Current worktree: ${WORKSPACE_ROOT}`);
          console.log(`  Accessing file in: ${differentWorktree.path}`);
          console.log(`  Branch: ${differentWorktree.branch}`);
          console.log('');
          console.log('  This may cause confusion. Consider switching worktrees.');
          console.log('─'.repeat(50));
          console.log('');
        }
      }

    } catch (err) {
      // Silent failure - don't disrupt workflow
    }

    return { proceed: true };
  }
};
