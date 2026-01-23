/**
 * Session Trigger Hook
 *
 * Detects special inputs that should trigger session-start protocol:
 * - Single "." character (manual session start trigger)
 * - Post-/clear resume patterns
 *
 * This ensures session-start protocols are consistently triggered
 * regardless of how a session begins or resumes.
 *
 * Version: 1.0.0
 * Created: 2026-01-23
 * Event: UserPromptSubmit
 */

const fs = require('fs');
const path = require('path');

// Patterns that trigger session-start protocol injection
const SESSION_TRIGGER_PATTERNS = [
  /^\s*\.\s*$/,                    // Single "." character
  /^resume$/i,                     // "resume" command
  /^continue$/i,                   // "continue"
  /^start\s*session$/i,            // "start session"
  /^begin$/i,                      // "begin"
];

// Patterns that indicate post-clear state
const POST_CLEAR_INDICATORS = [
  /cleared?\s*(context|conversation)/i,
  /after\s*\/clear/i,
  /resuming\s*after/i,
];

/**
 * Read session-state.md to get current work status
 */
function getSessionStatus(projectDir) {
  const statePath = path.join(projectDir, '.claude', 'context', 'session-state.md');

  if (!fs.existsSync(statePath)) {
    return { status: 'unknown', currentWork: 'none' };
  }

  try {
    const content = fs.readFileSync(statePath, 'utf8');

    // Extract status
    const statusMatch = content.match(/\*\*Status\*\*:\s*([^\n]+)/);
    const workMatch = content.match(/\*\*Current Work\*\*:\s*([^\n]+)/);
    const nextMatch = content.match(/\*\*Next Session\*\*:[\s\S]*?(?=\n---|\n##|$)/);

    return {
      status: statusMatch ? statusMatch[1].trim() : 'unknown',
      currentWork: workMatch ? workMatch[1].trim() : 'none',
      nextSteps: nextMatch ? nextMatch[0].trim() : null
    };
  } catch (err) {
    return { status: 'error', currentWork: 'none' };
  }
}

/**
 * Read current-priorities.md to get next priority
 */
function getNextPriority(projectDir) {
  const prioPath = path.join(projectDir, '.claude', 'context', 'current-priorities.md');

  if (!fs.existsSync(prioPath)) {
    return null;
  }

  try {
    const content = fs.readFileSync(prioPath, 'utf8');

    // Extract first "In Progress" item
    const inProgressMatch = content.match(/## In Progress[\s\S]*?###\s*([^\n]+)/);
    if (inProgressMatch) {
      return inProgressMatch[1].trim();
    }

    // Fall back to "Up Next"
    const upNextMatch = content.match(/## Up Next[\s\S]*?###\s*([^\n]+)/);
    if (upNextMatch) {
      return upNextMatch[1].trim();
    }

    return null;
  } catch (err) {
    return null;
  }
}

/**
 * Handler function for session trigger detection
 */
async function handler(context) {
  const { user_prompt } = context;
  const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();

  // Skip if no user prompt
  if (!user_prompt) {
    return { proceed: true };
  }

  const prompt = user_prompt.trim();

  // Check for session trigger patterns
  let shouldTrigger = false;
  for (const pattern of SESSION_TRIGGER_PATTERNS) {
    if (pattern.test(prompt)) {
      shouldTrigger = true;
      break;
    }
  }

  if (!shouldTrigger) {
    return { proceed: true };
  }

  // Get session status and priorities
  const status = getSessionStatus(projectDir);
  const nextPriority = getNextPriority(projectDir);

  // Build session-start protocol injection
  const additionalContext = `
--- SESSION START PROTOCOL TRIGGERED ---

Trigger: User input "${prompt}"

**AC-01 Self-Launch Protocol Activated**

PHASE A - GREETING:
Generate a personalized greeting using context (DO NOT use canned phrases).

PHASE B - SYSTEM REVIEW:
1. Review session-state.md: ${status.status}
2. Current work: ${status.currentWork}
3. Review current-priorities.md for next task

PHASE C - BRIEFING:
${nextPriority ? `Next Priority: ${nextPriority}` : 'Check current-priorities.md for next task'}

**AUTONOMY RULE**: NEVER simply "await instructions" - always suggest or begin work.

Reference: .claude/context/patterns/startup-protocol.md
---`;

  return {
    proceed: true,
    additionalContext
  };
}

// Export for require() usage
module.exports = {
  name: 'session-trigger',
  description: 'Detect session-start triggers like "." input',
  event: 'UserPromptSubmit',
  handler
};

// ============================================================
// STDIN/STDOUT HANDLER - Required for Claude Code hooks
// ============================================================
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
      console.error(`[session-trigger] Parse error: ${err.message}`);
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
