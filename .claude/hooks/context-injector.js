/**
 * Context Injector Hook (evo-2026-01-023)
 *
 * PreToolUse hook that injects relevant additionalContext to the model
 * based on tool usage patterns and current context budget.
 *
 * Created: 2026-01-18 (R&D Cycle implementation)
 *
 * Features:
 * - Injects tool-specific guidance
 * - Warns about context budget when high
 * - Provides selection intelligence hints
 * - Suggests better tool alternatives
 */

const fs = require('fs');
const path = require('path');

// Tool categories and their context hints
const TOOL_HINTS = {
  // File operations
  'Read': {
    hint: 'Use Glob to find files first if path is uncertain. Read returns max 2000 lines by default.',
    priority: 'low'
  },
  'Write': {
    hint: 'Prefer Edit over Write for existing files. Write overwrites completely.',
    priority: 'medium'
  },
  'Edit': {
    hint: 'Edit requires old_string to be unique in the file. Use replace_all for global replacements.',
    priority: 'low'
  },
  'Glob': {
    hint: 'Glob is fastest for finding files by pattern. Use ** for recursive search.',
    priority: 'low'
  },
  'Grep': {
    hint: 'Grep uses ripgrep syntax. Use -C for context lines. output_mode=files_with_matches for file list only.',
    priority: 'low'
  },

  // Bash operations
  'Bash': {
    hint: 'Prefer dedicated tools over Bash: Read over cat, Glob over find, Grep over grep.',
    priority: 'low'
  },

  // Task/Agent operations
  'Task': {
    hint: 'Use subagent_type=Explore for codebase exploration. Use run_in_background for long tasks.',
    priority: 'medium'
  },

  // MCP tools
  'mcp__memory__create_entities': {
    hint: 'Store decisions and architectural choices in Memory MCP. Details go in context files.',
    priority: 'low'
  },
  'mcp__git__git_commit': {
    hint: 'Use conventional commits format. Include Co-Authored-By for Claude Code commits.',
    priority: 'medium'
  },

  // Web operations
  'WebFetch': {
    hint: 'WebFetch has a 15-minute cache. Use prompt parameter to extract specific information.',
    priority: 'low'
  },
  'WebSearch': {
    hint: 'WebSearch is US-only. Use current year (2026) in queries for recent information.',
    priority: 'medium'
  }
};

// Context budget thresholds (Tier 3: disabled — JICM handles context proactively.
// Set to 200% so budget warnings never fire. Tool hints still active.)
const BUDGET_THRESHOLDS = {
  warning: 200,
  critical: 200
};

// Config paths
const CONFIG = {
  watcherStatusPath: path.join(process.env.CLAUDE_PROJECT_DIR || '.', '.claude/context/.jicm-state'),
  selectionGuidePath: path.join(process.env.CLAUDE_PROJECT_DIR || '.', '.claude/context/patterns/selection-intelligence-guide.md')
};

/**
 * Get current context usage percentage from Watcher's status file
 * (Reads live .jicm-state file from JICM v6 watcher)
 */
function getContextUsage() {
  try {
    if (fs.existsSync(CONFIG.watcherStatusPath)) {
      const content = fs.readFileSync(CONFIG.watcherStatusPath, 'utf8');
      // .jicm-state is YAML-like: "context_pct: 42"
      const match = content.match(/^context_pct:\s*(\d+)/m);
      if (match) return parseInt(match[1], 10);
    }
  } catch (e) {
    // Silently fail - watcher status not available
  }
  return 0;
}

/**
 * Build context injection based on tool and state
 */
function buildContextInjection(tool, parameters, contextUsage) {
  const injections = [];

  // 1. Tool-specific hint
  const toolHint = TOOL_HINTS[tool];
  if (toolHint && toolHint.priority !== 'low') {
    // Only inject medium/high priority hints to reduce noise
    injections.push(`[Tool Hint] ${toolHint.hint}`);
  }

  // 2. Context budget warning
  if (contextUsage >= BUDGET_THRESHOLDS.critical) {
    injections.push(`[Context Budget] CRITICAL: ${contextUsage.toFixed(0)}% context used. Consider /checkpoint or /compact soon.`);
  } else if (contextUsage >= BUDGET_THRESHOLDS.warning) {
    injections.push(`[Context Budget] WARNING: ${contextUsage.toFixed(0)}% context used. Monitor usage.`);
  }

  // 3. Tool-specific guidance for complex operations
  if (tool === 'Bash') {
    const command = parameters?.command || '';

    // Suggest better alternatives
    if (command.includes('cat ') && !command.includes('|')) {
      injections.push('[Better Alternative] Use Read tool instead of cat for reading files.');
    }
    if (command.includes('grep ') || command.includes('rg ')) {
      injections.push('[Better Alternative] Use Grep tool instead of grep/rg command.');
    }
    if (command.includes('find ')) {
      injections.push('[Better Alternative] Use Glob tool instead of find command.');
    }

    // Git operation hints
    if (command.includes('git commit')) {
      injections.push('[Git] Remember: Use conventional commits, include Co-Authored-By for AI commits.');
    }
    if (command.includes('git push --force') || command.includes('git push -f')) {
      injections.push('[Git Safety] Force push detected. Confirm this is intentional.');
    }
  }

  // 4. Task agent hints
  if (tool === 'Task') {
    const agentType = parameters?.subagent_type || '';
    if (agentType === 'general-purpose') {
      injections.push('[Agent Selection] Consider using specialized agents: Explore for codebase, Plan for architecture.');
    }
  }

  return injections;
}

/**
 * Handler function
 */
async function handler(context) {
  const { tool, tool_input } = context;
  const parameters = tool_input || context.parameters || {};

  try {
    // Get context usage
    const contextUsage = getContextUsage();

    // Build injections
    const injections = buildContextInjection(tool, parameters, contextUsage);

    // If no injections, just proceed
    if (injections.length === 0) {
      return { proceed: true };
    }

    // Return with additionalContext
    return {
      proceed: true,
      additionalContext: injections.join('\n')
    };

  } catch (error) {
    // Fail-open on error
    return { proceed: true };
  }
}

// Export for require() usage
module.exports = {
  name: 'context-injector',
  description: 'Inject contextual hints before tool execution',
  event: 'PreToolUse',
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
      // Silent fail - don't pollute output
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
