/**
 * Selection Audit Hook
 *
 * Part of PR-9.4: Selection Validation
 * Logs tool/agent/skill selections for audit and analysis.
 *
 * Tracks:
 * - Tool selections (Read, Write, Glob, Grep, etc.)
 * - MCP tool selections (mcp__*)
 * - Task delegations (subagents)
 * - Skill invocations
 *
 * Created: 2026-01-09
 * PR Reference: PR-9.4
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const WORKSPACE_ROOT = '/Users/aircannon/Claude/Jarvis';
const LOG_DIR = path.join(WORKSPACE_ROOT, '.claude/logs');
const AUDIT_FILE = path.join(LOG_DIR, 'selection-audit.jsonl');

// Tool categories for analysis
const TOOL_CATEGORIES = {
  file_ops: ['Read', 'Write', 'Edit', 'Glob', 'Grep', 'NotebookEdit'],
  git: ['mcp__git__', 'Bash:git'],
  research: ['WebSearch', 'WebFetch', 'mcp__perplexity__', 'mcp__brave-search__', 'mcp__gptresearcher__', 'mcp__arxiv__', 'mcp__wikipedia__'],
  browser: ['mcp__playwright__', 'browser-automation'],
  memory: ['mcp__memory__'],
  subagent: ['Task'],
  skill: ['Skill'],
  bash: ['Bash']
};

// Interesting selections to log (not everything)
const LOG_PATTERNS = [
  // Always log these
  'Task',           // Subagent delegations
  'Skill',          // Skill invocations
  'EnterPlanMode',  // Planning mode
  // Log MCP tools
  /^mcp__/,
  // Log research tools
  'WebSearch',
  'WebFetch'
];

/**
 * Check if this tool selection should be logged
 */
function shouldLog(tool) {
  for (const pattern of LOG_PATTERNS) {
    if (pattern instanceof RegExp) {
      if (pattern.test(tool)) return true;
    } else {
      if (tool === pattern) return true;
    }
  }
  return false;
}

/**
 * Categorize a tool
 */
function categorize(tool) {
  for (const [category, patterns] of Object.entries(TOOL_CATEGORIES)) {
    for (const pattern of patterns) {
      if (tool.startsWith(pattern) || tool === pattern) {
        return category;
      }
    }
  }
  return 'other';
}

/**
 * Extract context from tool input for audit
 */
function extractContext(tool, tool_input) {
  const params = tool_input || {};

  switch (tool) {
    case 'Task':
      return {
        subagent_type: params.subagent_type,
        description: params.description,
        prompt_preview: (params.prompt || '').slice(0, 100)
      };
    case 'Skill':
      return {
        skill: params.skill,
        args: params.args
      };
    case 'WebSearch':
      return { query: params.query };
    case 'WebFetch':
      return { url: params.url };
    case 'Read':
      return { file: params.file_path };
    case 'Glob':
      return { pattern: params.pattern };
    case 'Grep':
      return { pattern: params.pattern, path: params.path };
    default:
      // For MCP tools, try to extract key params
      if (tool.startsWith('mcp__')) {
        const keys = Object.keys(params).slice(0, 3);
        const preview = {};
        for (const k of keys) {
          const v = params[k];
          preview[k] = typeof v === 'string' ? v.slice(0, 50) : v;
        }
        return preview;
      }
      return {};
  }
}

/**
 * Handler function
 */
async function handler(context) {
  const { tool, tool_input } = context;

  // Check if we should log this selection
  if (!shouldLog(tool)) {
    return { proceed: true };
  }

  try {
    // Build audit entry
    const entry = {
      timestamp: new Date().toISOString(),
      tool: tool,
      category: categorize(tool),
      context: extractContext(tool, tool_input)
    };

    // Append to audit log (JSONL format)
    await fs.mkdir(LOG_DIR, { recursive: true });
    await fs.appendFile(AUDIT_FILE, JSON.stringify(entry) + '\n');

  } catch (err) {
    // Silent failure - don't break tool execution
    console.error(`[selection-audit] Error: ${err.message}`);
  }

  return { proceed: true };
}

// Export for require() usage
module.exports = {
  name: 'selection-audit',
  description: 'Log tool/agent/skill selections for audit and analysis',
  event: 'PostToolUse',
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
      console.error(`[selection-audit] Parse error: ${err.message}`);
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
