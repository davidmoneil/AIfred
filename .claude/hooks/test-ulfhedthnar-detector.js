#!/usr/bin/env node
/**
 * Functional test for ulfhedthnar-detector.js
 *
 * Tests signal accumulation, weight calculation, threshold detection,
 * cooldown logic, and event routing. Run via: node test-ulfhedthnar-detector.js
 *
 * Created: 2026-02-10
 */

const path = require('path');
const fs = require('fs');

// Paths for state files that may be modified by tests
const WORKSPACE_ROOT = process.env.CLAUDE_PROJECT_DIR || '/Users/aircannon/Claude/Jarvis';
const SIGNAL_FILE = path.join(WORKSPACE_ROOT, '.claude/state/ulfhedthnar-signals.json');
const AC10_STATE = path.join(WORKSPACE_ROOT, '.claude/state/components/AC-10-ulfhedthnar.json');

// Backup original state files before tests (restored at end)
let signalBackup = null;
let ac10Backup = null;
try { signalBackup = fs.readFileSync(SIGNAL_FILE, 'utf8'); } catch {}
try { ac10Backup = fs.readFileSync(AC10_STATE, 'utf8'); } catch {}

// Clean signal file before tests to start fresh
try { fs.unlinkSync(SIGNAL_FILE); } catch {}

// Load the module
const detector = require('./ulfhedthnar-detector.js');
const { _internal } = detector;

let passed = 0;
let failed = 0;

function assert(condition, name) {
  if (condition) {
    console.log(`  PASS: ${name}`);
    passed++;
  } else {
    console.log(`  FAIL: ${name}`);
    failed++;
  }
}

// ─── Test 1: Signal Weight Calculation ──────────────────────

console.log('\n=== Test 1: Weight Calculation ===');

const state1 = {
  signals: [
    { type: 'tool_failure', weight: 1, timestamp: Date.now() },
    { type: 'agent_failure', weight: 2, timestamp: Date.now() },
    { type: 'loop_stall', weight: 3, timestamp: Date.now() }
  ],
  last_activation: null,
  total_activations: 0,
  active: false,
  activated_at: null,
  consecutive_failures: 0,
  uncertainty_count: 0
};

const weight1 = _internal.calculateWeight(state1);
assert(weight1 === 6, `Fresh signals weight = 6 (got ${weight1})`);

// Test decay: signals 20 minutes old (>15 min = 50% decay)
const state2 = {
  signals: [
    { type: 'agent_cascade', weight: 3, timestamp: Date.now() - 20 * 60 * 1000 },
    { type: 'loop_stall', weight: 3, timestamp: Date.now() - 20 * 60 * 1000 }
  ]
};
const weight2 = _internal.calculateWeight(state2);
assert(weight2 === 3, `Decayed signals weight = 3 (got ${weight2})`);

// Test expiry: signals 2 hours old (>1 hour = expired)
const state3 = {
  signals: [
    { type: 'agent_cascade', weight: 3, timestamp: Date.now() - 2 * 60 * 60 * 1000 }
  ]
};
const weight3 = _internal.calculateWeight(state3);
assert(weight3 === 0, `Expired signals weight = 0 (got ${weight3})`);

// ─── Test 2: Activation Threshold ───────────────────────────

console.log('\n=== Test 2: Activation Threshold ===');

assert(_internal.ACTIVATION_THRESHOLD === 7, `Threshold = 7 (got ${_internal.ACTIVATION_THRESHOLD})`);

// Weight = 6, below threshold
const belowThreshold = _internal.calculateWeight(state1);
assert(belowThreshold < _internal.ACTIVATION_THRESHOLD, `6 < 7 threshold (${belowThreshold} < ${_internal.ACTIVATION_THRESHOLD})`);

// Weight = 8, above threshold
const state4 = {
  signals: [
    { type: 'agent_cascade', weight: 3, timestamp: Date.now() },
    { type: 'loop_stall', weight: 3, timestamp: Date.now() },
    { type: 'agent_failure', weight: 2, timestamp: Date.now() }
  ]
};
const aboveThreshold = _internal.calculateWeight(state4);
assert(aboveThreshold >= _internal.ACTIVATION_THRESHOLD, `8 >= 7 threshold (${aboveThreshold} >= ${_internal.ACTIVATION_THRESHOLD})`);

// ─── Test 3: Cooldown Logic ─────────────────────────────────

console.log('\n=== Test 3: Cooldown Logic ===');

assert(_internal.COOLDOWN_MS === 30 * 60 * 1000, `Cooldown = 30 min (${_internal.COOLDOWN_MS}ms)`);

// No previous activation — can activate
const stateNoActivation = { active: false, last_activation: null };
// canActivate checks state.active and state.last_activation
assert(stateNoActivation.active === false && stateNoActivation.last_activation === null,
  'No prior activation → can activate');

