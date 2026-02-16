#!/usr/bin/env node
/**
 * Pre-Compact Hook
 *
 * Runs before Claude compacts the conversation (when context gets full).
 * Preserves critical state that should survive compaction:
 * - Current session state
 * - Active blockers/errors
 * - In-progress work
 *
 * Created: 2026-01-03
 * Updated: 2026-01-22 (converted to stdin/stdout pattern)
 * Source: hooks-mastery research project
 */

const fs = require('fs').promises;
const path = require('path');

// Project root
const PROJECT_ROOT = path.join(__dirname, '..', '..');
const LOG_DIR = path.join(__dirname, '..', 'logs');

// Files to preserve context from
const PRESERVE_FILES = [
  { path: '.claude/context/compaction-essentials.md', maxChars: 2000, label: 'Core Essentials', extractKey: false },
  { path: '.claude/context/session-state.md', maxChars: 1500, label: 'Session State', extractKey: true }
];

// Blockers file (updated by other hooks/processes)
const BLOCKERS_FILE = path.join(LOG_DIR, 'recent-blockers.md');

/**
 * Read file safely
 */
async function readFileSafe(filePath, maxChars) {
  try {
    const content = await fs.readFile(filePath, 'utf8');
    if (content.length > maxChars) {
      return content.substring(0, maxChars) + '\n...[truncated]';
    }
    return content;
  } catch {
    return null;
  }
}

/**
 * Get recent blockers/errors if any
 */
async function getRecentBlockers() {
  try {
    const content = await fs.readFile(BLOCKERS_FILE, 'utf8');
    // Only return if not empty
    if (content.trim().length > 0) {
      return content.substring(0, 500);
    }
  } catch {
    // File doesn't exist - that's fine
  }
  return null;
}

/**
 * Extract key information from session state
 */
function extractKeyInfo(sessionContent) {
  const lines = sessionContent.split('\n');
  const keyInfo = [];

  // Look for status, current work, blockers sections
  let inSection = null;
  const importantSections = ['status', 'current work', 'blockers', 'next steps', 'in progress'];

  for (const line of lines) {
    const lowerLine = line.toLowerCase();

    // Check if entering an important section
    for (const section of importantSections) {
      if (lowerLine.includes(section) && (line.startsWith('#') || line.startsWith('**'))) {
        inSection = section;
        keyInfo.push(line);
        break;
      }
    }

    // If in an important section, capture content
    if (inSection && !line.startsWith('#') && line.trim().length > 0) {
      keyInfo.push(line);
    }

    // Exit section on new header
    if (line.startsWith('#') && !importantSections.some(s => lowerLine.includes(s))) {
      inSection = null;
    }
  }

  return keyInfo.join('\n');
}

/**
 * Main handler logic
 */
async function handleHook(context) {
  const preservedParts = [];

  try {
    // Load and extract key info from context files
    for (const file of PRESERVE_FILES) {
      const fullPath = path.join(PROJECT_ROOT, file.path);
      const content = await readFileSafe(fullPath, file.maxChars);

      if (content) {
        // Some files should be included as-is, others need key extraction
        const finalContent = file.extractKey ? extractKeyInfo(content) : content;
        if (finalContent.trim().length > 0) {
          preservedParts.push(`--- ${file.label} (preserved) ---`);
          preservedParts.push(finalContent);
        }
      }
    }

    // Check for recent blockers
    const blockers = await getRecentBlockers();
    if (blockers) {
      preservedParts.push('\n--- Recent Blockers (preserved) ---');
      preservedParts.push(blockers);
    }

    // Add compaction marker
    preservedParts.push('\n--- Context Compacted ---');
    preservedParts.push(`Time: ${new Date().toLocaleString()}`);
    preservedParts.push('Note: Some earlier context may have been summarized.');

  } catch (err) {
    console.error(`[pre-compact] Error preserving context: ${err.message}`);
    // Still add marker even if preservation failed
    preservedParts.push('--- Context Compacted (preservation partial) ---');
  }

  // Return preserved context
  if (preservedParts.length > 0) {
    return {
      hookSpecificOutput: {
        hookEventName: 'PreCompact',
        preservedContext: preservedParts.join('\n')
      }
    };
  }

  return {};
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

  let context = {};
  try {
    if (input.trim()) {
      context = JSON.parse(input);
    }
  } catch (err) {
    // If we can't parse input, continue with empty context
    console.error(`[pre-compact] Warning: Could not parse input JSON`);
  }

  const result = await handleHook(context);
  console.log(JSON.stringify(result));
}

main().catch(err => {
  console.error(`[pre-compact] Fatal error: ${err.message}`);
  console.log(JSON.stringify({}));
});
