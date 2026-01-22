#!/usr/bin/env node
/**
 * Branch Protection Hook
 *
 * Prevents dangerous git operations on protected branches:
 * - Force pushes to main/master
 * - Hard resets
 * - Destructive rebases
 *
 * Priority: HIGH (Security Critical)
 * Created: 2025-12-06
 * Fixed: 2026-01-21 - Converted to stdin/stdout executable hook
 */

const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);

// Protected branch patterns
const PROTECTED_BRANCHES = [
  'main',
  'master',
  'production',
  'prod',
  'release',
  'stable'
];

// Dangerous command patterns
const DANGEROUS_PATTERNS = [
  {
    pattern: /git\s+push\s+.*--force(?:-with-lease)?/i,
    action: 'force push',
    severity: 'high'
  },
  {
    pattern: /git\s+push\s+-f\s/i,
    action: 'force push',
    severity: 'high'
  },
  {
    pattern: /git\s+reset\s+--hard/i,
    action: 'hard reset',
    severity: 'medium'
  },
  {
    pattern: /git\s+rebase\s+.*-i/i,
    action: 'interactive rebase',
    severity: 'low'  // Just warn
  },
  {
    pattern: /git\s+branch\s+-[dD]\s+(main|master|production)/i,
    action: 'delete protected branch',
    severity: 'high'
  },
  {
    pattern: /git\s+push\s+.*:\s*(main|master|production)/i,
    action: 'delete remote protected branch',
    severity: 'high'
  }
];

/**
 * Get current branch name
 */
async function getCurrentBranch() {
  try {
    const { stdout } = await execAsync('git rev-parse --abbrev-ref HEAD 2>/dev/null');
    return stdout.trim();
  } catch {
    return null;
  }
}

/**
 * Check if current branch is protected
 */
function isProtectedBranch(branchName) {
  if (!branchName) return false;
  return PROTECTED_BRANCHES.some(protected =>
    branchName.toLowerCase() === protected.toLowerCase()
  );
}

/**
 * Parse command to find target branch for push
 */
function getTargetBranch(command) {
  // Match patterns like "git push origin main" or "git push -f origin feature"
  const pushMatch = command.match(/git\s+push\s+(?:[^\s]+\s+)?([^\s]+)$/i);
  if (pushMatch) {
    return pushMatch[1];
  }

  // Match "origin/main" style
  const remoteMatch = command.match(/origin\/(\S+)/i);
  if (remoteMatch) {
    return remoteMatch[1];
  }

  return null;
}

/**
 * Check if command is dangerous
 */
function checkDangerousCommand(command) {
  for (const { pattern, action, severity } of DANGEROUS_PATTERNS) {
    if (pattern.test(command)) {
      return { isDangerous: true, action, severity };
    }
  }
  return { isDangerous: false };
}

/**
 * Main handler logic
 */
async function handleHook(context) {
  const { tool_name, tool_input } = context;

  // Only check Bash git commands
  if (tool_name !== 'Bash') return { proceed: true };

  const command = tool_input?.command || '';
  if (!command.includes('git ')) return { proceed: true };

  // Check for dangerous patterns
  const { isDangerous, action, severity } = checkDangerousCommand(command);

  if (!isDangerous) return { proceed: true };

  // Get current and target branches
  const currentBranch = await getCurrentBranch();
  const targetBranch = getTargetBranch(command) || currentBranch;

  // Determine if we're affecting a protected branch
  const affectsProtected = isProtectedBranch(currentBranch) || isProtectedBranch(targetBranch);

  if (affectsProtected) {
    console.error('\n[branch-protection] DANGEROUS OPERATION DETECTED');
    console.error('-'.repeat(50));
    console.error(`Action: ${action}`);
    console.error(`Current branch: ${currentBranch || 'unknown'}`);
    console.error(`Target branch: ${targetBranch || 'unknown'}`);
    console.error(`Severity: ${severity.toUpperCase()}`);
    console.error('-'.repeat(50));

    if (severity === 'high') {
      console.error('[branch-protection] BLOCKED: Cannot perform this action on protected branch');
      console.error('[branch-protection] Protected branches:', PROTECTED_BRANCHES.join(', '));
      console.error('\nIf you must proceed, ask the user to confirm manually.\n');
      return {
        proceed: false,
        message: `Blocked: ${action} on protected branch ${targetBranch || currentBranch}`
      };
    } else {
      console.error(`[branch-protection] WARNING: ${action} on protected branch`);
      console.error('[branch-protection] Proceeding with caution...\n');
    }
  } else if (isDangerous && severity === 'high') {
    // Even on non-protected branches, warn about force pushes
    console.error(`\n[branch-protection] Warning: ${action} detected`);
    console.error(`[branch-protection] Branch: ${currentBranch || 'unknown'}`);
    console.error('[branch-protection] Proceeding (branch not protected)...\n');
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
  console.error(`[branch-protection] Fatal error: ${err.message}`);
  console.log(JSON.stringify({ proceed: true }));
});