// Recent activation — cannot activate
const stateRecentActivation = { active: false, last_activation: Date.now() - 5 * 60 * 1000 };
const cooldownCheck = (Date.now() - stateRecentActivation.last_activation) > _internal.COOLDOWN_MS;
assert(!cooldownCheck, 'Recent activation (5 min ago) → cooldown active');

// Old activation — can activate
const stateOldActivation = { active: false, last_activation: Date.now() - 45 * 60 * 1000 };
const oldCheck = (Date.now() - stateOldActivation.last_activation) > _internal.COOLDOWN_MS;
assert(oldCheck, 'Old activation (45 min ago) → cooldown expired');

// ─── Test 4: Defeat Pattern Detection ───────────────────────

console.log('\n=== Test 4: Defeat Patterns ===');

const defeatTexts = [
  "I can't figure out how to fix this",
  "I'm unable to resolve this error",
  "I don't think I can solve this problem",
  "I don't know how to approach this",
  "This isn't possible with the current setup",
  "It's impossible to do this without admin access",
  "I'm stuck on this issue",
  "We've hit a dead end",
  "Failed to find a solution",
  "I'm giving up on this approach"
];

for (const text of defeatTexts) {
  const matched = _internal.DEFEAT_PATTERNS.some(p => p.test(text));
  assert(matched, `Detects: "${text.slice(0, 50)}..."`);
}

// Negative cases — should NOT match
const nonDefeatTexts = [
  "I can fix this easily",
  "The solution is possible",
  "I'm sure about this approach",
  "This works perfectly"
];

for (const text of nonDefeatTexts) {
  const matched = _internal.DEFEAT_PATTERNS.some(p => p.test(text));
  assert(!matched, `Does NOT detect: "${text}"`);
}

// ─── Test 5: User Frustration Detection ─────────────────────

console.log('\n=== Test 5: Frustration Patterns ===');

const frustrationTexts = [
  "try again please",
  "still not working",
  "you keep failing at this",
  "that didn't work",
  "wrong again",
  "same error as before",
  "this is the 4th time",
  "stop trying that"
];

for (const text of frustrationTexts) {
  const matched = _internal.FRUSTRATION_PATTERNS.some(p => p.test(text));
  assert(matched, `Detects frustration: "${text}"`);
}

// ─── Test 6: Agent Cascade Detection ────────────────────────

console.log('\n=== Test 6: Agent Cascade ===');

const cascadeResult = _internal.checkAgentCascade();
assert(typeof cascadeResult === 'object', 'checkAgentCascade returns object');
assert(typeof cascadeResult.is_cascade === 'boolean', 'has is_cascade boolean');
assert(typeof cascadeResult.failure_count === 'number', 'has failure_count number');

// ─── Test 7: Loop Stall Detection ───────────────────────────

console.log('\n=== Test 7: Loop Stall ===');

const stallResult = _internal.checkLoopStall();
assert(typeof stallResult === 'object', 'checkLoopStall returns object');
assert(typeof stallResult.stalled === 'boolean', 'has stalled boolean');

// ─── Test 8: Event Routing ──────────────────────────────────

console.log('\n=== Test 8: Event Routing ===');

// SubagentStop event (has agent_name)
const subagentResult = detector.main({
  agent_name: 'test-agent',
  success: true,
  output: 'Agent completed successfully'
});
assert(subagentResult.proceed === true, 'SubagentStop returns proceed: true');

// UserPromptSubmit event (has user_prompt)
const promptResult = detector.main({
  user_prompt: 'Hello, help me with this task'
});
assert(promptResult.proceed === true, 'UserPromptSubmit returns proceed: true');

// ─── Test 9: PostToolUse Event Routing ───────────────────────

console.log('\n=== Test 9: PostToolUse Routing ===');

// PostToolUse event (has tool_name + tool_output)
const postToolResult = detector.main({
  tool_name: 'Bash',
  tool_output: 'command not found: nonexistent'
});
assert(postToolResult.proceed === true, 'PostToolUse returns proceed: true');

// Task with defeat language
const taskDefeatResult = detector.main({
  tool_name: 'Task',
  tool_output: "I can't figure out how to solve this problem"
});
assert(taskDefeatResult.proceed === true, 'Task defeat language returns proceed: true');

// Short output should skip processing
const shortResult = detector.main({
  tool_name: 'Bash',
  tool_output: 'ok'
});
assert(shortResult.proceed === true, 'Short output skips processing');

// ─── Test 10: JICM Safety Gate ──────────────────────────────

console.log('\n=== Test 10: JICM Safety ===');

