#!/usr/bin/env node
/**
 * Permission Gate Hook
 *
 * Detects policy-crossing operations in user prompts and injects
 * system reminders requesting explicit confirmation.
 *
 * This formalizes the "ad-hoc permission check" pattern tested in PR-3 validation,
 * where Claude uses AskUserQuestion for operations that cross policy boundaries
 * but aren't strictly blocked.
 *
 * Created: PR-4a (Jarvis v1.2.1)
 *
 * Use cases (soft gates - not blocked, but flagged):
 * - Operations mentioning the AIfred baseline (even reads are notable)
 * - Requests to push, force push, or merge to protected branches
 * - Requests to delete multiple files or directories
 * - Operations affecting system-wide configuration
 *
 * This hook adds a system reminder suggesting Claude confirm with the user
 * using AskUserQuestion before proceeding with policy-crossing operations.
 */

// Patterns that trigger a permission gate reminder
const GATE_PATTERNS = [
  {
    name: 'AIfred baseline operation',
    patterns: [
      /aifred.*baseline/i,
      /push.*aifred/i,
      /commit.*aifred/i,
      /edit.*aifred/i,
      /modify.*aifred/i,
      /change.*aifred/i,
      /\/Users\/aircannon\/Claude\/AIfred/i,
    ],
    reminder: `<permission-gate name="aifred-baseline">
POLICY-CROSSING OPERATION: AIfred Baseline

The user's request involves the AIfred baseline repository, which is READ-ONLY per workspace policy.

Before proceeding:
1. Verify this is intentional (use AskUserQuestion if unclear)
2. For reads: Proceed normally
3. For modifications: ONLY /sync-aifred-baseline can review upstream changes
4. For pushes: This requires explicit user confirmation with rationale

If the user explicitly approved this operation in this message, proceed.
Otherwise, use AskUserQuestion to confirm intent.
</permission-gate>`
  },
  {
    name: 'Force push request',
    patterns: [
      /force\s*push/i,
      /push.*--force/i,
      /push.*-f\b/i,
      /git\s+push.*force/i,
    ],
    reminder: `<permission-gate name="force-push">
POLICY-CROSSING OPERATION: Force Push

Force pushing can overwrite remote history and is generally discouraged.

Before proceeding:
1. Confirm the target branch with the user
2. Verify this won't affect collaborators
3. Document the reason in the commit/push message

Use AskUserQuestion to confirm:
- Which branch to force push
- Why force push is necessary
- Whether collaborators have been notified
</permission-gate>`
  },
  {
    name: 'Mass deletion request',
    patterns: [
      /delete\s+(all|every|multiple)/i,
      /remove\s+(all|every|multiple)/i,
      /clean\s*up.*files/i,
      /rm\s+-rf?\s+.*\*/i,
      /delete.*directory/i,
      /remove.*folder/i,
    ],
    reminder: `<permission-gate name="mass-deletion">
POLICY-CROSSING OPERATION: Mass Deletion

The user's request may involve deleting multiple files or directories.

Before proceeding:
1. List exactly what will be deleted
2. Confirm this is recoverable (git tracked) or intentionally permanent
3. Get explicit confirmation for the deletion list

Use AskUserQuestion to:
- Show the list of files/directories to be deleted
- Confirm the user wants to proceed
</permission-gate>`
  },
  {
    name: 'Protected branch operation',
    patterns: [
      /push.*main\b/i,
      /push.*master\b/i,
      /merge.*main\b/i,
      /merge.*master\b/i,
      /commit.*main\b/i,
      /reset.*main\b/i,
    ],
    reminder: `<permission-gate name="protected-branch">
POLICY-CROSSING OPERATION: Protected Branch

The user's request involves the main/master branch, which requires care.

Before proceeding:
1. For pushes: Ensure all tests pass and changes are reviewed
2. For merges: Verify the source branch is ready
3. For resets: This is destructive - confirm explicitly

In Jarvis, the main branch mirrors AIfred baseline (read-only).
Active development happens on Project_Aion branch.
</permission-gate>`
  },
  {
    name: 'Credential or secret handling',
    patterns: [
      /api\s*key/i,
      /secret\s*key/i,
      /password/i,
      /credential/i,
      /token/i,
      /\.env\s+file/i,
      /add.*secret/i,
    ],
    reminder: `<permission-gate name="credentials">
POLICY-CROSSING OPERATION: Credential/Secret Handling

The user's request may involve sensitive credentials.

Before proceeding:
1. NEVER commit credentials to git
2. Use environment variables or secret managers
3. If user wants to add credentials to a file, suggest .env (gitignored)

Remind the user:
- The secret-scanner hook will block commits with detected secrets
- Consider using environment variables instead
</permission-gate>`
  },
];

// Read hook input from stdin
let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const result = processPrompt(data);
    console.log(JSON.stringify(result));
  } catch (e) {
    // On error, allow the prompt through without modification
    console.log(JSON.stringify({ continue: true }));
  }
});

function processPrompt(data) {
  const message = data.prompt || '';

  if (!message.trim()) {
    return { continue: true };
  }

  // Check for matching gate patterns
  const triggeredGates = [];

  for (const gate of GATE_PATTERNS) {
    for (const pattern of gate.patterns) {
      if (pattern.test(message)) {
        triggeredGates.push(gate);
        break; // Only add each gate once
      }
    }
  }

  // No gates triggered
  if (triggeredGates.length === 0) {
    return { continue: true };
  }

  // Build combined reminder
  const reminders = triggeredGates.map(g => g.reminder).join('\n\n');

  return {
    continue: true,
    messages: [{
      role: 'system',
      content: reminders
    }]
  };
}
