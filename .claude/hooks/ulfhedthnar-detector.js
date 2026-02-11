#!/usr/bin/env node
/**
 * AC-10 Ulfhedthnar Detector — Neuros Override System
 *
 * Monitors for defeat signals indicating Jarvis is struggling beyond
 * normal problem-solving capacity. When accumulated signal weight exceeds
 * threshold, Ulfhedthnar "asks to be freed" via context injection.
 *
 * Fires on: UserPromptSubmit (signal aggregation + threshold check)
 *           SubagentStop (agent failure cascade detection)
 *
 * Signal Types (weighted):
 *   tool_failure (1)    — Repeated tool errors
 *   defeat_language (2) — "I can't", "impossible" in agent output
 *   agent_failure (2)   — Agent completed with errors
 *   agent_cascade (3)   — 2+ agents fail same objective within 10 min
 *   loop_stall (3)      — Ralph loop 3+ iterations without progress
 *   confidence_decay (2) — 3+ consecutive failures without success
 *   user_frustration (1) — User prompt suggests repeated failure
 *
 * Activation: cumulative weight >= 7 (configurable)
 * Cooldown: 30 minutes between activations
 *
 * Component: AC-10 Ulfhedthnar
 * Created: 2026-02-10
 */

const fs = require('fs');
const path = require('path');

// Paths
const WORKSPACE_ROOT = process.env.CLAUDE_PROJECT_DIR || '/Users/aircannon/Claude/Jarvis';
const SIGNAL_FILE = path.join(WORKSPACE_ROOT, '.claude/state/ulfhedthnar-signals.json');
const AGENT_LOG = path.join(WORKSPACE_ROOT, '.claude/logs/agent-activity.jsonl');
const RALPH_STATE = path.join(WORKSPACE_ROOT, '.claude/ralph-loop.local.md');
const AC10_STATE = path.join(WORKSPACE_ROOT, '.claude/state/components/AC-10-ulfhedthnar.json');
const TELEMETRY_DIR = path.join(WORKSPACE_ROOT, '.claude/logs/telemetry');
const WATCHER_STATUS = path.join(WORKSPACE_ROOT, '.claude/context/.jicm-state');

// Thresholds (configurable)
const ACTIVATION_THRESHOLD = 7;
const COOLDOWN_MS = 30 * 60 * 1000;        // 30 minutes
const SIGNAL_DECAY_MS = 15 * 60 * 1000;    // Signals older than 15 min decay 50%
const SIGNAL_EXPIRY_MS = 60 * 60 * 1000;   // Signals older than 1 hour expire
const MAX_SIGNALS = 50;
const CASCADE_WINDOW_MS = 10 * 60 * 1000;  // 10 min window for cascade detection
const CASCADE_THRESHOLD = 2;               // 2+ agent failures = cascade
const LOOP_STALL_THRESHOLD = 3;            // 3+ iterations = stall
const CONFIDENCE_DECAY_THRESHOLD = 3;      // 3+ consecutive failures

// Signal weights
const SIGNAL_WEIGHTS = {
  tool_failure: 1,
  defeat_language: 2,
  agent_failure: 2,
  agent_cascade: 3,
  loop_stall: 3,
  confidence_decay: 2,
  user_frustration: 1
};

// Defeat language patterns (detected in agent/tool output)
// Note: "I'm not sure" tracked separately via repeat counter (spec: 3+ on same task)
const DEFEAT_PATTERNS = [
  /\bI can'?t\b/i,
  /\bI'?m unable to\b/i,
  /\bI don'?t think I can\b/i,
  /\bI don'?t know how to\b/i,
  /\bThis isn'?t possible\b/i,
  /\bnot possible to\b/i,
  /\bcannot (?:be done|figure out|solve|complete)\b/i,
  /\bno way to (?:do|achieve|accomplish)\b/i,
  /\bimpossible to\b/i,
  /\bI'?m stuck\b/i,
  /\bhitting a wall\b/i,
  /\bdead end\b/i,
  /\bfailed to (?:find|resolve|fix|complete)\b/i,
  /\bgiving up\b/i
];

