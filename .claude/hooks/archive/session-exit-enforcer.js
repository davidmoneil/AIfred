/**
 * Session Exit Enforcer Hook
 *
 * Detects when user signals session end and reminds about exit procedure.
 * Tracks which exit checklist items have been completed.
 *
 * Priority: MEDIUM (Documentation Quality)
 * Created: 2025-12-06
 */

const fs = require('fs').promises;
const path = require('path');

// Patterns that indicate session end
const END_SESSION_PATTERNS = [
  /\bend\s+session\b/i,
  /\bsession\s+end\b/i,
  /\bexit\s+session\b/i,
  /\bwrap\s+up\b/i,
  /\bclosing\s+out\b/i,
  /\bsigning\s+off\b/i,
  /\bdone\s+for\s+(?:today|now)\b/i,
  /\bthat's\s+(?:it|all)\s+for\s+(?:today|now)\b/i
];

// Exit checklist items to track
const CHECKLIST_ITEMS = [
  { id: 'session_state', file: '.claude/context/session-state.md', description: 'Update session-state.md' },
  { id: 'priorities', file: '.claude/context/projects/current-priorities.md', description: 'Update current-priorities.md' },
  { id: 'git_status', command: 'git status', description: 'Check git status clean' },
  { id: 'git_commit', pattern: /git commit/, description: 'Commit any changes' },
  { id: 'git_push', pattern: /git push/, description: 'Push to GitHub' }
];

// Track what's been done this session
const sessionActions = new Set();

/**
 * Check if message indicates session end
 */
function isSessionEndMessage(message) {
  if (!message) return false;
  return END_SESSION_PATTERNS.some(pattern => pattern.test(message));
}

/**
 * Check if action matches checklist item
 */
function matchesChecklistItem(tool, parameters, item) {
  if (item.command && tool === 'Bash') {
    return parameters?.command?.includes(item.command);
  }
  if (item.pattern && tool === 'Bash') {
    return item.pattern.test(parameters?.command || '');
  }
  if (item.file && (tool === 'Write' || tool === 'Edit')) {
    const filePath = parameters?.file_path || '';
    return filePath.includes(item.file);
  }
  return false;
}

/**
 * Get checklist status
 */
function getChecklistStatus() {
  return CHECKLIST_ITEMS.map(item => ({
    ...item,
    done: sessionActions.has(item.id)
  }));
}

/**
 * Format checklist for display
 */
function formatChecklist(status) {
  const lines = ['Session Exit Checklist:', '─'.repeat(40)];

  status.forEach(item => {
    const check = item.done ? '✓' : '○';
    lines.push(`  ${check} ${item.description}`);
  });

  lines.push('─'.repeat(40));

  const completed = status.filter(i => i.done).length;
  const total = status.length;
  lines.push(`Progress: ${completed}/${total} items`);

  if (completed < total) {
    lines.push('\nRemaining items should be completed before ending session.');
    lines.push('See: .claude/context/workflows/session-exit-procedure.md');
  } else {
    lines.push('\n✓ All checklist items complete - safe to end session');
  }

  return lines.join('\n');
}

module.exports = {
  name: 'session-exit-enforcer',
  description: 'Track and enforce session exit checklist',
  event: 'PreToolUse',

  async handler(context) {
    const { tool, parameters } = context;

    // Track actions that match checklist items
    CHECKLIST_ITEMS.forEach(item => {
      if (matchesChecklistItem(tool, parameters, item)) {
        sessionActions.add(item.id);
      }
    });

    // For Notification events, check for session end signals
    // Note: This hook uses PreToolUse but we can check for patterns in user messages
    // when they trigger tool calls

    return { proceed: true };
  }
};

// Also export utility for external use
module.exports.getChecklistStatus = getChecklistStatus;
module.exports.formatChecklist = formatChecklist;
module.exports.isSessionEndMessage = isSessionEndMessage;
