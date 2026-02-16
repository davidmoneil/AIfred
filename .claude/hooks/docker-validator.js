/**
 * Docker Validator Hook (Consolidated)
 *
 * Combines validation for Docker deployments:
 * - Compose file syntax and security (from compose-validator.js)
 * - Network configuration (from network-validator.js)
 * - Environment variables (from env-validator.js)
 *
 * Priority: MEDIUM (Infrastructure Safety)
 * Created: 2025-12-24
 * Consolidated from: compose-validator.js, network-validator.js, env-validator.js
 */

const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);
const fs = require('fs').promises;
const path = require('path');

// =============================================================================
// CONFIGURATION
// =============================================================================

// Dangerous patterns in compose files
const DANGEROUS_PATTERNS = [
  { pattern: /privileged:\s*true/i, message: 'Privileged mode enabled - security risk' },
  { pattern: /network_mode:\s*host/i, message: 'Host network mode - security risk' },
  { pattern: /pid:\s*host/i, message: 'Host PID namespace - security risk' },
  { pattern: /:\/:/g, message: 'Root filesystem mount detected' },
  { pattern: /\/var\/run\/docker\.sock:/i, message: 'Docker socket mount - high security risk' }
];

// Known networks that should exist
const KNOWN_NETWORKS = [
  'caddy-network',
  'logging',
  'bridge',
  'host',
  'none'
];

// Sensitive variable patterns
const SENSITIVE_PATTERNS = [
  /password/i,
  /secret/i,
  /api[_-]?key/i,
  /token/i,
  /private[_-]?key/i,
  /encryption[_-]?key/i
];

// Performance tracking
let perfMetrics = {};

// =============================================================================
// UTILITY FUNCTIONS
// =============================================================================

/**
 * Track performance of a function
 */
async function trackPerf(name, fn) {
  const start = Date.now();
  try {
    return await fn();
  } finally {
    const duration = Date.now() - start;
    perfMetrics[name] = duration;
    if (duration > 100) {
      console.log(`  [perf] ${name}: ${duration}ms`);
    }
  }
}

/**
 * Print validation header
 */
function printHeader(title) {
  console.log(`\n[docker-validator] ${title}`);
  console.log('─'.repeat(50));
}

// =============================================================================
// COMPOSE VALIDATION
// =============================================================================

/**
 * Validate compose file syntax with docker-compose
 */
async function validateComposeSyntax(filePath) {
  return trackPerf('compose-syntax', async () => {
    try {
      await execAsync(`docker-compose -f "${filePath}" config --quiet 2>&1`);
      return { valid: true, errors: [] };
    } catch (err) {
      const errors = err.stderr?.split('\n').filter(line => line.trim()) || [];
      return { valid: false, errors };
    }
  });
}

/**
 * Check for dangerous patterns in compose content
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

  // Check for hardcoded passwords
  if (/password:\s*["']?[^${\s]+["']?$/mi.test(content)) {
    issues.push('Hardcoded password detected - use environment variables');
  }

  // Check for missing restart policy
  if (!content.includes('restart:')) {
    issues.push('No restart policy defined - containers may not restart on failure');
  }

  // Check for /etc mount
  if (/volumes:[\s\S]*?-\s*\/etc:/m.test(content)) {
    issues.push('/etc mount detected - ensure this is intentional');
  }

  return issues;
}

// =============================================================================
// NETWORK VALIDATION
// =============================================================================

/**
 * Get list of existing Docker networks
 */
async function getExistingNetworks() {
  return trackPerf('network-list', async () => {
    try {
      const { stdout } = await execAsync('docker network ls --format "{{.Name}}" 2>/dev/null');
      return stdout.trim().split('\n').filter(n => n);
    } catch {
      return [];
    }
  });
}

/**
 * Extract networks from compose file
 */