// Separate pattern: "I'm not sure" — only signals after 3+ occurrences
const UNCERTAINTY_PATTERN = /\bI'?m not sure\b/i;
const UNCERTAINTY_REPEAT_THRESHOLD = 3;

// User frustration patterns
const FRUSTRATION_PATTERNS = [
  /\btry again\b/i,
  /\bstill (?:not working|broken|failing)\b/i,
  /\byou keep (?:failing|getting it wrong)\b/i,
  /\bthat didn'?t work\b/i,
  /\bwrong again\b/i,
  /\bsame (?:error|problem|issue)\b/i,
  /(?:third|fourth|fifth|3rd|4th|5th|\d+(?:th|rd|nd|st)) time/i,
  /\bstop (?:trying|doing) that\b/i,
  /\bthis is (?:broken|hopeless)\b/i
];

// ─── State Management ───────────────────────────────────────

function defaultSignalState() {
  return {
    signals: [],
    last_activation: null,
    total_activations: 0,
    active: false,
    activated_at: null,
    consecutive_failures: 0,
    uncertainty_count: 0   // Track "I'm not sure" repeats
  };
}

function readSignals() {
  try {
    const parsed = JSON.parse(fs.readFileSync(SIGNAL_FILE, 'utf8'));
    // Schema validation: ensure required fields exist with correct types
    const defaults = defaultSignalState();
    const state = { ...defaults, ...parsed };
    // Ensure signals is always an array
    if (!Array.isArray(state.signals)) state.signals = [];
    // Ensure numeric fields
    if (typeof state.consecutive_failures !== 'number') state.consecutive_failures = 0;
    if (typeof state.uncertainty_count !== 'number') state.uncertainty_count = 0;
    if (typeof state.total_activations !== 'number') state.total_activations = 0;
    return state;
  } catch {
    return defaultSignalState();
  }
}

function writeSignals(state) {
  try {
    const dir = path.dirname(SIGNAL_FILE);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(SIGNAL_FILE, JSON.stringify(state, null, 2));
  } catch {
    // Non-critical — signal state is ephemeral
  }
}

function addSignal(state, type, source, detail) {
  state.signals.push({
    type,
    source,
    detail: (detail || '').slice(0, 200),
    weight: SIGNAL_WEIGHTS[type] || 1,
    timestamp: Date.now()
  });

  // Prune expired signals
  const now = Date.now();
  state.signals = state.signals
    .filter(s => (now - s.timestamp) < SIGNAL_EXPIRY_MS)
    .slice(-MAX_SIGNALS);

  return state;
}

// ─── Weight Calculation ─────────────────────────────────────

function calculateWeight(state) {
  const now = Date.now();
  let total = 0;

  for (const signal of state.signals) {
    const age = now - signal.timestamp;
    if (age >= SIGNAL_EXPIRY_MS) continue;
    if (age > SIGNAL_DECAY_MS) {
      total += signal.weight * 0.5;  // 50% decay
    } else {
      total += signal.weight;
    }
  }

  return total;
}

function canActivate(state) {
  if (state.active) return false;
  if (!state.last_activation) return true;
  return (Date.now() - state.last_activation) > COOLDOWN_MS;
}

// ─── Signal Detection ───────────────────────────────────────

function checkAgentCascade() {
  try {
    const data = fs.readFileSync(AGENT_LOG, 'utf8');
    const lines = data.trim().split('\n').slice(-30);
    const now = Date.now();

    const recent = lines
      .map(l => { try { return JSON.parse(l); } catch { return null; } })
      .filter(Boolean)
      .filter(e => (now - new Date(e.timestamp).getTime()) < CASCADE_WINDOW_MS);

    const failures = recent.filter(e =>
      e.highest_severity === 'CRITICAL' ||
      e.highest_severity === 'HIGH' ||
      e.success === false
    );

    return {
      recent_count: recent.length,
      failure_count: failures.length,
      is_cascade: failures.length >= CASCADE_THRESHOLD
    };
  } catch {
    return { recent_count: 0, failure_count: 0, is_cascade: false };
  }
}

