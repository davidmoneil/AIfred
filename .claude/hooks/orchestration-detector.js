/**
 * Orchestration Detector Hook (Jarvis Enhanced)
 *
 * Analyzes user prompts for complexity and triggers orchestration system
 * when complex multi-phase tasks are detected.
 *
 * Jarvis Enhancements:
 * - MCP tier signals (browser/research tasks trigger Tier 3 warnings)
 * - Skill routing (detected patterns suggest relevant skills)
 * - Integration with Tool Selection Intelligence pattern
 *
 * Tiered Response:
 *   Score < 4:  Nothing (simple task)
 *   Score 4-8:  Suggest orchestration
 *   Score >= 9: Auto-invoke orchestration
 *
 * Created: 2026-01-03
 * Updated: 2026-01-09 (Jarvis MCP/skill integration)
 * Source: AIfred baseline 2ea4e8b (adapted for Jarvis)
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const WORKSPACE_ROOT = '/Users/aircannon/Claude/Jarvis';
const LOG_DIR = path.join(WORKSPACE_ROOT, '.claude/logs');
const DETECTION_LOG = path.join(LOG_DIR, 'orchestration-detections.jsonl');
const ORCHESTRATION_DIR = path.join(WORKSPACE_ROOT, '.claude/orchestration');

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

// ============================================================
// JARVIS ENHANCEMENTS: MCP Tier Detection
// ============================================================

// Tier 3 MCP triggers (browser automation, expensive APIs)
const TIER3_MCP_PATTERNS = [
  /\b(browser|playwright|selenium|puppeteer)\b/i,
  /\b(automate|automation)\s+(the\s+)?browser/i,
  /\b(web\s*app|webapp)\s+(test|testing|automation)/i,
  /\b(e2e|end-to-end)\s+test/i,
  /\b(screenshot|snapshot)\s+(the\s+)?(page|website|screen)/i
];

// Research MCP triggers (Perplexity, GPTresearcher, deep research)
const RESEARCH_MCP_PATTERNS = [
  /\b(research|investigate|deep\s*dive)\b/i,
  /\b(comprehensive|thorough)\s+(analysis|research|investigation)/i,
  /\b(academic|scholarly|scientific)\s+(paper|research|source)/i,
  /\b(arxiv|paper|journal|publication)\b/i,
  /\b(multi-source|cross-reference)\b/i
];

// ============================================================
// JARVIS ENHANCEMENTS: Skill Routing
// ============================================================

// Skill suggestions based on detected patterns
const SKILL_PATTERNS = {
  docx: [/\b(word|docx|document)\s*(file|document|report)/i, /\b(create|write|generate)\s+(a\s+)?(word|docx)/i],
  xlsx: [/\b(excel|xlsx|spreadsheet)\b/i, /\b(create|write|generate)\s+(a\s+)?(excel|spreadsheet)/i],
  pdf: [/\b(pdf)\s*(file|document)/i, /\b(create|merge|split)\s+(a\s+)?pdf/i],
  pptx: [/\b(powerpoint|pptx|presentation|slides)\b/i, /\b(create|write|generate)\s+(a\s+)?presentation/i],
  'mcp-builder': [/\b(mcp|model\s+context\s+protocol)\s*(server|tool)/i, /\b(create|build)\s+(an?\s+)?mcp/i],
  'skill-creator': [/\b(create|build|make)\s+(a\s+)?(new\s+)?skill/i, /\b(skill|command)\s*(creation|builder)/i]
};

/**
 * Detect suggested skills based on prompt
 */
function detectSkills(prompt) {
  const suggestedSkills = [];

  for (const [skill, patterns] of Object.entries(SKILL_PATTERNS)) {
    for (const pattern of patterns) {
      if (pattern.test(prompt)) {
        suggestedSkills.push(skill);
        break;
      }
    }
  }

  return suggestedSkills;
}

/**
 * Detect MCP tier requirements
 */
