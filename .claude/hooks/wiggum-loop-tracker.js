/**
 * AC-02 Wiggum Loop Tracker Hook
 *
 * Lightweight observer for Ralph Loop status.
 * The actual loop mechanics are handled by ralph-stop-hook.sh.
 * This hook provides visibility and can inject loop status into responses.
 *
 * Fires on: UserPromptSubmit
 *
 * Features:
 * - Detects active Ralph loops
 * - Injects loop status into hook output
 * - Reads current iteration from state file
 *
 * Created: 2026-01-17
 * Component: AC-02 Wiggum Loop
 * PR Reference: PR-12.2 Implementation
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const WORKSPACE_ROOT = process.env.CLAUDE_PROJECT_DIR || '/Users/aircannon/Claude/Jarvis';
const STATE_FILE = path.join(WORKSPACE_ROOT, '.claude/ralph-loop.local.md');
const AC02_STATE = path.join(WORKSPACE_ROOT, '.claude/state/components/AC-02-wiggum.json');

/**
 * Parse YAML frontmatter from markdown file
 */
function parseFrontmatter(content) {
  const match = content.match(/^---\n([\s\S]*?)\n---/);
  if (!match) return null;

  const yaml = match[1];
  const result = {};

  yaml.split('\n').forEach(line => {
    const colonIndex = line.indexOf(':');
    if (colonIndex > 0) {
      const key = line.slice(0, colonIndex).trim();
      let value = line.slice(colonIndex + 1).trim();
      // Remove quotes if present
      if (value.startsWith('"') && value.endsWith('"')) {
        value = value.slice(1, -1);
      }
      // Parse numbers
      if (/^\d+$/.test(value)) {
        value = parseInt(value, 10);
      }
      result[key] = value;
    }
  });

  return result;
}

/**
 * Check if Ralph loop is active and get status
 */
async function getLoopStatus() {
  try {
    const content = await fs.readFile(STATE_FILE, 'utf8');
    const frontmatter = parseFrontmatter(content);

    if (!frontmatter || !frontmatter.active) {
      return null;
    }

    return {
      active: true,
      iteration: frontmatter.iteration || 1,
      maxIterations: frontmatter.max_iterations || 0,
      taskId: frontmatter.task_id || 'unknown',
      completionPromise: frontmatter.completion_promise !== 'null' ? frontmatter.completion_promise : null
    };
  } catch {
    return null;
  }
}

/**
 * Handle UserPromptSubmit - inject loop status if active
 */
async function handleUserPrompt(context) {
  const loopStatus = await getLoopStatus();

  if (!loopStatus) {
    // No active loop
    return { proceed: true };
  }

  // Loop is active - provide status in hook output
  const iterationInfo = loopStatus.maxIterations > 0
    ? `${loopStatus.iteration}/${loopStatus.maxIterations}`
    : `${loopStatus.iteration}`;

  const promiseInfo = loopStatus.completionPromise
    ? ` | Complete with: <promise>${loopStatus.completionPromise}</promise>`
    : '';

  return {
    proceed: true,
    hookSpecificOutput: {
      hookEventName: 'UserPromptSubmit',
      ac02Active: true,
      iteration: loopStatus.iteration,
      maxIterations: loopStatus.maxIterations,
      taskId: loopStatus.taskId,
      message: `[AC-02] Ralph Loop iteration ${iterationInfo}${promiseInfo}`
    }
  };
}

/**
 * Main handler
 */
async function handler(context) {
  const hookEvent = context.hook_event || context.event;

  try {
    if (hookEvent === 'UserPromptSubmit') {
      return await handleUserPrompt(context);
    }
  } catch (err) {
    // Log error but don't block
    console.error(`[wiggum-loop-tracker] Error: ${err.message}`);
  }

  return { proceed: true };
}

// Export for require() usage
module.exports = {
  name: 'wiggum-loop-tracker',
  description: 'Track AC-02 Ralph Loop status',
  events: ['UserPromptSubmit'],
  handler
};

// STDIN/STDOUT handler for Claude Code hooks
if (require.main === module) {
  let inputData = '';

  process.stdin.setEncoding('utf8');
  process.stdin.on('data', chunk => { inputData += chunk; });
  process.stdin.on('end', async () => {
    try {
      const context = JSON.parse(inputData || '{}');
      const result = await handler(context);
      console.log(JSON.stringify(result));
    } catch (err) {
      console.error(`[wiggum-loop-tracker] Parse error: ${err.message}`);
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
