/**
 * Wiggum Loop Tracker Hook (AC-02)
 *
 * Tracks the multi-pass verification loop state and provides
 * visible output about loop iterations.
 *
 * Fires on: UserPromptSubmit (task detection), PostToolUse (TodoWrite tracking)
 *
 * Features:
 * - Detects new task assignments
 * - Tracks TodoWrite calls to monitor progress
 * - Updates AC-02-wiggum.json state file
 * - Outputs pass indicators to chat
 * - Detects suppression keywords ("quick", "rough", etc.)
 *
 * Created: 2026-01-17
 * PR Reference: PR-12.2
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const WORKSPACE_ROOT = '/Users/aircannon/Claude/Jarvis';
const STATE_DIR = path.join(WORKSPACE_ROOT, '.claude/state/components');
const LOG_DIR = path.join(WORKSPACE_ROOT, '.claude/logs');
const STATE_FILE = path.join(STATE_DIR, 'AC-02-wiggum.json');
const CONFIG_FILE = path.join(WORKSPACE_ROOT, '.claude/config/autonomy-config.yaml');

// Suppression keywords
const SUPPRESSION_PHRASES = [
  'quick solution', 'rough pass', 'first pass', 'simple sketch',
  'just a draft', 'quick fix', 'rough draft', 'quick', 'simple'
];

// Detect if message contains suppression keywords
function shouldSuppress(message) {
  if (!message) return false;
  const lower = message.toLowerCase();
  return SUPPRESSION_PHRASES.some(phrase => lower.includes(phrase));
}

// Load current state
async function loadState() {
  try {
    const content = await fs.readFile(STATE_FILE, 'utf8');
    return JSON.parse(content);
  } catch {
    return {
      "$schema": "wiggum-state-v1",
      "component_id": "AC-02",
      "version": "1.0.0",
      "status": "idle",
      "last_updated": new Date().toISOString(),
      "current_loop": null,
      "passes": [],
      "todos": { total: 0, completed: 0, in_progress: 0, pending: 0 },
      "metrics": { total_token_cost: 0, total_duration_ms: 0 },
      "history": { last_completed_task: null, total_tasks_completed: 0, avg_passes_per_task: 0 }
    };
  }
}

// Save state
async function saveState(state) {
  await fs.mkdir(STATE_DIR, { recursive: true });
  state.last_updated = new Date().toISOString();
  await fs.writeFile(STATE_FILE, JSON.stringify(state, null, 2));
}

// Load max_passes from config
async function loadMaxPasses() {
  try {
    const content = await fs.readFile(CONFIG_FILE, 'utf8');
    const match = content.match(/max_passes:\s*(\d+)/);
    return match ? parseInt(match[1], 10) : 5;
  } catch {
    return 5;
  }
}

// Generate unique task ID
function generateTaskId() {
  return `task-${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
}

/**
 * Handle UserPromptSubmit - detect new tasks
 */
async function handleUserPrompt(context) {
  const { message } = context;
  const state = await loadState();
  const timestamp = new Date().toISOString();

  // Check for suppression keywords
  const suppressed = shouldSuppress(message);

  // Check environment
  const envDisabled = process.env.JARVIS_DISABLE_AC02 === 'true';
  const quickMode = process.env.JARVIS_QUICK_MODE === 'true';

  if (envDisabled) {
    return { proceed: true };
  }

  // If there's already an active loop, this is a new user message during the task
  // We'll track it as a potential scope change
  if (state.status === 'active' && state.current_loop) {
    // Log additional input during loop
    await fs.appendFile(
      path.join(LOG_DIR, 'wiggum-loop.log'),
      `${timestamp} | SCOPE_CHECK | Additional user input during task: "${message?.slice(0, 100)}..."\n`
    );
    return { proceed: true };
  }

  // Start a new loop if this looks like a task
  // (Has content, isn't just a greeting, isn't empty)
  const isGreeting = /^(hi|hello|hey|jarvis|\.)\s*$/i.test(message?.trim() || '');

  if (message && message.trim().length > 5 && !isGreeting) {
    const maxPasses = await loadMaxPasses();

    state.status = suppressed || quickMode ? 'suppressed' : 'active';
    state.current_loop = {
      task_id: generateTaskId(),
      task_description: message.slice(0, 200),
      started_at: timestamp,
      current_pass: 1,
      max_passes: maxPasses,
      suppressed: suppressed || quickMode,
      suppression_reason: suppressed ? 'keyword' : (quickMode ? 'env' : null)
    };
    state.passes = [{
      pass_number: 1,
      started_at: timestamp,
      completed_at: null,
      issues_found: 0,
      issues_fixed: 0,
      todos_snapshot: { total: 0, completed: 0 }
    }];

    await saveState(state);

    // Log
    await fs.appendFile(
      path.join(LOG_DIR, 'wiggum-loop.log'),
      `${timestamp} | LOOP_START | task_id=${state.current_loop.task_id} | suppressed=${suppressed || quickMode}\n`
    );

    // Return additionalContext to inject into conversation
    const modeLabel = (suppressed || quickMode) ? 'SINGLE-PASS (quick mode)' : 'WIGGUM LOOP Pass 1';
    return {
      proceed: true,
      hookSpecificOutput: {
        hookEventName: 'UserPromptSubmit',
        loopStatus: state.status,
        passNumber: 1,
        message: `[AC-02] ${modeLabel} — Task tracking started`
      }
    };
  }

  return { proceed: true };
}