function detectMcpTiers(prompt) {
  const tiers = {
    tier3: [],
    research: []
  };

  for (const pattern of TIER3_MCP_PATTERNS) {
    if (pattern.test(prompt)) {
      tiers.tier3.push('playwright');
      break;
    }
  }

  for (const pattern of RESEARCH_MCP_PATTERNS) {
    if (pattern.test(prompt)) {
      tiers.research.push('deep-research');
      break;
    }
  }

  return tiers;
}

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

  // JARVIS: Tier 3 MCP detection (+2 for browser/research tasks)
  const mcpTiers = detectMcpTiers(prompt);
  if (mcpTiers.tier3.length > 0) {
    score += 2;
    signals.push('tier3_mcp');
  }
  if (mcpTiers.research.length > 0) {
    score += 1;
    signals.push('research_mcp');
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
      signals: result.signals.slice(0, 5),
      skills: result.skills || [],
      mcpTiers: result.mcpTiers || {}
    };

    await fs.appendFile(DETECTION_LOG, JSON.stringify(entry) + '\n');
  } catch (err) {
    console.error('[orchestration-detector] Log error: ' + err.message);
  }
}

/**
 * Format skill suggestions
 */
function formatSkillSuggestions(skills) {
  if (skills.length === 0) return '';

  return '\n\n💡 **Relevant Skills Detected**: ' + skills.map(s => '`/' + s + '`').join(', ') +
    '\nConsider using these skills for specialized workflows.';
}

/**
 * Format MCP tier warnings
 */
function formatMcpWarnings(mcpTiers) {
  const warnings = [];

  if (mcpTiers.tier3.length > 0) {
    warnings.push('⚠️ **Tier 3 MCP Required**: This task needs Playwright/browser automation. ' +
      'Ensure Playwright MCP is enabled.');
  }

  if (mcpTiers.research.length > 0) {
    warnings.push('📚 **Research MCPs Recommended**: Consider enabling Perplexity or GPTresearcher ' +
      'for comprehensive research tasks.');
  }

  return warnings.length > 0 ? '\n\n' + warnings.join('\n') : '';
}

/**
 * Handler function (can be called via require or stdin)
 */
async function handler(context) {
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

      // JARVIS: Detect skills and MCP tiers
      const skills = detectSkills(prompt);
      const mcpTiers = detectMcpTiers(prompt);

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
          'Signals detected: ' + result.signals.slice(0, 3).join(', ') +
          formatSkillSuggestions(skills) +
          formatMcpWarnings(mcpTiers) +
          '\n━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

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
          '- Enable progress tracking across sessions\n' +
          formatSkillSuggestions(skills) +
          formatMcpWarnings(mcpTiers) +
          '\nProceed directly if you prefer, or orchestrate first.\n---';

        console.log('[orchestration-detector] SUGGEST: score=' + result.score);

      } else if (skills.length > 0 || mcpTiers.tier3.length > 0 || mcpTiers.research.length > 0) {
        // Low complexity but skill/MCP suggestions available
        action = 'tool-hint';
        additionalContext = formatSkillSuggestions(skills) + formatMcpWarnings(mcpTiers);

        if (additionalContext.trim()) {
          console.log('[orchestration-detector] TOOL-HINT: skills=' + skills.join(','));
        }
      }

      // Log the detection
      await logDetection(prompt, { ...result, action, skills, mcpTiers });

      if (additionalContext && additionalContext.trim()) {
        return {
          proceed: true,
          hookSpecificOutput: {
            hookEventName: 'UserPromptSubmit',
            orchestrationDetected: result.score >= SUGGEST_THRESHOLD,
            complexityScore: result.score,
            action,
            suggestedSkills: skills,
            mcpTiers,
            additionalContext
          }
        };
      }

  } catch (err) {
    console.error('[orchestration-detector] Error: ' + err.message);
  }

  return { proceed: true };
}

// Export for require() usage
module.exports = {
  name: 'orchestration-detector',
  description: 'Detect complex tasks and trigger orchestration system (Jarvis enhanced)',
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
      console.error(`[orchestration-detector] Parse error: ${err.message}`);
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
