/**
 * Milestone Documentation Enforcer Hook
 *
 * Detects milestone completion signals and enforces documentation requirements
 * by injecting reminders about required planning/progress document updates.
 *
 * IMPORTANT: All document paths are sourced from planning-tracker.yaml
 * This hook does NOT hardcode paths - it reads from the tracker dynamically.
 *
 * Version: 1.1.0
 * Created: 2026-01-23
 * Updated: 2026-01-23 (Dynamic path loading from planning-tracker.yaml)
 * Event: UserPromptSubmit
 *
 * Trigger Phrases:
 * - "milestone complete", "milestone done", "M[N] complete"
 * - "finished milestone", "/end-session" (with milestone work)
 *
 * Reference: .claude/review-criteria/milestone-completion-gate.yaml
 * Source of Truth: .claude/planning-tracker.yaml
 */

const fs = require('fs');
const path = require('path');

// Patterns that indicate milestone completion
const MILESTONE_PATTERNS = [
  /milestone\s*#?\d*\s*(is\s+)?(complete|done|finished)/i,
  /\bM\d+\s+(is\s+)?(complete|done|finished)/i,
  /finished\s+(the\s+)?milestone/i,
  /completed?\s+(the\s+)?milestone/i,
  /milestone\s+completion/i,
  /mark(ing)?\s+(this\s+)?milestone\s+(as\s+)?(complete|done)/i,
];

// Pattern for end-session command
const END_SESSION_PATTERN = /\/end-session/i;

/**
 * Parse planning-tracker.yaml and extract documents by section
 * Returns structured object with planning, progress, always_review docs
 */
function parsePlanningTracker(projectDir) {
  const trackerPath = path.join(projectDir, '.claude', 'planning-tracker.yaml');

  if (!fs.existsSync(trackerPath)) {
    return null;
  }

  try {
    const content = fs.readFileSync(trackerPath, 'utf8');

    const docs = {
      planning: [],
      progress: [],
      always_review: []
    };

    // Use regex to extract sections more reliably
    // Extract always_review section
    const alwaysMatch = content.match(/always_review:\s*\n((?:\s+-[^\n]+\n?(?:\s+[a-z_]+:[^\n]+\n?)*)*)/);
    if (alwaysMatch) {
      const entries = alwaysMatch[1].match(/-\s*path:\s*([^\n]+)[\s\S]*?(?=\s+-\s*path:|\n[a-z]|$)/g);
      if (entries) {
        entries.forEach(entry => {
          const pathMatch = entry.match(/path:\s*([^\n]+)/);
          const purposeMatch = entry.match(/purpose:\s*([^\n]+)/);
          const enforcementMatch = entry.match(/enforcement:\s*([^\n]+)/);
          if (pathMatch) {
            docs.always_review.push({
              path: pathMatch[1].trim(),
              purpose: purposeMatch ? purposeMatch[1].trim() : null,
              enforcement: enforcementMatch ? enforcementMatch[1].trim() : null
            });
          }
        });
      }
    }

    // Extract planning section
    const planningMatch = content.match(/\nplanning:\s*\n((?:\s+-[^\n]+\n?(?:\s+[a-z_]+:[^\n]+\n?)*)*)/);
    if (planningMatch) {
      const entries = planningMatch[1].match(/-\s*path:\s*([^\n]+)[\s\S]*?(?=\s+-\s*path:|\n[a-z]|$)/g);
      if (entries) {
        entries.forEach(entry => {
          const pathMatch = entry.match(/path:\s*([^\n]+)/);
          const enforcementMatch = entry.match(/enforcement:\s*([^\n]+)/);
          const scopeMatch = entry.match(/scope:\s*([^\n]+)/);
          if (pathMatch) {
            docs.planning.push({
              path: pathMatch[1].trim(),
              enforcement: enforcementMatch ? enforcementMatch[1].trim() : null,
              scope: scopeMatch ? scopeMatch[1].trim() : null
            });
          }
        });
      }
    }

    // Extract progress section
    const progressMatch = content.match(/\nprogress:\s*\n((?:\s+-[^\n]+\n?(?:\s+[a-z_]+:[^\n]+\n?)*)*)/);
    if (progressMatch) {
      const entries = progressMatch[1].match(/-\s*path:\s*([^\n]+)[\s\S]*?(?=\s+-\s*path:|\n[a-z]|$)/g);
      if (entries) {
        entries.forEach(entry => {
          const pathMatch = entry.match(/path:\s*([^\n]+)/);
          const enforcementMatch = entry.match(/enforcement:\s*([^\n]+)/);
          const scopeMatch = entry.match(/scope:\s*([^\n]+)/);
          if (pathMatch) {
            docs.progress.push({
              path: pathMatch[1].trim(),
              enforcement: enforcementMatch ? enforcementMatch[1].trim() : null,
              scope: scopeMatch ? scopeMatch[1].trim() : null
            });
          }
        });
      }
    }

    return docs;
  } catch (err) {
    console.error(`[milestone-doc-enforcer] Error reading tracker: ${err.message}`);
    return null;
  }
}

/**
 * Get mandatory documents filtered by enforcement level
 */
