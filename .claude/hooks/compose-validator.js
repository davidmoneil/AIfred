/**
 * @deprecated Use docker-validator.js instead (consolidated 2025-12-24)
 *
 * Compose Validator Hook
 *
 * Validates docker-compose files before deployment:
 * - YAML syntax validation
 * - Required fields check
 * - Volume mount validation
 * - Network configuration check
 *
 * Priority: MEDIUM (Infrastructure Safety)
 * Created: 2025-12-06
 */

const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);
const path = require('path');

// Required fields for services
const REQUIRED_FIELDS = ['image', 'container_name'];

// Recommended fields (warn if missing)
const RECOMMENDED_FIELDS = ['restart', 'networks'];

// Dangerous patterns to warn about
const DANGEROUS_PATTERNS = [
  { pattern: /privileged:\s*true/i, message: 'Privileged mode enabled - security risk' },
  { pattern: /network_mode:\s*host/i, message: 'Host network mode - security risk' },
  { pattern: /pid:\s*host/i, message: 'Host PID namespace - security risk' },
  { pattern: /:\/:/g, message: 'Root filesystem mount detected' },
  { pattern: /\/var\/run\/docker\.sock:/i, message: 'Docker socket mount - high security risk' }
];

/**
 * Check if file is a docker-compose file
 */
function isComposeFile(filePath) {
  const basename = path.basename(filePath);
  return (
    basename === 'docker-compose.yml' ||
    basename === 'docker-compose.yaml' ||
    basename.startsWith('docker-compose.') && (basename.endsWith('.yml') || basename.endsWith('.yaml')) ||
    basename.startsWith('compose.') && (basename.endsWith('.yml') || basename.endsWith('.yaml'))
  );
}

/**
 * Validate compose file syntax with docker-compose
 */
async function validateSyntax(filePath) {
  try {
    await execAsync(`docker-compose -f "${filePath}" config --quiet 2>&1`);
    return { valid: true, errors: [] };
  } catch (err) {
    // Parse error messages
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

  // Check for version (deprecated but often expected)
  if (content.includes('version:')) {
    // This is actually fine, just informational
  }

  // Check for hardcoded passwords
  if (/password:\s*["']?[^${\s]+["']?$/mi.test(content)) {
    issues.push('Hardcoded password detected - use environment variables');
  }

  // Check for missing restart policy
  if (!content.includes('restart:')) {
    issues.push('No restart policy defined - containers may not restart on failure');
  }

  // Check for absolute path volumes
  if (/volumes:[\s\S]*?-\s*\/[^:]+:[^:]+/m.test(content)) {
    // Absolute paths are fine, but check for system directories
    if (/volumes:[\s\S]*?-\s*\/etc:/m.test(content)) {
      issues.push('/etc mount detected - ensure this is intentional');
    }
  }

  return issues;
}

module.exports = {
  name: 'compose-validator',
  description: 'Validate docker-compose files before deployment',
  event: 'PreToolUse',

  async handler(context) {
    const { tool, parameters } = context;

    // Check for compose operations
    if (tool !== 'Bash') return { proceed: true };

    const command = parameters?.command || '';

    // Look for docker-compose up/start/restart
    const composeMatch = command.match(/docker(?:-compose| compose)\s+(?:-f\s+["']?([^"'\s]+)["']?\s+)?(?:up|start|restart)/i);

    if (!composeMatch) return { proceed: true };

    // Get compose file path
    let composePath = composeMatch[1];

    if (!composePath) {
      // Try to find docker-compose.yml in current directory
      composePath = 'docker-compose.yml';
    }

    console.log('\n[compose-validator] Validating compose file...');
    console.log('─'.repeat(50));
    console.log(`File: ${composePath}`);

    try {
      // Validate syntax
      const syntaxResult = await validateSyntax(composePath);

      if (!syntaxResult.valid) {
        console.log('\n❌ SYNTAX ERRORS:');
        syntaxResult.errors.forEach(err => console.log(`  • ${err}`));
        console.log('─'.repeat(50));
        console.log('[compose-validator] Fix syntax errors before deploying\n');

        return {
          proceed: false,
          message: `Compose file has syntax errors: ${syntaxResult.errors[0]}`
        };
      }

      console.log('✓ Syntax valid');

      // Read file for additional checks
      const fs = require('fs').promises;
      let content;
      try {
        content = await fs.readFile(composePath, 'utf-8');
      } catch {
        // Can't read file, just proceed with syntax validation
        console.log('─'.repeat(50) + '\n');
        return { proceed: true };
      }

      // Check for dangerous patterns
      const dangerWarnings = checkDangerousPatterns(content);
      if (dangerWarnings.length > 0) {
        console.log('\n⚠️  SECURITY WARNINGS:');
        dangerWarnings.forEach(w => console.log(`  • ${w}`));
      }

      // Check for common issues
      const issues = checkCommonIssues(content);
      if (issues.length > 0) {
        console.log('\n⚠️  RECOMMENDATIONS:');
        issues.forEach(i => console.log(`  • ${i}`));
      }

      if (dangerWarnings.length === 0 && issues.length === 0) {
        console.log('✓ No warnings');
      }

      console.log('─'.repeat(50) + '\n');

    } catch (err) {
      console.log(`[compose-validator] Warning: Could not validate: ${err.message}`);
      console.log('─'.repeat(50) + '\n');
    }

    return { proceed: true };
  }
};
