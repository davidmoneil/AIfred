#!/usr/bin/env node
/**
 * Bash Safety Guard — Consolidated PreToolUse Hook
 *
 * Merges 6 security hooks into a single process for ~83% spawn reduction:
 *   1. checkCredentials()    — credential-guard.js
 *   2. checkDangerousOps()   — dangerous-op-guard.js
 *   3. checkBranchProtection() — branch-protection.js
 *   4. checkWorkspaceBounds()  — workspace-guard.js
 *   5. checkAmendSafety()    — amend-validator.js
 *   6. checkSecrets()        — secret-scanner.js
 *
 * Registered under two matchers in settings.json:
 *   ^Bash$            → all 6 checks (short-circuit on first block)
 *   ^(Read|Write|Edit)$ → credential + workspace checks only
 *
 * Execution order: fast regex checks first, async git checks later.
 * Short-circuits on first { proceed: false } result.
 *
 * Created: 2026-02-09 (B.3 Hook Consolidation, Merge 1)
 * Source hooks: credential-guard.js, branch-protection.js, amend-validator.js,
 *              workspace-guard.js, dangerous-op-guard.js, secret-scanner.js
 */

const path = require('path');
const { exec, execSync } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);

// ============================================================
// CREDENTIAL GUARD — Patterns & Functions
// ============================================================

const BLOCKED_PATHS = [
  /\.ssh\/id_/, /\.ssh\/.*_key$/, /\.ssh\/known_hosts$/,
  /\.aws\/credentials$/, /\.aws\/config$/, /\.npmrc$/, /\.netrc$/,
  /\.docker\/config\.json$/,
  /\.anthropic/, /\.openai/, /\.github\/.*token/,
  /\.password-store\//, /\.gnupg\/.*\.key$/,
  /\.bash_history$/, /\.zsh_history$/,
  /\.pgpass$/, /\.my\.cnf$/,
  /\.env$/, /\.env\.[^/]+$/, /secrets\.ya?ml$/, /credentials\.json$/,
  /service-account.*\.json$/
];

const JARVIS_ALLOWED = [
  /\.claude\/config\//, /\.claude\/state\//, /\.claude\/context\//,
  /\.claude\/settings\.json$/, /paths-registry\.yaml$/
];

const WARN_PATHS = [
  /config\.ya?ml$/, /settings\.json$/, /\.conf$/,
  /docker-compose.*\.ya?ml$/
];

const CREDENTIAL_PATTERNS = [
  /password\s*[:=]/i, /api[_-]?key\s*[:=]/i, /secret[_-]?key\s*[:=]/i,
  /access[_-]?token\s*[:=]/i, /auth[_-]?token\s*[:=]/i,
  /private[_-]?key\s*[:=]/i, /bearer\s+[A-Za-z0-9_\-.]+/i
];

function normalizePath(filePath) {
  return filePath.replace(/^~/, process.env.HOME || '');
}

function isJarvisAllowed(filePath) {
  const normalized = normalizePath(filePath);
  return JARVIS_ALLOWED.some(p => p.test(normalized));
}

function isBlockedCredentialPath(filePath) {
  const normalized = normalizePath(filePath);
  if (isJarvisAllowed(normalized)) return false;
  return BLOCKED_PATHS.some(p => p.test(normalized));
}

function isWarnCredentialPath(filePath) {
  const normalized = normalizePath(filePath);
  if (isJarvisAllowed(normalized)) return false;
  return WARN_PATHS.some(p => p.test(normalized));
}

function containsCredentials(content) {
  if (!content) return false;
  return CREDENTIAL_PATTERNS.some(p => p.test(content));
}

function extractBashReadPath(command) {
  const patterns = [
    /cat\s+([^\s|>]+)/, /less\s+([^\s]+)/, /more\s+([^\s]+)/,
    /head\s+(?:-n\s+\d+\s+)?([^\s]+)/, /tail\s+(?:-n\s+\d+\s+)?([^\s]+)/,
    /vim?\s+([^\s]+)/, /nano\s+([^\s]+)/
  ];
  for (const p of patterns) {
    const m = command.match(p);
    if (m) return m[1];
  }
  return null;
}

