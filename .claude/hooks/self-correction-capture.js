/**
 * Self-Correction Capture Hook
 *
 * Detects when user corrects Claude and captures the lesson.
 * Enables Claude to learn from mistakes over time.
 *
 * Triggers on patterns like:
 * - "No, actually..."
 * - "That's wrong"
 * - "You should have..."
 * - "Correction:"
 *
 * Created: 2026-01-03
 * Source: grapeot/devin.cursorrules research
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const LESSONS_DIR = path.join(__dirname, '..', 'context', 'lessons');
const LESSONS_FILE = path.join(LESSONS_DIR, 'corrections.md');
const LOG_DIR = path.join(__dirname, '..', 'logs');
const CORRECTIONS_LOG = path.join(LOG_DIR, 'corrections.jsonl');

// Correction detection patterns
const CORRECTION_PATTERNS = [
  // Direct corrections
  /^no,?\s+(actually|that'?s\s+wrong|incorrect|not\s+right)/i,
  /^wrong\.?\s+/i,
  /^that'?s\s+not\s+(right|correct|what\s+i)/i,
  /^incorrect\.?\s*/i,

  // Should/shouldn't patterns
  /^you\s+(should|shouldn'?t)\s+have/i,
  /^you\s+were\s+(supposed|meant)\s+to/i,
  /^you\s+need(ed)?\s+to/i,

  // Clarification corrections
  /^i\s+meant/i,
  /^i\s+said/i,
  /^what\s+i\s+(meant|wanted)/i,
  /^let\s+me\s+clarify/i,

  // Explicit correction markers
  /^correction:/i,
  /^fix:/i,
  /^actually,?\s+/i,

  // Frustration indicators (gentle)
  /^please\s+(don'?t|stop)/i,
  /^i\s+already\s+(told|said|mentioned)/i
];

// Severity patterns (how strong the correction is)
const SEVERITY_PATTERNS = {
  high: [
    /wrong/i,
    /incorrect/i,
    /never\s+do/i,
    /don'?t\s+ever/i,
    /completely/i,
    /totally/i
  ],
  medium: [
    /should\s+have/i,
    /supposed\s+to/i,
    /meant\s+to/i,
    /instead/i
  ],
  low: [
    /actually/i,
    /clarify/i,
    /meant/i
  ]
};

/**
 * Detect if a prompt is a correction
 */
function detectCorrection(prompt) {
  const trimmedPrompt = prompt.trim();

  for (const pattern of CORRECTION_PATTERNS) {
    if (pattern.test(trimmedPrompt)) {
      return {
        isCorrection: true,
        matchedPattern: pattern.toString(),
        severity: detectSeverity(trimmedPrompt)
      };
    }
  }

  return { isCorrection: false };
}

/**
 * Detect severity of correction
 */
function detectSeverity(prompt) {
  for (const [severity, patterns] of Object.entries(SEVERITY_PATTERNS)) {
    for (const pattern of patterns) {
      if (pattern.test(prompt)) {
        return severity;
      }
    }
  }
  return 'low';
}

/**
 * Log correction for analysis
 */
async function logCorrection(prompt, detection) {
  try {
    await fs.mkdir(LOG_DIR, { recursive: true });

    const entry = {
      timestamp: new Date().toISOString(),
      prompt: prompt.substring(0, 500), // Truncate for privacy
      severity: detection.severity,
      pattern: detection.matchedPattern
    };

    await fs.appendFile(CORRECTIONS_LOG, JSON.stringify(entry) + '\n');
  } catch (err) {
    console.error(`[self-correction] Failed to log: ${err.message}`);
  }
}

/**
 * Get recent corrections count (for context)
 */
async function getRecentCorrectionsCount() {
  try {
    const content = await fs.readFile(CORRECTIONS_LOG, 'utf8');
    const lines = content.trim().split('\n').filter(l => l.length > 0);

    // Count corrections in last hour
    const oneHourAgo = Date.now() - 3600000;
    let recentCount = 0;

    for (const line of lines.slice(-20)) { // Check last 20
      try {
        const entry = JSON.parse(line);
        if (new Date(entry.timestamp).getTime() > oneHourAgo) {
          recentCount++;
        }
      } catch {
        continue;
      }
    }

    return recentCount;
  } catch {
    return 0;
  }
}

/**
 * UserPromptSubmit Hook - Detect corrections
 */
module.exports = {
  name: 'self-correction-capture',
  description: 'Detect user corrections and capture lessons learned',
  event: 'UserPromptSubmit',

  async handler(context) {
    const { prompt } = context;

    if (!prompt || prompt.length < 5) {
      return { proceed: true };
    }

    try {
      const detection = detectCorrection(prompt);

      if (detection.isCorrection) {
        // Log the correction
        await logCorrection(prompt, detection);

        // Get context about recent corrections
        const recentCount = await getRecentCorrectionsCount();

        // Build context for Claude
        const contextParts = [];

        contextParts.push('\n--- Correction Detected ---');
        contextParts.push(`Severity: ${detection.severity.toUpperCase()}`);

        if (recentCount > 2) {
          contextParts.push(`⚠️ Note: ${recentCount} corrections in the last hour`);
        }

        // Severity-specific suggestions
        if (detection.severity === 'high') {
          contextParts.push('\n💡 This seems important. Consider:');
          contextParts.push('1. Acknowledging the mistake clearly');
          contextParts.push('2. Asking: "Should I save this as a lesson learned?"');
          contextParts.push('3. Explaining what you\'ll do differently');
        } else if (detection.severity === 'medium') {
          contextParts.push('\n💡 Consider asking if this should be documented as a lesson.');
        }

        // Add instruction hint
        contextParts.push('\nTo save a lesson: Create entry in `.claude/context/lessons/corrections.md`');

        console.log(`[self-correction] Detected ${detection.severity} correction`);

        return {
          proceed: true,
          hookSpecificOutput: {
            hookEventName: 'UserPromptSubmit',
            isCorrection: true,
            severity: detection.severity,
            additionalContext: contextParts.join('\n')
          }
        };
      }

    } catch (err) {
      console.error(`[self-correction] Error: ${err.message}`);
    }

    return { proceed: true };
  }
};
