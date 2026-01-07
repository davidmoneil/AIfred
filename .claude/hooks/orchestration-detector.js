/**
 * Orchestration Detector Hook
 *
 * Analyzes user prompts for complexity and triggers orchestration system
 * when complex multi-phase tasks are detected.
 *
 * Tiered Response:
 *   Score < 4:  Nothing (simple task)
 *   Score 4-8:  Suggest orchestration
 *   Score >= 9: Auto-invoke orchestration
 *
 * Created: 2026-01-03
 * Source: Design Pattern Integration Plan - Phase 2
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const LOG_DIR = path.join(__dirname, '..', 'logs');
const DETECTION_LOG = path.join(LOG_DIR, 'orchestration-detections.jsonl');
const ORCHESTRATION_DIR = path.join(__dirname, '..', 'orchestration');

// Thresholds
const SUGGEST_THRESHOLD = 4;   // Score 4-8: Suggest orchestration
const AUTO_THRESHOLD = 9;       // Score >= 9: Auto-invoke

// ============================================================
// COMPLEXITY SCORING SYSTEM
// ============================================================

// Build/Creation verbs (strong indicators)
const BUILD_VERBS = [
  /\b(build|create|implement|develop|design|architect|construct)\b/i,
  /\b(set\s*up|spin\s*up|stand\s*up)\b/i,
  /\b(make|write|code)\s+(a|an|the)\s+\w+\s+(system|app|application|service|api)/i
];

// Scope indicators (what's being built)
const SCOPE_WORDS = [
  /\b(application|app|system|platform|service|api|backend|frontend)\b/i,
  /\b(module|component|feature|functionality|capability)\b/i,
  /\b(pipeline|workflow|automation|integration)\b/i,
  /\b(infrastructure|architecture|stack)\b/i
];

// Multi-component indicators
const MULTI_COMPONENT = [
  /\bwith\s+(a\s+)?(\w+\s+){0,2}(authentication|auth|login)/i,
  /\bwith\s+(a\s+)?(\w+\s+){0,2}(database|db|storage)/i,
  /\bwith\s+(a\s+)?(\w+\s+){0,2}(api|endpoint|rest|graphql)/i,
  /\bwith\s+(a\s+)?(\w+\s+){0,2}(ui|interface|frontend|dashboard)/i,
  /\bwith\s+(a\s+)?(\w+\s+){0,2}(testing|tests|ci\/cd)/i,
  /\b(including|that\s+has|along\s+with|plus)\b/i,
  /\band\s+(also\s+)?(\w+\s+){0,3}(integration|support|functionality)/i
];

// Explicit complexity markers
const EXPLICIT_COMPLEXITY = [
  /\b(complex|comprehensive|complete|full|full-featured|robust)\b/i,
  /\b(multi-phase|multi-step|phased|staged)\b/i,
  /\b(large|big|major|significant|substantial)\b/i,
  /\b(production|enterprise|scalable)\b/i
];

// Time/effort indicators
const TIME_INDICATORS = [
  /\b(over\s+(multiple|several)\s+sessions?)\b/i,
  /\b(long-term|multi-day|week-long)\b/i,
  /\b(project|initiative|undertaking)\b/i
];

// Integration complexity
const INTEGRATION_WORDS = [
  /\b(integrate|connect|sync|hook\s+into|bridge)\b/i,
  /\b(with\s+existing|into\s+the\s+current)\b/i,
  /\b(third-party|external|api\s+integration)\b/i
];

// Negative signals (reduce score for simple tasks)
const SIMPLICITY_INDICATORS = [
  /\b(simple|quick|basic|minimal|just|only)\b/i,
  /\b(fix|tweak|adjust|update|change)\s+(a|the|this)\b/i,
  /\b(small|minor|tiny|little)\b/i,
  /\b(single|one)\s+(file|function|component|line)/i
];

// Skip patterns (don't even score these)
const SKIP_PATTERNS = [
  /^\/orchestration:/i,           // Already orchestration command
  /^(what|how|why|where|when)\s/i, // Questions
  /^(show|display|list|find|search|look)/i, // Read-only ops
  /^(help|explain|describe)\b/i,  // Informational
  /^(commit|push|pull|merge|checkout)\b/i, // Git ops
  /^(run|execute|test)\s+(the\s+)?(tests?|build|linter)/i // Simple commands
];

/**
 * Calculate complexity score for a prompt
 */