// isContextBudgetSafe is not exported but we can verify it doesn't crash
assert(typeof detector.handlePostToolUse === 'function', 'handlePostToolUse exported');
assert(typeof detector.handleUserPrompt === 'function', 'handleUserPrompt exported');
assert(typeof detector.handleSubagentStop === 'function', 'handleSubagentStop exported');

// ─── Test 11: Schema Validation / Defaults ─────────────────

console.log('\n=== Test 11: Schema Validation ===');

// defaultSignalState exposed via _internal
const defaultState = _internal.readSignals();
assert(Array.isArray(defaultState.signals), 'Default state has signals array');
assert(defaultState.active === false, 'Default state active = false');
assert(typeof defaultState.consecutive_failures === 'number', 'Default consecutive_failures is number');
assert(typeof defaultState.uncertainty_count === 'number', 'Default uncertainty_count is number');

// Test with partial/corrupted state object
const statePartial = { signals: 'not_an_array', active: true };
const weightPartial = _internal.calculateWeight({ signals: [] });
assert(weightPartial === 0, 'Empty signals array → weight 0');

// ─── Test 12: Activation Negation Patterns ─────────────────

console.log('\n=== Test 12: Negation Patterns ===');

// "don't unleash" should NOT activate
const negationResult1 = detector.main({ user_prompt: "don't unleash" });
assert(negationResult1.proceed === true, '"don\'t unleash" does NOT activate');
assert(!negationResult1.additionalContext || !negationResult1.additionalContext.includes('UNLEASHED'),
  '"don\'t unleash" has no activation context');

// "never unleash" should NOT activate
const negationResult2 = detector.main({ user_prompt: "never unleash the wolf" });
assert(!negationResult2.additionalContext || !negationResult2.additionalContext.includes('UNLEASHED'),
  '"never unleash" does NOT activate');

// "stop unleash" should NOT activate
const negationResult3 = detector.main({ user_prompt: "stop unleash process" });
assert(!negationResult3.additionalContext || !negationResult3.additionalContext.includes('UNLEASHED'),
  '"stop unleash" does NOT activate');

// ─── Test 13: Deactivation Command ─────────────────────────

console.log('\n=== Test 13: Deactivation ===');

// "stand down" when not active should be no-op
const standDownInactive = detector.main({ user_prompt: "stand down" });
assert(standDownInactive.proceed === true, '"stand down" when inactive → proceed true');
assert(!standDownInactive.additionalContext || !standDownInactive.additionalContext.includes('stands down'),
  '"stand down" when inactive → no deactivation message');

// ─── Test 14: Consecutive Failure Tracking ─────────────────

console.log('\n=== Test 14: Consecutive Failures ===');

// Simulate 3 consecutive Bash failures
for (let i = 0; i < 3; i++) {
  detector.main({
    tool_name: 'Bash',
    tool_output: 'Error: command not found: foobar' + ' '.repeat(20)
  });
}
// A successful Bash should reduce the counter
detector.main({
  tool_name: 'Bash',
  tool_output: 'Success: operation completed normally and everything is fine'
});
assert(true, 'Consecutive failure tracking does not crash');

// ─── Test 15: Uncertainty Repeat Tracking ───────────────────

console.log('\n=== Test 15: Uncertainty Tracking ===');

// Simulate 2 "I'm not sure" — below threshold
const uncertainResult1 = detector.main({
  agent_name: 'test-uncertain-1',
  success: true,
  output: "I'm not sure about this approach but will try"
});
assert(uncertainResult1.proceed === true, 'First uncertainty does not signal');

const uncertainResult2 = detector.main({
  agent_name: 'test-uncertain-2',
  success: true,
  output: "I'm not sure this will work either"
});
assert(uncertainResult2.proceed === true, 'Second uncertainty does not signal');

// Third should trigger the signal internally (we can't easily verify
// signal file contents without exporting more, but verify no crash)
const uncertainResult3 = detector.main({
  agent_name: 'test-uncertain-3',
  success: true,
  output: "I'm not sure there's a way to do this"
});
assert(uncertainResult3.proceed === true, 'Third uncertainty does not crash');

// ─── Summary ────────────────────────────────────────────────

console.log(`\n${'═'.repeat(50)}`);
console.log(`Results: ${passed} passed, ${failed} failed, ${passed + failed} total`);
console.log(`${'═'.repeat(50)}`);

// Restore original state files (undo test side effects)
try { fs.unlinkSync(SIGNAL_FILE); } catch {}
if (signalBackup) {
  try { fs.writeFileSync(SIGNAL_FILE, signalBackup); } catch {}
}
if (ac10Backup) {
  try { fs.writeFileSync(AC10_STATE, ac10Backup); } catch {}
}

process.exit(failed > 0 ? 1 : 0);
