#!/usr/bin/env node
/**
 * Subagent Dispatcher Hook
 *
 * Event: SubagentStop
 * Purpose: Single entry point for all subagent completion handling.
 *
 * Consolidates:
 * - subagent-stop.js (activity logging, chaining suggestions)
 * - metrics-collector.js (token/cost metrics from transcripts)
 *
 * Created: 2026-03-03 (consolidation)
 */

const fs = require('fs').promises;
const path = require('path');
const { readStdin, getSessionName, ensureDir, appendJsonl, LOG_DIR, runHook } = require('./lib/shared');

// Configuration
const AGENT_LOG_FILE = path.join(LOG_DIR, 'agent-activity.jsonl');
const METRICS_FILE = path.join(LOG_DIR, 'task-metrics.jsonl');

// ============================================================================
// Section 1: Agent Classification (from metrics-collector)
// ============================================================================

const BUILTIN_SUBAGENTS = ['Plan', 'Explore', 'claude-code-guide', 'Bash'];
const FEATURE_DEV_PREFIXES = ['code-architect', 'code-explorer', 'code-reviewer'];
const PLUGIN_AGENTS = [
  'hookify:conversation-analyzer',
  'agent-sdk-dev:agent-sdk-verifier-py',
  'agent-sdk-dev:agent-sdk-verifier-ts',
  'project-plan-validator'
];

function classifyAgent(agentType) {
  if (!agentType) return 'unknown';
  if (BUILTIN_SUBAGENTS.includes(agentType)) return 'builtin-subagent';
  if (FEATURE_DEV_PREFIXES.some(p => agentType.includes(p))) return 'feature-dev';
  if (PLUGIN_AGENTS.some(p => agentType === p || agentType.includes(p))) return 'plugin-agent';
  if (agentType.startsWith('parallel-dev')) return 'parallel-dev';
  if (agentType === 'general-purpose') return 'general-purpose';
  const customAgents = [
    'deep-research', 'service-troubleshooter', 'docker-deployer',
    'memory-bank-synchronizer', 'code-analyzer', 'code-tester',
    'code-implementer'
  ];
  if (customAgents.includes(agentType)) return 'custom-agent';
  return 'other';
}

// ============================================================================
// Section 2: Transcript Metrics (from metrics-collector)
// ============================================================================

async function extractTranscriptMetrics(transcriptPath) {
  const metrics = {
    totalInputTokens: 0, totalOutputTokens: 0,
    cacheReadTokens: 0, cacheWriteTokens: 0,
    costUSD: null, modelUsage: {}, numTurns: 0, toolUseCount: 0
  };

  if (!transcriptPath) return nullMetrics();

  const expandedPath = transcriptPath.replace(/^~/, process.env.HOME || '/tmp');
  try { await fs.access(expandedPath); } catch { return nullMetrics(); }

  try {
    const content = await fs.readFile(expandedPath, 'utf8');
    const lines = content.trim().split('\n');
    let hasData = false;

    for (const line of lines) {
      try {
        const entry = JSON.parse(line);
        const msg = entry.message;
        if (!msg) continue;

        if (entry.type === 'assistant' || msg.role === 'assistant') {
          metrics.numTurns++;
          if (msg.usage) {
            hasData = true;
            metrics.totalInputTokens += msg.usage.input_tokens || 0;
            metrics.totalOutputTokens += msg.usage.output_tokens || 0;
            metrics.cacheReadTokens += msg.usage.cache_read_input_tokens || 0;
            metrics.cacheWriteTokens += msg.usage.cache_creation_input_tokens || 0;
          }
          if (msg.model && msg.usage) {
            if (!metrics.modelUsage[msg.model]) {
              metrics.modelUsage[msg.model] = { inputTokens: 0, outputTokens: 0, turns: 0 };
            }
            metrics.modelUsage[msg.model].inputTokens += msg.usage.input_tokens || 0;
            metrics.modelUsage[msg.model].outputTokens += msg.usage.output_tokens || 0;
            metrics.modelUsage[msg.model].turns++;
          }
          if (Array.isArray(msg.content)) {
            for (const block of msg.content) {
              if (block.type === 'tool_use') metrics.toolUseCount++;
            }
          }
        }
        if (entry.costUSD != null) metrics.costUSD = entry.costUSD;
        if (entry.total_cost_usd != null) metrics.costUSD = entry.total_cost_usd;
      } catch { /* skip unparseable lines */ }
    }

    if (!hasData) return nullMetrics();
    if (Object.keys(metrics.modelUsage).length === 0) metrics.modelUsage = null;
    return metrics;
  } catch { return nullMetrics(); }
}

