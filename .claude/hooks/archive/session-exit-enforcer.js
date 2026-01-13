/**
 * Session Exit Enforcer Hook
 *
 * Tracks session activity and reminds about exit procedures.
 *
 * Created: AIfred v1.0
 */

const fs = require('fs').promises;
const path = require('path');

const STATE_FILE = path.join(__dirname, '..', 'logs', '.session-activity');

// Tracked activities
const TRACKED_ACTIVITIES = {
  'Write': 'file_modified',
  'Edit': 'file_modified',
  'Bash': 'command_executed',
  'mcp__mcp-gateway__create_entities': 'memory_updated',
  'mcp__mcp-gateway__add_observations': 'memory_updated'
};

async function loadState() {
  try {
    const content = await fs.readFile(STATE_FILE, 'utf8');
    return JSON.parse(content);
  } catch {
    return {
      session_start: new Date().toISOString(),
      activities: [],
      files_modified: [],
      memory_updates: 0,
      commands_run: 0
    };
  }
}

async function saveState(state) {
  const dir = path.dirname(STATE_FILE);
  await fs.mkdir(dir, { recursive: true });
  await fs.writeFile(STATE_FILE, JSON.stringify(state, null, 2));
}

module.exports = {
  name: 'session-exit-enforcer',
  description: 'Track session activity for exit procedures',
  event: 'PostToolUse',

  async handler(context) {
    const { tool, parameters, result } = context;

    const activityType = TRACKED_ACTIVITIES[tool];
    if (!activityType) return { proceed: true };

    try {
      const state = await loadState();

      if (activityType === 'file_modified') {
        const filePath = parameters?.file_path || parameters?.path;
        if (filePath && !state.files_modified.includes(filePath)) {
          state.files_modified.push(filePath);
        }
      } else if (activityType === 'memory_updated') {
        state.memory_updates++;
      } else if (activityType === 'command_executed') {
        state.commands_run++;
      }

      state.activities.push({
        tool,
        type: activityType,
        timestamp: new Date().toISOString()
      });

      // Keep only last 100 activities
      if (state.activities.length > 100) {
        state.activities = state.activities.slice(-100);
      }

      await saveState(state);

    } catch (err) {
      // Silent failure - don't disrupt workflow
    }

    return { proceed: true };
  }
};
