/**
 * Milestone Detector Hook (AC-03)
 *
 * Detects when PR/milestone work is complete and prompts for review.
 *
 * Fires on: PostToolUse (TodoWrite tracking)
 *
 * Features:
 * - Monitors TodoWrite for task completion
 * - Detects PR milestone patterns in task descriptions
 * - Prompts user for review when milestone appears complete
 * - Updates AC-03-review.json state file
 * - Emits telemetry events for monitoring
 *
 * Created: 2026-01-17
 * Updated: 2026-01-19 (telemetry integration)
 * PR Reference: PR-12.3, PR-13.1
 */

const fs = require('fs').promises;
const path = require('path');

// Telemetry integration
let telemetry;
try {
  telemetry = require('./telemetry-emitter');
} catch {
  telemetry = {
    emit: () => ({ success: false }),
    lifecycle: { start: () => {}, end: () => {}, error: () => {} }
  };
}

// Configuration
const WORKSPACE_ROOT = '/Users/aircannon/Claude/Jarvis';
const STATE_DIR = path.join(WORKSPACE_ROOT, '.claude/state/components');
const LOG_DIR = path.join(WORKSPACE_ROOT, '.claude/logs');
const STATE_FILE = path.join(STATE_DIR, 'AC-03-review.json');
const WIGGUM_STATE_FILE = path.join(STATE_DIR, 'AC-02-wiggum.json');

// Milestone detection patterns
const MILESTONE_PATTERNS = [
  /PR[-\s]?\d+/i,           // PR-11, PR 12
  /milestone/i,              // milestone
  /phase[-\s]?\d+/i,         // Phase 6, Phase-5
  /release[-\s]?v?\d+/i,     // Release v2.1.0
  /complete.*PR/i,           // complete PR
  /finish.*feature/i,        // finish feature
  /implement.*system/i,      // implement system
];

// Detect if task description matches milestone patterns
function isMilestoneTask(description) {
  if (!description) return false;
  return MILESTONE_PATTERNS.some(pattern => pattern.test(description));
}

// Load AC-03 state
async function loadState() {
  try {
    const content = await fs.readFile(STATE_FILE, 'utf8');
    return JSON.parse(content);
  } catch {
    return {
      "$schema": "review-state-v1",
      "component_id": "AC-03",
      "version": "1.0.0",
      "status": "idle",
      "last_updated": new Date().toISOString(),
      "pending_review": null,
      "review_history": [],
      "metrics": {
        "total_reviews": 0,
        "approved": 0,
        "conditional": 0,
        "rejected": 0
      }
    };
  }
}

// Load Wiggum Loop state to check task info
async function loadWiggumState() {
  try {
    const content = await fs.readFile(WIGGUM_STATE_FILE, 'utf8');
    return JSON.parse(content);
  } catch {
    return null;
  }
}

// Save state
async function saveState(state) {
  await fs.mkdir(STATE_DIR, { recursive: true });
  state.last_updated = new Date().toISOString();
  await fs.writeFile(STATE_FILE, JSON.stringify(state, null, 2));
}

/**
 * Handle PostToolUse - detect milestone completion
 */
async function handler(context) {
  const { tool, tool_input } = context;

  // Only care about TodoWrite calls
  if (tool !== 'TodoWrite') {
    return { proceed: true };
  }

  // Check environment
  const envDisabled = process.env.JARVIS_DISABLE_AC03 === 'true';
  const quickMode = process.env.JARVIS_QUICK_MODE === 'true';

  if (envDisabled || quickMode) {
    return { proceed: true };
  }

  try {
    const state = await loadState();
    const wiggumState = await loadWiggumState();
    const timestamp = new Date().toISOString();

    // Get task info from Wiggum state
    const taskDescription = wiggumState?.current_loop?.task_description || '';

    // Check if this looks like a milestone task
    const isMilestone = isMilestoneTask(taskDescription);

    // Parse todos
    const todos = tool_input?.todos || [];
    const completed = todos.filter(t => t.status === 'completed').length;
    const total = todos.length;
    const allComplete = total > 0 && completed === total;

    // If all todos complete AND this is a milestone task AND no pending review
    if (allComplete && isMilestone && !state.pending_review) {
      // Set up pending review
      state.status = 'pending';
      state.pending_review = {
        task_id: wiggumState?.current_loop?.task_id || `task-${Date.now()}`,
        task_description: taskDescription,
        detected_at: timestamp,
        todos_completed: completed,
        milestone_indicators: MILESTONE_PATTERNS
          .filter(p => p.test(taskDescription))
          .map(p => p.source)
      };

      await saveState(state);

      // Emit telemetry event
      telemetry.emit('AC-03', 'milestone_detected', {
        task_id: state.pending_review.task_id,
        task_description: taskDescription.slice(0, 100),
        todos_completed: completed,
        milestone_indicators: state.pending_review.milestone_indicators
      });

      // Log
      await fs.appendFile(
        path.join(LOG_DIR, 'milestone-detector.log'),
        `${timestamp} | MILESTONE_DETECTED | task="${taskDescription.slice(0, 100)}" | todos=${completed}\n`
      );

      // Return prompt for user
      return {
        proceed: true,
        hookSpecificOutput: {
          hookEventName: 'PostToolUse',
          milestoneDetected: true,
          message: `[AC-03] Milestone completion detected: "${taskDescription.slice(0, 80)}..." — Review recommended. Run /design-review when ready.`
        }
      };
    }

    // If all todos complete but not a milestone, just note it
    if (allComplete && !isMilestone) {
      await fs.appendFile(
        path.join(LOG_DIR, 'milestone-detector.log'),
        `${timestamp} | TASK_COMPLETE | non-milestone | task="${taskDescription.slice(0, 100)}"\n`
      );
    }

  } catch (err) {
    console.error(`[milestone-detector] Error: ${err.message}`);
  }

  return { proceed: true };
}

// Export for require() usage
module.exports = {
  name: 'milestone-detector',
  description: 'Detect milestone completion for AC-03 review trigger',
  event: 'PostToolUse',
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
      console.error(`[milestone-detector] Parse error: ${err.message}`);
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
