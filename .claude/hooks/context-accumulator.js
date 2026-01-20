/**
 * Context Accumulator Hook (AC-04 JICM)
 *
 * Part of Jarvis Intelligent Context Management (JICM)
 * Tracks cumulative context consumption to enable proactive management.
 *
 * With auto-compact OFF, this system provides early warning and
 * auto-triggers /smart-compact --full at 75% actual context.
 *
 * LOOP PREVENTION:
 * - State flag (.compaction-in-progress) prevents re-triggering
 * - Excluded tools/paths won't increment accumulator
 * - SessionStart resets estimate + clears flag
 *
 * Created: 2026-01-09
 * Updated: 2026-01-19 (telemetry integration)
 * PR Reference: PR-9 / AIfred Sync ADAPT #7, PR-13.1
 */

const fs = require('fs').promises;
const path = require('path');
const { execSync } = require('child_process');

// Telemetry integration
let telemetry;
try {
  telemetry = require('./telemetry-emitter');
} catch {
  telemetry = {
    emit: () => ({ success: false }),
    metrics: { gauge: () => {}, counter: () => {} }
  };
}

// Configuration
const WORKSPACE_ROOT = '/Users/aircannon/Claude/Jarvis';
const CONTEXT_DIR = path.join(WORKSPACE_ROOT, '.claude/context');
const LOG_DIR = path.join(WORKSPACE_ROOT, '.claude/logs');
const CONFIG_FILE = path.join(WORKSPACE_ROOT, '.claude/config/autonomy-config.yaml');

const ESTIMATE_FILE = path.join(LOG_DIR, 'context-estimate.json');
const MCP_USAGE_FILE = path.join(LOG_DIR, 'mcp-usage.json');  // PR-9.3: Track MCP tool usage
const COMPACTION_FLAG = path.join(CONTEXT_DIR, '.compaction-in-progress');
const CHECKPOINT_FILE = path.join(CONTEXT_DIR, '.soft-restart-checkpoint.md');
const SIGNAL_FILE = path.join(CONTEXT_DIR, '.auto-clear-signal');

// Default thresholds (can be overridden by config)
const MAX_CONTEXT_TOKENS = 200000;
let WARNING_THRESHOLD = 50;       // Show warning (default)
let VERIFY_THRESHOLD = 75;        // Trigger checkpoint (default)

/**
 * Load thresholds from autonomy-config.yaml
 * Falls back to defaults if config unavailable
 */
async function loadConfigThresholds() {
  try {
    const content = await fs.readFile(CONFIG_FILE, 'utf8');
    // Simple YAML parsing for threshold_tokens
    const match = content.match(/threshold_tokens:\s*(\d+)/);
    if (match) {
      const thresholdTokens = parseInt(match[1], 10);
      // Convert token threshold to percentage
      VERIFY_THRESHOLD = Math.round((thresholdTokens / MAX_CONTEXT_TOKENS) * 100);
      WARNING_THRESHOLD = Math.round(VERIFY_THRESHOLD * 0.67); // Warning at ~2/3 of threshold
    }
  } catch {
    // Use defaults if config unavailable
  }
}

// Rough token estimates (characters / 4)
const CHAR_TO_TOKEN_RATIO = 4;

// Tools to EXCLUDE from accumulation (prevent loops)
const EXCLUDED_TOOLS = [
  'mcp__memory__read_graph',
  'mcp__memory__search_nodes',
  'mcp__memory__open_nodes'
];

// File paths to EXCLUDE (checkpoint-related)
const EXCLUDED_PATH_PATTERNS = [
  '.soft-restart-checkpoint',
  'context-estimate.json',
  '.compaction-in-progress',
  '.auto-clear-signal',
  'compaction-history',
  'session-start-diagnostic'
];

/**
 * Check if tool/path should be excluded
 */
function shouldExclude(tool, parameters) {
  // Exclude specific tools
  if (EXCLUDED_TOOLS.includes(tool)) {
    return true;
  }

  // Exclude writes to checkpoint-related paths
  if (tool === 'Write' || tool === 'Edit') {
    const filePath = parameters?.file_path || '';
    for (const pattern of EXCLUDED_PATH_PATTERNS) {
      if (filePath.includes(pattern)) {
        return true;
      }
    }
  }

  return false;
}

/**
 * Estimate tokens from tool operation
 */
