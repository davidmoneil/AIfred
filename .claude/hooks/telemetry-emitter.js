#!/usr/bin/env node
/**
 * Telemetry Emitter - PR-13.1 Core Component
 *
 * Provides event emission for all autonomic components (AC-01 through AC-09).
 * Events are written to JSONL files and optionally to Memory MCP.
 *
 * Usage:
 *   const telemetry = require('./telemetry-emitter');
 *   telemetry.emit('AC-01', 'component_start', { phase: 'greeting' });
 *
 * Or as a CLI:
 *   echo '{"component":"AC-01","event_type":"component_start","data":{}}' | node telemetry-emitter.js
 */

const fs = require('fs');
const path = require('path');

// Configuration
const CONFIG = {
  logDir: path.join(__dirname, '..', 'logs', 'telemetry'),
  metricsDir: path.join(__dirname, '..', 'metrics'),
  significantEvents: [
    'component_error',
    'evolution_implement',
    'evolution_rollback',
    'session_end',
    'drift_detected',
    'context_checkpoint'
  ],
  maxQueueSize: 1000,
  flushIntervalMs: 5000
};

// Event queue for batching
let eventQueue = [];
let flushTimer = null;

/**
 * Get current session ID from environment
 */
function getSessionId() {
  return process.env.CLAUDE_SESSION_ID || `local-${Date.now()}`;
}

/**
 * Get current date string for log file naming
 */
function getDateString() {
  return new Date().toISOString().split('T')[0];
}

/**
 * Ensure log directory exists
 */
function ensureLogDir() {
  if (!fs.existsSync(CONFIG.logDir)) {
    fs.mkdirSync(CONFIG.logDir, { recursive: true });
  }
}

/**
 * Get log file path for current day
 */
function getLogFilePath() {
  return path.join(CONFIG.logDir, `events-${getDateString()}.jsonl`);
}

/**
 * Validate event structure
 */
function validateEvent(event) {
  const required = ['component', 'event_type'];
  for (const field of required) {
    if (!event[field]) {
      throw new Error(`Missing required field: ${field}`);
    }
  }

  // Validate component ID format
  if (!/^AC-\d{2}$|^orchestrator$/.test(event.component)) {
    throw new Error(`Invalid component ID: ${event.component}. Expected AC-XX or orchestrator.`);
  }

  return true;
}

/**
 * Create a complete event object
 */
function createEvent(component, eventType, data = {}, metadata = {}) {
  const event = {
    timestamp: new Date().toISOString(),
    component,
    event_type: eventType,
    session_id: getSessionId(),
    data,
    metadata: {
      ...metadata,
      jarvis_version: getJarvisVersion()
    }
  };

  return event;
}

/**
 * Get Jarvis version from VERSION file
 */
function getJarvisVersion() {
  try {
    const versionPath = path.join(__dirname, '..', '..', 'VERSION');
    if (fs.existsSync(versionPath)) {
      return fs.readFileSync(versionPath, 'utf8').trim();
    }
  } catch (e) {
    // Ignore errors
  }
  return 'unknown';
}

/**
 * Write event to JSONL file
 */
function writeToLog(event) {
  ensureLogDir();
  const logPath = getLogFilePath();
  const line = JSON.stringify(event) + '\n';

  try {
    fs.appendFileSync(logPath, line);
    return true;
  } catch (error) {
    console.error(`[telemetry] Failed to write to log: ${error.message}`);
    return false;
  }
}

/**
 * Queue event for batch writing
 */
function queueEvent(event) {
  eventQueue.push(event);

  if (eventQueue.length >= CONFIG.maxQueueSize) {
    flushQueue();
  } else if (!flushTimer) {
    flushTimer = setTimeout(flushQueue, CONFIG.flushIntervalMs);
  }
}

/**
 * Flush event queue to disk
 */
function flushQueue() {
  if (flushTimer) {
    clearTimeout(flushTimer);
    flushTimer = null;
  }

  if (eventQueue.length === 0) return;

  ensureLogDir();
  const logPath = getLogFilePath();
  const lines = eventQueue.map(e => JSON.stringify(e)).join('\n') + '\n';

  try {
    fs.appendFileSync(logPath, lines);
    eventQueue = [];
  } catch (error) {
    console.error(`[telemetry] Failed to flush queue: ${error.message}`);
    // Keep events in queue for retry
  }
}

