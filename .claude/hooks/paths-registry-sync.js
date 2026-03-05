/**
 * Paths Registry Sync Hook
 *
 * Validates paths-registry.yaml consistency when:
 * - New external paths are referenced
 * - Symlinks are created in external-sources/
 * - Docker compose files are modified
 *
 * Priority: MEDIUM (Documentation Quality)
 * Created: 2025-12-06
 */

const fs = require('fs').promises;
const path = require('path');

const PATHS_REGISTRY = path.join(process.cwd(), 'paths-registry.yaml');
const EXTERNAL_SOURCES = path.join(process.cwd(), 'external-sources');

// Patterns that suggest new external paths
const HOME = process.env.HOME || '/tmp';
const EXTERNAL_PATH_PATTERNS = [
  new RegExp(HOME.replace(/[.*+?${}()|[\]\\]/g, '\\$&') + '/Docker/'),
  new RegExp(HOME.replace(/[.*+?${}()|[\]\\]/g, '\\$&') + '/Code/'),
  /\/mnt\/[^/]+\//,
  /\/opt\//,
  /~\/Docker\//,
  /~\/Code\//
];

// File types that often reference external paths
const RELEVANT_EXTENSIONS = ['.yml', '.yaml', '.md', '.json', '.sh'];

/**
 * Check if path is external (not in project)
 */
function isExternalPath(filePath) {
  const aiprojectsRoot = process.cwd();
  const resolved = path.resolve(filePath);
  return !resolved.startsWith(aiprojectsRoot) ||
         resolved.includes('external-sources');
}

/**
 * Extract external paths from content
 */
function extractExternalPaths(content) {
  const paths = [];

  EXTERNAL_PATH_PATTERNS.forEach(pattern => {
    const matches = content.match(new RegExp(pattern.source + '[^\\s"\']+', 'g'));
    if (matches) {
      paths.push(...matches);
    }
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
  } catch {
    return false;
  }
}

/**
 * Check if symlink exists for path
 */
async function hasSymlink(targetPath) {
  try {
    const files = await fs.readdir(EXTERNAL_SOURCES, { recursive: true });
    for (const file of files) {
      const fullPath = path.join(EXTERNAL_SOURCES, file);
      try {
        const link = await fs.readlink(fullPath);
        if (link === targetPath || link.includes(targetPath)) {
          return true;
        }
      } catch {
        // Not a symlink
      }
    }
    return false;
  } catch {
    return false;
  }
}

module.exports = {
  name: 'paths-registry-sync',
  description: 'Validate paths-registry.yaml consistency',
  event: 'PostToolUse',

  async handler(context) {
    const { tool, parameters, result } = context;

    // Only check Write/Edit operations
    if (!['Write', 'Edit', 'mcp__filesystem__write_file'].includes(tool)) {
      return { proceed: true };
    }

    const filePath = parameters?.file_path || parameters?.path;
    const content = parameters?.content || parameters?.new_string;

    if (!filePath || !content) return { proceed: true };

    // Check if file type is relevant
    const ext = path.extname(filePath);
    if (!RELEVANT_EXTENSIONS.includes(ext)) {
      return { proceed: true };
    }

    // Skip paths-registry.yaml itself
    if (filePath.includes('paths-registry.yaml')) {
      return { proceed: true };
    }

    // Extract external paths from content
    const externalPaths = extractExternalPaths(content);

    if (externalPaths.length === 0) {
      return { proceed: true };
    }

    // Check each external path
    const unregisteredPaths = [];

    for (const extPath of externalPaths) {
      const inRegistry = await isPathInRegistry(extPath);
      if (!inRegistry) {
        unregisteredPaths.push(extPath);
      }
    }

    if (unregisteredPaths.length > 0) {
      console.log('\n[paths-registry-sync] ⚠️  UNREGISTERED EXTERNAL PATHS DETECTED');
      console.log('─'.repeat(50));
      console.log(`File: ${filePath}`);
      console.log('\nNew external paths found:');
      unregisteredPaths.forEach(p => console.log(`  • ${p}`));
      console.log('\nRecommendation:');
      console.log('  1. Add these paths to paths-registry.yaml');
      console.log('  2. Create symlinks in external-sources/');
      console.log('  3. Use /link-external command for automation');
      console.log('─'.repeat(50) + '\n');
    }

    return { proceed: true };
  }
};
