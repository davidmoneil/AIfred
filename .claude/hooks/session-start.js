/**
 * Session Start Hook
 *
 * Auto-loads context when Claude Code starts:
 * - Current git branch and uncommitted changes count
 * - Session state (truncated to 2000 chars)
 * - Current priorities (truncated to 1500 chars)
 * - AIfred baseline status check
 * - MCP loading suggestions based on work type (PR-8.3)
 *
 * Priority: HIGH (Context Loading)
 * Created: 2026-01-06
 * Updated: 2026-01-07 (PR-8.3 - Dynamic Loading Protocol)
 * Source: AIfred baseline af66364 (implemented for Jarvis)
 */

const fs = require('fs').promises;
const path = require('path');
const { execSync } = require('child_process');

// Configuration
const WORKSPACE_ROOT = '/Users/aircannon/Claude/Jarvis';
const SESSION_STATE_PATH = path.join(WORKSPACE_ROOT, '.claude/context/session-state.md');
const PRIORITIES_PATH = path.join(WORKSPACE_ROOT, '.claude/context/projects/current-priorities.md');
const AIFRED_BASELINE = '/Users/aircannon/Claude/AIfred';

const SESSION_STATE_MAX_CHARS = 2000;
const PRIORITIES_MAX_CHARS = 1500;

// MCP Tier 2 suggestions based on work type keywords
const WORK_TYPE_MCP_MAP = {
  // PR/GitHub work
  'PR': ['github'],
  'pull request': ['github'],
  'issue': ['github'],
  'review': ['github'],

  // Research/documentation
  'research': ['context7', 'duckduckgo'],
  'documentation': ['context7'],
  'docs': ['context7'],
  'library': ['context7'],

  // Complex planning
  'design': ['sequential-thinking'],
  'architecture': ['sequential-thinking'],
  'planning': ['sequential-thinking'],
  'complex': ['sequential-thinking'],

  // Time-sensitive
  'schedule': ['time'],
  'timestamp': ['time'],
  'timezone': ['time'],

  // Browser/testing (Tier 3 - just inform, don't suggest)
  'browser': ['⚠️ Playwright (Tier 3 - use /browser-test)'],
  'webapp': ['⚠️ Playwright (Tier 3 - use /browser-test)'],
};

/**
 * Truncate text to max chars, preserving complete lines
 */
function truncateText(text, maxChars) {
  if (text.length <= maxChars) return text;

  // Find last newline before maxChars
  const truncated = text.substring(0, maxChars);
  const lastNewline = truncated.lastIndexOf('\n');

  if (lastNewline > maxChars * 0.5) {
    return truncated.substring(0, lastNewline) + '\n\n[... truncated ...]';
  }
  return truncated + '\n\n[... truncated ...]';
}

/**
 * Get git branch and status info
 */
function getGitInfo() {
  try {
    const branch = execSync('git rev-parse --abbrev-ref HEAD', {
      cwd: WORKSPACE_ROOT,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe']
    }).trim();

    const statusOutput = execSync('git status --porcelain', {
      cwd: WORKSPACE_ROOT,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe']
    }).trim();

    const uncommittedCount = statusOutput ? statusOutput.split('\n').length : 0;

    return {
      branch,
      uncommittedCount,
      status: uncommittedCount === 0 ? 'clean' : `${uncommittedCount} uncommitted changes`
    };
  } catch (err) {
    return {
      branch: 'unknown',
      uncommittedCount: 0,
      status: 'git info unavailable'
    };
  }
}

/**
 * Analyze work type from session state and suggest MCPs
 */
function analyzeWorkType(sessionState, priorities) {
  const combinedText = (sessionState + ' ' + priorities).toLowerCase();
  const suggestedMcps = new Set();
  const tier3Warnings = [];

  for (const [keyword, mcps] of Object.entries(WORK_TYPE_MCP_MAP)) {
    if (combinedText.includes(keyword.toLowerCase())) {
      for (const mcp of mcps) {
        if (mcp.startsWith('⚠️')) {
          tier3Warnings.push(mcp);
        } else {
          suggestedMcps.add(mcp);
        }
      }
    }
  }

  return {
    suggested: Array.from(suggestedMcps),
    tier3Warnings: [...new Set(tier3Warnings)]
  };
}

