/**
 * Doc Sync Trigger Hook
 *
 * Detects when significant code changes may require documentation updates.
 * Suggests running memory-bank-synchronizer agent.
 *
 * Features:
 * - Tracks Write/Edit operations on significant files
 * - After 5+ significant changes in 24 hours, suggests sync
 * - Cooldown: Only suggests once every 4 hours
 * - State persists to .claude/logs/.doc-sync-state.json
 *
 * Priority: LOW (Background Tracking)
 * Created: 2026-01-05
 * Source: Design Pattern Integration Plan - Phase 3
 * AIfred documentation sync trigger
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const STATE_FILE = path.join(__dirname, '..', 'logs', '.doc-sync-state.json');
const CHANGE_THRESHOLD = 5;                        // Suggest after 5 significant changes
const SUGGESTION_COOLDOWN_MS = 4 * 60 * 60 * 1000; // 4 hours
const CHANGE_WINDOW_MS = 24 * 60 * 60 * 1000;      // 24 hours

// Significant file patterns (code that should have docs)
const SIGNIFICANT_PATTERNS = [
  /^\.claude\/commands\//,       // Slash commands
  /^\.claude\/agents\//,         // Agent definitions
  /^\.claude\/hooks\/[^/]+\.js$/,// Hook implementations (not subdirs)
  /^\.claude\/skills\//,         // Skills
  /^src\//,                      // Source code
  /^lib\//,                      // Library code
  /^scripts\//,                  // Scripts (lowercase for AIfred)
  /docker-compose.*\.ya?ml$/,    // Docker compose files
  /^external-sources\//          // External source configs
];

// Exclude patterns (docs themselves, logs, state files)
const EXCLUDE_PATTERNS = [
  /\.claude\/logs\//,
  /\.claude\/context\//,
  /\.claude\/orchestration\//,
  /knowledge\//,
  /_index\.md$/,
  /README\.md$/,
  /\.json$/,                     // State/config files
  /\.jsonl$/                     // Log files
];

/**
 * Check if file path is significant (code that should have docs)
 */
function isSignificantFile(filePath) {
  // Normalize path (remove absolute prefix if present)
  const normalized = filePath
    .replace(/^\/home\/[^/]+\/Code\/AIfred\//, '')
    .replace(/^\.\//, '');

  // Check exclusions first
  for (const pattern of EXCLUDE_PATTERNS) {
    if (pattern.test(normalized)) {
      return false;
    }
  }

  // Check if matches significant patterns
  for (const pattern of SIGNIFICANT_PATTERNS) {
    if (pattern.test(normalized)) {
      return true;
    }
  }

  return false;
}

/**
 * Load state from file
 */
async function loadState() {
  try {
    const content = await fs.readFile(STATE_FILE, 'utf8');
    return JSON.parse(content);
  } catch {
    return {
      version: '1.0',
      changes: [],
      lastSuggested: null,
      totalSuggestions: 0
    };
  }
}

/**
 * Save state to file
 */
async function saveState(state) {
  const dir = path.dirname(STATE_FILE);
  await fs.mkdir(dir, { recursive: true });
  await fs.writeFile(STATE_FILE, JSON.stringify(state, null, 2));
}

/**
 * Clean old changes and keep only within time window
 */
function cleanOldChanges(changes, windowMs) {
  const cutoff = Date.now() - windowMs;
  return changes.filter(c => new Date(c.timestamp).getTime() > cutoff);
}

/**
 * Check if enough time has passed since last suggestion
 */
function canSuggest(lastSuggested) {
  if (!lastSuggested) return true;
  const elapsed = Date.now() - new Date(lastSuggested).getTime();
  return elapsed > SUGGESTION_COOLDOWN_MS;
}

/**
 * Format suggestion message
 */
function formatSuggestion(changeCount, changes) {
  // Get unique files, most recent first
  const uniqueFiles = [...new Set(changes.map(c => c.file))].reverse();

  const lines = [
    '',
    '[doc-sync-trigger] Documentation Sync Suggested',
    '─'.repeat(50),
    '',
    `${changeCount} significant code changes in the last 24 hours:`,
    ''
  ];

  // Show up to 5 most recent unique files
  const displayFiles = uniqueFiles.slice(0, 5);
  displayFiles.forEach(f => {
    // Shorten path for display
    const short = f.replace(/^\/home\/[^/]+\/Code\/AIfred\//, '');
    lines.push(`  • ${short}`);
  });

  if (uniqueFiles.length > 5) {
    lines.push(`  ... and ${uniqueFiles.length - 5} more`);
  }

  lines.push('');
  lines.push('Consider running:');
  lines.push('  /agent memory-bank-synchronizer');
  lines.push('');
  lines.push('Or check first (no changes):');
  lines.push('  /agent memory-bank-synchronizer --check-only');
  lines.push('');
  lines.push('─'.repeat(50));

  return lines.join('\n');
}

module.exports = {
  name: 'doc-sync-trigger',
  description: 'Suggest documentation sync after significant code changes',
  event: 'PostToolUse',

  async handler(context) {
    const { tool, parameters, result } = context;

    // Only track Write and Edit operations
    const trackableTools = [
      'Write',
      'Edit',
      'mcp__filesystem__write_file',
      'mcp__filesystem__edit_file'
    ];

    if (!trackableTools.includes(tool)) {
      return { proceed: true };
    }

    // Skip if operation failed
    if (result?.error) {
      return { proceed: true };
    }

    // Get file path from parameters
    const filePath = parameters?.file_path || parameters?.path;
    if (!filePath) {
      return { proceed: true };
    }

    // Check if file is significant
    if (!isSignificantFile(filePath)) {
      return { proceed: true };
    }

    try {
      // Load current state
      let state = await loadState();

      // Track this change
      state.changes.push({
        file: filePath,
        tool: tool,
        timestamp: new Date().toISOString()
      });

      // Clean old changes (keep last 24 hours)
      state.changes = cleanOldChanges(state.changes, CHANGE_WINDOW_MS);

      // Save updated state
      await saveState(state);

      // Check if we should suggest sync
      const changeCount = state.changes.length;
      const shouldSuggest = changeCount >= CHANGE_THRESHOLD && canSuggest(state.lastSuggested);

      if (shouldSuggest) {
        // Update suggestion timestamp
        state.lastSuggested = new Date().toISOString();
        state.totalSuggestions++;
        await saveState(state);

        // Output suggestion
        console.log(formatSuggestion(changeCount, state.changes));
      }

    } catch (err) {
      // Silent failure - don't disrupt workflow
      // Uncomment for debugging:
      // console.error(`[doc-sync-trigger] Error: ${err.message}`);
    }

    return { proceed: true };
  }
};

// Export utilities for other hooks/commands
module.exports.getState = loadState;
module.exports.resetState = async () => {
  await saveState({
    version: '1.0',
    changes: [],
    lastSuggested: null,
    totalSuggestions: 0
  });
};
module.exports.isSignificantFile = isSignificantFile;
