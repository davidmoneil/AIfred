/**
 * MCP Enforcer Hook
 *
 * Encourages use of MCP tools over bash equivalents:
 * - Suggests MCP alternatives for common operations
 * - Tracks MCP vs Bash usage patterns
 * - Provides recommendations for better tool choices
 *
 * Priority: LOW (Workflow Enhancement)
 * Created: 2025-12-06
 */

// Map of Bash commands to MCP alternatives
const MCP_ALTERNATIVES = {
  // Docker operations
  'docker ps': {
    mcp: 'mcp__docker-mcp__list-containers',
    description: 'Use Docker MCP for container listing'
  },
  'docker logs': {
    mcp: 'mcp__docker-mcp__get-logs',
    description: 'Use Docker MCP for log retrieval'
  },
  'docker inspect': {
    mcp: 'mcp__docker-mcp__get-container-info',
    description: 'Use Docker MCP for container info'
  },

  // Git operations
  'git status': {
    mcp: 'mcp__git__git_status',
    description: 'Use Git MCP for status'
  },
  'git log': {
    mcp: 'mcp__git__git_log',
    description: 'Use Git MCP for history'
  },
  'git diff': {
    mcp: 'mcp__git__git_diff',
    description: 'Use Git MCP for diffs'
  },
  'git show': {
    mcp: 'mcp__git__git_show',
    description: 'Use Git MCP for commit details'
  },
  'git branch': {
    mcp: 'mcp__git__git_branch',
    description: 'Use Git MCP for branches'
  },

  // File operations
  'cat ': {
    mcp: 'mcp__filesystem__read_text_file',
    description: 'Use Filesystem MCP for reading files',
    note: 'Only for single file reads'
  },
  'ls ': {
    mcp: 'mcp__filesystem__list_directory',
    description: 'Use Filesystem MCP for directory listing'
  },
  'tree ': {
    mcp: 'mcp__filesystem__directory_tree',
    description: 'Use Filesystem MCP for tree view'
  },
  'find ': {
    mcp: 'mcp__filesystem__search_files',
    description: 'Use Filesystem MCP for file search',
    note: 'For pattern-based searching'
  }
};

// Track usage statistics
const usageStats = {
  bashCount: 0,
  mcpSuggested: 0,
  mcpUsed: 0
};

// Cooldown to avoid spamming suggestions
let lastSuggestionTime = 0;
const SUGGESTION_COOLDOWN = 60000; // 1 minute

/**
 * Check if command matches an MCP alternative
 */
function findMCPAlternative(command) {
  for (const [bashCmd, info] of Object.entries(MCP_ALTERNATIVES)) {
    if (command.startsWith(bashCmd) || command.includes(` ${bashCmd}`)) {
      return { ...info, original: bashCmd };
    }
  }
  return null;
}

/**
 * Check if enough time has passed for a new suggestion
 */
function shouldSuggest() {
  const now = Date.now();
  if (now - lastSuggestionTime > SUGGESTION_COOLDOWN) {
    lastSuggestionTime = now;
    return true;
  }
  return false;
}

module.exports = {
  name: 'mcp-enforcer',
  description: 'Encourage use of MCP tools over bash equivalents',
  event: 'PreToolUse',

  async handler(context) {
    const { tool, parameters } = context;

    // Track MCP usage
    if (tool.startsWith('mcp__')) {
      usageStats.mcpUsed++;
      return { proceed: true };
    }

    // Only check Bash commands
    if (tool !== 'Bash') return { proceed: true };

    const command = parameters?.command || '';
    usageStats.bashCount++;

    // Check for MCP alternative
    const alternative = findMCPAlternative(command);

    if (alternative && shouldSuggest()) {
      usageStats.mcpSuggested++;

      console.log('\n[mcp-enforcer] 💡 MCP ALTERNATIVE AVAILABLE');
      console.log('─'.repeat(50));
      console.log(`Command: ${command.substring(0, 60)}${command.length > 60 ? '...' : ''}`);
      console.log(`Suggestion: ${alternative.description}`);
      console.log(`MCP Tool: ${alternative.mcp}`);
      if (alternative.note) {
        console.log(`Note: ${alternative.note}`);
      }
      console.log('─'.repeat(50));

      // Don't block, just inform
      console.log('[mcp-enforcer] Proceeding with Bash (MCP preferred for consistency)\n');
    }

    return { proceed: true };
  }
};

// Export stats for external use
module.exports.getStats = () => ({ ...usageStats });
module.exports.resetStats = () => {
  usageStats.bashCount = 0;
  usageStats.mcpSuggested = 0;
  usageStats.mcpUsed = 0;
};