function estimateTokens(tool, parameters, result) {
  let chars = 0;

  switch (tool) {
    case 'Read':
      // Result contains file content
      chars = (result?.content?.length || result?.length || 0);
      break;

    case 'Write':
    case 'Edit':
      // Content being written
      chars = (parameters?.content?.length || parameters?.new_string?.length || 0);
      break;

    case 'Bash':
      // Command output
      chars = (result?.output?.length || result?.length || 0);
      break;

    case 'Task':
      // Agent delegation - significant context
      chars = 8000; // ~2000 tokens base cost
      break;

    case 'WebFetch':
    case 'mcp__fetch__fetch':
      chars = (result?.content?.length || 4000);
      break;

    case 'Grep':
    case 'Glob':
      chars = (result?.length || 500);
      break;

    default:
      // Default estimate for other tools
      chars = 400;
  }

  return Math.ceil(chars / CHAR_TO_TOKEN_RATIO);
}

/**
 * Load current estimate
 */
async function loadEstimate() {
  try {
    const content = await fs.readFile(ESTIMATE_FILE, 'utf8');
    return JSON.parse(content);
  } catch {
    return {
      sessionStart: new Date().toISOString(),
      totalTokens: 30000, // Base MCP load (~30K)
      toolCalls: 0,
      lastUpdate: new Date().toISOString()
    };
  }
}

/**
 * Save estimate
 */
async function saveEstimate(estimate) {
  await fs.mkdir(LOG_DIR, { recursive: true });
  estimate.lastUpdate = new Date().toISOString();
  await fs.writeFile(ESTIMATE_FILE, JSON.stringify(estimate, null, 2));
}

/**
 * Check if compaction is already in progress
 */
async function isCompactionInProgress() {
  try {
    await fs.access(COMPACTION_FLAG);
    return true;
  } catch {
    return false;
  }
}

/**
 * Set compaction in progress flag
 */
async function setCompactionInProgress() {
  await fs.mkdir(CONTEXT_DIR, { recursive: true });
  await fs.writeFile(COMPACTION_FLAG, new Date().toISOString());
}

/**
 * Get actual context percentage from /context command
 */
function getActualContextPercentage() {
  try {
    // This is a rough approach - we can't actually call /context from a hook
    // Instead, we trust our estimate and have SessionStart calibrate
    // Future: integrate with ccusage or similar tool
    return null; // Signal that we should use estimate
  } catch {
    return null;
  }
}

/**
 * Create checkpoint for /smart-compact
 */
async function createAutoCheckpoint(estimate) {
  const checkpointContent = `# Auto-Generated Context Checkpoint

**Created**: ${new Date().toISOString()}
**Reason**: JICM auto-trigger at estimated ${estimate.percentage.toFixed(0)}% context
**Tool Calls**: ${estimate.toolCalls}

## Work State

Check session-state.md and current-priorities.md for work context.
The context accumulator detected threshold exceeded and triggered this checkpoint.

## Next Steps After Restart

1. Review session-state.md for current work status
2. Check current-priorities.md for next tasks
3. Continue from where you left off

## JICM Info

- Estimated tokens: ${estimate.totalTokens}
- Threshold: ${VERIFY_THRESHOLD}%
- Auto-triggered: true

`;

  await fs.mkdir(CONTEXT_DIR, { recursive: true });
  await fs.writeFile(CHECKPOINT_FILE, checkpointContent);
}

/**
 * Signal auto-clear watcher
 */
async function signalClear() {
  await fs.writeFile(SIGNAL_FILE, new Date().toISOString());
}

/**
 * PR-9.3: Track MCP tool usage for smarter deselection recommendations
 */
async function trackMcpUsage(tool) {
  // Only track MCP tools (start with mcp__)
  if (!tool.startsWith('mcp__')) {
    return;
  }

  // Extract MCP name from tool (e.g., mcp__perplexity__search -> perplexity)
  const parts = tool.split('__');
  if (parts.length < 2) return;
  const mcpName = parts[1];

  try {
    // Load existing usage data
    let usage;
    try {
      const content = await fs.readFile(MCP_USAGE_FILE, 'utf8');
      usage = JSON.parse(content);
    } catch {
      usage = {
        sessionStart: new Date().toISOString(),
        mcpCalls: {},
        lastUpdate: new Date().toISOString()
      };
    }

    // Increment call count for this MCP
    if (!usage.mcpCalls[mcpName]) {
      usage.mcpCalls[mcpName] = { count: 0, tools: {}, lastUsed: null };
    }
    usage.mcpCalls[mcpName].count += 1;
    usage.mcpCalls[mcpName].lastUsed = new Date().toISOString();

    // Track specific tools within MCP
    if (!usage.mcpCalls[mcpName].tools[tool]) {
      usage.mcpCalls[mcpName].tools[tool] = 0;
    }
    usage.mcpCalls[mcpName].tools[tool] += 1;

    // Save
    usage.lastUpdate = new Date().toISOString();
    await fs.writeFile(MCP_USAGE_FILE, JSON.stringify(usage, null, 2));
  } catch {
    // Silent failure
  }
}