function getMandatoryDocuments(projectDir) {
  const docs = parsePlanningTracker(projectDir);
  if (!docs) return null;

  return {
    planning: docs.planning.filter(d => d.enforcement === 'mandatory'),
    progress: docs.progress.filter(d => d.enforcement === 'mandatory'),
    always_review: docs.always_review.filter(d => d.enforcement === 'mandatory')
  };
}

/**
 * Check if a file was modified today
 */
function wasModifiedToday(filePath) {
  if (!fs.existsSync(filePath)) {
    return false;
  }

  try {
    const stats = fs.statSync(filePath);
    const today = new Date();
    const modDate = new Date(stats.mtime);

    return today.toDateString() === modDate.toDateString();
  } catch (err) {
    return false;
  }
}

/**
 * Generate dynamic reminder message from planning-tracker.yaml
 */
function generateDynamicReminder(projectDir) {
  const docs = getMandatoryDocuments(projectDir);
  if (!docs) {
    return null;
  }

  // Build planning documents list from tracker
  const planningItems = docs.planning.map(d =>
    `- ${d.path}${d.purpose ? ' — ' + d.purpose : ''}`
  );

  // Build progress documents list from tracker
  const progressItems = docs.progress.map(d =>
    `- ${d.path}${d.purpose ? ' — ' + d.purpose : ''}`
  );

  // Build always_review list from tracker
  const alwaysItems = docs.always_review.map(d =>
    `- ${d.path}${d.purpose ? ' — ' + d.purpose : ''}`
  );

  return {
    planning: planningItems,
    progress: progressItems,
    always_review: alwaysItems
  };
}

/**
 * Handler function for milestone documentation enforcement
 */
async function handler(context) {
  const { user_prompt, session_state } = context;
  const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();

  // Skip if no user prompt
  if (!user_prompt) {
    return { proceed: true };
  }

  const prompt = user_prompt.toLowerCase();

  // Check for milestone completion patterns
  let milestoneDetected = false;
  for (const pattern of MILESTONE_PATTERNS) {
    if (pattern.test(user_prompt)) {
      milestoneDetected = true;
      break;
    }
  }

  // Check for end-session with potential milestone work
  const isEndSession = END_SESSION_PATTERN.test(user_prompt);

  // If milestone completion detected, inject reminder
  if (milestoneDetected) {
    const docs = generateDynamicReminder(projectDir);
    if (docs) {
      const planningList = docs.planning.length > 0
        ? docs.planning.join('\n')
        : '- (none configured in planning-tracker.yaml)';

      const progressList = docs.progress.length > 0
        ? docs.progress.join('\n')
        : '- (none configured in planning-tracker.yaml)';

      const additionalContext = `
--- MILESTONE DOCUMENTATION GATE TRIGGERED ---

Before marking this milestone complete, verify the following documents are updated.
**Source of truth: .claude/planning-tracker.yaml**

**MANDATORY - Planning Documents:**
${planningList}

**MANDATORY - Progress Documents:**
${progressList}
  Required sections: What Was Done, How, Why, What Was Learned, What to Watch

**MANDATORY - Session State:**
${docs.always_review.join('\n') || '- .claude/context/session-state.md'}

**RECOMMENDED - Milestone Review:**
- Run /review-milestone for formal AC-03 review

Reference: .claude/review-criteria/milestone-completion-gate.yaml
Source: .claude/planning-tracker.yaml (v2.0)

⚠️ Milestone completion is BLOCKED until documentation is verified.
---`;

      return {
        proceed: true,
        additionalContext
      };
    }
  }

  // If end-session, add softer reminder to check docs
  if (isEndSession) {
    // Check session-state.md for milestone work indicators
    const sessionStatePath = path.join(projectDir, '.claude', 'context', 'session-state.md');
    let hasMilestoneWork = false;

    if (fs.existsSync(sessionStatePath)) {
      try {
        const content = fs.readFileSync(sessionStatePath, 'utf8');
        hasMilestoneWork = /milestone|M\d|aifred.*integration/i.test(content);
      } catch (err) {
        // Ignore read errors
      }
    }

    if (hasMilestoneWork) {
      const docs = generateDynamicReminder(projectDir);
      const docList = docs ? [
        ...docs.planning,
        ...docs.progress
      ].join('\n  ') : '(check planning-tracker.yaml)';

      const additionalContext = `
--- END-SESSION DOCUMENTATION REMINDER ---

Milestone work detected in session. Before ending, verify:

1. **Planning Tracker Review** (.claude/planning-tracker.yaml)
   Documents with enforcement: mandatory:
  ${docList}

2. **Verify updates** (modified today with milestone content)

Source: .claude/planning-tracker.yaml (v2.0)
Enforcement: mandatory documents block completion
---`;

      return {
        proceed: true,
        additionalContext
      };
    }
  }

  // No milestone signals detected
  return { proceed: true };
}

// Export for require() usage
module.exports = {
  name: 'milestone-doc-enforcer',
  description: 'Enforce documentation requirements at milestone completion',
  event: 'UserPromptSubmit',
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
      console.error(`[milestone-doc-enforcer] Parse error: ${err.message}`);
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
