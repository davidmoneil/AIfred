/**
 * Cross-Project Commit Tracker Hook
 *
 * Tracks git commits across multiple projects during a Claude Code session.
 * Customize PROJECT_MAPPINGS to match your project structure.
 *
 * Created: 2026-01-06
 * Source: Design Pattern Integration - parallel session management
 */

const { execFile } = require('child_process');
const { promisify } = require('util');
const path = require('path');
const fs = require('fs').promises;
const os = require('os');

const execFileAsync = promisify(execFile);

// Configuration
const PROJECT_ROOT = path.join(__dirname, '..', '..');
const LOG_DIR = path.join(__dirname, '..', 'logs');
const TRACKING_FILE = path.join(LOG_DIR, 'cross-project-commits.json');
const SESSION_FILE = path.join(LOG_DIR, '.current-session');
const HOME = os.homedir();

// Known project mappings (Jarvis/Project Aion setup)
// pathPattern: regex to match project path
// name: project display name (null = extract from path)
// github: GitHub repo name
// type: project type (hub, code, infrastructure, creative, research)
const PROJECT_MAPPINGS = [
  // Jarvis - Master Archon (Project Aion)
  {
    pathPattern: new RegExp(`^${HOME}/Claude/Jarvis`),
    name: 'Jarvis',
    github: 'Jarvis',
    type: 'archon'
  },
  // AIfred baseline (read-only reference)
  {
    pathPattern: new RegExp(`^${HOME}/Claude/AIfred`),
    name: 'AIfred-Baseline',
    github: 'AIfred',
    type: 'baseline'
  },
  // Docker infrastructure
  {
    pathPattern: new RegExp(`^${HOME}/Docker`),
    name: 'Docker',
    github: null,
    type: 'infrastructure'
  },
  // Projects root
  {
    pathPattern: new RegExp(`^${HOME}/Claude/projects_root/([^/]+)`),
    name: null, // Will extract from path
    github: null,
    type: 'project'
  },
  // Fallback: Any Claude/* project
  {
    pathPattern: new RegExp(`^${HOME}/Claude/([^/]+)`),
    name: null, // Will extract from path
    github: null,
    type: 'claude-project'
  }
];

/**
 * Get current session name
 */
async function getSessionName() {
  try {
    const content = await fs.readFile(SESSION_FILE, 'utf8');
    return content.trim() || 'default-session';
  } catch {
    return 'default-session';
  }
}

/**
 * Load existing tracking data
 */
async function loadTrackingData() {
  try {
    const content = await fs.readFile(TRACKING_FILE, 'utf8');
    return JSON.parse(content);
  } catch {
    return {
      version: 1,
      createdAt: new Date().toISOString(),
      sessions: {}
    };
  }
}

/**
 * Save tracking data
 */
async function saveTrackingData(data) {
  await fs.mkdir(LOG_DIR, { recursive: true });
  data.lastUpdated = new Date().toISOString();
  await fs.writeFile(TRACKING_FILE, JSON.stringify(data, null, 2));
}

/**
 * Identify project from repository path
 */
function identifyProject(repoPath) {
  for (const mapping of PROJECT_MAPPINGS) {
    const match = repoPath.match(mapping.pathPattern);
    if (match) {
      // If name is null, extract from path
      const name = mapping.name || match[1] || path.basename(repoPath);
      const github = mapping.github || name;

      return {
        name,
        github,
        type: mapping.type,
        path: repoPath
      };
    }
  }

  // Unknown project - use folder name
  return {
    name: path.basename(repoPath),
    github: null,
    type: 'unknown',
    path: repoPath
  };
}

/**
 * Extract repository path from command
 */
function extractRepoPath(command) {
  // Pattern: git -C <path> commit
  const gitCMatch = command.match(/git\s+-C\s+([^\s]+)/);
  if (gitCMatch) {
    return gitCMatch[1];
  }

  // Default to PROJECT_ROOT if no -C flag
  return PROJECT_ROOT;
}

/**
 * Get commit details from the repository
 */