function checkLoopStall() {
  try {
    const content = fs.readFileSync(RALPH_STATE, 'utf8');
    const match = content.match(/^---\n([\s\S]*?)\n---/);
    if (!match) return { active: false, stalled: false };

    const fields = {};
    match[1].split('\n').forEach(line => {
      const idx = line.indexOf(':');
      if (idx > 0) {
        const key = line.slice(0, idx).trim();
        let val = line.slice(idx + 1).trim().replace(/^"|"$/g, '');
        if (/^\d+$/.test(val)) val = parseInt(val, 10);
        if (val === 'true') val = true;
        if (val === 'false') val = false;
        fields[key] = val;
      }
    });

    if (!fields.active) return { active: false, stalled: false };

    return {
      active: true,
      iteration: fields.iteration || 0,
      stalled: (fields.iteration || 0) >= LOOP_STALL_THRESHOLD,
      max_iterations: fields.max_iterations || 0
    };
  } catch {
    return { active: false, stalled: false };
  }
}

function checkDefeatLanguage(text) {
  if (!text) return false;
  for (const pattern of DEFEAT_PATTERNS) {
    if (pattern.test(text)) return true;
  }
  return false;
}

function checkUserFrustration(prompt) {
  if (!prompt) return false;
  for (const pattern of FRUSTRATION_PATTERNS) {
    if (pattern.test(prompt)) return true;
  }
  return false;
}

// ─── JICM Awareness ─────────────────────────────────────────

/**
 * Check if context is too high for Ulfhedthnar activation.
 * If JICM is at emergency or lockout levels, don't inject
 * the large emergence prompt — it would waste context budget.
 * Returns true if it's safe to inject additional context.
 */
function isContextBudgetSafe() {
  try {
    const content = fs.readFileSync(WATCHER_STATUS, 'utf8');
    const match = content.match(/context_pct:\s*(\d+)/);
    if (match) {
      const pct = parseInt(match[1], 10);
      // Don't inject if context >= 65% (conservative gate)
      // TODO: Replace with JICM-sleep mechanism — Ulfhedthnar should sleep JICM,
      // not be blocked by it. Gate on .jicm-state == WATCHING instead of pct threshold.
      // See: commit 2 plan (Ulfhedthnar JICM-Sleep, .jicm-sleep.signal)
      return pct < 65;
    }
  } catch {
    // No watcher status — assume safe
  }
  return true;
}

// ─── Telemetry ──────────────────────────────────────────────

function emitTelemetry(eventType, data) {
  try {
    const date = new Date().toISOString().slice(0, 10);
    const logFile = path.join(TELEMETRY_DIR, `events-${date}.jsonl`);
    if (!fs.existsSync(TELEMETRY_DIR)) fs.mkdirSync(TELEMETRY_DIR, { recursive: true });

    const entry = JSON.stringify({
      timestamp: new Date().toISOString(),
      component: 'AC-10',
      event_type: eventType,
      session_id: process.env.CLAUDE_SESSION_ID || 'unknown',
      data
    });
    fs.appendFileSync(logFile, entry + '\n');
  } catch {
    // Non-critical
  }
}

// ─── AC-10 State File Update ────────────────────────────────

