/**
 * Priority Validator Hook
 *
 * Tracks evidence for priority completion:
 * - Monitors work related to current priorities
 * - Collects evidence from git commits, file changes
 * - Assists with /update-priorities validation
 *
 * Priority: LOW (Workflow Enhancement)
 * Created: 2025-12-06
 */

const fs = require('fs').promises;
const path = require('path');

const PRIORITIES_FILE = path.join(process.cwd(), '.claude/context/projects/current-priorities.md');

// Track evidence for current session
const evidence = {
  commits: [],
  filesModified: [],
  servicesChanged: [],
  commandsRun: []
};

// Patterns to detect work categories
const WORK_PATTERNS = {
  docker: {
    pattern: /docker(?:-compose| compose)?\s+(up|down|restart|start|stop|build|pull)/i,
    category: 'Infrastructure'
  },
  git: {
    pattern: /git\s+(commit|push|merge)/i,
    category: 'Development'
  },
  service: {
    pattern: /systemctl\s+(start|stop|restart|enable|disable)/i,
    category: 'Services'
  },
  backup: {
    pattern: /restic|backup/i,
    category: 'Backup'
  },
  documentation: {
    pattern: /\.md$/i,
    category: 'Documentation'
  }
};

/**
 * Detect work category from command
 */
function detectCategory(command) {
  for (const [name, { pattern }] of Object.entries(WORK_PATTERNS)) {
    if (pattern.test(command)) {
      return name;
    }
  }
  return null;
}

/**
 * Extract service name from command
 */
function extractServiceName(command) {
  const patterns = [
    /docker(?:-compose| compose)?\s+(?:logs|restart|stop|start|up|down)\s+(?:-[a-z]+\s+)*(\S+)/i,
    /systemctl\s+\w+\s+(\S+)/i
  ];

  for (const pattern of patterns) {
    const match = command.match(pattern);
    if (match) {
      return match[1];
    }
  }
  return null;
}

/**
 * Record evidence from tool execution
 */
function recordEvidence(tool, parameters) {
  if (tool === 'Bash') {
    const command = parameters?.command || '';
    const category = detectCategory(command);

    if (category) {
      evidence.commandsRun.push({
        command: command.substring(0, 100),
        category,
        timestamp: new Date().toISOString()
      });

      const service = extractServiceName(command);
      if (service && !evidence.servicesChanged.includes(service)) {
        evidence.servicesChanged.push(service);
      }
    }

    // Track git commits
    if (command.includes('git commit')) {
      const msgMatch = command.match(/-m\s+["']([^"']+)["']/);
      if (msgMatch) {
        evidence.commits.push({
          message: msgMatch[1].substring(0, 80),
          timestamp: new Date().toISOString()
        });
      }
    }
  }

  if (tool === 'Write' || tool === 'Edit') {
    const filePath = parameters?.file_path || '';
    if (filePath && !evidence.filesModified.includes(filePath)) {
      evidence.filesModified.push(filePath);
    }
  }
}

/**
 * Generate evidence summary
 */
function generateSummary() {
  const lines = ['Session Evidence Summary:', '─'.repeat(40)];

  if (evidence.commits.length > 0) {
    lines.push(`\nCommits (${evidence.commits.length}):`);
    evidence.commits.slice(-5).forEach(c => {
      lines.push(`  • ${c.message}`);
    });
  }

  if (evidence.servicesChanged.length > 0) {
    lines.push(`\nServices Modified (${evidence.servicesChanged.length}):`);
    evidence.servicesChanged.forEach(s => lines.push(`  • ${s}`));
  }

  if (evidence.filesModified.length > 0) {
    lines.push(`\nFiles Changed (${evidence.filesModified.length}):`);
    evidence.filesModified.slice(-10).forEach(f => {
      lines.push(`  • ${path.basename(f)}`);
    });
  }

  // Category breakdown
  const categories = {};
  evidence.commandsRun.forEach(c => {
    categories[c.category] = (categories[c.category] || 0) + 1;
  });

  if (Object.keys(categories).length > 0) {
    lines.push('\nWork Categories:');
    Object.entries(categories).forEach(([cat, count]) => {
      lines.push(`  • ${cat}: ${count} operations`);
    });
  }

  lines.push('─'.repeat(40));
  return lines.join('\n');
}

module.exports = {
  name: 'priority-validator',
  description: 'Track evidence for priority completion',
  event: 'PostToolUse',

  async handler(context) {
    const { tool, parameters } = context;

    // Record evidence
    recordEvidence(tool, parameters);

    // Periodically show summary (every 20 significant actions)
    const significantActions = evidence.commits.length +
                              evidence.servicesChanged.length +
                              Math.floor(evidence.filesModified.length / 5);

    if (significantActions > 0 && significantActions % 20 === 0) {
      console.log('\n[priority-validator] 📊 SESSION ACTIVITY SUMMARY');
      console.log(generateSummary());
      console.log('\nUse /update-priorities to validate completions\n');
    }

    return { proceed: true };
  }
};

// Export for external use
module.exports.getEvidence = () => JSON.parse(JSON.stringify(evidence));
module.exports.getSummary = generateSummary;
module.exports.clearEvidence = () => {
  evidence.commits = [];
  evidence.filesModified = [];
  evidence.servicesChanged = [];
  evidence.commandsRun = [];
};
