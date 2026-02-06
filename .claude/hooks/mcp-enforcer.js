#!/usr/bin/env node
/**
 * MCP Enforcer Hook
 *
 * Encourages use of MCP tools over bash equivalents:
 * - Suggests MCP alternatives for common operations
 * - Provides recommendations for better tool choices
 *
 * Profile: general
 * Event: PreToolUse (Bash)
 * Priority: RECOMMENDED
 * Created: 2025-12-06
 * Adapted for AIfred: 2026-02-05
 */

const fs = require('fs');
const path = require('path');

// Map of Bash commands to MCP alternatives
const MCP_ALTERNATIVES = {
  'docker ps': { mcp: 'mcp__docker-mcp__list-containers', description: 'Use Docker MCP for container listing' },
  'docker logs': { mcp: 'mcp__docker-mcp__get-logs', description: 'Use Docker MCP for log retrieval' },
  'docker inspect': { mcp: 'mcp__docker-mcp__get-container-info', description: 'Use Docker MCP for container info' },
  'git status': { mcp: 'mcp__git__git_status', description: 'Use Git MCP for status' },
  'git log': { mcp: 'mcp__git__git_log', description: 'Use Git MCP for history' },
  'git diff': { mcp: 'mcp__git__git_diff', description: 'Use Git MCP for diffs' },
  'git show': { mcp: 'mcp__git__git_show', description: 'Use Git MCP for commit details' },
  'git branch': { mcp: 'mcp__git__git_branch', description: 'Use Git MCP for branches' },
  'cat ': { mcp: 'mcp__filesystem__read_text_file', description: 'Use Filesystem MCP for reading files', note: 'Only for single file reads' },
  'ls ': { mcp: 'mcp__filesystem__list_directory', description: 'Use Filesystem MCP for directory listing' },
  'tree ': { mcp: 'mcp__filesystem__directory_tree', description: 'Use Filesystem MCP for tree view' },
  'find ': { mcp: 'mcp__filesystem__search_files', description: 'Use Filesystem MCP for file search', note: 'For pattern-based searching' }
};

const COOLDOWN_FILE = path.join(__dirname, '..', 'logs', '.mcp-enforcer-last');
const COOLDOWN_MS = 60000; // 1 minute

function shouldSuggest() {
  try {
    const stat = fs.statSync(COOLDOWN_FILE);
    if (Date.now() - stat.mtimeMs < COOLDOWN_MS) return false;
  } catch { /* file doesn't exist */ }
  try {
    const dir = path.dirname(COOLDOWN_FILE);
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
    fs.writeFileSync(COOLDOWN_FILE, Date.now().toString());
  } catch { /* ignore */ }
  return true;
}

function findMCPAlternative(command) {
  for (const [bashCmd, info] of Object.entries(MCP_ALTERNATIVES)) {
    if (command.startsWith(bashCmd) || command.includes(` ${bashCmd}`)) {
      return { ...info, original: bashCmd };
    }
  }
  return null;
}

async function main() {
  let input = '';
  for await (const chunk of process.stdin) input += chunk;
  const context = JSON.parse(input);

  const { tool_name, tool_input } = context;
  if (tool_name !== 'Bash') {
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  const command = tool_input?.command || '';
  const alternative = findMCPAlternative(command);

  if (alternative && shouldSuggest()) {
    console.error(`\n[mcp-enforcer] MCP alternative available`);
    console.error(`  Command: ${command.substring(0, 60)}${command.length > 60 ? '...' : ''}`);
    console.error(`  Suggestion: ${alternative.description}`);
    console.error(`  MCP Tool: ${alternative.mcp}`);
    if (alternative.note) console.error(`  Note: ${alternative.note}`);
    console.error(`  Proceeding with Bash (MCP preferred for consistency)\n`);
  }

  console.log(JSON.stringify({ proceed: true }));
}

main().catch(err => {
  console.error(`[mcp-enforcer] Fatal: ${err.message}`);
  console.log(JSON.stringify({ proceed: true }));
});
