#!/usr/bin/env node
/**
 * Priority Validator Hook
 *
 * Tracks evidence for priority completion:
 * - Monitors work related to current priorities
 * - Collects evidence from git commits, file changes
 * - Assists with /update-priorities validation
 *
 * Uses file-based persistence so evidence survives across hook invocations.
 *
 * Priority: LOW (Workflow Enhancement)
 * Created: 2025-12-06
 * Converted to stdin/stdout executable hook with file persistence
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const LOG_DIR = path.join(__dirname, '..', 'logs');
const EVIDENCE_FILE = path.join(LOG_DIR, 'priority-evidence.json');

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
 * Load evidence from file
 */
async function loadEvidence() {
  try {
    const data = await fs.readFile(EVIDENCE_FILE, 'utf8');
    return JSON.parse(data);
  } catch {
    return {
      sessionStart: new Date().toISOString(),
      commits: [],
      filesModified: [],
      servicesChanged: [],
      commandsRun: [],
      significantActions: 0
    };
  }
}

/**
 * Save evidence to file
 */
async function saveEvidence(evidence) {
  try {
    await fs.mkdir(LOG_DIR, { recursive: true });
    await fs.writeFile(EVIDENCE_FILE, JSON.stringify(evidence, null, 2));
  } catch (err) {
    console.error(`[priority-validator] Failed to save evidence: ${err.message}`);
  }
}

/**
 * Detect work category from command
 */
function detectCategory(command) {
  for (const [, { pattern, category }] of Object.entries(WORK_PATTERNS)) {
    if (pattern.test(command)) {
      return category;
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
function recordEvidence(evidence, tool, parameters) {
  if (tool === 'Bash') {
    const command = parameters?.command || '';
    const category = detectCategory(command);

    if (category) {
      evidence.commandsRun.push({
        command: command.substring(0, 100),
        category,
        timestamp: new Date().toISOString()
      });
      // Keep last 50 commands
      if (evidence.commandsRun.length > 50) {
        evidence.commandsRun = evidence.commandsRun.slice(-50);
      }

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
      // Keep last 100 files
      if (evidence.filesModified.length > 100) {
        evidence.filesModified = evidence.filesModified.slice(-100);
      }
    }
  }
}

/**
 * Generate evidence summary
 */
function generateSummary(evidence) {
  const lines = ['Session Evidence Summary:', String.fromCharCode(9472).repeat(40)];

  if (evidence.commits.length > 0) {
    lines.push(`\nCommits (${evidence.commits.length}):`);
    evidence.commits.slice(-5).forEach(c => {
      lines.push(`  - ${c.message}`);
    });
  }

  if (evidence.servicesChanged.length > 0) {
    lines.push(`\nServices Modified (${evidence.servicesChanged.length}):`);
    evidence.servicesChanged.forEach(s => lines.push(`  - ${s}`));
  }

  if (evidence.filesModified.length > 0) {
    lines.push(`\nFiles Changed (${evidence.filesModified.length}):`);
    evidence.filesModified.slice(-10).forEach(f => {
      lines.push(`  - ${path.basename(f)}`);
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
      lines.push(`  - ${cat}: ${count} operations`);
    });
  }

  lines.push(String.fromCharCode(9472).repeat(40));
  return lines.join('\n');
}

/**
 * Main handler
 */
async function handleHook(context) {
  const { tool, parameters } = context;

  const evidence = await loadEvidence();

  // Record evidence
  recordEvidence(evidence, tool, parameters);

  // Track significant actions
  const newSignificant = evidence.commits.length +
    evidence.servicesChanged.length +
    Math.floor(evidence.filesModified.length / 5);

  const shouldShowSummary = newSignificant > 0 &&
    newSignificant !== evidence.significantActions &&
    newSignificant % 20 === 0;

  evidence.significantActions = newSignificant;

  // Save updated evidence
  await saveEvidence(evidence);

  if (shouldShowSummary) {
    return {
      proceed: true,
      outputToUser: '\n[priority-validator] Session Activity Summary\n' +
        generateSummary(evidence) +
        '\nUse /update-priorities to validate completions\n'
    };
  }

  return { proceed: true };
}

/**
 * Main function - reads from stdin, processes, outputs to stdout
 */
async function main() {
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const input = Buffer.concat(chunks).toString('utf8');

  let context;
  try {
    context = JSON.parse(input);
  } catch {
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  const result = await handleHook(context);
  console.log(JSON.stringify(result));
}

main().catch(err => {
  console.error(`[priority-validator] Fatal error: ${err.message}`);
  console.log(JSON.stringify({ proceed: true }));
});
