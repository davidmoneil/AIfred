/**
 * Index Sync Hook
 *
 * Keeps index files (_index.md) synchronized when:
 * - New files are created in indexed directories
 * - Files are renamed or moved
 * - Files are deleted
 *
 * Priority: MEDIUM (Documentation Quality)
 * Created: 2025-12-06
 */

const fs = require('fs').promises;
const path = require('path');

// Directories with index files
const INDEXED_DIRECTORIES = [
  { dir: '.claude/context', index: '.claude/context/_index.md' },
  { dir: '.claude/context/systems', index: '.claude/context/systems/_index.md' },
  { dir: '.claude/context/integrations', index: '.claude/context/integrations/_index.md' },
  { dir: '.claude/context/projects', index: '.claude/context/projects/_index.md' },
  { dir: '.claude/context/workflows', index: '.claude/context/workflows/_index.md' },
  { dir: 'knowledge/docs', index: 'knowledge/docs/_index.md' },
  { dir: 'knowledge/reference', index: 'knowledge/reference/_index.md' }
];

// Track pending index updates
const pendingUpdates = new Set();

/**
 * Find which indexed directory contains the file
 */
function findIndexedDirectory(filePath) {
  const normalized = filePath.replace(new RegExp('^' + (process.env.AIFRED_HOME || process.cwd()).replace(/[.*+?${}()|[\]\]/g, '\\$&') + '/'), '');

  for (const { dir, index } of INDEXED_DIRECTORIES) {
    if (normalized.startsWith(dir + '/') || normalized.startsWith(dir)) {
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

  // Skip index files themselves
  if (basename === '_index.md') return false;

  // Only markdown files
  if (!filePath.endsWith('.md')) return false;

  // Skip hidden files
  if (basename.startsWith('.')) return false;

  return true;
}

/**
 * Check if file is mentioned in index
 */
async function isInIndex(indexPath, filename) {
  try {
    const content = await fs.readFile(indexPath, 'utf-8');
    return content.includes(filename);
  } catch {
    return false;
  }
}

/**
 * Get relative path from index to file
 */
function getRelativePath(indexDir, filePath) {
  const fileDir = path.dirname(filePath);
  const fileName = path.basename(filePath);

  if (fileDir === indexDir) {
    return fileName;
  }

  return path.relative(indexDir, filePath);
}

module.exports = {
  name: 'index-sync',
  description: 'Keep index files synchronized with directory contents',
  event: 'PostToolUse',

  async handler(context) {
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
      pendingUpdates.add(indexed.index);

      console.log('\n[index-sync] 📋 NEW FILE IN INDEXED DIRECTORY');
      console.log('─'.repeat(50));
      console.log(`File: ${filename}`);
      console.log(`Directory: ${indexed.dir}`);
      console.log(`Index: ${indexed.index}`);
      console.log('\nAction needed:');
      console.log(`  Add reference to ${filename} in ${indexed.index}`);
      console.log('─'.repeat(50) + '\n');
    }

    return { proceed: true };
  }
};

// Export pending updates for external use
module.exports.getPendingUpdates = () => [...pendingUpdates];
module.exports.clearPendingUpdates = () => pendingUpdates.clear();