/**
 * Format warning message
 */
function formatWarning(percentage, level) {
  if (level === 'caution') {
    return `
[context-accumulator] ⚠️ Context at ~${percentage.toFixed(0)}%
Consider running /smart-compact if you want to checkpoint now.
`;
  }

  if (level === 'warning') {
    return `
╔══════════════════════════════════════════════════════════════╗
║  ⚠️  JICM: Context threshold reached (~${percentage.toFixed(0)}%)               ║
╚══════════════════════════════════════════════════════════════╝

Auto-triggering /smart-compact --full in 5 seconds...
To cancel: Ctrl+C
`;
  }

  return '';
}

/**
 * PostToolUse Hook - Context Accumulator
 */
/**
 * Handler function (can be called via require or stdin)
 */
async function handler(context) {
  const { tool, tool_input, result } = context;
  const parameters = tool_input || {};

  // Check exclusions (prevent loops)
  if (shouldExclude(tool, parameters)) {
    return { proceed: true };
  }

  try {
    // Load config thresholds (reads from autonomy-config.yaml)
    await loadConfigThresholds();

    // Load current estimate
    const estimate = await loadEstimate();

    // Add tokens from this tool call
    const tokens = estimateTokens(tool, parameters, result);
    estimate.totalTokens += tokens;
    estimate.toolCalls += 1;
    estimate.percentage = (estimate.totalTokens / MAX_CONTEXT_TOKENS) * 100;

    // Save updated estimate
    await saveEstimate(estimate);

    // PR-9.3: Track MCP tool usage for smarter deselection
    await trackMcpUsage(tool);

    // Check thresholds
    const percentage = estimate.percentage;

    // Below warning threshold - continue silently
    if (percentage < WARNING_THRESHOLD) {
      return { proceed: true };
    }

    // Warning threshold (50-74%) - show caution
    if (percentage >= WARNING_THRESHOLD && percentage < VERIFY_THRESHOLD) {
      // Only warn occasionally (every 10 tool calls after threshold)
      if (estimate.toolCalls % 10 === 0) {
        console.error(formatWarning(percentage, 'caution'));
        // Emit telemetry
        telemetry.emit('AC-04', 'context_warning', {
          percentage: percentage.toFixed(1),
          threshold: WARNING_THRESHOLD,
          tool_calls: estimate.toolCalls,
          estimated_tokens: estimate.totalTokens
        });
      }
      return { proceed: true };
    }

    // Verify threshold (75%+) - check for compaction
    if (percentage >= VERIFY_THRESHOLD) {
      // Check if already handling compaction
      if (await isCompactionInProgress()) {
        return { proceed: true }; // Already handling
      }

      // Set flag to prevent loops
      await setCompactionInProgress();

      // Show warning (to stderr so it doesn't interfere with JSON output)
      console.error(formatWarning(percentage, 'warning'));

      // Emit telemetry for checkpoint trigger
      telemetry.emit('AC-04', 'context_checkpoint', {
        percentage: percentage.toFixed(1),
        threshold: VERIFY_THRESHOLD,
        tool_calls: estimate.toolCalls,
        estimated_tokens: estimate.totalTokens,
        auto_triggered: true
      });

      // Create checkpoint
      await createAutoCheckpoint(estimate);

      // Signal watcher for /clear
      await signalClear();

      // Log action
      const logEntry = `${new Date().toISOString()} | JICM | Auto-triggered at ${percentage.toFixed(0)}% estimated\n`;
      await fs.appendFile(path.join(LOG_DIR, 'jicm-triggers.log'), logEntry);
    }

  } catch (err) {
    // Silent failure - don't break tool execution
    console.error(`[context-accumulator] Error: ${err.message}`);
  }

  return { proceed: true };
}

// Export for require() usage
module.exports = {
  name: 'context-accumulator',
  description: 'Track context consumption for JICM (auto-compact OFF)',
  event: 'PostToolUse',
  handler
};

// ============================================================
// STDIN/STDOUT HANDLER - Required for Claude Code hooks
// ============================================================
// When run directly via `node <file>`, read JSON from stdin and output to stdout

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
      console.error(`[context-accumulator] Parse error: ${err.message}`);
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
