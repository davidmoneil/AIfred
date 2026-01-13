/**
 * Dangerous Operation Guard Hook
 *
 * Blocks or warns about dangerous shell operations.
 *
 * Created: PR-4a (Jarvis v1.2.1)
 *
 * Categories:
 * - BLOCK: Destructive patterns that should never execute
 * - WARN: Potentially dangerous patterns that proceed with caution
 *
 * Behavior:
 * - FAIL-OPEN: On pattern match error, logs warning but allows operation
 */

// Patterns that are ALWAYS blocked
const BLOCK_PATTERNS = [
  {
    name: 'Delete system root',
    pattern: /rm\s+(-[rfRvfi]+\s+)*\/(?!Users|home|tmp)/,
    message: 'Attempting to delete system root directories'
  },
  {
    name: 'Delete entire home',
    pattern: /rm\s+(-[rfRvfi]+\s+)*~\/?$/,
    message: 'Attempting to delete entire home directory'
  },
  {
    name: 'Sudo recursive delete',
    pattern: /sudo\s+rm\s+(-[rfRvfi]+\s+)*(\/|~)/,
    message: 'Sudo recursive delete on root or home'
  },
  {
    name: 'Format filesystem',
    pattern: /mkfs(\.[a-z0-9]+)?\s+/i,
    message: 'Filesystem format command detected'
  },
  {
    name: 'Raw disk write',
    pattern: /dd\s+.*if=.*of=\/dev\//,
    message: 'Raw disk write operation detected'
  },
  {
    name: 'Force push to main',
    pattern: /git\s+push\s+.*--force.*\s+(main|master)\b/,
    message: 'Force push to main/master branch'
  },
  {
    name: 'Force push main (alt)',
    pattern: /git\s+push\s+(-f|--force)\s+.*\s*(main|master)/,
    message: 'Force push to main/master branch'
  },
  {
    name: 'Recursive chmod 777 root',
    pattern: /chmod\s+(-R\s+)?777\s+\//,
    message: 'Recursive chmod 777 on root'
  },
  {
    name: 'Fork bomb',
    pattern: /:\(\)\s*{\s*:\s*\|\s*:\s*&\s*}\s*;?\s*:/,
    message: 'Fork bomb detected'
  },
  {
    name: 'Overwrite boot sector',
    pattern: /dd\s+.*of=\/dev\/(sd[a-z]|nvme|hd[a-z])$/,
    message: 'Overwriting disk device'
  },
];

// Patterns that generate WARNINGs but proceed
const WARN_PATTERNS = [
  {
    name: 'Recursive delete',
    pattern: /rm\s+(-[rfRvfi]*r[rfRvfi]*|-[rfRvfi]*R[rfRvfi]*)\s+/,
    message: 'Recursive delete operation'
  },
  {
    name: 'Git hard reset',
    pattern: /git\s+reset\s+--hard/,
    message: 'Hard reset will discard uncommitted changes'
  },
  {
    name: 'Git clean force',
    pattern: /git\s+clean\s+(-[fd]+|--force)/,
    message: 'Will delete untracked files'
  },
  {
    name: 'Chmod recursive',
    pattern: /chmod\s+-R\s+/,
    message: 'Recursive permission change'
  },
  {
    name: 'Chown recursive',
    pattern: /chown\s+-R\s+/,
    message: 'Recursive ownership change'
  },
  {
    name: 'Kill all processes',
    pattern: /pkill\s+-9\s+|killall\s+-9\s+/,
    message: 'Force killing processes'
  },
];

/**
 * Log a blocked operation
 */
function logBlocked(name, command, message) {
  console.error('\n[X] CRITICAL: DANGEROUS OPERATION BLOCKED');
  console.error(`    Pattern: ${name}`);
  console.error(`    Reason: ${message}`);
  console.error(`    Command: ${command.length > 80 ? command.substring(0, 80) + '...' : command}`);
  console.error('\n    This operation is not permitted for safety reasons.');
  console.error('    If this is intentional, please execute manually in terminal.\n');
}

/**
 * Log a warning (non-blocking)
 */
function logWarning(name, command, message) {
  console.error('\n[!] HIGH: DANGEROUS OPERATION DETECTED');
  console.error(`    Pattern: ${name}`);
  console.error(`    Reason: ${message}`);
  console.error(`    Command: ${command.length > 80 ? command.substring(0, 80) + '...' : command}`);
  console.error('\n    Proceeding with caution. Verify this is intentional.\n');
}

/**
 * Log an error during checking (fail-open)
 */
function logError(error) {
  console.error('\n[!] HIGH: Dangerous operation check failed');
  console.error(`    Error: ${error.message}`);
  console.error('    Proceeding with caution - unable to verify safety.\n');
}

/**
 * Handler function for dangerous operation guard
 */
async function handler(context) {
  const { tool, tool_input } = context;
  const parameters = tool_input || context.parameters || {};

  // Only check Bash commands
  if (tool !== 'Bash') {
    return { proceed: true };
  }

  const command = parameters?.command || '';

  // Skip empty commands
  if (!command.trim()) {
    return { proceed: true };
  }

  try {
    // Check BLOCK patterns (always blocked)
    for (const { name, pattern, message } of BLOCK_PATTERNS) {
      if (pattern.test(command)) {
        logBlocked(name, command, message);
        return { proceed: false };
      }
    }

    // Check WARN patterns (allow but warn)
    for (const { name, pattern, message } of WARN_PATTERNS) {
      if (pattern.test(command)) {
        logWarning(name, command, message);
        // Proceed after warning
        return { proceed: true };
      }
    }

    // No dangerous patterns detected
    return { proceed: true };

  } catch (error) {
    // FAIL-OPEN: On error, log and allow
    logError(error);
    return { proceed: true };
  }
}

// Export for require() usage
module.exports = {
  name: 'dangerous-op-guard',
  description: 'Block dangerous shell operations',
  event: 'PreToolUse',
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
      console.error(`[dangerous-op-guard] Parse error: ${err.message}`);
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
