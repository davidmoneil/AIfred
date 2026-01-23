/**
 * Milestone Documentation Enforcer Hook
 *
 * Detects milestone completion signals and enforces documentation requirements
 * by injecting reminders about required planning/progress document updates.
 *
 * Version: 1.0.0
 * Created: 2026-01-23
 * Event: UserPromptSubmit
 *
 * Trigger Phrases:
 * - "milestone complete", "milestone done", "M[N] complete"
 * - "finished milestone", "/end-session" (with milestone work)
 *
 * Reference: .claude/review-criteria/milestone-completion-gate.yaml
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
 * Read planning-tracker.yaml and extract required documents
 */
function getRequiredDocuments(projectDir) {
  const trackerPath = path.join(projectDir, '.claude', 'planning-tracker.yaml');

  if (!fs.existsSync(trackerPath)) {
    return null;
  }

  try {
    const content = fs.readFileSync(trackerPath, 'utf8');

    // Simple YAML parsing for our structure
    const docs = {
      planning: [],
      progress: [],
      always_review: []
    };

    // Extract paths with enforcement: mandatory
    const mandatoryPaths = content.match(/path:\s*(.+)\n.*enforcement:\s*mandatory/g);
    if (mandatoryPaths) {
      mandatoryPaths.forEach(match => {
        const pathMatch = match.match(/path:\s*(.+)/);
        if (pathMatch) {
          docs.planning.push(pathMatch[1].trim());
        }
      });
    }

    // Extract progress documents
    const progressSection = content.match(/progress:[\s\S]*?(?=\n[a-z_]+:|$)/);
    if (progressSection) {
      const progressPaths = progressSection[0].match(/path:\s*(.+)/g);
      if (progressPaths) {
        progressPaths.forEach(match => {
          const p = match.replace('path:', '').trim();
          docs.progress.push(p);
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
 * Generate reminder message for documentation gate
 */
function generateReminder(projectDir, isEndSession = false) {
  const docs = getRequiredDocuments(projectDir);
  if (!docs) {
    return null;
  }

  const reminder = {
    type: 'milestone_doc_gate',
    message: isEndSession
      ? 'END-SESSION MILESTONE DOCUMENTATION CHECK'
      : 'MILESTONE COMPLETION DOCUMENTATION GATE',
    requirements: [
      {
        category: 'Planning Documents',
        items: [
          'projects/project-aion/evolution/aifred-integration/roadmap.md — Update session checkboxes',
          'projects/project-aion/roadmap.md — Mark milestone deliverables complete'
        ],
        enforcement: 'MANDATORY'
      },
      {
        category: 'Progress Documents',
        items: [
          'projects/project-aion/evolution/aifred-integration/chronicle.md — Write milestone entry with:',
          '  - What Was Done',
          '  - How It Was Approached',
          '  - Why Decisions Were Made',
          '  - What Was Learned',
          '  - What to Watch'
        ],
        enforcement: 'MANDATORY'
      },
      {
        category: 'Session State',
        items: [
          '.claude/context/session-state.md — Update with milestone completion'
        ],
        enforcement: 'MANDATORY'
      }
    ],
    reference: '.claude/review-criteria/milestone-completion-gate.yaml',
    action: 'VERIFY all mandatory documents are updated before proceeding'
  };

  return reminder;
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
    const reminder = generateReminder(projectDir, false);
    if (reminder) {
      const additionalContext = `
--- MILESTONE DOCUMENTATION GATE TRIGGERED ---

Before marking this milestone complete, verify the following documents are updated:

**MANDATORY - Planning Documents:**
- projects/project-aion/evolution/aifred-integration/roadmap.md (session checkboxes)
- projects/project-aion/roadmap.md (milestone deliverables)

**MANDATORY - Progress Documents:**
- projects/project-aion/evolution/aifred-integration/chronicle.md
  Required sections: What Was Done, How, Why, What Was Learned, What to Watch

**MANDATORY - Session State:**
- .claude/context/session-state.md (milestone completion status)

**RECOMMENDED - Milestone Review:**
- Run /review-milestone for formal AC-03 review

Reference: .claude/review-criteria/milestone-completion-gate.yaml
Reference: .claude/planning-tracker.yaml

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
      const additionalContext = `
--- END-SESSION DOCUMENTATION REMINDER ---

Milestone work detected in session. Before ending, verify:

1. **Planning Tracker Review** (.claude/planning-tracker.yaml)
   - Check documents in 'update_required_on: [session-end, milestone-completion]'

2. **Chronicle Entry** (if milestone completed)
   - projects/project-aion/evolution/aifred-integration/chronicle.md

3. **Roadmap Checkboxes** (if milestone completed)
   - Mark completed session/milestone items

Enforcement: planning-tracker.yaml v2.0 — mandatory documents block completion
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
