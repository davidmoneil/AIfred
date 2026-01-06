/**
 * Subagent Stop Hook
 *
 * Handles spawned agent completion:
 * - Logs agent activity to .claude/logs/agent-activity.jsonl
 * - Detects HIGH/CRITICAL issues in output
 * - Suggests next actions based on agent type
 *
 * Priority: MEDIUM (Agent Coordination)
 * Created: 2026-01-06
 * Source: AIfred baseline af66364 (implemented for Jarvis)
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const AGENT_ACTIVITY_LOG = path.join(__dirname, '..', 'logs', 'agent-activity.jsonl');

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

module.exports = {
  name: 'subagent-stop',
  description: 'Handle spawned agent completion and suggest follow-ups',
  event: 'SubagentStop',

  async handler(context) {
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

    return { proceed: true };
  }
};