function calculateComplexityScore(prompt) {
  const trimmedPrompt = prompt.trim().toLowerCase();

  // Check skip patterns first
  for (const pattern of SKIP_PATTERNS) {
    if (pattern.test(trimmedPrompt)) {
      return { score: 0, signals: ['skipped'], shouldSkip: true };
    }
  }

  let score = 0;
  const signals = [];

  // Build verbs (+2 each, max 4)
  let buildVerbCount = 0;
  for (const pattern of BUILD_VERBS) {
    if (pattern.test(prompt) && buildVerbCount < 2) {
      score += 2;
      buildVerbCount++;
      signals.push('build_verb');
    }
  }

  // Scope words (+2 each, max 4)
  let scopeCount = 0;
  for (const pattern of SCOPE_WORDS) {
    if (pattern.test(prompt) && scopeCount < 2) {
      score += 2;
      scopeCount++;
      signals.push('scope_word');
    }
  }

  // Multi-component (+1 each, max 4)
  let componentCount = 0;
  for (const pattern of MULTI_COMPONENT) {
    if (pattern.test(prompt) && componentCount < 4) {
      score += 1;
      componentCount++;
      signals.push('multi_component');
    }
  }

  // Explicit complexity (+3 each, max 6)
  let explicitCount = 0;
  for (const pattern of EXPLICIT_COMPLEXITY) {
    if (pattern.test(prompt) && explicitCount < 2) {
      score += 3;
      explicitCount++;
      signals.push('explicit_complexity');
    }
  }

  // Time indicators (+2 each, max 4)
  let timeCount = 0;
  for (const pattern of TIME_INDICATORS) {
    if (pattern.test(prompt) && timeCount < 2) {
      score += 2;
      timeCount++;
      signals.push('time_indicator');
    }
  }

  // Integration (+1 each, max 2)
  let integrationCount = 0;
  for (const pattern of INTEGRATION_WORDS) {
    if (pattern.test(prompt) && integrationCount < 2) {
      score += 1;
      integrationCount++;
      signals.push('integration');
    }
  }

  // Simplicity indicators (-2 each, max -4)
  let simplicityCount = 0;
  for (const pattern of SIMPLICITY_INDICATORS) {
    if (pattern.test(prompt) && simplicityCount < 2) {
      score -= 2;
      simplicityCount++;
      signals.push('simplicity:-2');
    }
  }

  // Prompt length bonus (longer = more complex)
  if (prompt.length > 200) {
    score += 1;
    signals.push('length_bonus');
  }
  if (prompt.length > 400) {
    score += 1;
    signals.push('length_bonus');
  }

  return {
    score: Math.max(0, score),
    signals,
    shouldSkip: false
  };
}

/**
 * Check if there's already an active orchestration
 */
async function hasActiveOrchestration() {
  try {
    const files = await fs.readdir(ORCHESTRATION_DIR);
    const yamlFiles = files.filter(f => f.endsWith('.yaml') && !f.startsWith('_'));

    for (const file of yamlFiles) {
      const content = await fs.readFile(path.join(ORCHESTRATION_DIR, file), 'utf8');
      if (content.includes('status: active')) {
        return { hasActive: true, fileName: file };
      }
    }
  } catch {
    // Directory doesn't exist or other error
  }
  return { hasActive: false };
}

/**
 * Detect resume intent
 */