async function extractNetworksFromCompose(content) {
  const networks = {
    defined: [],
    referenced: []
  };

  // Find networks section
  const networksMatch = content.match(/^networks:\s*\n((?:[ \t]+\S[^\n]*\n?)+)/m);
  if (networksMatch) {
    const networkLines = networksMatch[1].split('\n');
    networkLines.forEach(line => {
      const match = line.match(/^\s{2}(\S+):/);
      if (match) {
        networks.defined.push(match[1]);
      }
    });
  }

  // Find service network references
  const serviceNetworksPattern = /networks:\s*\n((?:\s+-\s*\S+\n?)+)/g;
  let match;
  while ((match = serviceNetworksPattern.exec(content)) !== null) {
    const networkLines = match[1].split('\n');
    networkLines.forEach(line => {
      const netMatch = line.match(/^\s+-\s*(\S+)/);
      if (netMatch) {
        networks.referenced.push(netMatch[1]);
      }
    });
  }

  // Check for network_mode
  const networkModePattern = /network_mode:\s*["']?(\S+)["']?/g;
  while ((match = networkModePattern.exec(content)) !== null) {
    if (!['host', 'bridge', 'none'].includes(match[1])) {
      networks.referenced.push(match[1].replace(/^container:/, ''));
    }
  }

  return {
    defined: [...new Set(networks.defined)],
    referenced: [...new Set(networks.referenced)]
  };
}

/**
 * Validate network configuration
 */
async function validateNetworks(content, existingNetworks) {
  return trackPerf('network-validate', async () => {
    const composeNetworks = await extractNetworksFromCompose(content);
    const issues = [];
    const warnings = [];

    for (const network of composeNetworks.referenced) {
      if (['bridge', 'host', 'none', 'default'].includes(network)) {
        continue;
      }

      const isDefinedInCompose = composeNetworks.defined.includes(network);
      const existsExternally = existingNetworks.includes(network);

      if (!isDefinedInCompose && !existsExternally) {
        issues.push(`Network "${network}" does not exist and is not defined in compose`);
      } else if (existsExternally && !isDefinedInCompose) {
        warnings.push(`Network "${network}" is external - ensure it's marked with "external: true"`);
      }
    }

    const usesKnownNetwork = composeNetworks.referenced.some(n => KNOWN_NETWORKS.includes(n));
    if (!usesKnownNetwork && composeNetworks.referenced.length > 0) {
      warnings.push('No standard network (caddy-network, logging) detected');
    }

    return { issues, warnings };
  });
}

// =============================================================================
// ENVIRONMENT VALIDATION
// =============================================================================

/**
 * Read .env file and parse variables
 */
async function parseEnvFile(envPath) {
  const vars = {};
  try {
    const content = await fs.readFile(envPath, 'utf-8');
    const lines = content.split('\n');

    lines.forEach(line => {
      const trimmed = line.trim();
      if (trimmed && !trimmed.startsWith('#')) {
        const match = trimmed.match(/^([^=]+)=(.*)$/);
        if (match) {
          vars[match[1].trim()] = match[2].trim();
        }
      }
    });
  } catch {
    // File doesn't exist or not readable
  }
  return vars;
}

/**
 * Extract env_file references from compose
 */
function extractEnvFiles(content) {
  const envFiles = [];

  // Match env_file patterns
  const envFilePattern = /env_file:\s*\n((?:\s+-\s*[^\n]+\n?)+)/g;
  let match;
  while ((match = envFilePattern.exec(content)) !== null) {
    const lines = match[1].split('\n');
    lines.forEach(line => {
      const fileMatch = line.match(/^\s+-\s*["']?([^"'\n]+)["']?/);
      if (fileMatch) {
        envFiles.push(fileMatch[1].trim());
      }
    });
  }

  // Also check single env_file reference
  const singleMatch = content.match(/env_file:\s*["']?([^"'\n]+)["']?$/m);
  if (singleMatch && !singleMatch[1].includes('-')) {
    envFiles.push(singleMatch[1].trim());
  }

  return [...new Set(envFiles)];
}

/**
 * Check if variable value looks empty or placeholder
 */
function isEmptyOrPlaceholder(value) {
  if (!value) return true;
  const lower = value.toLowerCase();
  return (
    value === '' ||
    value === '""' ||
    value === "''" ||
    lower.includes('changeme') ||
    lower.includes('replace') ||
    lower.includes('your_') ||
    lower.includes('xxx') ||
    lower === 'password' ||
    lower === 'secret'
  );
}

/**
 * Check if variable is sensitive
 */
function isSensitiveVar(varName) {
  return SENSITIVE_PATTERNS.some(pattern => pattern.test(varName));
}

/**
 * Validate environment configuration
 */
async function validateEnvironment(content, composePath) {
  return trackPerf('env-validate', async () => {
    const composeDir = path.dirname(path.resolve(composePath));
    const issues = [];
    const warnings = [];

    const envFiles = extractEnvFiles(content);

    for (const envFile of envFiles) {
      const envPath = path.resolve(composeDir, envFile);

      try {
        await fs.access(envPath);
        const vars = await parseEnvFile(envPath);

        Object.entries(vars).forEach(([name, value]) => {
          if (isSensitiveVar(name) && isEmptyOrPlaceholder(value)) {
            warnings.push(`${name} in ${envFile} appears empty or placeholder`);
          }
        });
      } catch {
        issues.push(`env_file "${envFile}" does not exist`);
      }
    }

    // Check default .env file
    const defaultEnvPath = path.resolve(composeDir, '.env');
    try {
      await fs.access(defaultEnvPath);
      const defaultVars = await parseEnvFile(defaultEnvPath);

      Object.entries(defaultVars).forEach(([name, value]) => {
        if (isSensitiveVar(name) && isEmptyOrPlaceholder(value)) {
          warnings.push(`${name} in .env appears empty or placeholder`);
        }
      });
    } catch {
      // No .env file, that's often fine
    }

    return { issues, warnings };
  });
}

// =============================================================================
// MAIN HANDLER
// =============================================================================

module.exports = {
  name: 'docker-validator',
  description: 'Comprehensive Docker deployment validation (compose, network, env)',
  event: 'PreToolUse',

  async handler(context) {
    const { tool, parameters } = context;

    if (tool !== 'Bash') return { proceed: true };

    const command = parameters?.command || '';

    // Check for docker-compose up/start/restart
    const composeMatch = command.match(/docker(?:-compose| compose)\s+(?:-f\s+["']?([^"'\s]+)["']?\s+)?(?:up|start|restart)/i);

    if (!composeMatch) {
      // Check for docker network connect
      if (command.includes('docker network connect')) {
        const match = command.match(/docker network connect\s+(\S+)\s+(\S+)/);
        if (match) {
          const [, networkName] = match;
          const existingNetworks = await getExistingNetworks();
          if (!existingNetworks.includes(networkName)) {
            console.log(`\n[docker-validator] ❌ Network "${networkName}" does not exist`);
            console.log(`Create it with: docker network create ${networkName}\n`);
            return {
              proceed: false,
              message: `Network "${networkName}" does not exist`
            };
          }
        }
      }
      return { proceed: true };
    }

    const composePath = composeMatch[1] || 'docker-compose.yml';
    perfMetrics = {};

    printHeader('Validating Docker deployment');
    console.log(`File: ${composePath}`);

    try {
      // 1. Validate syntax
      const syntaxResult = await validateComposeSyntax(composePath);

      if (!syntaxResult.valid) {
        console.log('\n❌ SYNTAX ERRORS:');
        syntaxResult.errors.forEach(err => console.log(`  • ${err}`));
        console.log('─'.repeat(50));
        console.log('[docker-validator] Fix syntax errors before deploying\n');
        return {
          proceed: false,
          message: `Compose file has syntax errors: ${syntaxResult.errors[0]}`
        };
      }
      console.log('✓ Syntax valid');

      // Read compose file for further validation
      let content;
      try {
        content = await fs.readFile(composePath, 'utf-8');
      } catch {
        console.log('─'.repeat(50) + '\n');
        return { proceed: true };
      }

      // Collect all issues and warnings
      const allIssues = [];
      const allWarnings = [];

      // 2. Check dangerous patterns
      const dangerWarnings = checkDangerousPatterns(content);
      if (dangerWarnings.length > 0) {
        allWarnings.push(...dangerWarnings.map(w => `[security] ${w}`));
      }

      // 3. Check common issues
      const commonIssues = checkCommonIssues(content);
      if (commonIssues.length > 0) {
        allWarnings.push(...commonIssues.map(i => `[compose] ${i}`));
      }

      // 4. Validate networks
      const existingNetworks = await getExistingNetworks();
      const networkResult = await validateNetworks(content, existingNetworks);
      if (networkResult.issues.length > 0) {
        allIssues.push(...networkResult.issues.map(i => `[network] ${i}`));
      }
      if (networkResult.warnings.length > 0) {
        allWarnings.push(...networkResult.warnings.map(w => `[network] ${w}`));
      }

      // 5. Validate environment
      const envResult = await validateEnvironment(content, composePath);
      if (envResult.issues.length > 0) {
        allIssues.push(...envResult.issues.map(i => `[env] ${i}`));
      }
      if (envResult.warnings.length > 0) {
        allWarnings.push(...envResult.warnings.map(w => `[env] ${w}`));
      }

      // Report findings
      if (allIssues.length > 0) {
        console.log('\n❌ BLOCKING ISSUES:');
        allIssues.forEach(i => console.log(`  • ${i}`));
        console.log('─'.repeat(50));
        console.log('\nTo fix:');
        if (allIssues.some(i => i.includes('[network]'))) {
          console.log('  • Create missing networks: docker network create <name>');
        }
        if (allIssues.some(i => i.includes('[env]'))) {
          console.log('  • Create missing .env files or remove env_file references');
        }
        console.log('');
        return {
          proceed: false,
          message: allIssues[0]
        };
      }

      if (allWarnings.length > 0) {
        console.log('\n⚠️  WARNINGS:');
        allWarnings.forEach(w => console.log(`  • ${w}`));
      } else {
        console.log('✓ All validations passed');
      }

      console.log('─'.repeat(50) + '\n');

    } catch (err) {
      console.log(`[docker-validator] Warning: ${err.message}\n`);
    }

    return { proceed: true };
  }
};
