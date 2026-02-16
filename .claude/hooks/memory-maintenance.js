/**
 * Memory Maintenance Hook
 *
 * Tracks Memory MCP entity access for intelligent pruning:
 * - Records when entities are accessed
 * - Tracks access frequency
 * - Enables data-driven archiving decisions
 *
 * Metadata stored in: .claude/agents/memory/entity-metadata.json
 *
 * Priority: LOW (Background Tracking)
 * Created: 2025-12-24
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const METADATA_FILE = path.join(__dirname, '..', 'agents', 'memory', 'entity-metadata.json');
const PRUNE_CANDIDATES_FILE = path.join(__dirname, '..', 'agents', 'memory', 'prune-candidates.json');
const PRUNE_THRESHOLD_DAYS = 90;

/**
 * Ensure metadata directory exists
 */
async function ensureMetadataDir() {
  const dir = path.dirname(METADATA_FILE);
  try {
    await fs.mkdir(dir, { recursive: true });
  } catch (err) {
    if (err.code !== 'EEXIST') throw err;
  }
}

/**
 * Load entity metadata
 */
async function loadMetadata() {
  try {
    const content = await fs.readFile(METADATA_FILE, 'utf8');
    return JSON.parse(content);
  } catch {
    return {
      version: '1.0',
      last_updated: new Date().toISOString(),
      entities: {}
    };
  }
}

/**
 * Save entity metadata
 */
async function saveMetadata(metadata) {
  await ensureMetadataDir();
  metadata.last_updated = new Date().toISOString();
  await fs.writeFile(METADATA_FILE, JSON.stringify(metadata, null, 2));
}

/**
 * Update entity access record
 */
function updateEntityAccess(metadata, entityName, accessType) {
  const now = new Date().toISOString();
  const today = now.split('T')[0];

  if (!metadata.entities[entityName]) {
    metadata.entities[entityName] = {
      first_seen: now,
      last_accessed: now,
      access_count: 0,
      access_history: [],
      access_types: {}
    };
  }

  const entity = metadata.entities[entityName];
  entity.last_accessed = now;
  entity.access_count++;

  // Track access type
  entity.access_types[accessType] = (entity.access_types[accessType] || 0) + 1;

  // Keep last 30 days of access history
  if (!entity.access_history.includes(today)) {
    entity.access_history.push(today);
    if (entity.access_history.length > 30) {
      entity.access_history.shift();
    }
  }

  return metadata;
}

/**
 * Identify entities that should be pruned
 */
function identifyPruneCandidates(metadata) {
  const now = new Date();
  const candidates = [];

  Object.entries(metadata.entities).forEach(([name, data]) => {
    const lastAccess = new Date(data.last_accessed);
    const daysSinceAccess = Math.floor((now - lastAccess) / (1000 * 60 * 60 * 24));

    if (daysSinceAccess >= PRUNE_THRESHOLD_DAYS) {
      candidates.push({
        name,
        last_accessed: data.last_accessed,
        days_inactive: daysSinceAccess,
        total_accesses: data.access_count,
        recommendation: daysSinceAccess > 180 ? 'archive' : 'review'
      });
    }
  });

  return candidates.sort((a, b) => b.days_inactive - a.days_inactive);
}

/**
 * Save prune candidates for review
 */
async function savePruneCandidates(candidates) {
  if (candidates.length === 0) return;

  await ensureMetadataDir();
  const report = {
    generated: new Date().toISOString(),
    threshold_days: PRUNE_THRESHOLD_DAYS,
    candidate_count: candidates.length,
    candidates
  };

  await fs.writeFile(PRUNE_CANDIDATES_FILE, JSON.stringify(report, null, 2));
}

/**
 * Extract entity names from MCP parameters
 */
function extractEntityNames(tool, parameters) {
  const entities = [];

  // open_nodes - reading entities
  if (tool.includes('open_nodes') && parameters?.names) {
    entities.push(...parameters.names);
  }

  // search_nodes - searching (counts as light access)
  if (tool.includes('search_nodes') && parameters?.query) {
    // Can't track specific entities from search, skip
  }

  // create_entities - new entities
  if (tool.includes('create_entities') && parameters?.entities) {
    try {
      const entitiesData = typeof parameters.entities === 'string'
        ? JSON.parse(parameters.entities)
        : parameters.entities;
      entitiesData.forEach(e => {
        if (e.name) entities.push(e.name);
      });
    } catch {
      // Parse error, skip
    }
  }

  // add_observations - updating entities
  if (tool.includes('add_observations') && parameters?.observations) {
    try {
      const obsData = typeof parameters.observations === 'string'
        ? JSON.parse(parameters.observations)
        : parameters.observations;
      obsData.forEach(o => {
        if (o.entityName) entities.push(o.entityName);
      });
    } catch {
      // Parse error, skip
    }
  }

  // create_relations - relationship access
  if (tool.includes('create_relations') && parameters?.relations) {
    try {
      const relData = typeof parameters.relations === 'string'
        ? JSON.parse(parameters.relations)
        : parameters.relations;
      relData.forEach(r => {
        if (r.from) entities.push(r.from);
        if (r.to) entities.push(r.to);
      });
    } catch {
      // Parse error, skip
    }
  }

  return [...new Set(entities)];
}

/**
 * Determine access type from tool name
 */
function getAccessType(tool) {
  if (tool.includes('open_nodes')) return 'read';
  if (tool.includes('search_nodes')) return 'search';
  if (tool.includes('create_entities')) return 'create';
  if (tool.includes('add_observations')) return 'update';
  if (tool.includes('create_relations')) return 'relate';
  if (tool.includes('delete')) return 'delete';
  return 'other';
}

module.exports = {
  name: 'memory-maintenance',
  description: 'Track Memory MCP entity access for pruning decisions',
  event: 'PostToolUse',

  async handler(context) {
    const { tool, parameters, result } = context;

    // Only track Memory MCP operations
    if (!tool.includes('mcp-gateway') && !tool.includes('memory')) {
      return { proceed: true };
    }

    // Skip if operation failed
    if (result?.error) {
      return { proceed: true };
    }

    try {
      const entityNames = extractEntityNames(tool, parameters);

      if (entityNames.length === 0) {
        return { proceed: true };
      }

      const accessType = getAccessType(tool);
      let metadata = await loadMetadata();

      // Update access records for each entity
      for (const entityName of entityNames) {
        metadata = updateEntityAccess(metadata, entityName, accessType);
      }

      await saveMetadata(metadata);

      // Periodically check for prune candidates (every 100 accesses)
      const totalAccesses = Object.values(metadata.entities)
        .reduce((sum, e) => sum + e.access_count, 0);

      if (totalAccesses % 100 === 0) {
        const candidates = identifyPruneCandidates(metadata);
        if (candidates.length > 0) {
          await savePruneCandidates(candidates);
          console.log(`\n[memory-maintenance] ${candidates.length} entities may need pruning`);
          console.log(`  Review: .claude/agents/memory/prune-candidates.json\n`);
        }
      }

    } catch (err) {
      // Silent failure - don't disrupt workflow
      // console.error(`[memory-maintenance] Error: ${err.message}`);
    }

    return { proceed: true };
  }
};