/**
 * Check AIfred baseline status
 */
function checkBaselineStatus() {
  try {
    // Fetch latest from origin
    execSync('git fetch origin', {
      cwd: AIFRED_BASELINE,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe']
    });

    // Check if behind
    const behindCount = execSync('git rev-list HEAD..origin/main --count', {
      cwd: AIFRED_BASELINE,
      encoding: 'utf8',
      stdio: ['pipe', 'pipe', 'pipe']
    }).trim();

    const count = parseInt(behindCount, 10);
    if (count > 0) {
      return `⚠️ ${count} commit(s) behind → run /sync-aifred-baseline`;
    }
    return '✅ Up to date';
  } catch (err) {
    return '❓ Unable to check (network or path issue)';
  }
}

/**
 * Read file safely
 */
async function readFileSafe(filePath, maxChars) {
  try {
    const content = await fs.readFile(filePath, 'utf8');
    return truncateText(content, maxChars);
  } catch (err) {
    return `[Unable to read: ${err.message}]`;
  }
}

/**
 * Format MCP suggestions section
 */
function formatMcpSuggestions(mcpAnalysis) {
  if (mcpAnalysis.suggested.length === 0 && mcpAnalysis.tier3Warnings.length === 0) {
    return '   No specific MCPs suggested for current work type';
  }

  const lines = [];

  if (mcpAnalysis.suggested.length > 0) {
    lines.push(`   Tier 2 (Task-Scoped): ${mcpAnalysis.suggested.join(', ')}`);
    lines.push(`   → If needed, these will be loaded on-demand`);
  }

  if (mcpAnalysis.tier3Warnings.length > 0) {
    lines.push('');
    for (const warning of mcpAnalysis.tier3Warnings) {
      lines.push(`   ${warning}`);
    }
  }

  return lines.join('\n');
}

/**
 * Format budget reminder section
 */
function formatBudgetReminder() {
  return [
    '   💡 Run /context-budget for current usage',
    '   💡 Run /checkpoint before enabling new MCPs'
  ].join('\n');
}

/**
 * Format the context injection message
 */
function formatContextMessage(gitInfo, sessionState, priorities, baselineStatus, mcpAnalysis) {
  const lines = [
    '',
    '╔══════════════════════════════════════════════════════════════╗',
    '║                    JARVIS SESSION START                      ║',
    '╚══════════════════════════════════════════════════════════════╝',
    '',
    `📍 Branch: ${gitInfo.branch} (${gitInfo.status})`,
    `📦 AIfred Baseline: ${baselineStatus}`,
    '',
    '─────────────────── MCP & Budget (PR-8.3) ───────────────────',
    '',
    formatMcpSuggestions(mcpAnalysis),
    '',
    formatBudgetReminder(),
    '',
    '─────────────────── Session State ───────────────────',
    '',
    sessionState,
    '',
    '─────────────────── Current Priorities ───────────────────',
    '',
    priorities,
    '',
    '══════════════════════════════════════════════════════════════',
    ''
  ];

  return lines.join('\n');
}

module.exports = {
  name: 'session-start',
  description: 'Auto-load context when Claude Code starts',
  event: 'SessionStart',

  async handler(context) {
    try {
      // Gather all context in parallel
      const [sessionState, priorities] = await Promise.all([
        readFileSafe(SESSION_STATE_PATH, SESSION_STATE_MAX_CHARS),
        readFileSafe(PRIORITIES_PATH, PRIORITIES_MAX_CHARS)
      ]);

      const gitInfo = getGitInfo();
      const baselineStatus = checkBaselineStatus();

      // Analyze work type and suggest MCPs (PR-8.3)
      const mcpAnalysis = analyzeWorkType(sessionState, priorities);

      // Output the context
      const message = formatContextMessage(gitInfo, sessionState, priorities, baselineStatus, mcpAnalysis);
      console.log(message);

    } catch (err) {
      console.log(`[session-start] Error loading context: ${err.message}`);
    }

    return { proceed: true };
  }
};