/**
 * Check if event is significant (should be stored in Memory MCP)
 */
function isSignificantEvent(eventType) {
  return CONFIG.significantEvents.includes(eventType);
}

/**
 * Main emit function - used by all AC components
 */
function emit(component, eventType, data = {}, metadata = {}) {
  try {
    const event = createEvent(component, eventType, data, metadata);
    validateEvent(event);

    // Write immediately (sync) for reliability
    const success = writeToLog(event);

    // Return event for chaining or inspection
    return { success, event };
  } catch (error) {
    console.error(`[telemetry] Emit failed: ${error.message}`);
    return { success: false, error: error.message };
  }
}

/**
 * Emit with async batching (for high-frequency events)
 */
function emitAsync(component, eventType, data = {}, metadata = {}) {
  try {
    const event = createEvent(component, eventType, data, metadata);
    validateEvent(event);
    queueEvent(event);
    return { success: true, event, queued: true };
  } catch (error) {
    console.error(`[telemetry] EmitAsync failed: ${error.message}`);
    return { success: false, error: error.message };
  }
}

/**
 * Component lifecycle helpers
 */
const lifecycle = {
  start: (component, data = {}) => emit(component, 'component_start', data),
  end: (component, data = {}) => emit(component, 'component_end', data),
  error: (component, error, data = {}) => emit(component, 'component_error', { error: error.message || error, ...data }),
  skip: (component, reason, data = {}) => emit(component, 'component_skip', { reason, ...data })
};

/**
 * Metric helpers
 */
const metrics = {
  gauge: (component, name, value, unit = '') =>
    emit(component, 'metric', { metric_type: 'gauge', name, value, unit }),
  counter: (component, name, increment = 1) =>
    emit(component, 'metric', { metric_type: 'counter', name, increment }),
  timing: (component, name, durationMs) =>
    emit(component, 'metric', { metric_type: 'timing', name, value: durationMs, unit: 'ms' })
};

/**
 * Get recent events for a component
 */
function getRecentEvents(component, limit = 100) {
  try {
    const logPath = getLogFilePath();
    if (!fs.existsSync(logPath)) return [];

    const content = fs.readFileSync(logPath, 'utf8');
    const lines = content.trim().split('\n').filter(Boolean);

    const events = lines
      .map(line => {
        try { return JSON.parse(line); } catch { return null; }
      })
      .filter(e => e && (!component || e.component === component))
      .slice(-limit);

    return events;
  } catch (error) {
    console.error(`[telemetry] Failed to read events: ${error.message}`);
    return [];
  }
}

/**
 * Get event counts by type for a component
 */
function getEventCounts(component) {
  const events = getRecentEvents(component);
  const counts = {};

  for (const event of events) {
    counts[event.event_type] = (counts[event.event_type] || 0) + 1;
  }

  return counts;
}

// Export for module use
module.exports = {
  emit,
  emitAsync,
  lifecycle,
  metrics,
  getRecentEvents,
  getEventCounts,
  flushQueue,
  getSessionId,
  CONFIG
};

// CLI mode - handle stdin input for hook integration
if (require.main === module) {
  let input = '';

  process.stdin.on('data', chunk => {
    input += chunk;
  });

  process.stdin.on('end', () => {
    try {
      const data = JSON.parse(input);

      // Handle direct event emission
      if (data.component && data.event_type) {
        const result = emit(data.component, data.event_type, data.data || {}, data.metadata || {});
        console.log(JSON.stringify(result));
      }
      // Handle hook-style input
      else if (data.hook_event) {
        const result = emit(
          data.component || 'orchestrator',
          data.hook_event,
          data,
          { hook: true }
        );
        console.log(JSON.stringify({ continue: true, result }));
      }
      else {
        console.log(JSON.stringify({ error: 'Invalid input format' }));
      }
    } catch (error) {
      console.log(JSON.stringify({ error: error.message }));
    }
  });
}
