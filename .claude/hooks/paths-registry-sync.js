#!/usr/bin/env node
/**
 * Paths Registry Sync Hook
 *
 * Validates paths-registry.yaml consistency when:
 * - New external paths are referenced
 * - Symlinks are created in external-sources/
 * - Docker compose files are modified
 *
 * Profile: general
 * Event: PostToolUse (*)
 * Priority: RECOMMENDED
 * Created: 2025-12-06
 * AIfred paths registry sync
 */

const fs = require('fs').promises;
const path = require('path');

const PROJECT_DIR = process.env.CLAUDE_PROJECT_DIR || process.cwd();
const PATHS_REGISTRY = path.join(PROJECT_DIR, 'paths-registry.yaml');
const EXTERNAL_SOURCES = path.join(PROJECT_DIR, 'external-sources');

// Patterns that suggest external paths (generalized - no hardcoded user dirs)
const EXTERNAL_PATH_PATTERNS = [
  /\/mnt\/[^/]+\//,          // NAS/mount points
  /\/opt\//,                  // System packages
  /\/srv\//,                  // Service data
  /\/var\/lib\/docker\//,     // Docker data
  /~\/Docker\//,              // User Docker dirs
  /~\/Code\//,                // User code dirs
];

// File types that often reference external paths
const RELEVANT_EXTENSIONS = ['.yml', '.yaml', '.md', '.json', '.sh'];

/**
 * Extract external paths from content
 */
function extractExternalPaths(content) {
  const paths = [];
  EXTERNAL_PATH_PATTERNS.forEach(pattern => {
    const matches = content.match(new RegExp(pattern.source + '[^\\s"\']+', 'g'));
    if (matches) paths.push(...matches);
  });
  return [...new Set(paths)];
}

/**
 * Check if path exists in paths-registry.yaml
 */
async function isPathInRegistry(targetPath) {
  try {
    const content = await fs.readFile(PATHS_REGISTRY, 'utf-8');
    return content.includes(targetPath);
  } catch { return false; }
}

async function main() {
  let input = '';
  for await (const chunk of process.stdin) input += chunk;
  const context = JSON.parse(input);

  const { tool_name, tool_input } = context;

  // Only check Write/Edit operations
  if (!['Write', 'Edit', 'mcp__filesystem__write_file'].includes(tool_name)) {
    console.log(JSON.stringify({}));
    return;
  }

  const filePath = tool_input?.file_path || tool_input?.path;
  const content = tool_input?.content || tool_input?.new_string;

  if (!filePath || !content) {
    console.log(JSON.stringify({}));
    return;
  }

  // Check if file type is relevant
  const ext = path.extname(filePath);
  if (!RELEVANT_EXTENSIONS.includes(ext)) {
    console.log(JSON.stringify({}));
    return;
  }

  // Skip paths-registry.yaml itself
  if (filePath.includes('paths-registry.yaml')) {
    console.log(JSON.stringify({}));
    return;
  }

  // Extract external paths from content
  const externalPaths = extractExternalPaths(content);
  if (externalPaths.length === 0) {
    console.log(JSON.stringify({}));
    return;
  }

  // Check each external path
  const unregisteredPaths = [];
  for (const extPath of externalPaths) {
    const inRegistry = await isPathInRegistry(extPath);
    if (!inRegistry) unregisteredPaths.push(extPath);
  }

  if (unregisteredPaths.length > 0) {
    console.error('\n[paths-registry-sync] Unregistered external paths detected');
    console.error(`  File: ${filePath}`);
    console.error('  New external paths:');
    unregisteredPaths.forEach(p => console.error(`    ${p}`));
    console.error('  Recommendation: Add to paths-registry.yaml or use /link-external\n');
  }

  console.log(JSON.stringify({}));
}

main().catch(err => {
  console.error(`[paths-registry-sync] Fatal: ${err.message}`);
  console.log(JSON.stringify({}));
});
