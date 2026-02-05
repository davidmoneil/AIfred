#!/usr/bin/env node
/**
 * Compose Validator Hook
 *
 * Validates docker-compose files before deployment:
 * - YAML syntax validation (via docker-compose config)
 * - Security pattern checks (privileged, host network, docker socket)
 * - Common issues (hardcoded passwords, missing restart policy)
 *
 * Priority: MEDIUM (Infrastructure Safety)
 * Created: 2025-12-06
 * Synced from AIProjects: 2026-02-05 (v2.1)
 * Converted to stdin/stdout executable hook
 */

const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);
const fs = require('fs').promises;
const path = require('path');

// Dangerous patterns to warn about
const DANGEROUS_PATTERNS = [
  { pattern: /privileged:\s*true/i, message: 'Privileged mode enabled - security risk' },
  { pattern: /network_mode:\s*host/i, message: 'Host network mode - security risk' },
  { pattern: /pid:\s*host/i, message: 'Host PID namespace - security risk' },
  { pattern: /:\/:/g, message: 'Root filesystem mount detected' },
  { pattern: /\/var\/run\/docker\.sock:/i, message: 'Docker socket mount - high security risk' }
];

/**
 * Validate compose file syntax with docker compose
 */
async function validateSyntax(filePath) {
  try {
    // Try newer 'docker compose' first, fall back to 'docker-compose'
    try {
      await execAsync(`docker compose -f "${filePath}" config --quiet 2>&1`);
    } catch {
      await execAsync(`docker-compose -f "${filePath}" config --quiet 2>&1`);
    }
    return { valid: true, errors: [] };
  } catch (err) {
    const errors = err.stderr?.split('\n').filter(line => line.trim()) || [];
    return { valid: false, errors };
  }
}

/**
 * Check for dangerous patterns in content
 */
function checkDangerousPatterns(content) {
  const warnings = [];
  DANGEROUS_PATTERNS.forEach(({ pattern, message }) => {
    if (pattern.test(content)) {
      warnings.push(message);
    }
  });
  return warnings;
}

/**
 * Check for common issues in compose content
 */
function checkCommonIssues(content) {
  const issues = [];

  if (/password:\s*["']?[^${\s]+["']?$/mi.test(content)) {
    issues.push('Hardcoded password detected - use environment variables');
  }

  if (!content.includes('restart:')) {
    issues.push('No restart policy defined - containers may not restart on failure');
  }

  if (/volumes:[\s\S]*?-\s*\/etc:/m.test(content)) {
    issues.push('/etc mount detected - ensure this is intentional');
  }

  return issues;
}

/**
 * Main handler
 */
async function handleHook(context) {
  const { tool, parameters } = context;

  if (tool !== 'Bash') return { proceed: true };

  const command = parameters?.command || '';

  // Look for docker compose up/start/restart
  const composeMatch = command.match(/docker(?:-compose| compose)\s+(?:-f\s+["']?([^"'\s]+)["']?\s+)?(?:up|start|restart)/i);

  if (!composeMatch) return { proceed: true };

  let composePath = composeMatch[1] || 'docker-compose.yml';

  console.error('[compose-validator] Validating compose file: ' + composePath);

  try {
    const syntaxResult = await validateSyntax(composePath);

    if (!syntaxResult.valid) {
      const errorMsg = syntaxResult.errors[0] || 'Unknown syntax error';
      return {
        proceed: false,
        message: `Compose file has syntax errors: ${errorMsg}. Fix syntax errors before deploying.`
      };
    }

    // Read file for additional checks
    let content;
    try {
      content = await fs.readFile(composePath, 'utf-8');
    } catch {
      return { proceed: true };
    }

    const dangerWarnings = checkDangerousPatterns(content);
    const issues = checkCommonIssues(content);

    if (dangerWarnings.length > 0 || issues.length > 0) {
      let warning = '[compose-validator] Validation warnings:\n';
      if (dangerWarnings.length > 0) {
        warning += 'Security: ' + dangerWarnings.join(', ') + '\n';
      }
      if (issues.length > 0) {
        warning += 'Issues: ' + issues.join(', ') + '\n';
      }
      console.error(warning);
    }
  } catch (err) {
    console.error(`[compose-validator] Warning: Could not validate: ${err.message}`);
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
  console.error(`[compose-validator] Fatal error: ${err.message}`);
  console.log(JSON.stringify({ proceed: true }));
});
