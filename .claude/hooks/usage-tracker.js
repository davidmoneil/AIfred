#!/usr/bin/env node
/**
 * Usage Tracker — Consolidated PostToolUse Hook
 *
 * Merges 3 tracking hooks into a single process:
 *   1. trackSelection()    — selection-audit.js (Task/Skill/Web/MCP tools)
 *   2. trackFileAccess()   — file-access-tracker.js (Read tool)
 *   3. trackMemoryAccess() — memory-maintenance.js (mcp__ tools)
 *
 * All tracking is append-only logging (never blocks, never modifies behavior).
 * Internal dispatch by tool name — each invocation runs only relevant trackers.
 *
 * Registered: PostToolUse, matchers:
 *   ^(Task|Skill|WebSearch|WebFetch|EnterPlanMode|Read)$|^mcp__
 *
 * Created: 2026-02-09 (B.3 Hook Consolidation, Merge 3)
 * Source hooks: selection-audit.js, file-access-tracker.js, memory-maintenance.js
 */

const fs = require('fs').promises;
const path = require('path');

const WORKSPACE_ROOT = '/Users/aircannon/Claude/Jarvis';
const LOG_DIR = path.join(WORKSPACE_ROOT, '.claude/logs');

// ============================================================
// SELECTION AUDIT — Track tool/agent/skill selections
// ============================================================

const AUDIT_FILE = path.join(LOG_DIR, 'selection-audit.jsonl');

const TOOL_CATEGORIES = {
  file_ops: ['Read', 'Write', 'Edit', 'Glob', 'Grep', 'NotebookEdit'],
  git: ['mcp__git__', 'Bash:git'],
  research: ['WebSearch', 'WebFetch', 'mcp__perplexity__', 'mcp__brave-search__', 'mcp__gptresearcher__', 'mcp__arxiv__', 'mcp__wikipedia__'],
  browser: ['mcp__playwright__'],
  memory: ['mcp__memory__'],
  subagent: ['Task'],
  skill: ['Skill'],
  bash: ['Bash']
};

const AUDIT_PATTERNS = ['Task', 'Skill', 'EnterPlanMode', /^mcp__/, 'WebSearch', 'WebFetch'];

function shouldAudit(tool) {
  return AUDIT_PATTERNS.some(p => p instanceof RegExp ? p.test(tool) : tool === p);
}

function categorize(tool) {
  for (const [cat, patterns] of Object.entries(TOOL_CATEGORIES)) {
    if (patterns.some(p => tool.startsWith(p) || tool === p)) return cat;
  }
  return 'other';
}

function extractAuditContext(tool, input) {
  const params = input || {};
  switch (tool) {
    case 'Task': return { subagent_type: params.subagent_type, description: params.description, prompt_preview: (params.prompt || '').slice(0, 100) };
    case 'Skill': return { skill: params.skill, args: params.args };
    case 'WebSearch': return { query: params.query };
    case 'WebFetch': return { url: params.url };
    default:
      if (tool.startsWith('mcp__')) {
        const preview = {};
        for (const k of Object.keys(params).slice(0, 3)) {
          preview[k] = typeof params[k] === 'string' ? params[k].slice(0, 50) : params[k];
        }
        return preview;
      }
      return {};
  }
}

async function trackSelection(tool, tool_input) {
  if (!shouldAudit(tool)) return;
  const entry = {
    timestamp: new Date().toISOString(),
    tool, category: categorize(tool),
    context: extractAuditContext(tool, tool_input)
  };
  await fs.mkdir(LOG_DIR, { recursive: true });
  await fs.appendFile(AUDIT_FILE, JSON.stringify(entry) + '\n');
}

// ============================================================
// FILE ACCESS TRACKER — Track context file reads
// ============================================================

const ACCESS_LOG_FILE = path.join(LOG_DIR, 'file-access.json');
const SESSION_FILE = path.join(LOG_DIR, '.current-session');

const TRACKED_PATHS = [
  '.claude/context/', '.claude/commands/', '.claude/agents/',
  '.claude/skills/', '.claude/hooks/', 'projects/project-aion/',
  'paths-registry.yaml', 'CLAUDE.md'
];

function shouldTrackFile(filePath) {
  if (!filePath) return false;
  return TRACKED_PATHS.some(t => filePath.includes(t));
}

function getRelativePath(filePath) {
  return filePath.startsWith(WORKSPACE_ROOT) ? filePath.substring(WORKSPACE_ROOT.length + 1) : filePath;
}

async function getCurrentSession() {
  try {
    const content = await fs.readFile(SESSION_FILE, 'utf8');
    try { const p = JSON.parse(content); return p.name || p.slug || 'default-session'; }
    catch { return content.trim() || 'default-session'; }
  } catch { return 'default-session'; }
}