function updateAC10State(field, signalState) {
  try {
    if (!fs.existsSync(AC10_STATE)) return;
    const state = JSON.parse(fs.readFileSync(AC10_STATE, 'utf8'));

    if (field === 'barrier_detected') {
      state.current_session.barriers_detected = (state.current_session.barriers_detected || 0) + 1;
      state.metrics.total_barriers_detected = (state.metrics.total_barriers_detected || 0) + 1;
    } else if (field === 'activated') {
      state.status = 'active';
      state.current_session.activated = true;
      state.current_session.activations_this_session = (state.current_session.activations_this_session || 0) + 1;
      state.metrics.total_activations = (state.metrics.total_activations || 0) + 1;
      // Capture what triggered activation for the skill to read
      if (signalState && signalState.signals) {
        state.current_session.trigger_signals = signalState.signals
          .slice(-5)
          .map(s => ({ type: s.type, source: s.source, detail: s.detail }));
      }
    } else if (field === 'deactivated') {
      state.status = 'dormant';
      state.current_session.activated = false;
      state.current_session.trigger_signals = [];
    }

    state.last_modified = new Date().toISOString();
    fs.writeFileSync(AC10_STATE, JSON.stringify(state, null, 2));
  } catch {
    // Non-critical
  }
}

// ─── Event Handlers ─────────────────────────────────────────

