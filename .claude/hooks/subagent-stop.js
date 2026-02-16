#!/usr/bin/env node
/**
 * Subagent Stop Hook
 *
 * Runs when any spawned agent (Task subagent) completes.
 * Enables:
 * - Agent activity logging
 * - Agent chaining (suggesting next agent based on output)
 * - Result summarization
 *
 * Created: 2026-01-03
 * Fixed: 2026-01-21 - Converted to stdin/stdout executable hook
 * Source: hooks-mastery research project
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const LOG_DIR = path.join(__dirname, '..', 'logs');
const AGENT_LOG_FILE = path.join(LOG_DIR, 'agent-activity.jsonl');

// Agent chaining rules - what to suggest after each agent type
const AGENT_CHAINS = {
  'code-reviewer': {
    onHighIssues: 'Consider running code fixes or addressing the HIGH priority issues found.',
    onCritical: 'CRITICAL issues found! Address these before proceeding.',
    default: 'Code review complete. Ready for next steps.'
  },
  'code-explorer': {
    default: 'Exploration complete. You can now plan implementation based on findings.'
  },
  'code-architect': {
    default: 'Architecture design complete. Ready to begin implementation.'
  },
  'Explore': {
    default: 'Codebase exploration complete.'
  },
  'Plan': {
    default: 'Planning complete. Review the plan and proceed with implementation.'
  },
  'deep-research': {
    default: 'Research complete. Findings ready for review.'
  }
};

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
 * Log agent completion
 */
async function logAgentCompletion(agentName, resultLength, duration, success) {
  try {
    await ensureLogDir();

    const entry = {
      timestamp: new Date().toISOString(),
      event: 'agent_complete',
      agent: agentName,
      resultLength: resultLength,
      durationMs: duration,
      success: success
    };

    await fs.appendFile(AGENT_LOG_FILE, JSON.stringify(entry) + '\n');
  } catch (err) {
    console.error(`[subagent-stop] Failed to log: ${err.message}`);
  }
}

/**
 * Analyze agent result for chaining decisions
 */
function analyzeResult(agentName, result) {
  const resultStr = String(result || '');
  const chainConfig = AGENT_CHAINS[agentName] || {};

  // Check for severity indicators in result
  const hasCritical = /\[X\]|CRITICAL/.test(resultStr);
  const hasHigh = /\[!\]|HIGH/.test(resultStr);

  if (hasCritical && chainConfig.onCritical) {
    return { severity: 'critical', suggestion: chainConfig.onCritical };
  }

  if (hasHigh && chainConfig.onHighIssues) {
    return { severity: 'high', suggestion: chainConfig.onHighIssues };
  }

  return { severity: 'normal', suggestion: chainConfig.default || '' };
}

/**
 * Main handler logic
 */
async function handleHook(context) {
  const {
    agentName = 'unknown',
    result = '',
    duration = 0,
    success = true
  } = context || {};

  const resultLength = String(result).length;

  try {
    // Log the completion
    await logAgentCompletion(agentName, resultLength, duration, success);

    // Analyze for chaining
    const analysis = analyzeResult(agentName, result);

    // Build response
    const contextParts = [];

    // Add completion notice
    contextParts.push(`\n--- Agent Complete: ${agentName} ---`);
    contextParts.push(`Result size: ${resultLength} chars`);

    if (duration > 0) {
      const seconds = Math.round(duration / 1000);
      contextParts.push(`Duration: ${seconds}s`);
    }

    // Add severity indicator if issues found
    if (analysis.severity === 'critical') {
      contextParts.push('\nCRITICAL issues detected in agent output!');
    } else if (analysis.severity === 'high') {
      contextParts.push('\nHigh-priority issues detected in agent output.');
    }

    // Add chaining suggestion
    if (analysis.suggestion) {
      contextParts.push(`\n${analysis.suggestion}`);
    }

    return {
      hookSpecificOutput: {
        hookEventName: 'SubagentStop',
        additionalContext: contextParts.join('\n')
      }
    };

  } catch (err) {
    console.error(`[subagent-stop] Error: ${err.message}`);
    return {};
  }
}

/**
 * Main function - reads from stdin, processes, outputs to stdout
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
    // If we can't parse input, just return empty
    console.log(JSON.stringify({}));
    return;
  }

  const result = await handleHook(context);
  console.log(JSON.stringify(result));
}

main().catch(err => {
  console.error(`[subagent-stop] Fatal error: ${err.message}`);
  console.log(JSON.stringify({}));
});