async function trackFileAccess(tool_input, tool_result) {
  if (tool_result?.error) return;
  const filePath = tool_input?.file_path;
  if (!shouldTrackFile(filePath)) return;

  const relativePath = getRelativePath(filePath);
  const session = await getCurrentSession();
  const today = new Date().toISOString().split('T')[0];
  const now = new Date().toISOString();

  let log;
  try {
    const content = await fs.readFile(ACCESS_LOG_FILE, 'utf8');
    log = JSON.parse(content);
  } catch {
    log = { version: '1.0', created: now, last_updated: now, files: {}, sessions: {} };
  }

  if (!log.files[relativePath]) {
    log.files[relativePath] = { first_read: now, last_read: now, read_count: 0, sessions: [], daily_history: [] };
  }
  const fr = log.files[relativePath];
  fr.last_read = now;
  fr.read_count++;
  if (!fr.sessions.includes(session)) { fr.sessions.push(session); if (fr.sessions.length > 20) fr.sessions.shift(); }
  if (!fr.daily_history.includes(today)) { fr.daily_history.push(today); if (fr.daily_history.length > 30) fr.daily_history.shift(); }

  if (!log.sessions[session]) { log.sessions[session] = { started: now, file_reads: 0, unique_files: [] }; }
  log.sessions[session].file_reads++;
  if (!log.sessions[session].unique_files.includes(relativePath)) log.sessions[session].unique_files.push(relativePath);

  log.last_updated = now;
  await fs.mkdir(LOG_DIR, { recursive: true });
  await fs.writeFile(ACCESS_LOG_FILE, JSON.stringify(log, null, 2));
}

// ============================================================
// MEMORY MAINTENANCE — Track Memory MCP entity access
// ============================================================

const MEMORY_METADATA_FILE = path.join(LOG_DIR, 'memory-access.json');

const MEMORY_TOOLS = [
  'mcp__mcp-gateway__open_nodes', 'mcp__mcp-gateway__search_nodes', 'mcp__mcp-gateway__read_graph',
  'mcp__memory__open_nodes', 'mcp__memory__search_nodes', 'mcp__memory__read_graph'
];

function isMemoryTool(toolName) {
  return MEMORY_TOOLS.includes(toolName);
}

function extractEntityNames(toolInput, toolName) {
  if (toolName.includes('open_nodes') && toolInput?.names) return toolInput.names;
  if (toolName.includes('search_nodes') && toolInput?.query) return [`search:${toolInput.query}`];
  if (toolName.includes('read_graph')) return ['graph:full'];
  return [];
}

async function trackMemoryAccess(toolName, toolInput) {
  if (!isMemoryTool(toolName)) return;
  const entities = extractEntityNames(toolInput, toolName);
  if (entities.length === 0) return;

  const today = new Date().toISOString().split('T')[0];
  let metadata;
  try {
    const content = await fs.readFile(MEMORY_METADATA_FILE, 'utf8');
    metadata = JSON.parse(content);
  } catch {
    metadata = { version: '1.0', created: new Date().toISOString(), lastUpdated: null, entities: {}, toolUsage: {} };
  }

  for (const name of entities) {
    if (!metadata.entities[name]) {
      metadata.entities[name] = { firstAccessed: today, lastAccessed: today, accessCount: 1, accessHistory: [today] };
    } else {
      metadata.entities[name].lastAccessed = today;
      metadata.entities[name].accessCount++;
      if (!metadata.entities[name].accessHistory.includes(today)) {
        metadata.entities[name].accessHistory.push(today);
        if (metadata.entities[name].accessHistory.length > 30) metadata.entities[name].accessHistory.shift();
      }
    }
  }

  if (!metadata.toolUsage[toolName]) metadata.toolUsage[toolName] = { count: 0, lastUsed: today };
  metadata.toolUsage[toolName].count++;
  metadata.toolUsage[toolName].lastUsed = today;

  metadata.lastUpdated = new Date().toISOString();
  await fs.mkdir(LOG_DIR, { recursive: true });
  await fs.writeFile(MEMORY_METADATA_FILE, JSON.stringify(metadata, null, 2));
}

// ============================================================
// MAIN HANDLER — Dispatch by tool type
// ============================================================

async function handler(context) {
  const { tool, tool_name, tool_input, tool_result } = context;
  const toolId = tool || tool_name;

  try {
    // Run applicable trackers (all are independent, no short-circuit needed)
    const tasks = [];

    // Selection audit: Task, Skill, WebSearch, WebFetch, EnterPlanMode, mcp__*
    if (shouldAudit(toolId)) {
      tasks.push(trackSelection(toolId, tool_input));
    }

    // File access tracker: Read tool only
    if (toolId === 'Read') {
      tasks.push(trackFileAccess(tool_input, tool_result));
    }

    // Memory maintenance: mcp__memory__* / mcp__mcp-gateway__* tools
    if (isMemoryTool(toolId)) {
      tasks.push(trackMemoryAccess(toolId, tool_input));
    }

    // Run all applicable trackers in parallel
    if (tasks.length > 0) {
      await Promise.all(tasks);
    }
  } catch {
    // Silent failure — tracking should never block workflow
  }

  return { proceed: true };
}

// Export for require() usage
module.exports = {
  name: 'usage-tracker',
  description: 'Consolidated usage tracking (selections, file access, memory)',
  event: 'PostToolUse',
  handler
};

// ============================================================
// STDIN/STDOUT HANDLER — Required for Claude Code hooks
// ============================================================
if (require.main === module) {
  const chunks = [];
  process.stdin.on('data', chunk => chunks.push(chunk));
  process.stdin.on('end', async () => {
    let context;
    try {
      context = JSON.parse(Buffer.concat(chunks).toString('utf8'));
    } catch {
      console.log(JSON.stringify({ proceed: true }));
      return;
    }
    try {
      const result = await handler(context);
      console.log(JSON.stringify(result));
    } catch {
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