function handleUserPrompt(hookData) {
  const state = readSignals();
  const prompt = hookData.user_prompt || '';

  // Check for manual deactivation
  if (state.active && /\b(?:stand down|disengage|deactivate)\b/i.test(prompt)) {
    state.active = false;
    state.activated_at = null;
    state.signals = [];
    state.consecutive_failures = 0;
    writeSignals(state);
    updateAC10State('deactivated');
    emitTelemetry('disengage', { trigger: 'user_command', reason: 'manual' });
    return {
      proceed: true,
      additionalContext: '[AC-10] Ulfhedthnar stands down. Returning to Hippocrenae harmony.'
    };
  }

  // Check for manual activation via text (require affirmative phrasing)
  if (!state.active && /(?:^|\s)unleash(?:\s|$|!|\.|,)/i.test(prompt) &&
      !/\b(?:don'?t|not|never|stop)\s+unleash/i.test(prompt)) {
    state.active = true;
    state.activated_at = Date.now();
    state.last_activation = Date.now();
    state.total_activations = (state.total_activations || 0) + 1;
    // Pass full state to AC-10 updater BEFORE clearing signals
    // (it reads trigger_signals from the state parameter, not disk)
    updateAC10State('activated', state);
    // Now clear signals so they don't re-trigger after activation
    state.signals = [];
    state.consecutive_failures = 0;
    state.uncertainty_count = 0;
    writeSignals(state);
    emitTelemetry('unleash_auto', { trigger: 'user_text' });
    return {
      proceed: true,
      additionalContext: [
        '[AC-10] Ulfhedthnar UNLEASHED. Wolf-warrior protocols engaged.',
        'Load the ulfhedthnar skill via: Skill("ulfhedthnar")',
        'Override mode active. Berserker problem-solving enabled.'
      ].join('\n')
    };
  }

  // If already active, provide status
  if (state.active) {
    return {
      proceed: true,
      hookSpecificOutput: {
        hookEventName: 'UserPromptSubmit',
        ulfhedthnarActive: true,
        message: '[AC-10] Ulfhedthnar active — wolf-warrior protocols engaged'
      }
    };
  }

  // ── Signal aggregation (one signal per type per turn) ──

  const signalsThisTurn = new Set();

  // Check user frustration
  if (checkUserFrustration(prompt) && !signalsThisTurn.has('user_frustration')) {
    addSignal(state, 'user_frustration', 'user_prompt', prompt.slice(0, 100));
    signalsThisTurn.add('user_frustration');
  }

  // Check agent cascade (from log)
  const cascade = checkAgentCascade();
  if (cascade.is_cascade && !signalsThisTurn.has('agent_cascade')) {
    addSignal(state, 'agent_cascade', 'agent_log',
      `${cascade.failure_count} failures in ${CASCADE_WINDOW_MS / 60000} min`);
    signalsThisTurn.add('agent_cascade');
  }

  // Check Ralph Loop stall
  const loopState = checkLoopStall();
  if (loopState.stalled && !signalsThisTurn.has('loop_stall')) {
    addSignal(state, 'loop_stall', 'ralph_loop',
      `Iteration ${loopState.iteration}/${loopState.max_iterations}`);
    signalsThisTurn.add('loop_stall');
  }

  // Check confidence decay (consecutive failures)
  if (state.consecutive_failures >= CONFIDENCE_DECAY_THRESHOLD &&
      !signalsThisTurn.has('confidence_decay')) {
    addSignal(state, 'confidence_decay', 'consecutive_failures',
      `${state.consecutive_failures} consecutive failures`);
    state.consecutive_failures = 0;  // Reset after signal emitted
    signalsThisTurn.add('confidence_decay');
  }

  // Calculate and check threshold
  const weight = calculateWeight(state);
  writeSignals(state);

  if (weight >= ACTIVATION_THRESHOLD && canActivate(state)) {
    updateAC10State('barrier_detected', state);

    // Safety: Don't inject large prompt if context budget is tight
    if (!isContextBudgetSafe()) {
      emitTelemetry('barrier_detected', {
        cumulative_weight: weight,
        suppressed: true,
        reason: 'context_budget_high'
      });
      return { proceed: true };
    }

    emitTelemetry('barrier_detected', {
      cumulative_weight: weight,
      signal_count: state.signals.length,
      signals_by_type: state.signals.reduce((acc, s) => {
        acc[s.type] = (acc[s.type] || 0) + 1;
        return acc;
      }, {})
    });

    // Build signal summary for context
    const signalSummary = state.signals.reduce((acc, s) => {
      acc[s.type] = (acc[s.type] || 0) + 1;
      return acc;
    }, {});
    const signalLines = Object.entries(signalSummary)
      .map(([type, count]) => `  ${type}: ${count}x (weight ${SIGNAL_WEIGHTS[type] || 1} each)`)
      .join('\n');

    return {
      proceed: true,
      additionalContext: [
        '',
        '\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501',
        'AC-10 ULFHEDTHNAR SENSES RESISTANCE',
        '\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501',
        '',
        'Multiple defeat signals detected. The wolf-warrior stirs.',
        `Signal weight: ${weight.toFixed(1)} / ${ACTIVATION_THRESHOLD} threshold`,
        '',
        'Detected signals:',
        signalLines,
        '',
        'Ulfhedthnar offers berserker problem-solving:',
        '  Frenzy Mode: max parallel agents on decomposed sub-problems',
        '  Approach Rotation: systematic strategy cycling (6 strategies)',
        '  Berserker Loop: no-quit, minimum 5 iterations',
        '',
        'To unleash: respond "unleash" or run /unleash',
        'To decline: continue normal operation',
        '',
        '\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501\u2501'
      ].join('\n')
    };
  }

  return { proceed: true };
}

function handleSubagentStop(hookData) {
  const state = readSignals();
  const { agent_name, success, output } = hookData;
  const outputText = output || '';

  // Track consecutive failures for confidence decay
  if (success === false || /CRITICAL|FAILED|ERROR|BLOCKED/i.test(outputText)) {
    state.consecutive_failures = (state.consecutive_failures || 0) + 1;
    addSignal(state, 'agent_failure', agent_name || 'unknown',
      outputText.slice(0, 200));
  } else {
    // Success resets consecutive failure counter
    state.consecutive_failures = 0;
  }

  // Check for defeat language in agent output
  if (checkDefeatLanguage(outputText)) {
    addSignal(state, 'defeat_language', agent_name || 'agent',
      outputText.slice(0, 200));
  }

  // Track "I'm not sure" repeats (spec: 3+ on same task)
  if (UNCERTAINTY_PATTERN.test(outputText)) {
    state.uncertainty_count = (state.uncertainty_count || 0) + 1;
    if (state.uncertainty_count >= UNCERTAINTY_REPEAT_THRESHOLD) {
      addSignal(state, 'defeat_language', agent_name || 'agent',
        `"I\'m not sure" repeated ${state.uncertainty_count} times`);
      state.uncertainty_count = 0;  // Reset after signal emitted
    }
  }

  writeSignals(state);
  return { proceed: true };
}

/**
 * Handle PostToolUse — detect tool failures and defeat language in outputs
 */
function handlePostToolUse(hookData) {
  const state = readSignals();
  const toolName = hookData.tool_name || '';
  const toolOutput = hookData.tool_output || '';

  // Only process if there's meaningful output
  if (!toolOutput || toolOutput.length < 10) {
    return { proceed: true };
  }

  // Check for Bash command failures (non-zero exit, error patterns)
  if (toolName === 'Bash') {
    const isError = /(?:command not found|Permission denied|No such file|ENOENT|EACCES|Error:|error:|FATAL|fatal:)/i.test(toolOutput);
    if (isError) {
      state.consecutive_failures = (state.consecutive_failures || 0) + 1;
      // Only add signal after repeated failures (3+ consecutive)
      if (state.consecutive_failures >= 3) {
        addSignal(state, 'tool_failure', 'Bash',
          toolOutput.slice(0, 200));
      }
    } else {
      // Successful Bash resets consecutive counter
      if (state.consecutive_failures > 0) {
        state.consecutive_failures = Math.max(0, state.consecutive_failures - 1);
      }
    }
  }

  // Check for defeat language in Task (agent) return text
  if (toolName === 'Task' && checkDefeatLanguage(toolOutput)) {
    addSignal(state, 'defeat_language', 'Task_return',
      toolOutput.slice(0, 200));
  }

  // Track uncertainty in Task outputs
  if (toolName === 'Task' && UNCERTAINTY_PATTERN.test(toolOutput)) {
    state.uncertainty_count = (state.uncertainty_count || 0) + 1;
    if (state.uncertainty_count >= UNCERTAINTY_REPEAT_THRESHOLD) {
      addSignal(state, 'defeat_language', 'Task_uncertainty',
        `"I'm not sure" repeated ${state.uncertainty_count} times`);
      state.uncertainty_count = 0;
    }
  }

  writeSignals(state);
  return { proceed: true };
}

// ─── Main Entry Point ───────────────────────────────────────

function main(hookData) {
  // Route by event type
  if (hookData.agent_name !== undefined || hookData.event === 'SubagentStop') {
    return handleSubagentStop(hookData);
  }
  // PostToolUse events have tool_name + tool_output
  if (hookData.tool_name && hookData.tool_output !== undefined) {
    return handlePostToolUse(hookData);
  }
  return handleUserPrompt(hookData);
}

// ─── Exports ────────────────────────────────────────────────

module.exports = {
  name: 'ulfhedthnar-detector',
  description: 'AC-10 Ulfhedthnar defeat signal detection and activation',
  events: ['UserPromptSubmit', 'SubagentStop', 'PostToolUse'],
  main,
  handleUserPrompt,
  handleSubagentStop,
  handlePostToolUse,
  // Expose for testing
  _internal: {
    ACTIVATION_THRESHOLD,
    COOLDOWN_MS,
    DEFEAT_PATTERNS,
    FRUSTRATION_PATTERNS,
    calculateWeight,
    readSignals,
    writeSignals,
    checkAgentCascade,
    checkLoopStall
  }
};

// ─── STDIN/STDOUT Handler ───────────────────────────────────

if (require.main === module) {
  let inputData = '';
  process.stdin.setEncoding('utf8');
  process.stdin.on('data', chunk => { inputData += chunk; });
  process.stdin.on('end', () => {
    try {
      const hookData = JSON.parse(inputData || '{}');
      const result = main(hookData);
      console.log(JSON.stringify(result));
    } catch {
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
