#!/usr/bin/env node
/**
 * Memory Maintenance Hook
 *
 * Tracks entity access in Memory MCP for intelligent pruning decisions.
 * Updates a metadata file with access timestamps and counts.
 *
 * Data stored in: .claude/logs/memory-access.json
 *
 * Ported from AIfred baseline: 2026-01-23
 * Original: AIfred v1.0
 *
 * Event: PostToolUse
 * Triggers: After mcp__mcp-gateway__open_nodes calls
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const WORKSPACE_ROOT = '/Users/aircannon/Claude/Jarvis';
const METADATA_FILE = path.join(WORKSPACE_ROOT, '.claude/logs/memory-access.json');

// Memory MCP tool names to track (Jarvis uses mcp-gateway)
const MEMORY_TOOLS = [
  'mcp__mcp-gateway__open_nodes',
  'mcp__mcp-gateway__search_nodes',
  'mcp__mcp-gateway__read_graph',
  'mcp__memory__open_nodes',  // Fallback for standard naming
  'mcp__memory__search_nodes',
  'mcp__memory__read_graph'
];

/**
 * Load existing metadata or create empty structure
 */
async function loadMetadata() {
  try {
    const content = await fs.readFile(METADATA_FILE, 'utf8');
    return JSON.parse(content);
  } catch (err) {
    return {
      version: '1.0',
      created: new Date().toISOString(),
      lastUpdated: null,
      entities: {},
      toolUsage: {}
    };
  }
}

/**
 * Save metadata to file
 */
async function saveMetadata(metadata) {
  try {
    // Ensure directory exists
    const dir = path.dirname(METADATA_FILE);
    await fs.mkdir(dir, { recursive: true });

    metadata.lastUpdated = new Date().toISOString();
    await fs.writeFile(METADATA_FILE, JSON.stringify(metadata, null, 2));
  } catch (err) {
    // Silent failure - don't disrupt workflow
    // console.error(`[memory-maintenance] Error saving metadata: ${err.message}`);
  }
}

/**
 * Update access tracking for entities
 */
async function trackAccess(entityNames, toolName) {
  const metadata = await loadMetadata();
  const today = new Date().toISOString().split('T')[0];

  // Track individual entity access
  for (const name of entityNames) {
    if (!metadata.entities[name]) {
      metadata.entities[name] = {
        firstAccessed: today,
        lastAccessed: today,
        accessCount: 1,
        accessHistory: [today]
      };
    } else {
      metadata.entities[name].lastAccessed = today;
      metadata.entities[name].accessCount += 1;

      // Keep last 30 days of history
      if (!metadata.entities[name].accessHistory.includes(today)) {
        metadata.entities[name].accessHistory.push(today);
        if (metadata.entities[name].accessHistory.length > 30) {
          metadata.entities[name].accessHistory.shift();
        }
      }
    }
  }

  // Track tool usage patterns
  if (!metadata.toolUsage[toolName]) {
    metadata.toolUsage[toolName] = { count: 0, lastUsed: today };
  }
  metadata.toolUsage[toolName].count++;
  metadata.toolUsage[toolName].lastUsed = today;

  await saveMetadata(metadata);
  return entityNames.length;
}

/**
 * Extract entity names from tool input
 */
function extractEntityNames(toolInput, toolName) {
  // open_nodes uses 'names' array
  if (toolName.includes('open_nodes') && toolInput?.names) {
    return toolInput.names;
  }

  // search_nodes uses 'query' - extract entity name from search
  if (toolName.includes('search_nodes') && toolInput?.query) {
    // Record the search query as a pseudo-entity for tracking
    return [`search:${toolInput.query}`];
  }

  // read_graph doesn't have entity names
  if (toolName.includes('read_graph')) {
    return ['graph:full'];
  }

  return [];
}

/**
 * Main handler logic
 */
async function handleHook(context) {
  const { tool_name, tool_input } = context;

  // Only process Memory MCP tools
  if (!MEMORY_TOOLS.includes(tool_name)) {
    return { proceed: true };
  }

  // Extract entity names from the tool input
  const entityNames = extractEntityNames(tool_input, tool_name);

  if (entityNames.length === 0) {
    return { proceed: true };
  }

  try {
    await trackAccess(entityNames, tool_name);
  } catch (err) {
    // Silent failure - don't disrupt workflow
    // console.error(`[memory-maintenance] Error: ${err.message}`);
  }

  return { proceed: true };
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

  let context;
  try {
    context = JSON.parse(input);
  } catch (err) {
    // If we can't parse input, just allow to proceed
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  const result = await handleHook(context);
  console.log(JSON.stringify(result));
}

main().catch(err => {
  // Silent failure - don't disrupt workflow
  console.log(JSON.stringify({ proceed: true }));
});
