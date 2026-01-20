/**
 * Self-Correction Capture Hook (AC-05)
 *
 * Detects when user corrects Claude and captures these as potential lessons.
 * Logs corrections to .claude/logs/corrections.jsonl for later review.
 *
 * Detection patterns:
 * - "No, actually..."
 * - "That's wrong..."
 * - "You should have..."
 * - "That's not correct..."
 * - "I meant..."
 *
 * Priority: MEDIUM (Learning)
 * Created: 2026-01-06
 * Updated: 2026-01-19 (telemetry integration)
 * Source: AIfred baseline af66364 (implemented for Jarvis)
 * PR Reference: PR-13.1
 */

const fs = require('fs').promises;
const path = require('path');

// Telemetry integration
let telemetry;
try {
  telemetry = require('./telemetry-emitter');
} catch {
  telemetry = { emit: () => ({ success: false }) };
}

// Configuration
const CORRECTIONS_LOG = path.join(__dirname, '..', 'logs', 'corrections.jsonl');

// Correction detection patterns with severity
const CORRECTION_PATTERNS = [
  { pattern: /\bno,?\s+actually\b/i, severity: 'MEDIUM' },
  { pattern: /\bthat'?s\s+(wrong|incorrect|not\s+right|not\s+correct)\b/i, severity: 'HIGH' },
  { pattern: /\byou\s+should\s+have\b/i, severity: 'HIGH' },
  { pattern: /\bi\s+meant\b/i, severity: 'LOW' },
  { pattern: /\bthat'?s\s+not\s+what\s+i\b/i, severity: 'MEDIUM' },
  { pattern: /\bplease\s+(fix|correct|change)\b/i, severity: 'MEDIUM' },
  { pattern: /\bwrong\s+(file|path|command|approach)\b/i, severity: 'HIGH' },
  { pattern: /\byou\s+(misunderstood|missed|forgot)\b/i, severity: 'MEDIUM' },
  { pattern: /\blet\s+me\s+clarify\b/i, severity: 'LOW' },
  { pattern: /\bactually,?\s+i\s+wanted\b/i, severity: 'LOW' }
];

/**
 * Detect correction in user message
 */
function detectCorrection(message) {
  for (const { pattern, severity } of CORRECTION_PATTERNS) {
    if (pattern.test(message)) {
      return {
        detected: true,
        severity,
        pattern: pattern.toString()
      };
    }
  }
  return { detected: false };
}

/**
 * Extract context from message (first 200 chars)
 */
function extractContext(message) {
  const cleaned = message.replace(/\s+/g, ' ').trim();
  if (cleaned.length <= 200) return cleaned;
  return cleaned.substring(0, 200) + '...';
}

/**
 * Log correction to file
 */
async function logCorrection(correction) {
  try {
    const dir = path.dirname(CORRECTIONS_LOG);
    await fs.mkdir(dir, { recursive: true });

    const entry = JSON.stringify(correction) + '\n';
    await fs.appendFile(CORRECTIONS_LOG, entry);
  } catch (err) {
    // Silent failure - don't disrupt workflow
  }
}

/**
 * Format suggestion message
 */
function formatSuggestion(correction) {
  const severityEmoji = {
    HIGH: '🔴',
    MEDIUM: '🟡',
    LOW: '🟢'
  };

  const lines = [
    '',
    `[self-correction-capture] ${severityEmoji[correction.severity]} Correction Detected (${correction.severity})`,
    '─'.repeat(50),
    '',
    'Consider saving this as a lesson learned.',
    '',
    'To capture lessons, update:',
    '  .claude/context/lessons/corrections.md',
    '',
    'Or store in Memory MCP for persistent recall.',
    '',
    '─'.repeat(50)
  ];

  return lines.join('\n');
}

/**
 * Handler function (can be called via require or stdin)
 */
async function handler(context) {
  const { user_prompt } = context;

  if (!user_prompt) {
    return { proceed: true };
  }

  const detection = detectCorrection(user_prompt);

  if (detection.detected) {
    const correction = {
      timestamp: new Date().toISOString(),
      severity: detection.severity,
      pattern: detection.pattern,
      context: extractContext(user_prompt),
      captured: false
    };

    // Log to file
    await logCorrection(correction);

    // Emit telemetry event for AC-05
    telemetry.emit('AC-05', 'correction_logged', {
      severity: correction.severity,
      pattern: correction.pattern,
      context_length: user_prompt.length
    });

    // Show suggestion for HIGH/MEDIUM severity (stderr to not interfere with JSON)
    if (detection.severity === 'HIGH' || detection.severity === 'MEDIUM') {
      console.error(formatSuggestion(correction));
    }
  }

  return { proceed: true };
}

// Export for require() usage
module.exports = {
  name: 'self-correction-capture',
  description: 'Detect user corrections and capture as lessons',
  event: 'UserPromptSubmit',
  handler,
  detectCorrection  // Export for testing
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
      console.error(`[self-correction-capture] Parse error: ${err.message}`);
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
