/**
 * Memory Maintenance Hook
 * 
 * Tracks entity access in Memory MCP for intelligent pruning decisions.
 * Updates a metadata file with access timestamps and counts.
 * 
 * Event: PostToolUse
 * Triggers: After mcp__mcp-gateway__open_nodes calls
 */

const fs = require('fs');
const path = require('path');

// Metadata file location
const METADATA_FILE = path.join(__dirname, '..', 'agents', 'memory', 'entity-metadata.json');

/**
 * Load existing metadata or create empty structure
 */
function loadMetadata() {
  try {
    if (fs.existsSync(METADATA_FILE)) {
      const content = fs.readFileSync(METADATA_FILE, 'utf8');
      return JSON.parse(content);
    }
  } catch (err) {
    console.error(`[memory-maintenance] Error loading metadata: ${err.message}`);
  }
  return { entities: {}, lastUpdated: null };
}

/**
 * Save metadata to file
 */
function saveMetadata(metadata) {
  try {
    // Ensure directory exists
    const dir = path.dirname(METADATA_FILE);
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
    
    metadata.lastUpdated = new Date().toISOString();
    fs.writeFileSync(METADATA_FILE, JSON.stringify(metadata, null, 2));
  } catch (err) {
    console.error(`[memory-maintenance] Error saving metadata: ${err.message}`);
  }
}

/**
 * Update access tracking for entities
 */
function trackAccess(entityNames) {
  const metadata = loadMetadata();
  const now = new Date().toISOString();
  const today = now.split('T')[0];
  
  for (const name of entityNames) {
    if (!metadata.entities[name]) {
      metadata.entities[name] = {
        firstAccessed: today,
        lastAccessed: today,
        accessCount: 1
      };
    } else {
      metadata.entities[name].lastAccessed = today;
      metadata.entities[name].accessCount += 1;
    }
  }
  
  saveMetadata(metadata);
  return entityNames.length;
}

/**
 * Main hook handler
 */
module.exports = async (context) => {
  const { tool, tool_input, result } = context;
  
  // Only process Memory MCP open_nodes calls
  if (tool !== 'mcp__mcp-gateway__open_nodes') {
    return;
  }
  
  // Extract entity names from the tool input
  const entityNames = tool_input?.names || [];
  
  if (entityNames.length === 0) {
    return;
  }
  
  // Track access
  const tracked = trackAccess(entityNames);
  
  // Optional: Log for debugging (comment out in production)
  // console.log(`[memory-maintenance] Tracked access to ${tracked} entities`);
};
