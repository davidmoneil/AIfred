#!/usr/bin/env node
/**
 * Milestone Coordinator — Consolidated Hook (Merge 4)
 *
 * Merges 2 milestone-related hooks into one:
 *   1. enforceDocs()    — milestone-doc-enforcer.js (UserPromptSubmit)
 *   2. detectMilestone() — milestone-detector.js (PostToolUse:TodoWrite)
 *
 * Registered under two events in settings.json:
 *   UserPromptSubmit (matcher: "") → enforceDocs path
 *   PostToolUse (matcher: ^TodoWrite$) → detectMilestone path
 *
 * Internal dispatch by event type (hookEvent or tool field).
 *
 * Created: 2026-02-09 (B.3 Hook Consolidation, Merge 4)
 * Source hooks: milestone-doc-enforcer.js, milestone-detector.js
 */

const fs = require('fs');
const fsPromises = require('fs').promises;
const path = require('path');

const WORKSPACE_ROOT = '/Users/aircannon/Claude/Jarvis';
const STATE_DIR = path.join(WORKSPACE_ROOT, '.claude/state/components');
const LOG_DIR = path.join(WORKSPACE_ROOT, '.claude/logs');

// Telemetry integration
let telemetry;
try {
  telemetry = require('./telemetry-emitter');
} catch {
  telemetry = {
    emit: () => ({ success: false }),
    lifecycle: { start: () => {}, end: () => {}, error: () => {} }
  };
}

// ============================================================
// MILESTONE DOC ENFORCER — UserPromptSubmit path
// ============================================================

const MILESTONE_PHRASES = [
  /milestone\s*#?\d*\s*(is\s+)?(complete|done|finished)/i,
  /\bM\d+\s+(is\s+)?(complete|done|finished)/i,
  /finished\s+(the\s+)?milestone/i,
  /completed?\s+(the\s+)?milestone/i,
  /milestone\s+completion/i,
  /mark(ing)?\s+(this\s+)?milestone\s+(as\s+)?(complete|done)/i,

  // Roadmap II phase completion phrases
  /phase\s+[A-Z](\.\d+)?\s+(is\s+)?(complete|done|finished)/i,
  /completed?\s+(the\s+)?phase\s+[A-Z]/i,
  /finished\s+(the\s+)?phase/i,
  /\b[A-Z]\.\d+\s+(is\s+)?(complete|done|finished)/i,
  /hotfix\s+(is\s+)?(complete|done|applied|finished)/i,

  // PR completion phrases (pre-existing gap — MILESTONE_PHRASES never matched PR-\d+)
  /PR[-\s]?\d+\s+(is\s+)?(complete|done|finished)/i,
  /completed?\s+(the\s+)?PR[-\s]?\d+/i,
];

const END_SESSION_PATTERN = /\/end-session/i;

function parsePlanningTracker(projectDir) {
  const trackerPath = path.join(projectDir, '.claude', 'planning-tracker.yaml');
  if (!fs.existsSync(trackerPath)) return null;

  try {
    const content = fs.readFileSync(trackerPath, 'utf8');
    const docs = { planning: [], progress: [], always_review: [] };

    const extractSection = (sectionName) => {
      const re = new RegExp(`\\n${sectionName}:\\s*\\n((?:\\s+-[^\\n]+\\n?(?:\\s+[a-z_]+:[^\\n]+\\n?)*)*)`, '');
      const match = content.match(re);
      if (!match) return [];
      const entries = match[1].match(/-\s*path:\s*([^\n]+)[\s\S]*?(?=\s+-\s*path:|\n[a-z]|$)/g);
      if (!entries) return [];
      return entries.map(entry => {
        const p = entry.match(/path:\s*([^\n]+)/);
        const purpose = entry.match(/purpose:\s*([^\n]+)/);
        const enforcement = entry.match(/enforcement:\s*([^\n]+)/);
        return p ? { path: p[1].trim(), purpose: purpose?.[1]?.trim(), enforcement: enforcement?.[1]?.trim() } : null;
      }).filter(Boolean);
    };

    docs.always_review = extractSection('always_review');
    docs.planning = extractSection('planning');
    docs.progress = extractSection('progress');
    return docs;
  } catch { return null; }
}

