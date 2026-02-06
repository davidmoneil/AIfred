#!/usr/bin/env node
/**
 * Task Metrics Collector Hook
 *
 * Runs on SubagentStop to capture token usage, tool counts, and performance
 * data for every Task tool execution. Writes JSONL to task-metrics.jsonl.
 *
 * Input (stdin): { agentName, result, duration, success }
 * Output (stdout): {} (no context injection - subagent-stop.js handles that)
 *
 * Created: 2026-02-05
 * Pattern: SubagentStop hook (same event as subagent-stop.js)
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const LOG_DIR = path.join(__dirname, '..', 'logs');
const METRICS_FILE = path.join(LOG_DIR, 'task-metrics.jsonl');
const SESSION_FILE = path.join(LOG_DIR, '.current-session');

// Agent type classification
const BUILTIN_SUBAGENTS = ['Plan', 'Explore', 'claude-code-guide'];
const FEATURE_DEV_PREFIXES = ['code-architect', 'code-explorer', 'code-reviewer'];
const PLUGIN_AGENTS = [
  'hookify:conversation-analyzer',
  'agent-sdk-dev:agent-sdk-verifier-py',
  'agent-sdk-dev:agent-sdk-verifier-ts',
  'project-plan-validator'
];

/**
 * Classify agent type from agent name
 */
function classifyAgent(agentName) {
  if (!agentName) return 'unknown';

  if (BUILTIN_SUBAGENTS.includes(agentName)) {
    return 'builtin-subagent';
  }

  if (FEATURE_DEV_PREFIXES.some(p => agentName.includes(p))) {
    return 'feature-dev';
  }

  if (PLUGIN_AGENTS.some(p => agentName === p || agentName.includes(p))) {
    return 'plugin-agent';
  }

  // Custom agents (from .claude/agents/)
  const customAgentNames = [
    'deep-research', 'service-troubleshooter', 'docker-deployer',
    'memory-bank-synchronizer', 'plex-troubleshoot', 'creative-projects',
    'ollama-manager', 'code-analyzer', 'code-tester', 'code-implementer'
  ];
  if (customAgentNames.includes(agentName)) {
    return 'custom-agent';
  }

  // Parallel-dev agents
  if (agentName.startsWith('parallel-dev')) {
    return 'parallel-dev';
  }

  return 'other';
}

/**
 * Parse <usage> tags from result text
 * Format: <usage>total_tokens: N\ntool_uses: N\nduration_ms: N</usage>
 */
function parseUsageTags(resultStr) {
  const usage = {
    totalTokens: null,
    toolUses: null,
    durationMs: null
  };

  if (!resultStr) return usage;

  const usageMatch = resultStr.match(/<usage>([\s\S]*?)<\/usage>/);
  if (!usageMatch) return usage;

  const block = usageMatch[1];

  const tokensMatch = block.match(/total_tokens:\s*(\d+)/);
  if (tokensMatch) usage.totalTokens = parseInt(tokensMatch[1], 10);

  const toolsMatch = block.match(/tool_uses:\s*(\d+)/);
  if (toolsMatch) usage.toolUses = parseInt(toolsMatch[1], 10);

  const durationMatch = block.match(/duration_ms:\s*(\d+)/);
  if (durationMatch) usage.durationMs = parseInt(durationMatch[1], 10);

  return usage;
}

/**
 * Parse agentId from result text
 * Format: "agentId: a9664fc"
 */
function parseAgentId(resultStr) {
  if (!resultStr) return null;
  const match = resultStr.match(/agentId:\s*([a-f0-9]+)/);
  return match ? match[1] : null;
}

/**
 * Get session name from .current-session file
 */
async function getSessionName() {
  try {
    const content = await fs.readFile(SESSION_FILE, 'utf8');
    try {
      const parsed = JSON.parse(content);
      return parsed.name || parsed.slug || 'default-session';
    } catch {
      return content.trim();
    }
  } catch {
    return 'default-session';
  }
}

/**
 * Ensure log directory exists
 */
async function ensureLogDir() {
  try {
    await fs.mkdir(LOG_DIR, { recursive: true });
  } catch (err) {
    if (err.code !== 'EEXIST') throw err;
  }
}

/**
 * Main handler - collect and write metrics
 */
async function main() {
  // Read JSON from stdin
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const input = Buffer.concat(chunks).toString('utf8');

  let context;
  try {
    context = JSON.parse(input);
  } catch {
    console.log(JSON.stringify({}));
    return;
  }

  const {
    agentName = 'unknown',
    result = '',
    duration = 0,
    success = true
  } = context || {};

  try {
    await ensureLogDir();

    const resultStr = String(result);
    const usage = parseUsageTags(resultStr);
    const agentId = parseAgentId(resultStr);
    const session = await getSessionName();

    const entry = {
      timestamp: new Date().toISOString(),
      session,
      agentId,
      agentName,
      agentType: classifyAgent(agentName),
      success,
      durationMs: usage.durationMs || duration || null,
      totalTokens: usage.totalTokens,
      toolUses: usage.toolUses,
      resultLength: resultStr.length
    };

    await fs.appendFile(METRICS_FILE, JSON.stringify(entry) + '\n');
  } catch (err) {
    console.error(`[metrics-collector] Error: ${err.message}`);
  }

  // Never inject context - subagent-stop.js handles that
  console.log(JSON.stringify({}));
}

main().catch(err => {
  console.error(`[metrics-collector] Fatal: ${err.message}`);
  console.log(JSON.stringify({}));
});
