/**
 * Session Start Hook (with Soft Restart Support)
 *
 * Auto-loads context when Claude Code starts:
 * - Current git branch and uncommitted changes count
 * - Session state (truncated to 2000 chars)
 * - Current priorities (truncated to 1500 chars)
 * - AIfred baseline status check
 * - MCP loading suggestions based on work type (PR-8.3)
 *
 * Soft Restart Support (PR-8.4):
 * - Checks for .soft-restart-checkpoint.md file
 * - If found, loads checkpoint context instead of normal session
 * - Clears checkpoint file after loading
 * - Handles both /clear (source="clear") and new session (source="startup")
 *
 * SessionStart Sources:
 * - "startup" - Fresh session start
 * - "resume" - From --resume, --continue, or /resume
 * - "clear" - After /clear command (same process, conversation cleared)
 * - "compact" - After auto/manual compaction
 *
 * Priority: HIGH (Context Loading)
 * Created: 2026-01-06
 * Updated: 2026-01-07 (PR-8.3 - Dynamic Loading Protocol)
 * Updated: 2026-01-07 (PR-8.4 - Soft Restart/Checkpoint Support)
 * Updated: 2026-01-07 (Enhanced source detection for /clear)
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
const CHECKPOINT_PATH = path.join(WORKSPACE_ROOT, '.claude/context/.soft-restart-checkpoint.md');

const SESSION_STATE_MAX_CHARS = 2000;
const PRIORITIES_MAX_CHARS = 1500;
const CHECKPOINT_MAX_CHARS = 3000;

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
 * Check if checkpoint file exists
 */
async function checkForCheckpoint() {
  try {
    await fs.access(CHECKPOINT_PATH);
    return true;
  } catch {
    return false;
  }
}

/**
 * Read checkpoint file
 */
async function readCheckpoint() {
  try {
    const content = await fs.readFile(CHECKPOINT_PATH, 'utf8');
    return truncateText(content, CHECKPOINT_MAX_CHARS);
  } catch (err) {
    return null;
  }
}

/**
 * Delete checkpoint file after loading
 */
async function clearCheckpoint() {
  try {
    await fs.unlink(CHECKPOINT_PATH);
  } catch {
    // Ignore errors
  }
}

/**
 * Format checkpoint resume message
 */
function formatCheckpointMessage(checkpointContent, gitInfo, source) {
  const sourceLabel = source === 'clear' ? 'POST-CLEAR' : 'NEW SESSION';
  const lines = [
    '',
    '╔══════════════════════════════════════════════════════════════╗',
    `║     🔄 SOFT RESTART (${sourceLabel}) - CHECKPOINT LOADED     ║`,
    '╚══════════════════════════════════════════════════════════════╝',
    '',
    `📍 Branch: ${gitInfo.branch} (${gitInfo.status})`,
    `📦 Source: ${source}`,
    '',
    '─────────────────── Checkpoint Context ───────────────────',
    '',
    checkpointContent,
    '',
    '─────────────────── Instructions ───────────────────',
    '',
    '   ✅ Context cleared, checkpoint loaded',
    '   📝 Say "continue" or describe what to do next',
    source === 'startup' ? '   💡 MCP config was adjusted - reduced context load' : '   💡 MCPs unchanged (use hard restart for MCP reduction)',
    '',
    '══════════════════════════════════════════════════════════════',
    ''
  ];

  return lines.join('\n');
}

/**
 * Format message for /clear without checkpoint
 */
function formatClearMessage(gitInfo) {
  const lines = [
    '',
    '╔══════════════════════════════════════════════════════════════╗',
    '║               CONVERSATION CLEARED                           ║',
    '╚══════════════════════════════════════════════════════════════╝',
    '',
    `📍 Branch: ${gitInfo.branch} (${gitInfo.status})`,
    '',
    '   💡 No checkpoint found - starting fresh',
    '   💡 Use /soft-restart before /clear to preserve context',
    '',
    '══════════════════════════════════════════════════════════════',
    ''
  ];

  return lines.join('\n');
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
  description: 'Auto-load context when Claude Code starts (with checkpoint support)',
  event: 'SessionStart',

  async handler(context) {
    // DIAGNOSTIC: Write to file to confirm hook is firing
    const diagnosticPath = path.join(WORKSPACE_ROOT, '.claude/logs/session-start-diagnostic.log');
    const timestamp = new Date().toISOString();
    const diagnosticEntry = `${timestamp} | SessionStart fired | source=${context?.source || 'undefined'} | context_keys=${Object.keys(context || {}).join(',')}\n`;
    try {
      const dir = path.dirname(diagnosticPath);
      await fs.mkdir(dir, { recursive: true });
      await fs.appendFile(diagnosticPath, diagnosticEntry);
    } catch (diagErr) {
      // Silent fail for diagnostic
    }

    try {
      // Detect session source (startup, resume, clear, compact)
      const source = context?.source || 'unknown';
      const gitInfo = getGitInfo();

      // Check for soft-restart checkpoint first (PR-8.4)
      // Works for both /clear (source="clear") and new sessions (source="startup")
      const hasCheckpoint = await checkForCheckpoint();

      if (hasCheckpoint) {
        // Checkpoint mode: load checkpoint context
        const checkpointContent = await readCheckpoint();

        if (checkpointContent) {
          const message = formatCheckpointMessage(checkpointContent, gitInfo, source);
          console.log(message);

          // Clear checkpoint file after loading
          await clearCheckpoint();

          return { proceed: true };
        }
      }

      // For /clear without checkpoint, show minimal banner
      if (source === 'clear') {
        const clearMessage = formatClearMessage(gitInfo);
        console.log(clearMessage);
        return { proceed: true };
      }

      // Normal mode: load session state and priorities
      const [sessionState, priorities] = await Promise.all([
        readFileSafe(SESSION_STATE_PATH, SESSION_STATE_MAX_CHARS),
        readFileSafe(PRIORITIES_PATH, PRIORITIES_MAX_CHARS)
      ]);

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