async function getLastCommitDetails(repoPath) {
  try {
    const { stdout } = await execFileAsync('git', [
      '-C', repoPath,
      'log', '-1',
      '--format=%H|%h|%s|%an|%ae|%ai'
    ], { timeout: 5000 });

    const [hash, shortHash, message, authorName, authorEmail, date] = stdout.trim().split('|');

    // Get branch name
    const { stdout: branchOut } = await execFileAsync('git', [
      '-C', repoPath,
      'branch', '--show-current'
    ], { timeout: 5000 });

    return {
      hash,
      shortHash,
      message,
      author: { name: authorName, email: authorEmail },
      date,
      branch: branchOut.trim()
    };
  } catch (err) {
    console.error(`[cross-project-commit-tracker] Failed to get commit details: ${err.message}`);
    return null;
  }
}

/**
 * Check if this is a commit command
 */
function isCommitCommand(tool, parameters) {
  // MCP git commit tool
  if (tool === 'mcp__git__git_commit') {
    return { isCommit: true, repoPath: parameters?.repo_path };
  }

  // Bash git commit
  if (tool === 'Bash' && parameters?.command) {
    const cmd = parameters.command;

    // Match various git commit patterns
    if (cmd.includes('git commit') || cmd.includes('git -C') && cmd.includes('commit')) {
      return { isCommit: true, repoPath: extractRepoPath(cmd) };
    }
  }

  return { isCommit: false };
}

/**
 * Handler function (can be called via require or stdin)
 */
async function handler(context) {
  const { tool, tool_input, result } = context;
  const parameters = tool_input || {};

    // Check if this is a commit operation
    const { isCommit, repoPath } = isCommitCommand(tool, parameters);

    if (!isCommit) {
      return { proceed: true };
    }

    // Check if commit was successful (look for common error patterns)
    const resultStr = JSON.stringify(result || {});
    if (resultStr.includes('error') || resultStr.includes('failed') || resultStr.includes('nothing to commit')) {
      return { proceed: true }; // Don't track failed commits
    }

    try {
      // Get commit details
      const commitDetails = await getLastCommitDetails(repoPath);
      if (!commitDetails) {
        return { proceed: true };
      }

      // Identify the project
      const project = identifyProject(repoPath);

      // Get session name
      const sessionName = await getSessionName();

      // Load tracking data
      const data = await loadTrackingData();

      // Initialize session if needed
      const today = new Date().toISOString().split('T')[0];
      const sessionKey = `${today}_${sessionName}`;

      if (!data.sessions[sessionKey]) {
        data.sessions[sessionKey] = {
          date: today,
          sessionName,
          startedAt: new Date().toISOString(),
          projects: {}
        };
      }

      const session = data.sessions[sessionKey];
      session.lastActivity = new Date().toISOString();

      // Initialize project in session if needed
      if (!session.projects[project.name]) {
        session.projects[project.name] = {
          github: project.github,
          type: project.type,
          path: project.path,
          commits: []
        };
      }

      // Add commit
      session.projects[project.name].commits.push({
        hash: commitDetails.hash,
        shortHash: commitDetails.shortHash,
        message: commitDetails.message,
        branch: commitDetails.branch,
        author: commitDetails.author,
        timestamp: new Date().toISOString()
      });

      // Save
      await saveTrackingData(data);

      // Log summary
      const totalCommits = Object.values(session.projects)
        .reduce((sum, p) => sum + p.commits.length, 0);
      const projectCount = Object.keys(session.projects).length;

      console.log(`[cross-project-commit-tracker] Tracked: ${project.name}@${commitDetails.branch} - "${commitDetails.message.substring(0, 50)}..."`);
      console.log(`[cross-project-commit-tracker] Session total: ${totalCommits} commits across ${projectCount} projects`);

  } catch (err) {
    console.error(`[cross-project-commit-tracker] Error: ${err.message}`);
  }

  return { proceed: true };
}

// Export for require() usage
module.exports = {
  name: 'cross-project-commit-tracker',
  description: 'Track git commits across multiple projects during Claude Code sessions',
  event: 'PostToolUse',
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
      console.error(`[cross-project-commit-tracker] Parse error: ${err.message}`);
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