function checkCredentials(tool, parameters) {
  let filePath = null;
  let isWrite = false;
  let content = null;

  switch (tool) {
    case 'Read':
      filePath = parameters?.file_path || parameters?.path || null;
      break;
    case 'Write':
      filePath = parameters?.file_path || parameters?.path || null;
      isWrite = true;
      content = parameters?.content;
      break;
    case 'Edit':
      // Edit doesn't expose full file content; skip credential content check
      filePath = parameters?.file_path || parameters?.path || null;
      break;
    case 'Bash':
      filePath = extractBashReadPath(parameters?.command || '');
      break;
    default:
      return null;
  }

  if (!filePath) return null;

  if (isBlockedCredentialPath(filePath)) {
    console.error('\n[bash-safety-guard/credentials] BLOCKED: Credential file access');
    console.error(`  File: ${filePath}`);
    console.error('  Reason: This file type may contain sensitive credentials\n');
    return { proceed: false, message: `Blocked: Cannot access credential file ${path.basename(filePath)}` };
  }

  if (isWarnCredentialPath(filePath)) {
    console.error(`[bash-safety-guard/credentials] Warning: Config file access — ${filePath}`);
  }

  if (isWrite && content && containsCredentials(content)) {
    console.error('\n[bash-safety-guard/credentials] WARNING: Content may contain credentials');
    console.error(`  File: ${filePath}`);
    console.error('  Recommendation: Use environment variables or .gitignore\n');
  }

  return null; // no block
}

// ============================================================
// DANGEROUS OPERATION GUARD — Patterns & Functions
// ============================================================