function enforceDocs(context) {
  const { user_prompt } = context;
  if (!user_prompt) return { proceed: true };

  const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
  let milestoneDetected = false;

  for (const pattern of MILESTONE_PHRASES) {
    if (pattern.test(user_prompt)) { milestoneDetected = true; break; }
  }

  if (milestoneDetected) {
    const docs = parsePlanningTracker(projectDir);
    if (docs) {
      const mandatory = {
        planning: docs.planning.filter(d => d.enforcement === 'mandatory'),
        progress: docs.progress.filter(d => d.enforcement === 'mandatory'),
        always_review: docs.always_review.filter(d => d.enforcement === 'mandatory')
      };
      const fmt = (arr) => arr.length > 0 ? arr.map(d => `- ${d.path}${d.purpose ? ' — ' + d.purpose : ''}`).join('\n') : '- (none)';

      return {
        proceed: true,
        additionalContext: `
--- MILESTONE DOCUMENTATION GATE TRIGGERED ---
Before marking complete, verify updates to:
**Planning:** ${fmt(mandatory.planning)}
**Progress:** ${fmt(mandatory.progress)}
**Always Review:** ${fmt(mandatory.always_review)}
Run /review-milestone for formal AC-03 review.
Source: .claude/planning-tracker.yaml
---`
      };
    }
  }

  if (END_SESSION_PATTERN.test(user_prompt)) {
    const sessionStatePath = path.join(projectDir, '.claude', 'context', 'session-state.md');
    if (fs.existsSync(sessionStatePath)) {
      try {
        const content = fs.readFileSync(sessionStatePath, 'utf8');
        if (/milestone|M\d|aifred.*integration/i.test(content)) {
          return {
            proceed: true,
            additionalContext: `
--- END-SESSION: Milestone work detected. Verify planning-tracker.yaml docs are updated. ---`
          };
        }
      } catch { /* ignore */ }
    }
  }

  return { proceed: true };
}

// ============================================================
// MILESTONE DETECTOR — PostToolUse:TodoWrite path
// ============================================================

const STATE_FILE = path.join(STATE_DIR, 'AC-03-review.json');
const WIGGUM_STATE_FILE = path.join(STATE_DIR, 'AC-02-wiggum.json');

const MILESTONE_TASK_PATTERNS = [
  // Original patterns
  /PR[-\s]?\d+/i, /milestone/i, /release[-\s]?v?\d+/i,
  /complete.*PR/i, /finish.*feature/i, /implement.*system/i,

  // Roadmap II phase patterns (letters + sub-phases)
  /phase[-\s]?[A-Z]/i,              // Phase A, Phase F, Phase-C
  /phase[-\s]?\d+/i,                // Phase 5, phase-6 (original)
  /\b[A-Z]\.\d+\b/,                // B.7, F.3, A.1 (sub-phase dot notation)

  // Work type patterns
  /\bhotfix\b/i, /\bbugfix\b/i, /\bbacklog\b/i,
  /\bRoadmap\s*(I{1,2}|[12])\b/i,  // Roadmap I, Roadmap II

  // Broader completion patterns
  /complete.*phase/i, /finish.*phase/i,
  /complete.*implementation/i,
];

function isMilestoneTask(desc) {
  if (!desc) return false;
  return MILESTONE_TASK_PATTERNS.some(p => p.test(desc));
}

async function loadJsonFile(filePath, defaults) {
  try {
    const content = await fsPromises.readFile(filePath, 'utf8');
    return JSON.parse(content);
  } catch { return defaults; }
}

