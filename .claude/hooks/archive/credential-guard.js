/**
 * Credential Guard Hook
 *
 * Monitors file read/write operations to prevent accidental exposure
 * of credential files. Blocks reads of sensitive files and warns
 * about writes that might contain credentials.
 *
 * Priority: HIGH (Security Critical)
 * Ported from: AIfred baseline (2025-12-06)
 * Adapted for: Jarvis v2.1.0 (2026-01-22)
 *   - Added Jarvis-specific path exclusions
 *   - Added stdin/stdout handler for Claude Code compatibility
 */

const path = require('path');

// Paths that should NEVER be read
const BLOCKED_PATHS = [
  // SSH keys
  /\.ssh\/id_/,
  /\.ssh\/.*_key$/,
  /\.ssh\/known_hosts$/,

  // Credential files
  /\.aws\/credentials$/,
  /\.aws\/config$/,
  /\.npmrc$/,
  /\.netrc$/,
  /\.docker\/config\.json$/,

  // API keys and tokens
  /\.anthropic/,
  /\.openai/,
  /\.github\/.*token/,

  // Password stores
  /\.password-store\//,
  /\.gnupg\/.*\.key$/,

  // Shell history (can contain passwords)
  /\.bash_history$/,
  /\.zsh_history$/,

  // Database credentials
  /\.pgpass$/,
  /\.my\.cnf$/,

  // Application secrets
  /\.env$/,
  /\.env\.[^/]+$/,
  /secrets\.ya?ml$/,
  /credentials\.json$/,
  /service-account.*\.json$/
];

// Jarvis-specific ALLOWED paths (exclusions from blocking)
const JARVIS_ALLOWED = [
  /\.claude\/config\//,           // Jarvis config files
  /\.claude\/state\//,            // State files
  /\.claude\/context\//,          // Context files
  /\.claude\/settings\.json$/,    // Settings
  /paths-registry\.yaml$/         // Project registry
];

// Paths that should trigger a warning
const WARN_PATHS = [
  /config\.ya?ml$/,
  /settings\.json$/,
  /\.conf$/,
  /docker-compose.*\.ya?ml$/  // May contain secrets in environment
];

// Patterns in content that indicate credentials
const CREDENTIAL_PATTERNS = [
  /password\s*[:=]/i,
  /api[_-]?key\s*[:=]/i,
  /secret[_-]?key\s*[:=]/i,
  /access[_-]?token\s*[:=]/i,
  /auth[_-]?token\s*[:=]/i,
  /private[_-]?key\s*[:=]/i,
  /bearer\s+[A-Za-z0-9_\-.]+/i
];

/**
 * Normalize path for matching
 */
function normalizePath(filePath) {
  // Handle both absolute and relative paths
  return filePath.replace(/^~/, process.env.HOME || '');
}

/**
 * Check if path is Jarvis-allowed (exempt from blocking)
 */
function isJarvisAllowed(filePath) {
  const normalized = normalizePath(filePath);
  return JARVIS_ALLOWED.some(pattern => pattern.test(normalized));
}

/**
 * Check if path matches any blocked patterns
 */
function isBlockedPath(filePath) {
  const normalized = normalizePath(filePath);

  // Check Jarvis exclusions first
  if (isJarvisAllowed(normalized)) {
    return false;
  }

  return BLOCKED_PATHS.some(pattern => pattern.test(normalized));
}

/**
 * Check if path matches warning patterns
 */
function isWarnPath(filePath) {
  const normalized = normalizePath(filePath);

  // Don't warn about Jarvis allowed paths
  if (isJarvisAllowed(normalized)) {
    return false;
  }

  return WARN_PATHS.some(pattern => pattern.test(normalized));
}

/**
 * Check if content contains credentials
 */
function containsCredentials(content) {
  if (!content) return false;
  return CREDENTIAL_PATTERNS.some(pattern => pattern.test(content));
}

/**
 * Extract path from Read tool parameters
 */
function extractReadPath(parameters) {
  return parameters?.file_path || parameters?.path || null;
}

/**
 * Extract path from Write tool parameters
 */
function extractWritePath(parameters) {
  return parameters?.file_path || parameters?.path || null;
}

/**
 * Extract path from Bash command
 */
function extractBashPath(command) {
  // Match common patterns for reading files
  const readPatterns = [
    /cat\s+([^\s|>]+)/,
    /less\s+([^\s]+)/,
    /more\s+([^\s]+)/,
    /head\s+(?:-n\s+\d+\s+)?([^\s]+)/,
    /tail\s+(?:-n\s+\d+\s+)?([^\s]+)/,
    /vim?\s+([^\s]+)/,
    /nano\s+([^\s]+)/
  ];

  for (const pattern of readPatterns) {
    const match = command.match(pattern);
    if (match) return match[1];
  }

  return null;
}

/**
 * Handler function for credential guard
 */
async function handler(context) {
  const { tool, tool_input } = context;
  const parameters = tool_input || context.parameters || {};

  let filePath = null;
  let isWrite = false;
  let content = null;

  // Determine what file is being accessed
  switch (tool) {
    case 'Read':
    case 'mcp__filesystem__read_file':
    case 'mcp__filesystem__read_text_file':
      filePath = extractReadPath(parameters);
      break;

    case 'Write':
    case 'mcp__filesystem__write_file':
      filePath = extractWritePath(parameters);
      isWrite = true;
      content = parameters?.content;
      break;

    case 'Bash':
      filePath = extractBashPath(parameters?.command || '');
      break;

    default:
      return { proceed: true };
  }

  if (!filePath) return { proceed: true };

  // Check blocked paths
  if (isBlockedPath(filePath)) {
    console.error('\n[credential-guard] BLOCKED: Credential file access');
    console.error('-'.repeat(50));
    console.error(`File: ${filePath}`);
    console.error('Reason: This file type may contain sensitive credentials');
    console.error('-'.repeat(50));
    console.error('\nTo access credential files safely:');
    console.error('  1. Use environment variables');
    console.error('  2. Reference paths without reading content');
    console.error('  3. Ask user to provide specific values\n');

    return {
      proceed: false,
      message: `Blocked: Cannot read credential file ${path.basename(filePath)}`
    };
  }

  // Check warning paths
  if (isWarnPath(filePath)) {
    console.error(`\n[credential-guard] Warning: Config file access`);
    console.error(`File: ${filePath}`);
    console.error('Note: Check for embedded credentials before sharing content\n');
  }

  // For writes, check content for credentials
  if (isWrite && content && containsCredentials(content)) {
    console.error('\n[credential-guard] WARNING: Content may contain credentials');
    console.error('-'.repeat(50));
    console.error(`File: ${filePath}`);
    console.error('Detected: Patterns matching passwords, API keys, or tokens');
    console.error('-'.repeat(50));
    console.error('\nRecommendation:');
    console.error('  - Use environment variables instead');
    console.error('  - Add file to .gitignore');
    console.error('  - Consider using a secrets manager\n');
    // Allow but warn - don't block writes to user's own files
  }

  return { proceed: true };
}

// Export for require() usage
module.exports = {
  name: 'credential-guard',
  description: 'Prevent exposure of credential files',
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
      console.error(`[credential-guard] Parse error: ${err.message}`);
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
