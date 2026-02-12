#!/usr/bin/env node
/**
 * Audit Logger Hook
 *
 * Automatically logs all Claude Code tool executions to JSONL format.
 * Replaces manual audit logging calls - this runs guaranteed on every tool use.
 *
 * Log location: .claude/logs/audit.jsonl
 * Format: Ready for Promtail/Loki ingestion
 *
 * Created: 2025-12-06
 * Fixed: 2026-01-21 - Converted from module export to executable stdin/stdout hook
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const LOG_DIR = path.join(__dirname, '..', 'logs');
const LOG_FILE = path.join(LOG_DIR, 'audit.jsonl');
const SESSION_FILE = path.join(LOG_DIR, '.current-session');

// Verbosity levels: 'minimal', 'standard', 'full'
const VERBOSITY = process.env.CLAUDE_AUDIT_VERBOSITY || 'standard';

/**
 * Get or create session name
 */
async function getSessionName() {
  try {
    const content = await fs.readFile(SESSION_FILE, 'utf8');
    // Try to parse as JSON (new format with {name, slug, started})
    try {
      const parsed = JSON.parse(content);
      return parsed.name || parsed.slug || 'default-session';
    } catch {
      // Fall back to plain text format
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
 * Estimate complexity based on tool and parameters
 */
function estimateComplexity(toolName, params) {
  // Higher complexity for multi-step or impactful operations
  const highComplexity = ['Write', 'NotebookEdit', 'Task'];
  const mediumComplexity = ['Edit', 'Bash', 'WebFetch', 'WebSearch'];

  let complexity = 1;

  if (highComplexity.includes(toolName)) {
    complexity = 3;
  } else if (mediumComplexity.includes(toolName)) {
    complexity = 2;
  }

  // Increase complexity for longer content
  if (params?.content && params.content.length > 1000) {
    complexity++;
  }
  if (params?.command && params.command.length > 200) {
    complexity++;
  }

  return Math.min(complexity, 5);
}

/**
 * Detect design patterns being applied based on tool usage
 * Maps tool calls to documented patterns in .claude/context/patterns/
 */
function detectPatterns(toolName, params) {
  const patterns = [];

  // Memory Storage Pattern - using Memory MCP to store findings
  if (toolName.includes('mcp__mcp-gateway__create_entities') ||
      toolName.includes('mcp__mcp-gateway__add_observations') ||
      toolName.includes('mcp__mcp-gateway__create_relations')) {
    patterns.push('memory-storage');
  }

  // Agent Selection Pattern - invoking Task tool (subagents)
  if (toolName === 'Task') {
    patterns.push('agent-selection');
    // More specific based on subagent type
    if (params?.subagent_type === 'Explore') {
      patterns.push('codebase-exploration');
    } else if (params?.subagent_type === 'Plan') {
      patterns.push('implementation-planning');
    }
  }

  // Capability Layering Pattern - executing scripts
  if (toolName === 'Bash') {
    const cmd = params?.command || '';
    if (cmd.includes('Scripts/') || cmd.includes('.claude/jobs/')) {
      patterns.push('capability-layering');
    }
    // Worktree Pattern - git worktree operations
    if (cmd.includes('git worktree')) {
      patterns.push('worktree-workflow');
    }
    // Autonomous Execution Pattern - scheduled jobs
    if (cmd.includes('claude-scheduled')) {
      patterns.push('autonomous-execution');
    }
  }

  // Skill Invocation Pattern
  if (toolName === 'Skill') {
    patterns.push('skill-invocation');
    // PARC Design Review
    if (params?.skill === 'design-review') {
      patterns.push('parc-design-review');
    }
    // Orchestration
    if (params?.skill?.startsWith('orchestration:')) {
      patterns.push('task-orchestration');
    }
  }

  // MCP Tool Usage - indicates MCP loading strategy in action
  if (toolName.startsWith('mcp__')) {
    patterns.push('mcp-integration');
    // Specific MCP servers
    if (toolName.includes('mcp__git__')) {
      patterns.push('git-mcp-usage');
    }
    if (toolName.includes('mcp__filesystem__')) {
      patterns.push('filesystem-mcp-usage');
    }
  }

  // Cross-Project Pattern - working outside the hub directory
  if (toolName === 'Read' || toolName === 'Write' || toolName === 'Edit') {
    const filePath = params?.file_path || '';
    const hubDir = path.basename(process.cwd());
    if (filePath.includes('/Code/') && !filePath.includes(hubDir)) {
      patterns.push('cross-project-work');
    }
  }

  // Web Research Pattern
  if (toolName === 'WebFetch' || toolName === 'WebSearch') {
    patterns.push('web-research');
  }

  return patterns;
}

/**
 * Format parameters based on verbosity level
 */
function formatParameters(params, verbosity) {
  if (!params) return undefined;

  switch (verbosity) {
    case 'minimal':
      return undefined;
    case 'standard':
      // Include parameter names but truncate long values
      const truncated = {};
      for (const [key, value] of Object.entries(params)) {
        if (typeof value === 'string' && value.length > 200) {
          truncated[key] = value.substring(0, 200) + '...[truncated]';
        } else {
          truncated[key] = value;
        }
      }
      return truncated;
    case 'full':
      return params;
    default:
      return params;
  }
}

/**
 * Main hook handler - reads from stdin, logs, outputs to stdout
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
  } catch (err) {
    // If we can't parse input, just allow the tool to proceed
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  const { tool_name, tool_input } = context;

  try {
    await ensureLogDir();
    const sessionName = await getSessionName();

    // Detect patterns being applied
    const detectedPatterns = detectPatterns(tool_name, tool_input);

    const entry = {
      timestamp: new Date().toISOString(),
      session: sessionName,
      who: 'claude',
      type: 'tool_execution',
      tool: tool_name,
      parameters: formatParameters(tool_input, VERBOSITY),
      verbosity: VERBOSITY,
      // PAI-compatible fields
      hook_event_type: 'PreToolUse',
      source_app: 'aifred',
      agent_type: 'main',
      complexity: estimateComplexity(tool_name, tool_input),
      // Pattern detection
      patterns: detectedPatterns.length > 0 ? detectedPatterns : undefined
    };

    await fs.appendFile(LOG_FILE, JSON.stringify(entry) + '\n');

  } catch (err) {
    // Don't block tool execution on logging failures
    // Log to stderr so it doesn't interfere with stdout protocol
    console.error(`[audit-logger] Failed to log: ${err.message}`);
  }

  // Always allow the tool to proceed - output JSON to stdout
  console.log(JSON.stringify({ proceed: true }));
}

main().catch(err => {
  console.error(`[audit-logger] Fatal error: ${err.message}`);
  // Still allow tool to proceed even on fatal error
  console.log(JSON.stringify({ proceed: true }));
});
