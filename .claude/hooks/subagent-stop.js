/**
 * Subagent Stop Hook (JICM Enhanced)
 *
 * Handles spawned agent completion:
 * - Logs agent activity to .claude/logs/agent-activity.jsonl
 * - Detects HIGH/CRITICAL issues in output
 * - Suggests next actions based on agent type
 * - JICM: Triggers context checkpoint after agent work if threshold exceeded
 *
 * Priority: MEDIUM (Agent Coordination)
 * Created: 2026-01-06
 * Updated: 2026-01-09 (JICM integration)
 * Source: AIfred baseline af66364 (implemented for Jarvis)
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const WORKSPACE_ROOT = '/Users/aircannon/Claude/Jarvis';
const AGENT_ACTIVITY_LOG = path.join(__dirname, '..', 'logs', 'agent-activity.jsonl');
const CONTEXT_ESTIMATE_FILE = path.join(WORKSPACE_ROOT, '.claude/logs/context-estimate.json');
const CONTEXT_DIR = path.join(WORKSPACE_ROOT, '.claude/context');
const COMPACTION_FLAG = path.join(CONTEXT_DIR, '.compaction-in-progress');
const CHECKPOINT_FILE = path.join(CONTEXT_DIR, '.soft-restart-checkpoint.md');
const SIGNAL_FILE = path.join(CONTEXT_DIR, '.auto-clear-signal');

// JICM Thresholds
const JICM_WARNING_THRESHOLD = 50;
const JICM_TRIGGER_THRESHOLD = 75;
const MAX_CONTEXT_TOKENS = 200000;

// Issue detection patterns
const ISSUE_PATTERNS = [
  { pattern: /\[X\]\s*CRITICAL/i, severity: 'CRITICAL' },
  { pattern: /\[!\]\s*HIGH/i, severity: 'HIGH' },
  { pattern: /CRITICAL:/i, severity: 'CRITICAL' },
  { pattern: /FAILED:/i, severity: 'HIGH' },
  { pattern: /ERROR:/i, severity: 'HIGH' },
  { pattern: /BLOCKED:/i, severity: 'HIGH' }
];

// Agent-specific follow-up suggestions
const AGENT_FOLLOWUPS = {
  'memory-bank-synchronizer': {
    success: 'Documentation sync complete. Review changes if any manual review items flagged.',
    issues: 'Review the sync report and address flagged items manually.'
  },
  'deep-research': {
    success: 'Research complete. Consider storing key findings in Memory MCP.',
    issues: 'Some research sources may have been unavailable. Verify findings.'
  },
  'service-troubleshooter': {
    success: 'Diagnosis complete. Follow recommended remediation steps.',
    issues: 'Unable to fully diagnose. Consider checking logs directly.'
  },
  'docker-deployer': {
    success: 'Deployment complete. Verify service health with docker ps.',
    issues: 'Deployment encountered issues. Check docker logs for details.'
  },
  'default': {
    success: 'Agent completed successfully.',
    issues: 'Agent completed with issues. Review output for details.'
  }
};

/**
 * Detect issues in agent output
 */
function detectIssues(output) {
  const issues = [];

  for (const { pattern, severity } of ISSUE_PATTERNS) {
    if (pattern.test(output)) {
      issues.push({ severity, pattern: pattern.toString() });
    }
  }

  return issues;
}

/**
 * Get highest severity from issues
 */
function getHighestSeverity(issues) {
  if (issues.some(i => i.severity === 'CRITICAL')) return 'CRITICAL';
  if (issues.some(i => i.severity === 'HIGH')) return 'HIGH';
  return null;
}

/**
 * Log agent activity
 */
async function logActivity(entry) {
  try {
    const dir = path.dirname(AGENT_ACTIVITY_LOG);
    await fs.mkdir(dir, { recursive: true });

    const line = JSON.stringify(entry) + '\n';
    await fs.appendFile(AGENT_ACTIVITY_LOG, line);
  } catch (err) {
    // Silent failure
  }
}

/**
 * Format follow-up message
 */
function formatFollowup(agentName, issues, followups) {
  const hasIssues = issues.length > 0;
  const severity = getHighestSeverity(issues);
  const suggestion = hasIssues ? followups.issues : followups.success;

  const severityEmoji = {
    CRITICAL: '🔴',
    HIGH: '🟠'
  };

  const lines = [''];

  if (hasIssues) {
    lines.push(`[subagent-stop] ${severityEmoji[severity] || '⚠️'} Agent completed with ${severity} issues`);
    lines.push('─'.repeat(50));
    lines.push('');
    lines.push(`Agent: ${agentName}`);
    lines.push(`Issues detected: ${issues.length}`);
    lines.push('');
    lines.push(`Recommendation: ${suggestion}`);
  } else {
    lines.push(`[subagent-stop] ✅ Agent completed successfully`);
    lines.push('─'.repeat(50));
    lines.push('');
    lines.push(`Agent: ${agentName}`);
    lines.push(`Recommendation: ${suggestion}`);
  }

  lines.push('');
  lines.push('─'.repeat(50));

  return lines.join('\n');
}

// ============================================================
// JICM (Jarvis Intelligent Context Management) Functions
// ============================================================

/**
 * Load context estimate from accumulator
 */
