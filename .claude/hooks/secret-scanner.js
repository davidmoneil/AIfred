#!/usr/bin/env node
/**
 * Secret Scanner Hook
 *
 * Scans for potential secrets, API keys, and credentials before git commits.
 * Blocks commits if secrets are detected.
 *
 * Priority: HIGH (Security Critical)
 * Created: 2025-12-06
 * Fixed: 2026-01-21 - Converted to stdin/stdout executable hook
 */

const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);

// Patterns that indicate potential secrets
const SECRET_PATTERNS = [
  // API Keys - Specific Services
  { name: 'AWS Access Key', pattern: /AKIA[0-9A-Z]{16}/g },
  { name: 'AWS Secret Key', pattern: /[A-Za-z0-9/+=]{40}/g, context: 'aws_secret' },
  { name: 'GitHub Token', pattern: /gh[pousr]_[A-Za-z0-9_]{36,}/g },
  { name: 'GitHub Personal Access Token', pattern: /github_pat_[A-Za-z0-9_]{22,}/g },
  { name: 'Anthropic API Key', pattern: /sk-ant-[A-Za-z0-9-_]{20,}/g },
  { name: 'OpenAI API Key', pattern: /sk-[A-Za-z0-9]{48}/g },
  { name: 'Slack Token', pattern: /xox[baprs]-[0-9]{10,13}-[0-9]{10,13}[a-zA-Z0-9-]*/g },
  { name: 'Discord Token', pattern: /[MN][A-Za-z\d]{23,}\.[\w-]{6}\.[\w-]{27}/g },
  { name: 'Google API Key', pattern: /AIza[0-9A-Za-z_-]{35}/g },
  { name: 'Stripe Secret Key', pattern: /sk_live_[0-9a-zA-Z]{24,}/g },
  { name: 'Stripe Publishable Key', pattern: /pk_live_[0-9a-zA-Z]{24,}/g },
  { name: 'Twilio API Key', pattern: /SK[0-9a-fA-F]{32}/g },
  { name: 'NPM Token', pattern: /npm_[A-Za-z0-9]{36}/g },
  { name: 'Heroku API Key', pattern: /[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}/g, context: 'heroku' },
  { name: 'SendGrid API Key', pattern: /SG\.[A-Za-z0-9_-]{22}\.[A-Za-z0-9_-]{43}/g },
  { name: 'Mailchimp API Key', pattern: /[0-9a-f]{32}-us[0-9]{1,2}/g },

  // Database URLs with passwords
  { name: 'Database URL with Password', pattern: /(?:postgres|mysql|mongodb|redis):\/\/[^:]+:[^@]+@[^/\s]+/gi },

  // Private Keys
  { name: 'RSA Private Key', pattern: /-----BEGIN RSA PRIVATE KEY-----/g },
  { name: 'OpenSSH Private Key', pattern: /-----BEGIN OPENSSH PRIVATE KEY-----/g },
  { name: 'PGP Private Key', pattern: /-----BEGIN PGP PRIVATE KEY BLOCK-----/g },
  { name: 'EC Private Key', pattern: /-----BEGIN EC PRIVATE KEY-----/g },
  { name: 'DSA Private Key', pattern: /-----BEGIN DSA PRIVATE KEY-----/g },
  { name: 'Generic Private Key', pattern: /-----BEGIN PRIVATE KEY-----/g },
  { name: 'Encrypted Private Key', pattern: /-----BEGIN ENCRYPTED PRIVATE KEY-----/g },

  // Unquoted environment variable assignments (NEW - was missing)
  { name: 'Env Var - Anthropic Key', pattern: /^[A-Z_]*ANTHROPIC[A-Z_]*=sk-ant-[^\s]+/gm },
  { name: 'Env Var - OpenAI Key', pattern: /^[A-Z_]*OPENAI[A-Z_]*=sk-[^\s]+/gm },
  { name: 'Env Var - AWS Key', pattern: /^AWS_SECRET_ACCESS_KEY=[^\s]+/gm },
  { name: 'Env Var - Generic Secret', pattern: /^[A-Z_]*(SECRET|TOKEN|PASSWORD|API_KEY)[A-Z_]*=[^\s'"]{16,}/gm },

  // Base64 encoded secrets (NEW - was missing)
  { name: 'Base64 Secret (long)', pattern: /(?:secret|token|key|password|credential)s?\s*[:=]\s*[A-Za-z0-9+/]{50,}={0,2}/gi },

  // Docker secrets path (NEW - was missing)
  { name: 'Docker Secret Path', pattern: /\/run\/secrets\/[a-zA-Z0-9_-]+/g },

  // SSH config patterns (NEW - was missing)
  { name: 'SSH IdentityFile', pattern: /IdentityFile\s+~?\/?[^\s]+(?:id_rsa|id_ed25519|id_ecdsa|\.pem)/gi },

  // Generic patterns
  { name: 'Generic API Key', pattern: /['"][a-zA-Z0-9_-]*api[_-]?key['"]?\s*[:=]\s*['"][A-Za-z0-9_\-]{20,}['"]/gi },
  { name: 'Generic Secret', pattern: /['"][a-zA-Z0-9_-]*secret['"]?\s*[:=]\s*['"][A-Za-z0-9_\-]{20,}['"]/gi },
  { name: 'Password Assignment', pattern: /password\s*[:=]\s*['"][^'"]{8,}['"]/gi },
  { name: 'Bearer Token', pattern: /Bearer\s+[A-Za-z0-9_\-.]+/g },

  // JWT Tokens (with signature)
  { name: 'JWT Token', pattern: /eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/g }
];

// Files to skip scanning
const SKIP_FILES = [
  /\.lock$/,
  /package-lock\.json$/,
  /yarn\.lock$/,
  /\.min\.js$/,
  /\.min\.css$/,
  /node_modules\//,
  /\.git\//,
  /\.claude\/hooks\/secret-scanner\.js$/ // Don't scan ourselves
];

// Files that are always sensitive
const SENSITIVE_FILES = [
  /\.env$/,
  /\.env\./,
  /credentials/i,
  /secrets/i,
  /\.pem$/,
  /\.key$/,
  /id_rsa/,
  /id_ed25519/,
  /id_ecdsa/,
  /\.htpasswd$/,
  /\.netrc$/,
  /\.npmrc$/,  // Can contain auth tokens
  /\.pypirc$/,  // Python package credentials
  /docker-credential/i,
  /kubeconfig/i,
  /aws\/credentials/i
];

/**
 * Check if file should be skipped
 */
function shouldSkipFile(filename) {
  return SKIP_FILES.some(pattern => pattern.test(filename));
}

/**
 * Check if file is inherently sensitive
 */
function isSensitiveFile(filename) {
  return SENSITIVE_FILES.some(pattern => pattern.test(filename));
}

/**
 * Scan content for secrets
 */
function scanForSecrets(content, filename) {
  const findings = [];

  // Check if this is a sensitive file type
  if (isSensitiveFile(filename)) {
    findings.push({
      type: 'Sensitive File',
      match: filename,
      line: 0,
      message: `File type "${filename}" should not be committed`
    });
  }

  // Scan content with all patterns
  const lines = content.split('\n');
  lines.forEach((line, lineNum) => {
    // Skip comment lines in most cases
    const trimmedLine = line.trim();
    if (trimmedLine.startsWith('//') || trimmedLine.startsWith('#') || trimmedLine.startsWith('*')) {
      // Still check for actual keys in comments (they shouldn't be there either)
      if (!trimmedLine.includes('example') && !trimmedLine.includes('placeholder')) {
        // Continue scanning
      } else {
        return; // Skip example/placeholder comments
      }
    }

    SECRET_PATTERNS.forEach(({ name, pattern }) => {
      const matches = line.match(pattern);
      if (matches) {
        matches.forEach(match => {
          // Filter out false positives
          if (isFalsePositive(match, line, filename)) {
            return;
          }

          findings.push({
            type: name,
            match: truncateSecret(match),
            line: lineNum + 1,
            message: `Potential ${name} found`
          });
        });
      }
    });
  });

  return findings;
}

/**
 * Check for common false positives
 */
function isFalsePositive(match, line, filename) {
  const lowerLine = line.toLowerCase();
  const lowerMatch = match.toLowerCase();

  // Placeholder values
  const placeholders = [
    'your_',
    'example',
    'placeholder',
    'xxx',
    'yyy',
    'zzz',
    'insert_',
    'replace_',
    'changeme',
    '<your',
    '${',
    '{{',
    'test_key',
    'dummy',
    'fake',
    'mock'
  ];

  if (placeholders.some(p => lowerMatch.includes(p) || lowerLine.includes(p))) {
    return true;
  }

  // Documentation files
  if (filename.endsWith('.md') || filename.endsWith('.txt') || filename.endsWith('.rst')) {
    // More lenient for docs - only flag obvious real secrets
    if (lowerLine.includes('example') || lowerLine.includes('format') || lowerLine.includes('like this')) {
      return true;
    }
  }

  // Test files
  if (filename.includes('test') || filename.includes('spec') || filename.includes('mock')) {
    // Still flag real-looking keys in tests
    if (lowerLine.includes('mock') || lowerLine.includes('fake') || lowerLine.includes('test_')) {
      return true;
    }
  }

  return false;
}

/**
 * Truncate secret for safe logging
 */
function truncateSecret(secret) {
  if (secret.length <= 10) return '***';
  return secret.substring(0, 5) + '...' + secret.substring(secret.length - 3);
}

/**
 * Get staged files content
 */
async function getStagedFiles() {
  try {
    const { stdout } = await execAsync('git diff --cached --name-only 2>/dev/null');
    return stdout.trim().split('\n').filter(f => f);
  } catch {
    return [];
  }
}

/**
 * Get content of staged file
 */
async function getStagedFileContent(filename) {
  try {
    const { stdout } = await execAsync(`git show :${filename} 2>/dev/null`);
    return stdout;
  } catch {
    return '';
  }
}

/**
 * Main handler logic
 */
async function handleHook(context) {
  const { tool_name, tool_input } = context;

  // Only run for git commit commands
  if (tool_name !== 'Bash') return { proceed: true };

  const command = tool_input?.command || '';
  if (!command.includes('git commit') && !command.includes('git add')) {
    return { proceed: true };
  }

  // For git add, just warn - don't block
  const isCommit = command.includes('git commit');

  try {
    const stagedFiles = await getStagedFiles();
    if (stagedFiles.length === 0) {
      return { proceed: true };
    }

    const allFindings = [];

    for (const filename of stagedFiles) {
      if (shouldSkipFile(filename)) continue;

      const content = await getStagedFileContent(filename);
      if (!content) continue;

      const findings = scanForSecrets(content, filename);
      if (findings.length > 0) {
        allFindings.push({ filename, findings });
      }
    }

    if (allFindings.length > 0) {
      console.error('\n[secret-scanner] POTENTIAL SECRETS DETECTED:');
      console.error('-'.repeat(50));

      allFindings.forEach(({ filename, findings }) => {
        console.error(`\n${filename}:`);
        findings.forEach(f => {
          console.error(`   Line ${f.line}: ${f.type}`);
          console.error(`   Found: ${f.match}`);
        });
      });

      console.error('\n' + '-'.repeat(50));

      if (isCommit) {
        console.error('[secret-scanner] BLOCKING COMMIT - Review findings above');
        console.error('[secret-scanner] If these are false positives, you can:');
        console.error('  1. Add to .gitignore');
        console.error('  2. Use environment variables instead');
        console.error('  3. Manually commit with --no-verify (not recommended)\n');
        return { proceed: false, message: 'Potential secrets detected in staged files' };
      } else {
        console.error('[secret-scanner] WARNING: Review these files before committing\n');
      }
    }

  } catch (err) {
    console.error(`[secret-scanner] Error during scan: ${err.message}`);
    // Don't block on scanner errors
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
  console.error(`[secret-scanner] Fatal error: ${err.message}`);
  console.log(JSON.stringify({ proceed: true }));
});
