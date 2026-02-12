#!/usr/bin/env node
/**
 * Index Sync Hook
 *
 * Keeps index files (_index.md) synchronized when:
 * - New files are created in indexed directories
 * - Files are renamed or moved
 *
 * Alerts when a new .md file is written to an indexed directory
 * but isn't referenced in the corresponding _index.md.
 *
 * Priority: MEDIUM (Documentation Quality)
 * Created: 2025-12-06
 * Converted to stdin/stdout executable hook
 * Generalized: Uses project root detection instead of hardcoded paths
 */

const fs = require('fs').promises;
const path = require('path');

// Project root - derived from hooks location (.claude/hooks/ -> project root)
const PROJECT_ROOT = path.resolve(__dirname, '..', '..');

// Directories with index files (relative to project root)
// These are the standard AIfred indexed directories
const INDEXED_DIRECTORIES = [
  { dir: '.claude/context', index: '.claude/context/_index.md' },
  { dir: '.claude/context/patterns', index: '.claude/context/patterns/_index.md' },
  { dir: '.claude/context/standards', index: '.claude/context/standards/_index.md' },
  { dir: '.claude/context/systems', index: '.claude/context/systems/_index.md' },
  { dir: '.claude/context/integrations', index: '.claude/context/integrations/_index.md' },
  { dir: '.claude/context/projects', index: '.claude/context/projects/_index.md' },
  { dir: '.claude/context/workflows', index: '.claude/context/workflows/_index.md' },
  { dir: '.claude/skills', index: '.claude/skills/_index.md' },
  { dir: 'knowledge/docs', index: 'knowledge/docs/_index.md' },
  { dir: 'knowledge/reference', index: 'knowledge/reference/_index.md' }
];

/**
 * Find which indexed directory contains the file
 */
function findIndexedDirectory(filePath) {
  // Normalize to relative path from project root
  let normalized = filePath;
  if (path.isAbsolute(filePath)) {
    normalized = path.relative(PROJECT_ROOT, filePath);
  }

  for (const { dir, index } of INDEXED_DIRECTORIES) {
    if (normalized.startsWith(dir + '/') || normalized.startsWith(dir)) {
      // Check that the index file actually exists before suggesting
      return { dir, index };
    }
  }

  return null;
}

/**
 * Check if file should be indexed
 */
function shouldBeIndexed(filePath) {
  const basename = path.basename(filePath);

  if (basename === '_index.md') return false;
  if (!filePath.endsWith('.md')) return false;
  if (basename.startsWith('.')) return false;

  return true;
}

/**
 * Check if file is mentioned in index
 */
async function isInIndex(indexPath, filename) {
  try {
    const fullIndexPath = path.join(PROJECT_ROOT, indexPath);
    const content = await fs.readFile(fullIndexPath, 'utf-8');
    return content.includes(filename);
  } catch {
    return false;
  }
}

/**
 * Main handler
 */
async function handleHook(context) {
  const { tool, parameters } = context;

  // Only check Write operations
  if (!['Write', 'mcp__filesystem__write_file'].includes(tool)) {
    return { proceed: true };
  }

  const filePath = parameters?.file_path || parameters?.path;
  if (!filePath) return { proceed: true };

  // Check if file is in an indexed directory
  const indexed = findIndexedDirectory(filePath);
  if (!indexed) return { proceed: true };

  // Check if file should be indexed
  if (!shouldBeIndexed(filePath)) return { proceed: true };

  // Check if file is already in index
  const filename = path.basename(filePath);
  const isTracked = await isInIndex(indexed.index, filename);

  if (!isTracked) {
    console.error(`[index-sync] New file ${filename} in ${indexed.dir} - not yet in ${indexed.index}`);

    return {
      proceed: true,
      outputToUser: `[index-sync] New file in indexed directory:\n` +
        `  File: ${filename}\n` +
        `  Directory: ${indexed.dir}\n` +
        `  Index: ${indexed.index}\n` +
        `  Action: Consider adding a reference to ${filename} in ${indexed.index}`
    };
  }

  return { proceed: true };
}

/**
 * Main function - reads from stdin, processes, outputs to stdout
 */
async function main() {
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const input = Buffer.concat(chunks).toString('utf8');

  let context;
  try {
    context = JSON.parse(input);
  } catch {
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  const result = await handleHook(context);
  console.log(JSON.stringify(result));
}

main().catch(err => {
  console.error(`[index-sync] Fatal error: ${err.message}`);
  console.log(JSON.stringify({ proceed: true }));
});