async function loadContextEstimate() {
  try {
    const content = await fs.readFile(CONTEXT_ESTIMATE_FILE, 'utf8');
    const estimate = JSON.parse(content);
    estimate.percentage = (estimate.totalTokens / MAX_CONTEXT_TOKENS) * 100;
    return estimate;
  } catch {
    return { totalTokens: 30000, percentage: 15, toolCalls: 0 };
  }
}

/**
 * Check if compaction already in progress
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
async function setCompactionFlag() {
  await fs.mkdir(CONTEXT_DIR, { recursive: true });
  await fs.writeFile(COMPACTION_FLAG, new Date().toISOString());
}

/**
 * Create checkpoint after agent work
 */
async function createAgentCheckpoint(agentName, estimate) {
  const content = `# Post-Agent Context Checkpoint

**Created**: ${new Date().toISOString()}
**Reason**: SubagentStop JICM trigger after ${agentName}
**Estimated Context**: ${estimate.percentage.toFixed(0)}%

## Agent Work Completed

Agent \`${agentName}\` has completed. Context threshold (${JICM_TRIGGER_THRESHOLD}%) exceeded.
Auto-checkpoint created to preserve state before context reduction.

## Next Steps After Restart

1. Review session-state.md for current work status
2. Check current-priorities.md for next tasks
3. Continue from where you left off

## JICM Info

- Estimated tokens: ${estimate.totalTokens}
- Tool calls in session: ${estimate.toolCalls}
- Trigger: SubagentStop (post-agent)

`;

  await fs.mkdir(CONTEXT_DIR, { recursive: true });
  await fs.writeFile(CHECKPOINT_FILE, content);
}

/**
 * Signal auto-clear watcher
 */
async function signalClear() {
  await fs.writeFile(SIGNAL_FILE, new Date().toISOString());
}

/**
 * Format JICM message for agent completion
 */
function formatJicmMessage(agentName, estimate, willTrigger) {
  const percentage = estimate.percentage.toFixed(0);

  if (willTrigger) {
    return `
╔══════════════════════════════════════════════════════════════╗
║  🔄 JICM: Post-Agent Context Checkpoint                      ║
╚══════════════════════════════════════════════════════════════╝

Agent: ${agentName}
Estimated Context: ${percentage}% (threshold: ${JICM_TRIGGER_THRESHOLD}%)

Creating checkpoint and triggering /smart-compact --full...
`;
  }

  if (estimate.percentage >= JICM_WARNING_THRESHOLD) {
    return `
[subagent-stop] 💡 Context at ~${percentage}% after ${agentName}
Consider running /smart-compact if planning more agent work.
`;
  }

  return '';
}

/**
 * Handler function (can be called via require or stdin)
 */
async function handler(context) {
  const { agent_name, output, duration_ms, success } = context;

    // Detect issues in output
    const outputText = output || '';
    const issues = detectIssues(outputText);
    const highestSeverity = getHighestSeverity(issues);

    // Log activity
    const activity = {
      timestamp: new Date().toISOString(),
      agent: agent_name,
      duration_ms,
      success,
      issues_detected: issues.length,
      highest_severity: highestSeverity
    };
    await logActivity(activity);

    // Get agent-specific followups
    const followups = AGENT_FOLLOWUPS[agent_name] || AGENT_FOLLOWUPS.default;

    // Show followup message if issues detected or for specific agents
    if (issues.length > 0 || ['memory-bank-synchronizer', 'deep-research'].includes(agent_name)) {
      console.log(formatFollowup(agent_name, issues, followups));
    }

    // ============================================================
    // JICM: Context checkpoint trigger after agent work
    // ============================================================
    try {
      // Load context estimate
      const estimate = await loadContextEstimate();

      // Check if compaction already in progress
      if (await isCompactionInProgress()) {
        return { proceed: true }; // Already handling
      }

      // Check if we need to trigger JICM
      const shouldTrigger = estimate.percentage >= JICM_TRIGGER_THRESHOLD;
      const shouldWarn = estimate.percentage >= JICM_WARNING_THRESHOLD;

      if (shouldTrigger) {
        // Set flag to prevent loops
        await setCompactionFlag();

        // Show JICM message
        console.log(formatJicmMessage(agent_name, estimate, true));

        // Create checkpoint
        await createAgentCheckpoint(agent_name, estimate);

        // Signal watcher for /clear
        await signalClear();

        // Log action
        const logEntry = `${new Date().toISOString()} | JICM-SubagentStop | ${agent_name} | ${estimate.percentage.toFixed(0)}%\n`;
        const logDir = path.dirname(AGENT_ACTIVITY_LOG);
        await fs.appendFile(path.join(logDir, 'jicm-triggers.log'), logEntry);

      } else if (shouldWarn) {
        // Show warning only
        console.log(formatJicmMessage(agent_name, estimate, false));
      }

  } catch (jicmErr) {
    // Silent JICM failure - don't break agent completion
    console.error(`[subagent-stop] JICM error: ${jicmErr.message}`);
  }

  return { proceed: true };
}

// Export for require() usage
module.exports = {
  name: 'subagent-stop',
  description: 'Handle spawned agent completion and suggest follow-ups',
  event: 'SubagentStop',
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
      console.error(`[subagent-stop] Parse error: ${err.message}`);
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
