#!/usr/bin/env node
/**
 * Planning Mode Detector Hook
 *
 * Automatically triggers structured planning for:
 * - new_design: Building something from scratch
 * - system_review: Reviewing/improving existing system
 * - feature_planning: Adding features to existing project
 *
 * Tiered Response (like orchestration-detector):
 *   Score < 3:  Nothing (not a planning task)
 *   Score 3-5:  Suggest planning
 *   Score >= 6: AUTO-INVOKE planning workflow
 *
 * Works alongside orchestration-detector.js - this fires for planning needs,
 * orchestration fires for execution tracking needs.
 *
 * Created: 2026-01-19
 * Converted to stdin/stdout executable hook
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const LOG_DIR = path.join(__dirname, '..', 'logs');
const DETECTION_LOG = path.join(LOG_DIR, 'planning-detections.jsonl');

// Thresholds (score-based like orchestration-detector)
const SUGGEST_THRESHOLD = 3;    // Score 3-5: Suggest planning
const AUTO_THRESHOLD = 6;       // Score >= 6: Auto-invoke planning

// ============================================================
// MODE DETECTION PATTERNS
// ============================================================

const MODE_PATTERNS = {
  new_design: {
    strong: [
      /\b(from scratch|brand new|greenfield)\b/i,
      /\b(build|create|design|architect)\s+(a|an|the|my)\s+new\b/i,
      /\b(start|begin|kick off)\s+(building|developing|creating|designing)\b/i,
      /\bnew\s+(system|project|application|app|service|platform)\b/i,
      /\bI\s+want\s+to\s+(build|create|make|design)\b/i,
      /\bI('d| would)\s+like\s+to\s+(build|create|make|design)\b/i,
      /\bhelp\s+me\s+(build|create|design|plan)\b/i,
      /\blet'?s\s+(build|create|design|plan)\b/i,
      /\bcan\s+you\s+(help\s+)?(build|create|design|plan)\b/i,
      /\bplan\s+(out|for)\s+(a|an|the|my)\b/i,
    ],
    moderate: [
      /\b(build|create|implement|develop)\s+(a|an|the)\s+\w+/i,
      /\bdesign\s+(a|an)\b/i,
      /\barchitect\s+(a|an|the)\b/i,
      /\bset\s*up\s+(a|an|the)\b/i,
      /\bneed\s+(a|an|to build|to create)\b/i,
    ],
    weight: { strong: 3, moderate: 2 }
  },

  system_review: {
    strong: [
      /\b(review|audit|assess|evaluate)\s+(the|my|our|this|existing)\b/i,
      /\b(what's wrong with|issues in|problems with)\s+(the|my|our)\b/i,
      /\b(improve|optimize|refactor|modernize)\s+(the|my|our|existing|current)\b/i,
      /\bexisting\s+(system|codebase|architecture|infrastructure)\b/i,
      /\bhow\s+(can|do)\s+(I|we)\s+improve\b/i,
      /\bfull\s+review\b/i,
    ],
    moderate: [
      /\b(analyze|examine|look at|check)\s+(the|my|our)\s+\w+/i,
      /\b(technical debt|pain points|bottlenecks)\b/i,
      /\bwhat\s+needs\s+(to be|fixing|improvement)\b/i,
      /\bclean\s*up\s+(the|my|this)\b/i,
    ],
    weight: { strong: 3, moderate: 2 }
  },

  feature_planning: {
    strong: [
      /\b(add|implement)\s+(a\s+)?(new\s+)?feature\b/i,
      /\bnew\s+feature\s+(for|to|in)\b/i,
      /\b(extend|enhance|augment)\s+(the|my|our|this)\b/i,
      /\bfeature\s+request\b/i,
      /\badd\s+\w+\s+(support|functionality|capability)\b/i,
    ],
    moderate: [
      /\badd\s+(a|an|the)\s+\w+\s+(to|for)\b/i,
      /\bintegrate\s+\w+\s+(into|with)\b/i,
      /\b(bolt on|tack on|add on)\b/i,
      /\bextend\s+(the|this)\s+\w+\s+(with|to)\b/i,
    ],
    weight: { strong: 3, moderate: 2 }
  }
};

// Skip patterns - don't suggest planning for these
const SKIP_PATTERNS = [
  /^\/plan/i,                          // Already using plan command
  /^\/orchestration/i,                 // Using orchestration
  /^\/(check|discover|health)/i,       // Utility commands
  /^(show|list|status|what is|how do)/i,  // Questions/queries
  /\b(fix|bug|error|typo)\b/i,         // Bug fixes
  /\b(commit|push|merge|pull)\b/i,     // Git operations
  /^(run|execute|test)\s/i,            // Run commands
];

// ============================================================
// SCORING LOGIC
// ============================================================

function calculateModeScores(prompt) {
  const scores = {
    new_design: 0,
    system_review: 0,
    feature_planning: 0
  };

  for (const [mode, patterns] of Object.entries(MODE_PATTERNS)) {
    for (const pattern of patterns.strong) {
      if (pattern.test(prompt)) {
        scores[mode] += patterns.weight.strong;
      }
    }
    for (const pattern of patterns.moderate) {
      if (pattern.test(prompt)) {
        scores[mode] += patterns.weight.moderate;
      }
    }
  }

  return scores;
}

function determineMode(scores) {
  const totalScore = Object.values(scores).reduce((a, b) => a + b, 0);
  if (totalScore === 0) return null;

  const sorted = Object.entries(scores)
    .sort(([, a], [, b]) => b - a);

  const [topMode, topScore] = sorted[0];

  return {
    mode: topMode,
    score: topScore,
    totalScore,
    scores
  };
}

function shouldSkip(prompt) {
  return SKIP_PATTERNS.some(pattern => pattern.test(prompt));
}

// ============================================================
// LOGGING
// ============================================================

async function logDetection(entry) {
  try {
    await fs.mkdir(LOG_DIR, { recursive: true });
    await fs.appendFile(DETECTION_LOG, JSON.stringify(entry) + '\n');
  } catch {
    // Silently fail - logging shouldn't break the hook
  }
}

// ============================================================
// MAIN HANDLER
// ============================================================

async function handleHook(context) {
  const prompt = context.prompt || '';

  if (shouldSkip(prompt)) {
    return { proceed: true };
  }

  if (prompt.length < 15) {
    return { proceed: true };
  }

  const scores = calculateModeScores(prompt);
  const result = determineMode(scores);

  if (!result || result.score < SUGGEST_THRESHOLD) {
    return { proceed: true };
  }

  await logDetection({
    timestamp: new Date().toISOString(),
    prompt: prompt.substring(0, 200),
    mode: result.mode,
    score: result.score,
    action: result.score >= AUTO_THRESHOLD ? 'auto' : 'suggest',
    scores: result.scores
  });

  const modeNames = {
    new_design: 'New Design',
    system_review: 'System Review',
    feature_planning: 'Feature Planning'
  };

  const modeDescriptions = {
    new_design: 'building something new from scratch',
    system_review: 'reviewing and improving an existing system',
    feature_planning: 'adding a feature to an existing project'
  };

  const modeName = modeNames[result.mode];
  const modeDesc = modeDescriptions[result.mode];

  let message;

  if (result.score >= AUTO_THRESHOLD) {
    message = `
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Planning Detected: ${modeName} Mode (Score: ${result.score})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This looks like ${modeDesc}.

**AUTO-STARTING PLANNING**: Begin the structured planning workflow
using the ${modeName} mode. Guide the user through discovery questions,
create a specification document, and generate an orchestration plan.

Use the conversational flow from the /plan command:
1. Confirm the detected mode with the user
2. Ask vision/scope/technical questions
3. Use dynamic depth based on complexity signals
4. Generate spec at .claude/planning/specs/
5. Generate orchestration at .claude/orchestration/
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`;
  } else {
    message = `
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Planning Suggestion (Score: ${result.score})
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

This might benefit from structured planning (${modeName} mode).

If you want guided planning, I can:
- Ask discovery questions to clarify requirements
- Create a specification document
- Generate an orchestration plan for execution

Would you like me to start the planning workflow?
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
`;
  }

  return {
    proceed: true,
    outputToUser: message.trim()
  };
}

/**
 * Main function - reads from stdin, processes, outputs to stdout
 */
async function main() {
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const input = Buffer.concat(chunks).toString('utf8');

  let context;
  try {
    context = JSON.parse(input);
  } catch {
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  const result = await handleHook(context);
  console.log(JSON.stringify(result));
}

main().catch(err => {
  console.error(`[planning-mode-detector] Fatal error: ${err.message}`);
  console.log(JSON.stringify({ proceed: true }));
});
