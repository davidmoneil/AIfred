/**
 * Secret Scanner Hook
 *
 * Scans for secrets before git commits to prevent credential leaks.
 *
 * Created: AIfred v1.0
 */

const { execSync } = require('child_process');

// Patterns to detect
const SECRET_PATTERNS = [
  { name: 'AWS Access Key', pattern: /AKIA[0-9A-Z]{16}/ },
  { name: 'AWS Secret Key', pattern: /[A-Za-z0-9\/+=]{40}/ },
  { name: 'GitHub Token', pattern: /gh[pousr]_[A-Za-z0-9_]{36,}/ },
  { name: 'Generic API Key', pattern: /[aA][pP][iI][-_]?[kK][eE][yY][\s]*[=:]\s*["']?[A-Za-z0-9_\-]{20,}/ },
  { name: 'Private Key', pattern: /-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----/ },
  { name: 'Password in URL', pattern: /:\/\/[^:]+:[^@]+@/ },
  { name: 'JWT Token', pattern: /eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/ },
];

// False positive indicators
const FALSE_POSITIVE_INDICATORS = [
  'example', 'placeholder', 'your_', 'xxx', 'test_', 'dummy', 'sample'
];

function isFalsePositive(match) {
  const lower = match.toLowerCase();
  return FALSE_POSITIVE_INDICATORS.some(indicator => lower.includes(indicator));
}

function getStagedFiles() {
  try {
    const output = execSync('git diff --cached --name-only', { encoding: 'utf8' });
    return output.trim().split('\n').filter(Boolean);
  } catch {
    return [];
  }
}

function getStagedContent(file) {
  try {
    return execSync(`git show :${file}`, { encoding: 'utf8' });
  } catch {
    return '';
  }
}

module.exports = {
  name: 'secret-scanner',
  description: 'Scan for secrets before git commits',
  event: 'PreToolUse',

  async handler(context) {
    const { tool, parameters } = context;

    // Only check git commit operations
    if (tool !== 'Bash') return { proceed: true };

    const command = parameters?.command || '';
    if (!command.includes('git commit')) return { proceed: true };

    const stagedFiles = getStagedFiles();
    if (stagedFiles.length === 0) return { proceed: true };

    const findings = [];

    for (const file of stagedFiles) {
      // Skip binary and certain file types
      if (file.match(/\.(png|jpg|gif|ico|woff|ttf|pdf)$/i)) continue;

      const content = getStagedContent(file);

      for (const { name, pattern } of SECRET_PATTERNS) {
        const matches = content.match(new RegExp(pattern, 'g')) || [];

        for (const match of matches) {
          if (!isFalsePositive(match)) {
            findings.push({
              file,
              type: name,
              preview: match.substring(0, 20) + '...'
            });
          }
        }
      }
    }

    if (findings.length > 0) {
      console.log('\n⚠️  SECRETS DETECTED - COMMIT BLOCKED\n');
      console.log('The following potential secrets were found:\n');

      for (const finding of findings) {
        console.log(`  📄 ${finding.file}`);
        console.log(`     Type: ${finding.type}`);
        console.log(`     Preview: ${finding.preview}\n`);
      }

      console.log('To proceed, either:');
      console.log('1. Remove the secrets from the files');
      console.log('2. Add to .gitignore if the file should not be committed');
      console.log('3. Use environment variables instead of hardcoded values\n');

      return { proceed: false };
    }

    return { proceed: true };
  }
};
