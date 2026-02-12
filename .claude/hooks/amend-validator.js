/**
 * Amend Validator Hook
 *
 * Validates git commit --amend operations to prevent:
 * - Amending other developers' commits
 * - Amending already-pushed commits
 * - Changing authorship unexpectedly
 *
 * Priority: HIGH (Security Critical)
 * Created: 2025-12-06
 */

const { exec } = require('child_process');
const util = require('util');
const execAsync = util.promisify(exec);

// Expected author patterns (your commits)
// Customize this list with your name/email patterns
const EXPECTED_AUTHORS = [
  /claude/i,
  /anthropic/i,
  /noreply@anthropic\.com/i
  // Add your own patterns here, e.g.:
  // /your\s*name/i,
  // /yourname/i,
];

/**
 * Get HEAD commit info
 */
async function getHeadCommitInfo() {
  try {
    const { stdout } = await execAsync(
      'git log -1 --format="%H|%an|%ae|%s" 2>/dev/null'
    );
    const [hash, authorName, authorEmail, subject] = stdout.trim().split('|');
    return { hash, authorName, authorEmail, subject };
  } catch {
    return null;
  }
}

/**
 * Check if commit is pushed to remote
 */
async function isCommitPushed(hash) {
  try {
    // Check if commit exists on any remote branch
    const { stdout } = await execAsync(
      `git branch -r --contains ${hash} 2>/dev/null`
    );
    return stdout.trim().length > 0;
  } catch {
    return false;
  }
}

/**
 * Check if author is expected (our commits)
 */
function isExpectedAuthor(authorName, authorEmail) {
  const combined = `${authorName} ${authorEmail}`;
  return EXPECTED_AUTHORS.some(pattern => pattern.test(combined));
}

/**
 * Get current branch tracking status
 */
async function getBranchStatus() {
  try {
    const { stdout } = await execAsync('git status -sb 2>/dev/null');
    const firstLine = stdout.split('\n')[0];

    // Parse status like "## main...origin/main [ahead 2]"
    const aheadMatch = firstLine.match(/\[ahead (\d+)/);
    const behindMatch = firstLine.match(/behind (\d+)/);

    return {
      ahead: aheadMatch ? parseInt(aheadMatch[1]) : 0,
      behind: behindMatch ? parseInt(behindMatch[1]) : 0
    };
  } catch {
    return { ahead: 0, behind: 0 };
  }
}

module.exports = {
  name: 'amend-validator',
  description: 'Validate git amend operations for safety',
  event: 'PreToolUse',

  async handler(context) {
    const { tool, parameters } = context;

    // Only check Bash git commands
    if (tool !== 'Bash') return { proceed: true };

    const command = parameters?.command || '';

    // Check for amend operations
    if (!command.includes('git commit') || !command.includes('--amend')) {
      return { proceed: true };
    }

    console.log('\n[amend-validator] Checking amend safety...');

    try {
      // Get HEAD commit info
      const headInfo = await getHeadCommitInfo();
      if (!headInfo) {
        console.log('[amend-validator] ⚠️  Could not get commit info, proceeding with caution\n');
        return { proceed: true };
      }

      console.log('─'.repeat(50));
      console.log(`Commit: ${headInfo.hash.substring(0, 8)}`);
      console.log(`Author: ${headInfo.authorName} <${headInfo.authorEmail}>`);
      console.log(`Subject: ${headInfo.subject.substring(0, 50)}...`);
      console.log('─'.repeat(50));

      // Check 1: Is it our commit?
      if (!isExpectedAuthor(headInfo.authorName, headInfo.authorEmail)) {
        console.log('[amend-validator] ❌ BLOCKED: Attempting to amend another author\'s commit');
        console.log(`\nThe HEAD commit was authored by: ${headInfo.authorName}`);
        console.log('Only amend commits you authored.');
        console.log('\nIf this is intentional:');
        console.log('  - Create a new commit instead');
        console.log('  - Or get explicit approval from the original author\n');

        return {
          proceed: false,
          message: 'Cannot amend commit by different author'
        };
      }

      // Check 2: Is commit already pushed?
      const isPushed = await isCommitPushed(headInfo.hash);
      if (isPushed) {
        const status = await getBranchStatus();

        console.log('[amend-validator] ⚠️  WARNING: Commit is already pushed to remote');
        console.log(`Branch status: ${status.ahead} ahead, ${status.behind} behind`);

        if (status.ahead === 0) {
          // The commit is pushed and we're not ahead - this is dangerous
          console.log('\n[amend-validator] ❌ BLOCKED: Cannot amend synced commit');
          console.log('This commit exists on the remote. Amending would require force push.');
          console.log('\nOptions:');
          console.log('  - Create a new fixup commit');
          console.log('  - Use git revert for changes\n');

          return {
            proceed: false,
            message: 'Cannot amend commit that exists on remote'
          };
        } else {
          console.log('[amend-validator] Branch is ahead of remote - amend may be okay');
          console.log('Note: You will need to force push to update remote\n');
        }
      } else {
        console.log('[amend-validator] ✓ Commit is local only - safe to amend\n');
      }

    } catch (err) {
      console.error(`[amend-validator] Error: ${err.message}`);
      console.log('[amend-validator] Proceeding with caution\n');
    }

    return { proceed: true };
  }
};
