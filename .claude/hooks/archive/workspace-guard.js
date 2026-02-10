/**
 * Workspace Guard Hook
 *
 * Enforces workspace boundaries for file operations.
 * Blocks writes to AIfred baseline and forbidden system paths.
 *
 * Created: PR-4a (Jarvis v1.2.1)
 *
 * Behavior:
 * - BLOCKS: Write/Edit to AIfred baseline (always)
 * - BLOCKS: Operations to forbidden system paths
 * - WARNS: Operations outside allowlisted workspaces
 * - FAIL-OPEN: On config load error, logs warning but allows operation
 */

const fs = require('fs');
const path = require('path');

// Hardcoded paths for reliability (config file is optional enhancement)
const AIFRED_BASELINE = '/Users/aircannon/Claude/AIfred';
const JARVIS_WORKSPACE = '/Users/aircannon/Claude/Jarvis';

const FORBIDDEN_PATHS = [
  '/',
  '/etc',
  '/usr',
  '/bin',
  '/sbin',
  '/var',
  '/System',
  '/Library',
  '/Applications',
  path.join(process.env.HOME || '', '.ssh'),
  path.join(process.env.HOME || '', '.gnupg'),
];

// Tools that modify files
const WRITE_TOOLS = ['Write', 'Edit'];
const ALL_MODIFY_TOOLS = ['Write', 'Edit', 'Bash'];

/**
 * Check if a path is within the AIfred baseline (read-only)
 */
function isBaselinePath(targetPath) {
  if (!targetPath) return false;
  const resolved = path.resolve(targetPath);
  return resolved.startsWith(AIFRED_BASELINE);
}

/**
 * Check if a path is a forbidden system path
 */
function isForbiddenPath(targetPath) {
  if (!targetPath) return false;
  const resolved = path.resolve(targetPath);

  for (const forbidden of FORBIDDEN_PATHS) {
    // Exact match or is the forbidden path itself
    if (resolved === forbidden) return true;
    // Direct child of forbidden root paths (/, /etc, etc.)
    if (forbidden === '/' && !resolved.startsWith('/Users')) return true;
  }

  // Check if path is within forbidden directories
  for (const forbidden of FORBIDDEN_PATHS) {
    if (forbidden !== '/' && resolved.startsWith(forbidden + '/')) {
      return true;
    }
  }

  return false;
}

/**
 * Check if path is within Jarvis workspace (allowed)
 */
function isJarvisWorkspace(targetPath) {
  if (!targetPath) return false;
  const resolved = path.resolve(targetPath);
  return resolved.startsWith(JARVIS_WORKSPACE);
}

/**
 * Extract target path from tool parameters
 */
function extractTargetPath(tool, parameters) {
  if (!parameters) return null;

  if (tool === 'Write' || tool === 'Edit') {
    return parameters.file_path || parameters.path;
  }

  if (tool === 'Bash') {
    const command = parameters.command || '';

    // Look for path arguments after common write commands
    // Pattern: command path or command > path or command >> path
    const writePatterns = [
      />\s*(\S+)/,                    // redirect: > file
      />>\s*(\S+)/,                   // append: >> file
      /tee\s+(?:-a\s+)?(\S+)/,        // tee file
      /mv\s+\S+\s+(\S+)/,             // mv source dest
      /cp\s+\S+\s+(\S+)/,             // cp source dest
      /rm\s+(?:-[rf]+\s+)?(\S+)/,     // rm file
      /mkdir\s+(?:-p\s+)?(\S+)/,      // mkdir dir
      /touch\s+(\S+)/,                // touch file
    ];

    for (const pattern of writePatterns) {
      const match = command.match(pattern);
      if (match && match[1]) {
        return match[1];
      }
    }

    // Check if command references AIfred baseline path directly
    if (command.includes(AIFRED_BASELINE)) {
      return AIFRED_BASELINE;
    }
  }

  return null;
}

/**
 * Log a blocked operation with severity
 */
function logBlocked(severity, message, details) {
  const prefix = severity === 'CRITICAL' ? '[X]' : '[!]';
  console.error(`\n${prefix} ${severity}: ${message}`);
  if (details) {
    for (const line of details) {
      console.error(`    ${line}`);
    }
  }
  console.error('');
}

/**
 * Log a warning (non-blocking)
 */
function logWarning(message, details) {
  console.error(`\n[!] HIGH: ${message}`);
  if (details) {
    for (const line of details) {
      console.error(`    ${line}`);
    }
  }
  console.error('');
}

/**
 * Handler function for workspace guard
 */
async function handler(context) {
  const { tool, tool_input } = context;
  const parameters = tool_input || context.parameters || {};

  // Only check tools that modify files
  if (!ALL_MODIFY_TOOLS.includes(tool)) {
    return { proceed: true };
  }

  try {
    const targetPath = extractTargetPath(tool, parameters);

    // No path detected - allow (can't verify)
    if (!targetPath) {
      return { proceed: true };
    }

    // === CRITICAL: AIfred Baseline Protection ===
    if (isBaselinePath(targetPath)) {
      logBlocked('CRITICAL', 'BLOCKED - AIfred Baseline Modification', [
        `Path: ${targetPath}`,
        'The AIfred baseline repository is READ-ONLY.',
        'Use /sync-aifred-baseline to review upstream changes.',
        'All modifications should be made in Jarvis workspace only.',
      ]);
      return { proceed: false };
    }

    // === CRITICAL: Forbidden System Paths ===
    if (isForbiddenPath(targetPath)) {
      logBlocked('CRITICAL', 'BLOCKED - Forbidden System Path', [
        `Path: ${targetPath}`,
        'This path is outside allowed workspaces.',
        'System directories and sensitive paths are protected.',
      ]);
      return { proceed: false };
    }

    // === WARNING: Outside Jarvis Workspace ===
    // For Write/Edit tools, warn but allow (may be registered project)
    if (WRITE_TOOLS.includes(tool) && !isJarvisWorkspace(targetPath)) {
      logWarning('Operation outside Jarvis workspace', [
        `Path: ${targetPath}`,
        'This may be a registered project workspace.',
        'Use /register-project to formally add workspaces.',
      ]);
      // Allow but warned - future: check against allowlist
      return { proceed: true };
    }

    return { proceed: true };

  } catch (error) {
    // FAIL-OPEN: On error, log warning but allow operation
    logWarning('Workspace guard check failed - proceeding with caution', [
      `Error: ${error.message}`,
      'Unable to verify workspace boundaries.',
      'Operation allowed but not validated.',
    ]);
    return { proceed: true };
  }
}

// Export for require() usage
module.exports = {
  name: 'workspace-guard',
  description: 'Enforce workspace boundaries for file operations',
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
      console.error(`[workspace-guard] Parse error: ${err.message}`);
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