function detectResumeIntent(prompt) {
  const resumePatterns = [
    /\b(continue|resume|pick\s+up|where\s+we\s+left)\b/i,
    /\b(back\s+to|return\s+to)\s+(the\s+)?(orchestration|task|work)/i,
    /\bwhat('s|\s+is)\s+(the\s+)?(status|progress)/i
  ];

  for (const pattern of resumePatterns) {
    if (pattern.test(prompt)) {
      return true;
    }
  }
  return false;
}

/**
 * Log detection for analysis
 */
async function logDetection(prompt, result) {
  try {
    await fs.mkdir(LOG_DIR, { recursive: true });

    const entry = {
      timestamp: new Date().toISOString(),
      prompt: prompt.substring(0, 200),
      score: result.score,
      action: result.action,
      signals: result.signals.slice(0, 5)
    };

    await fs.appendFile(DETECTION_LOG, JSON.stringify(entry) + '\n');
  } catch (err) {
    console.error('[orchestration-detector] Log error: ' + err.message);
  }
}

/**
 * UserPromptSubmit Hook - Detect complexity and trigger orchestration
 */
module.exports = {
  name: 'orchestration-detector',
  description: 'Detect complex tasks and trigger orchestration system',
  event: 'UserPromptSubmit',

  async handler(context) {
    const { prompt } = context;

    if (!prompt || prompt.length < 10) {
      return { proceed: true };
    }

    try {
      // Check for resume intent first
      if (detectResumeIntent(prompt)) {
        const { hasActive, fileName } = await hasActiveOrchestration();
        if (hasActive) {
          console.log('[orchestration-detector] Resume intent detected, active: ' + fileName);

          return {
            proceed: true,
            hookSpecificOutput: {
              hookEventName: 'UserPromptSubmit',
              orchestrationResume: true,
              additionalContext: '\n--- Orchestration Resume Detected ---\n' +
                'Active orchestration found: ' + fileName + '\n\n' +
                'Consider running: /orchestration:resume\n' +
                'This will restore full context from where you left off.\n---'
            }
          };
        }
      }

      // Calculate complexity score
      const result = calculateComplexityScore(prompt);

      if (result.shouldSkip) {
        return { proceed: true };
      }

      let action = 'none';
      let additionalContext = null;

      // Tiered response based on score
      if (result.score >= AUTO_THRESHOLD) {
        // Score >= 9: Auto-invoke
        action = 'auto-invoke';
        additionalContext = '\n' +
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n' +
          '🎯 HIGH COMPLEXITY DETECTED (Score: ' + result.score + ')\n' +
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n' +
          'This appears to be a complex, multi-phase task.\n\n' +
          '**AUTO-ORCHESTRATING**: Run /orchestration:plan for this task.\n\n' +
          'Break it down into phases before starting implementation.\n' +
          'This ensures nothing is missed and progress is trackable.\n\n' +
          'Signals detected: ' + result.signals.slice(0, 3).join(', ') + '\n' +
          '━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

        console.log('[orchestration-detector] AUTO-INVOKE: score=' + result.score);

      } else if (result.score >= SUGGEST_THRESHOLD) {
        // Score 4-8: Suggest
        action = 'suggest';
        additionalContext = '\n--- Orchestration Suggestion ---\n' +
          'Complexity Score: ' + result.score + '/20\n\n' +
          'This task may benefit from orchestration.\n' +
          'Consider: /orchestration:plan "' + prompt.substring(0, 50) + '..."\n\n' +
          'This will:\n' +
          '- Break it into trackable phases\n' +
          '- Define clear done criteria\n' +
          '- Enable progress tracking across sessions\n\n' +
          'Proceed directly if you prefer, or orchestrate first.\n---';

        console.log('[orchestration-detector] SUGGEST: score=' + result.score);
      }

      // Log the detection
      await logDetection(prompt, { ...result, action });

      if (additionalContext) {
        return {
          proceed: true,
          hookSpecificOutput: {
            hookEventName: 'UserPromptSubmit',
            orchestrationDetected: true,
            complexityScore: result.score,
            action,
            additionalContext
          }
        };
      }

    } catch (err) {
      console.error('[orchestration-detector] Error: ' + err.message);
    }

    return { proceed: true };
  }
};
