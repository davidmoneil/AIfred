#!/usr/bin/env node
/**
 * Cross-Project Commit Tracker Hook
 *
 * Tracks git commits across multiple projects during a Claude Code session.
 * Detects commits to: hub (mybrain), myDocker, ~/Code/* projects
 *
 * Created: 2026-01-06
 * Fixed: 2026-01-21 - Converted to stdin/stdout executable hook
 * Source: Design Pattern Integration - parallel session management
 */

const { execFile } = require('child_process');
const { promisify } = require('util');
const path = require('path');
const fs = require('fs').promises;

const execFileAsync = promisify(execFile);

// Configuration
const PROJECT_ROOT = path.join(__dirname, '..', '..');
const LOG_DIR = path.join(__dirname, '..', 'logs');
const TRACKING_FILE = path.join(LOG_DIR, 'cross-project-commits.json');
const SESSION_FILE = path.join(LOG_DIR, '.current-session');

// Known project mappings (path prefix -> project info)
// The hub is auto-detected from AIFRED_HOME or cwd. Additional projects
// are detected dynamically from paths-registry.yaml if it exists, or
// from ~/Code/* as a fallback.
const HOME = process.env.HOME || '/tmp';
const PROJECTS_ROOT = process.env.PROJECTS_ROOT || path.join(HOME, 'Code');

const PROJECT_MAPPINGS = [
  {
    pathPattern: new RegExp('^' + (process.env.AIFRED_HOME || process.cwd()).replace(/[.*+?${}()|[\]\\]/g, '\\$&')),
    name: 'aifred',
    github: null,
    type: 'hub'
  },
  // Fallback: any project under PROJECTS_ROOT
  {
    pathPattern: new RegExp('^' + PROJECTS_ROOT.replace(/[.*+?${}()|[\]\\]/g, '\\$&') + '/([^/]+)'),
    name: null, // Will extract from path
    github: null,
    type: 'code'
  }
];

/**
 * Get current session name
 */
async function getSessionName() {
  try {
    const content = await fs.readFile(SESSION_FILE, 'utf8');
    // Try to parse as JSON (new format)
    try {
      const parsed = JSON.parse(content);
      return parsed.name || parsed.slug || 'default-session';
    } catch {
      return content.trim() || 'default-session';
    }
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
function isCommitCommand(tool_name, tool_input) {
  // MCP git commit tool
  if (tool_name === 'mcp__git__git_commit') {
    return { isCommit: true, repoPath: tool_input?.repo_path };
  }

  // Bash git commit
  if (tool_name === 'Bash' && tool_input?.command) {
    const cmd = tool_input.command;

    // Match various git commit patterns
    if (cmd.includes('git commit') || (cmd.includes('git -C') && cmd.includes('commit'))) {
      return { isCommit: true, repoPath: extractRepoPath(cmd) };
    }
  }

  return { isCommit: false };
}

/**
 * Main handler logic
 */
async function handleHook(context) {
  const { tool_name, tool_input, tool_result } = context;

  // Check if this is a commit operation
  const { isCommit, repoPath } = isCommitCommand(tool_name, tool_input);

  if (!isCommit) {
    return { proceed: true };
  }

  // Check if commit was successful (look for common error patterns)
  const resultStr = JSON.stringify(tool_result || {});
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

    console.error(`[cross-project-commit-tracker] Tracked: ${project.name}@${commitDetails.branch} - "${commitDetails.message.substring(0, 50)}..."`);
    console.error(`[cross-project-commit-tracker] Session total: ${totalCommits} commits across ${projectCount} projects`);

  } catch (err) {
    console.error(`[cross-project-commit-tracker] Error: ${err.message}`);
  }

  return { proceed: true };
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
    // If we can't parse input, just allow to proceed
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  const result = await handleHook(context);
  console.log(JSON.stringify(result));
}

main().catch(err => {
  console.error(`[cross-project-commit-tracker] Fatal error: ${err.message}`);
  console.log(JSON.stringify({ proceed: true }));
});