async function detectMilestone(context) {
  const { tool, tool_input } = context;
  if (tool !== 'TodoWrite') return { proceed: true };

  if (process.env.JARVIS_DISABLE_AC03 === 'true' || process.env.JARVIS_QUICK_MODE === 'true') {
    return { proceed: true };
  }

  try {
    const state = await loadJsonFile(STATE_FILE, {
      "$schema": "review-state-v1", component_id: "AC-03", status: "idle",
      last_updated: new Date().toISOString(), pending_review: null,
      review_history: [], metrics: { total_reviews: 0, approved: 0, conditional: 0, rejected: 0 }
    });
    const wiggumState = await loadJsonFile(WIGGUM_STATE_FILE, null);
    const timestamp = new Date().toISOString();
    const taskDescription = wiggumState?.current_loop?.task_description || '';
    const isMilestone = isMilestoneTask(taskDescription);

    const todos = tool_input?.todos || [];
    const completed = todos.filter(t => t.status === 'completed').length;
    const total = todos.length;
    const allComplete = total > 0 && completed === total;

    if (allComplete && isMilestone && !state.pending_review) {
      state.status = 'pending';
      state.pending_review = {
        task_id: wiggumState?.current_loop?.task_id || `task-${Date.now()}`,
        task_description: taskDescription,
        detected_at: timestamp,
        todos_completed: completed,
        milestone_indicators: MILESTONE_TASK_PATTERNS.filter(p => p.test(taskDescription)).map(p => p.source)
      };
      state.last_updated = timestamp;
      await fsPromises.mkdir(STATE_DIR, { recursive: true });
      await fsPromises.writeFile(STATE_FILE, JSON.stringify(state, null, 2));

      telemetry.emit('AC-03', 'milestone_detected', {
        task_id: state.pending_review.task_id,
        task_description: taskDescription.slice(0, 100),
        todos_completed: completed
      });

      await fsPromises.appendFile(
        path.join(LOG_DIR, 'milestone-detector.log'),
        `${timestamp} | MILESTONE_DETECTED | task="${taskDescription.slice(0, 100)}" | todos=${completed}\n`
      );

      return {
        proceed: true,
        hookSpecificOutput: {
          hookEventName: 'PostToolUse',
          milestoneDetected: true,
          message: `[AC-03] Milestone detected: "${taskDescription.slice(0, 80)}..." — Run /design-review when ready.`
        }
      };
    }

    if (allComplete && !isMilestone) {
      await fsPromises.appendFile(
        path.join(LOG_DIR, 'milestone-detector.log'),
        `${timestamp} | TASK_COMPLETE | non-milestone | task="${taskDescription.slice(0, 100)}"\n`
      );
    }
  } catch (err) {
    console.error(`[milestone-coordinator/detector] Error: ${err.message}`);
  }

  return { proceed: true };
}

// ============================================================
// MAIN HANDLER — Dispatch by event type
// ============================================================

async function handler(context) {
  // Dispatch: if tool field is present → PostToolUse path (detector)
  // If user_prompt field is present → UserPromptSubmit path (enforcer)
  if (context.tool === 'TodoWrite' || context.tool_name === 'TodoWrite') {
    return await detectMilestone(context);
  }
  if (context.user_prompt !== undefined) {
    return enforceDocs(context);
  }
  return { proceed: true };
}

// Export
module.exports = {
  name: 'milestone-coordinator',
  description: 'Consolidated milestone management (doc enforcement + detection)',
  events: ['UserPromptSubmit', 'PostToolUse'],
  handler
};

// STDIN/STDOUT handler
if (require.main === module) {
  const chunks = [];
  process.stdin.on('data', chunk => chunks.push(chunk));
  process.stdin.on('end', async () => {
    let context;
    try {
      context = JSON.parse(Buffer.concat(chunks).toString('utf8'));
    } catch {
      console.log(JSON.stringify({ proceed: true }));
      return;
    }
    try {
      const result = await handler(context);
      console.log(JSON.stringify(result));
    } catch {
      console.log(JSON.stringify({ proceed: true }));
    }
  });
}