function nullMetrics() {
  return {
    totalInputTokens: null, totalOutputTokens: null,
    cacheReadTokens: null, cacheWriteTokens: null,
    costUSD: null, modelUsage: null, numTurns: null, toolUseCount: 0
  };
}

// ============================================================================
// Section 3: Agent Chaining (from subagent-stop)
// ============================================================================

const AGENT_CHAINS = {
  'code-reviewer': {
    onHighIssues: 'Consider running code fixes or addressing the HIGH priority issues found.',
    onCritical: 'CRITICAL issues found! Address these before proceeding.',
    default: 'Code review complete. Ready for next steps.'
  },
  'code-explorer': { default: 'Exploration complete. You can now plan implementation based on findings.' },
  'code-architect': { default: 'Architecture design complete. Ready to begin implementation.' },
  'Explore': { default: 'Codebase exploration complete.' },
  'Plan': { default: 'Planning complete. Review the plan and proceed with implementation.' },
  'deep-research': { default: 'Research complete. Findings ready for review.' }
};

function analyzeResult(agentName, result) {
  const resultStr = String(result || '');
  const chainConfig = AGENT_CHAINS[agentName] || {};
  if (/\[X\]|CRITICAL/.test(resultStr) && chainConfig.onCritical) {
    return { severity: 'critical', suggestion: chainConfig.onCritical };
  }
  if (/\[!\]|HIGH/.test(resultStr) && chainConfig.onHighIssues) {
    return { severity: 'high', suggestion: chainConfig.onHighIssues };
  }
  return { severity: 'normal', suggestion: chainConfig.default || '' };
}

// ============================================================================
// Main
// ============================================================================

async function main() {
  const context = await readStdin();

  const {
    session_id = null,
    agent_id = null,
    agent_type = 'unknown',
    agent_transcript_path = null,
    last_assistant_message = ''
  } = context || {};

  const messageLength = (last_assistant_message || '').length;

  try {
    await ensureDir(LOG_DIR);
    const session = await getSessionName();

    // --- Activity log (from subagent-stop) ---
    await appendJsonl(AGENT_LOG_FILE, {
      timestamp: new Date().toISOString(),
      event: 'agent_complete',
      agent: agent_type,
      resultLength: messageLength,
      durationMs: 0,
      success: true
    });

    // --- Metrics log (from metrics-collector) ---
    const txMetrics = await extractTranscriptMetrics(agent_transcript_path);
    await appendJsonl(METRICS_FILE, {
      timestamp: new Date().toISOString(),
      session,
      sessionId: session_id,
      agentId: agent_id,
      agentType: agent_type,
      agentCategory: classifyAgent(agent_type),
      transcriptPath: agent_transcript_path || null,
      lastMessageLength: messageLength,
      totalInputTokens: txMetrics.totalInputTokens,
      totalOutputTokens: txMetrics.totalOutputTokens,
      cacheReadTokens: txMetrics.cacheReadTokens,
      cacheWriteTokens: txMetrics.cacheWriteTokens,
      costUSD: txMetrics.costUSD,
      modelUsage: txMetrics.modelUsage,
      numTurns: txMetrics.numTurns,
      toolUseCount: txMetrics.toolUseCount
    });

    // --- Chaining context (from subagent-stop) ---
    const analysis = analyzeResult(agent_type, last_assistant_message);
    const contextParts = [];
    contextParts.push(`\n--- Agent Complete: ${agent_type} ---`);
    if (agent_id) contextParts.push(`Agent ID: ${agent_id}`);
    contextParts.push(`Last message size: ${messageLength} chars`);
    if (analysis.severity === 'critical') contextParts.push('\nCRITICAL issues detected in agent output!');
    else if (analysis.severity === 'high') contextParts.push('\nHigh-priority issues detected in agent output.');
    if (analysis.suggestion) contextParts.push(`\n${analysis.suggestion}`);

    console.log(JSON.stringify({
      hookSpecificOutput: {
        hookEventName: 'SubagentStop',
        additionalContext: contextParts.join('\n')
      }
    }));

  } catch (err) {
    console.error(`[subagent-dispatcher] Error: ${err.message}`);
    console.log(JSON.stringify({}));
  }
}

runHook('subagent-dispatcher', main);
