/**
 * @deprecated Use docker-validator.js instead (consolidated 2025-12-24)
 *
 * Environment Validator Hook
 *
 * Checks for required environment variables before deployment:
 * - Validates .env file exists if referenced
 * - Checks env_file references in compose
 * - Warns about missing required variables
 *
 * Priority: MEDIUM (Infrastructure Safety)
 * Created: 2025-12-06
 */

const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);
const fs = require('fs').promises;
const path = require('path');

// Common required environment variables by service type
const COMMON_REQUIRED_VARS = {
  'postgres': ['POSTGRES_PASSWORD'],
  'mysql': ['MYSQL_ROOT_PASSWORD'],
  'redis': [],
  'n8n': ['N8N_ENCRYPTION_KEY'],
  'grafana': ['GF_SECURITY_ADMIN_PASSWORD'],
  'oauth2-proxy': ['OAUTH2_PROXY_CLIENT_SECRET', 'OAUTH2_PROXY_COOKIE_SECRET'],
  'openwebui': [],
  'caddy': []
};

// Sensitive variable patterns that should not be empty
const SENSITIVE_PATTERNS = [
  /password/i,
  /secret/i,
  /api[_-]?key/i,
  /token/i,
  /private[_-]?key/i,
  /encryption[_-]?key/i
];

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
async function extractEnvFiles(composePath) {
  const envFiles = [];

  try {
    const content = await fs.readFile(composePath, 'utf-8');

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
  } catch {
    // File not readable
  }

  return [...new Set(envFiles)];
}

/**
 * Extract environment variables referenced in compose
 */
async function extractReferencedVars(composePath) {
  const vars = [];

  try {
    const content = await fs.readFile(composePath, 'utf-8');

    // Match ${VAR} and ${VAR:-default} patterns
    const varPattern = /\$\{([A-Z_][A-Z0-9_]*)(?::-[^}]*)?\}/g;
    let match;
    while ((match = varPattern.exec(content)) !== null) {
      vars.push(match[1]);
    }

    // Match $VAR patterns (without braces)
    const simpleVarPattern = /\$([A-Z_][A-Z0-9_]*)/g;
    while ((match = simpleVarPattern.exec(content)) !== null) {
      vars.push(match[1]);
    }

    // Match environment: section variables
    const envMatch = content.match(/environment:\s*\n((?:\s+-?\s*[A-Z_][^\n]*\n?)+)/g);
    if (envMatch) {
      envMatch.forEach(section => {
        const lines = section.split('\n');
        lines.forEach(line => {
          const varMatch = line.match(/^\s+-?\s*([A-Z_][A-Z0-9_]*)\s*[:=]/);
          if (varMatch) {
            vars.push(varMatch[1]);
          }
        });
      });
    }
  } catch {
    // File not readable
  }

  return [...new Set(vars)];
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

module.exports = {
  name: 'env-validator',
  description: 'Check for required environment variables before deployment',
  event: 'PreToolUse',

  async handler(context) {
    const { tool, parameters } = context;

    if (tool !== 'Bash') return { proceed: true };

    const command = parameters?.command || '';

    // Check for docker-compose up
    const composeMatch = command.match(/docker(?:-compose| compose)\s+(?:-f\s+["']?([^"'\s]+)["']?\s+)?(?:up|start)/i);

    if (!composeMatch) return { proceed: true };

    const composePath = composeMatch[1] || 'docker-compose.yml';
    const composeDir = path.dirname(path.resolve(composePath));

    console.log('\n[env-validator] Checking environment configuration...');

    try {
      const issues = [];
      const warnings = [];

      // Check for env_file references
      const envFiles = await extractEnvFiles(composePath);

      for (const envFile of envFiles) {
        const envPath = path.resolve(composeDir, envFile);

        try {
          await fs.access(envPath);
          const vars = await parseEnvFile(envPath);

          // Check for empty sensitive variables
          Object.entries(vars).forEach(([name, value]) => {
            if (isSensitiveVar(name) && isEmptyOrPlaceholder(value)) {
              warnings.push(`${name} in ${envFile} appears empty or placeholder`);
            }
          });
        } catch {
          issues.push(`env_file "${envFile}" does not exist`);
        }
      }

      // Check for variable references without defaults
      const referencedVars = await extractReferencedVars(composePath);
      const loadedVars = {};

      for (const envFile of envFiles) {
        const envPath = path.resolve(composeDir, envFile);
        const vars = await parseEnvFile(envPath);
        Object.assign(loadedVars, vars);
      }

      // Also check process.env
      for (const varName of referencedVars) {
        if (!(varName in loadedVars) && !(varName in process.env)) {
          // Variable not defined anywhere
          if (isSensitiveVar(varName)) {
            warnings.push(`${varName} is referenced but not defined`);
          }
        }
      }

      // Check for default .env file
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

      if (issues.length > 0) {
        console.log('─'.repeat(50));
        console.log('❌ ENVIRONMENT ISSUES:');
        issues.forEach(i => console.log(`  • ${i}`));
        console.log('─'.repeat(50));
        console.log('\nTo fix:');
        console.log('  1. Create missing .env files');
        console.log('  2. Or remove env_file references');
        console.log('  3. Or use environment: section directly\n');

        return {
          proceed: false,
          message: `Missing env files: ${issues.join('; ')}`
        };
      }

      if (warnings.length > 0) {
        console.log('─'.repeat(50));
        console.log('⚠️  WARNINGS:');
        warnings.forEach(w => console.log(`  • ${w}`));
        console.log('─'.repeat(50));
        console.log('Note: Sensitive variables should have secure values\n');
      } else {
        console.log('✓ Environment configuration valid\n');
      }

    } catch (err) {
      console.log(`[env-validator] Warning: ${err.message}\n`);
    }

    return { proceed: true };
  }
};