/**
 * Handle PostToolUse - track TodoWrite calls
 */
async function handlePostToolUse(context) {
  const { tool, tool_input } = context;

  // Only care about TodoWrite calls
  if (tool !== 'TodoWrite') {
    return { proceed: true };
  }

  const state = await loadState();
  const timestamp = new Date().toISOString();

  // If no active loop, skip
  if (state.status !== 'active' || !state.current_loop) {
    return { proceed: true };
  }

  // Parse todos from input
  const todos = tool_input?.todos || [];
  const completed = todos.filter(t => t.status === 'completed').length;
  const inProgress = todos.filter(t => t.status === 'in_progress').length;
  const pending = todos.filter(t => t.status === 'pending').length;
  const total = todos.length;

  // Update state
  state.todos = { total, completed, in_progress: inProgress, pending };

  // Check if all todos are complete (potential pass completion)
  const allComplete = total > 0 && completed === total && inProgress === 0 && pending === 0;

  if (allComplete) {
    // Complete current pass
    const currentPass = state.passes[state.passes.length - 1];
    if (currentPass && !currentPass.completed_at) {
      currentPass.completed_at = timestamp;
      currentPass.todos_snapshot = { total, completed };
    }

    // Check if we should start another pass or complete
    if (state.current_loop.current_pass < state.current_loop.max_passes) {
      // Could start another pass for verification
      // But for now, mark loop as ready-to-complete
      // The actual "self-review" happens via behavioral instructions in CLAUDE.md
    }

    await fs.appendFile(
      path.join(LOG_DIR, 'wiggum-loop.log'),
      `${timestamp} | TODOS_COMPLETE | pass=${state.current_loop.current_pass} | total=${total}\n`
    );
  }

  // If task seems to be progressing, update pass
  if (state.passes.length > 0) {
    const currentPass = state.passes[state.passes.length - 1];
    currentPass.todos_snapshot = { total, completed, in_progress: inProgress, pending };
  }

  await saveState(state);

  return { proceed: true };
}

/**
 * Complete current loop (can be called when task is done)
 */
async function completeLoop() {
  const state = await loadState();
  const timestamp = new Date().toISOString();

  if (state.status !== 'active' || !state.current_loop) {
    return;
  }

  // Complete final pass
  const currentPass = state.passes[state.passes.length - 1];
  if (currentPass && !currentPass.completed_at) {
    currentPass.completed_at = timestamp;
  }

  // Update history
  state.history.total_tasks_completed += 1;
  state.history.last_completed_task = timestamp;
  if (state.passes.length > 0) {
    const totalPasses = state.history.total_tasks_completed;
    const currentAvg = state.history.avg_passes_per_task || 0;
    state.history.avg_passes_per_task =
      ((currentAvg * (totalPasses - 1)) + state.passes.length) / totalPasses;
  }

  // Mark complete
  state.status = 'completed';
  state.current_loop = null;

  await saveState(state);

  await fs.appendFile(
    path.join(LOG_DIR, 'wiggum-loop.log'),
    `${timestamp} | LOOP_COMPLETE | passes=${state.passes.length} | todos_completed=${state.todos.completed}\n`
  );
}

/**
 * Main handler - route based on hook event
 */
async function handler(context) {
  const hookEvent = context.hook_event || context.event;

  try {
    if (hookEvent === 'UserPromptSubmit') {
      return await handleUserPrompt(context);
    } else if (hookEvent === 'PostToolUse') {
      return await handlePostToolUse(context);
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
  description: 'Track Wiggum Loop state for AC-02',
  events: ['UserPromptSubmit', 'PostToolUse'],
  handler,
  completeLoop
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