const BLOCK_OPS = [
  { name: 'Delete system root', pattern: /rm\s+(-[rfRvfi]+\s+)*\/(?!Users|home|tmp)/, message: 'Attempting to delete system root directories' },
  { name: 'Delete entire home', pattern: /rm\s+(-[rfRvfi]+\s+)*~\/?$/, message: 'Attempting to delete entire home directory' },
  { name: 'Sudo recursive delete', pattern: /sudo\s+rm\s+(-[rfRvfi]+\s+)*(\/|~)/, message: 'Sudo recursive delete on root or home' },
  { name: 'Format filesystem', pattern: /mkfs(\.[a-z0-9]+)?\s+/i, message: 'Filesystem format command detected' },
  { name: 'Raw disk write', pattern: /dd\s+.*if=.*of=\/dev\//, message: 'Raw disk write operation detected' },
  { name: 'Force push to main', pattern: /git\s+push\s+.*--force.*\s+(main|master)\b/, message: 'Force push to main/master branch' },
  { name: 'Force push main (alt)', pattern: /git\s+push\s+(-f|--force)\s+.*\s*(main|master)/, message: 'Force push to main/master branch' },
  { name: 'Recursive chmod 777 root', pattern: /chmod\s+(-R\s+)?777\s+\//, message: 'Recursive chmod 777 on root' },
  { name: 'Fork bomb', pattern: /:\(\)\s*{\s*:\s*\|\s*:\s*&\s*}\s*;?\s*:/, message: 'Fork bomb detected' },
  { name: 'Overwrite boot sector', pattern: /dd\s+.*of=\/dev\/(sd[a-z]|nvme|hd[a-z])$/, message: 'Overwriting disk device' },
];

const WARN_OPS = [
  { name: 'Recursive delete', pattern: /rm\s+(-[rfRvfi]*r[rfRvfi]*|-[rfRvfi]*R[rfRvfi]*)\s+/, message: 'Recursive delete operation' },
  { name: 'Git hard reset', pattern: /git\s+reset\s+--hard/, message: 'Hard reset will discard uncommitted changes' },
  { name: 'Git clean force', pattern: /git\s+clean\s+(-[fd]+|--force)/, message: 'Will delete untracked files' },
  { name: 'Chmod recursive', pattern: /chmod\s+-R\s+/, message: 'Recursive permission change' },
  { name: 'Chown recursive', pattern: /chown\s+-R\s+/, message: 'Recursive ownership change' },
  { name: 'Kill all processes', pattern: /pkill\s+-9\s+|killall\s+-9\s+/, message: 'Force killing processes' },
];

function checkDangerousOps(command) {
  if (!command.trim()) return null;

  for (const { name, pattern, message } of BLOCK_OPS) {
    if (pattern.test(command)) {
      console.error('\n[bash-safety-guard/dangerous-ops] BLOCKED');
      console.error(`  Pattern: ${name}`);
      console.error(`  Reason: ${message}`);
      console.error(`  Command: ${command.length > 80 ? command.substring(0, 80) + '...' : command}\n`);
      return { proceed: false, message: `Blocked: ${message}` };
    }
  }

  for (const { name, pattern, message } of WARN_OPS) {
    if (pattern.test(command)) {
      console.error(`[bash-safety-guard/dangerous-ops] Warning: ${name} — ${message}`);
    }
  }

  return null;
}

// ============================================================
// BRANCH PROTECTION — Patterns & Functions
// ============================================================

const PROTECTED_BRANCHES = ['main', 'master', 'production', 'prod', 'release', 'stable'];

const DANGEROUS_GIT = [
  { pattern: /git\s+push\s+.*--force(?:-with-lease)?/i, action: 'force push', severity: 'high' },
  { pattern: /git\s+push\s+-f\s/i, action: 'force push', severity: 'high' },
  { pattern: /git\s+reset\s+--hard/i, action: 'hard reset', severity: 'medium' },
  { pattern: /git\s+rebase\s+.*-i/i, action: 'interactive rebase', severity: 'low' },
  { pattern: /git\s+branch\s+-[dD]\s+(main|master|production)/i, action: 'delete protected branch', severity: 'high' },
  { pattern: /git\s+push\s+.*:\s*(main|master|production)/i, action: 'delete remote protected branch', severity: 'high' },
];

async function getCurrentBranch() {
  try {
    const { stdout } = await execAsync('git rev-parse --abbrev-ref HEAD 2>/dev/null');
    return stdout.trim();
  } catch { return null; }
}

function isProtectedBranch(name) {
  if (!name) return false;
  return PROTECTED_BRANCHES.some(p => name.toLowerCase() === p.toLowerCase());
}

function getTargetBranch(command) {
  const pushMatch = command.match(/git\s+push\s+(?:[^\s]+\s+)?([^\s]+)$/i);
  if (pushMatch) return pushMatch[1];
  const remoteMatch = command.match(/origin\/(\S+)/i);
  if (remoteMatch) return remoteMatch[1];
  return null;
}

async function checkBranchProtection(command) {
  if (!command.includes('git ')) return null;

  for (const { pattern, action, severity } of DANGEROUS_GIT) {
    if (!pattern.test(command)) continue;

    const currentBranch = await getCurrentBranch();
    const targetBranch = getTargetBranch(command) || currentBranch;
    const affectsProtected = isProtectedBranch(currentBranch) || isProtectedBranch(targetBranch);

    if (affectsProtected && severity === 'high') {
      console.error('\n[bash-safety-guard/branch] BLOCKED');
      console.error(`  Action: ${action}`);
      console.error(`  Branch: ${targetBranch || currentBranch}`);
      console.error(`  Protected branches: ${PROTECTED_BRANCHES.join(', ')}\n`);
      return { proceed: false, message: `Blocked: ${action} on protected branch ${targetBranch || currentBranch}` };
    }

    if (affectsProtected) {
      console.error(`[bash-safety-guard/branch] Warning: ${action} on protected branch`);
    } else if (severity === 'high') {
      console.error(`[bash-safety-guard/branch] Warning: ${action} on ${currentBranch || 'unknown'}`);
    }

    break; // only report first matching pattern
  }

  return null;
}

// ============================================================
// WORKSPACE GUARD — Patterns & Functions
// ============================================================

const AIFRED_BASELINE = '/Users/aircannon/Claude/AIfred';
const JARVIS_WORKSPACE = '/Users/aircannon/Claude/Jarvis';

const FORBIDDEN_PATHS = [
  '/', '/etc', '/usr', '/bin', '/sbin', '/var', '/System', '/Library', '/Applications',
  path.join(process.env.HOME || '', '.ssh'),
  path.join(process.env.HOME || '', '.gnupg'),
];

function isBaselinePath(targetPath) {
  if (!targetPath) return false;
  return path.resolve(targetPath).startsWith(AIFRED_BASELINE);
}

function isForbiddenPath(targetPath) {
  if (!targetPath) return false;
  const resolved = path.resolve(targetPath);
  for (const forbidden of FORBIDDEN_PATHS) {
    if (resolved === forbidden) return true;
    if (forbidden === '/' && !resolved.startsWith('/Users')) return true;
  }
  for (const forbidden of FORBIDDEN_PATHS) {
    if (forbidden !== '/' && resolved.startsWith(forbidden + '/')) return true;
  }
  return false;
}

function isJarvisWorkspace(targetPath) {
  if (!targetPath) return false;
  return path.resolve(targetPath).startsWith(JARVIS_WORKSPACE);
}

function extractWritePath(tool, parameters) {
  if (tool === 'Write' || tool === 'Edit') {
    return parameters?.file_path || parameters?.path || null;
  }
  if (tool === 'Bash') {
    const command = parameters?.command || '';
    const writePatterns = [
      />\s*(\S+)/, />>\s*(\S+)/, /tee\s+(?:-a\s+)?(\S+)/,
      /mv\s+\S+\s+(\S+)/, /cp\s+\S+\s+(\S+)/, /rm\s+(?:-[rf]+\s+)?(\S+)/,
      /mkdir\s+(?:-p\s+)?(\S+)/, /touch\s+(\S+)/,
    ];
    for (const p of writePatterns) {
      const m = command.match(p);
      if (m && m[1]) return m[1];
    }
    if (command.includes(AIFRED_BASELINE)) return AIFRED_BASELINE;
  }
  return null;
}

function checkWorkspaceBounds(tool, parameters) {
  const WRITE_TOOLS = ['Write', 'Edit', 'Bash'];
  if (!WRITE_TOOLS.includes(tool)) return null;

  const targetPath = extractWritePath(tool, parameters);
  if (!targetPath) return null;

  if (isBaselinePath(targetPath)) {
    console.error('\n[bash-safety-guard/workspace] BLOCKED — AIfred Baseline Modification');
    console.error(`  Path: ${targetPath}`);
    console.error('  The AIfred baseline repository is READ-ONLY.\n');
    return { proceed: false, message: `Blocked: AIfred baseline is read-only` };
  }

  if (isForbiddenPath(targetPath)) {
    console.error('\n[bash-safety-guard/workspace] BLOCKED — Forbidden System Path');
    console.error(`  Path: ${targetPath}\n`);
    return { proceed: false, message: `Blocked: Forbidden system path ${targetPath}` };
  }

  if ((tool === 'Write' || tool === 'Edit') && !isJarvisWorkspace(targetPath)) {
    console.error(`[bash-safety-guard/workspace] Warning: Operation outside Jarvis workspace — ${targetPath}`);
  }

  return null;
}

// ============================================================
// AMEND VALIDATOR — Functions
// ============================================================

const EXPECTED_AUTHORS = [
  /david\s*moneil/i, /davidmoneil/i, /claude/i, /anthropic/i,
  /noreply@anthropic\.com/i, /aircannon/i, /CannonCoPilot/i
];

async function getHeadCommitInfo() {
  try {
    const { stdout } = await execAsync('git log -1 --format="%H|%an|%ae|%s" 2>/dev/null');
    const [hash, authorName, authorEmail, subject] = stdout.trim().split('|');
    return { hash, authorName, authorEmail, subject };
  } catch { return null; }
}

async function isCommitPushed(hash) {
  try {
    const { stdout } = await execAsync(`git branch -r --contains ${hash} 2>/dev/null`);
    return stdout.trim().length > 0;
  } catch { return false; }
}

function isExpectedAuthor(authorName, authorEmail) {
  const combined = `${authorName} ${authorEmail}`;
  return EXPECTED_AUTHORS.some(p => p.test(combined));
}

async function checkAmendSafety(command) {
  if (!command.includes('git commit') || !command.includes('--amend')) return null;

  const headInfo = await getHeadCommitInfo();
  if (!headInfo) {
    console.error('[bash-safety-guard/amend] Warning: Could not get commit info');
    return null;
  }

  if (!isExpectedAuthor(headInfo.authorName, headInfo.authorEmail)) {
    console.error('\n[bash-safety-guard/amend] BLOCKED — Amending another author\'s commit');
    console.error(`  Author: ${headInfo.authorName} <${headInfo.authorEmail}>`);
    console.error(`  Subject: ${headInfo.subject?.substring(0, 50)}...\n`);
    return { proceed: false, message: 'Cannot amend commit by different author' };
  }

  const isPushed = await isCommitPushed(headInfo.hash);
  if (isPushed) {
    try {
      const { stdout } = await execAsync('git status -sb 2>/dev/null');
      const aheadMatch = stdout.match(/\[ahead (\d+)/);
      const ahead = aheadMatch ? parseInt(aheadMatch[1]) : 0;

      if (ahead === 0) {
        console.error('\n[bash-safety-guard/amend] BLOCKED — Commit already synced to remote');
        console.error('  Amending would require force push. Create a new commit instead.\n');
        return { proceed: false, message: 'Cannot amend commit that exists on remote' };
      }
      console.error('[bash-safety-guard/amend] Warning: Branch ahead of remote — amend may be okay');
    } catch {
      // fall through
    }
  }

  return null;
}

// ============================================================
// SECRET SCANNER — Functions
// ============================================================

const SECRET_PATTERNS = [
  { name: 'AWS Access Key', pattern: /AKIA[0-9A-Z]{16}/ },
  { name: 'AWS Secret Key', pattern: /[A-Za-z0-9\/+=]{40}/ },
  { name: 'GitHub Token', pattern: /gh[pousr]_[A-Za-z0-9_]{36,}/ },
  { name: 'Generic API Key', pattern: /[aA][pP][iI][-_]?[kK][eE][yY][\s]*[=:]\s*["']?[A-Za-z0-9_\-]{20,}/ },
  { name: 'Private Key', pattern: /-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----/ },
  { name: 'Password in URL', pattern: /:\/\/[^:]+:[^@]+@/ },
  { name: 'JWT Token', pattern: /eyJ[A-Za-z0-9_-]+\.eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+/ },
];

const FALSE_POSITIVE_INDICATORS = ['example', 'placeholder', 'your_', 'xxx', 'test_', 'dummy', 'sample'];

function isFalsePositive(match) {
  const lower = match.toLowerCase();
  return FALSE_POSITIVE_INDICATORS.some(ind => lower.includes(ind));
}

function checkSecrets(command) {
  if (!command.includes('git commit')) return null;

  let stagedFiles;
  try {
    const output = execSync('git diff --cached --name-only', { encoding: 'utf8' });
    stagedFiles = output.trim().split('\n').filter(Boolean);
  } catch { return null; }

  if (stagedFiles.length === 0) return null;

  const findings = [];
  for (const file of stagedFiles) {
    if (file.match(/\.(png|jpg|gif|ico|woff|ttf|pdf)$/i)) continue;

    let content;
    try { content = execSync(`git show :${file}`, { encoding: 'utf8' }); }
    catch { continue; }

    for (const { name, pattern } of SECRET_PATTERNS) {
      const matches = content.match(new RegExp(pattern, 'g')) || [];
      for (const match of matches) {
        if (!isFalsePositive(match)) {
          findings.push({ file, type: name, preview: match.substring(0, 20) + '...' });
        }
      }
    }
  }

  if (findings.length > 0) {
    console.error('\n[bash-safety-guard/secrets] BLOCKED — Secrets detected in staged files\n');
    for (const f of findings) {
      console.error(`  File: ${f.file}  Type: ${f.type}  Preview: ${f.preview}`);
    }
    console.error('\n  Remove secrets, add to .gitignore, or use environment variables.\n');
    return { proceed: false, message: `Blocked: ${findings.length} potential secret(s) in staged files` };
  }

  return null;
}

// ============================================================
// MAIN HANDLER — Dispatch by tool type
// ============================================================

async function handler(context) {
  const { tool, tool_input } = context;
  const parameters = tool_input || context.parameters || {};

  try {
    if (tool === 'Bash') {
      const command = parameters?.command || '';

      // 1. Credential check (fast regex)
      const credResult = checkCredentials(tool, parameters);
      if (credResult) return credResult;

      // 2. Dangerous ops check (fast regex)
      const dangerResult = checkDangerousOps(command);
      if (dangerResult) return dangerResult;

      // 3. Branch protection (async — git call)
      const branchResult = await checkBranchProtection(command);
      if (branchResult) return branchResult;

      // 4. Workspace bounds (fast path.resolve)
      const workspaceResult = checkWorkspaceBounds(tool, parameters);
      if (workspaceResult) return workspaceResult;

      // 5. Amend safety (async — git calls)
      const amendResult = await checkAmendSafety(command);
      if (amendResult) return amendResult;

      // 6. Secret scanner (sync execSync — only for git commit)
      const secretResult = checkSecrets(command);
      if (secretResult) return secretResult;

    } else if (tool === 'Read' || tool === 'Write' || tool === 'Edit') {
      // Non-Bash file tools: credential + workspace checks only
      const credResult = checkCredentials(tool, parameters);
      if (credResult) return credResult;

      const workspaceResult = checkWorkspaceBounds(tool, parameters);
      if (workspaceResult) return workspaceResult;
    }
  } catch (err) {
    console.error(`[bash-safety-guard] Error: ${err.message} — proceeding with caution`);
  }

  return { proceed: true };
}

// Export for require() usage
module.exports = {
  name: 'bash-safety-guard',
  description: 'Consolidated security guard (credentials, dangerous ops, branch protection, workspace, amend safety, secrets)',
  event: 'PreToolUse',
  handler
};

// ============================================================
// STDIN/STDOUT HANDLER — Required for Claude Code hooks
// ============================================================
if (require.main === module) {
  const chunks = [];
  process.stdin.on('data', chunk => chunks.push(chunk));
  process.stdin.on('end', async () => {
    let context;
    try {
      context = JSON.parse(Buffer.concat(chunks).toString('utf8'));
    } catch (err) {
      console.error(`[bash-safety-guard] Parse error: ${err.message}`);
      console.log(JSON.stringify({ proceed: true }));
      return;
    }

    try {
      const result = await handler(context);
      console.log(JSON.stringify(result));
    } catch (err) {
      console.error(`[bash-safety-guard] Handler error: ${err.message}`);
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
