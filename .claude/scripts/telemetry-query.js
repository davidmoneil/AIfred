#!/usr/bin/env node
/**
 * Telemetry Query Interface - PR-13.1
 *
 * Query telemetry events by time range, component, event type.
 * Supports aggregation and trend analysis.
 *
 * Usage:
 *   node telemetry-query.js --component AC-01 --days 7
 *   node telemetry-query.js --type component_error --json
 *   node telemetry-query.js --aggregate daily --component AC-02
 */

const fs = require('fs');
const path = require('path');

const CONFIG = {
  logDir: path.join(__dirname, '..', 'logs', 'telemetry'),
  aggregatesDir: path.join(__dirname, '..', 'metrics', 'aggregates')
};

/**
 * Parse command line arguments
 */
function parseArgs() {
  const args = {
    component: null,
    type: null,
    days: 7,
    startDate: null,
    endDate: null,
    limit: 1000,
    json: false,
    aggregate: null,  // 'daily', 'hourly', 'component'
    help: false
  };

  const argv = process.argv.slice(2);
  for (let i = 0; i < argv.length; i++) {
    switch (argv[i]) {
      case '--component':
      case '-c':
        args.component = argv[++i];
        break;
      case '--type':
      case '-t':
        args.type = argv[++i];
        break;
      case '--days':
      case '-d':
        args.days = parseInt(argv[++i], 10);
        break;
      case '--start':
        args.startDate = argv[++i];
        break;
      case '--end':
        args.endDate = argv[++i];
        break;
      case '--limit':
      case '-l':
        args.limit = parseInt(argv[++i], 10);
        break;
      case '--json':
      case '-j':
        args.json = true;
        break;
      case '--aggregate':
      case '-a':
        args.aggregate = argv[++i];
        break;
      case '--help':
      case '-h':
        args.help = true;
        break;
    }
  }

  return args;
}

/**
 * Get list of log files in date range
 */
function getLogFiles(startDate, endDate) {
  if (!fs.existsSync(CONFIG.logDir)) return [];

  const files = fs.readdirSync(CONFIG.logDir)
    .filter(f => f.startsWith('events-') && f.endsWith('.jsonl'))
    .map(f => {
      const match = f.match(/events-(\d{4}-\d{2}-\d{2})\.jsonl/);
      return match ? { file: f, date: match[1] } : null;
    })
    .filter(Boolean)
    .filter(({ date }) => {
      if (startDate && date < startDate) return false;
      if (endDate && date > endDate) return false;
      return true;
    })
    .sort((a, b) => a.date.localeCompare(b.date));

  return files.map(({ file }) => path.join(CONFIG.logDir, file));
}

/**
 * Read events from a log file
 */
function readLogFile(filePath) {
  try {
    const content = fs.readFileSync(filePath, 'utf8');
    return content.trim().split('\n')
      .filter(Boolean)
      .map(line => {
        try { return JSON.parse(line); }
        catch { return null; }
      })
      .filter(Boolean);
  } catch (error) {
    console.error(`Error reading ${filePath}: ${error.message}`);
    return [];
  }
}

/**
 * Query events with filters
 */
function queryEvents(options) {
  const { component, type, startDate, endDate, limit } = options;

  const files = getLogFiles(startDate, endDate);
  let events = [];

  for (const file of files) {
    const fileEvents = readLogFile(file);
    events = events.concat(fileEvents);
  }

  // Apply filters
  if (component) {
    events = events.filter(e => e.component === component);
  }
  if (type) {
    events = events.filter(e => e.event_type === type);
  }

  // Apply date range filter on timestamps
  if (startDate) {
    events = events.filter(e => e.timestamp >= startDate);
  }
  if (endDate) {
    events = events.filter(e => e.timestamp <= endDate + 'T23:59:59.999Z');
  }

  // Sort by timestamp and limit
  events.sort((a, b) => a.timestamp.localeCompare(b.timestamp));
  if (limit && events.length > limit) {
    events = events.slice(-limit);
  }

  return events;
}

/**
 * Aggregate events by day
 */
function aggregateDaily(events) {
  const byDay = {};

  for (const event of events) {
    const day = event.timestamp.split('T')[0];
    if (!byDay[day]) {
      byDay[day] = {
        date: day,
        total: 0,
        by_component: {},
        by_type: {}
      };
    }

    byDay[day].total++;

    const comp = event.component;
    byDay[day].by_component[comp] = (byDay[day].by_component[comp] || 0) + 1;

    const type = event.event_type;
    byDay[day].by_type[type] = (byDay[day].by_type[type] || 0) + 1;
  }

  return Object.values(byDay).sort((a, b) => a.date.localeCompare(b.date));
}

/**
 * Aggregate events by component
 */
function aggregateByComponent(events) {
  const byComponent = {};

  for (const event of events) {
    const comp = event.component;
    if (!byComponent[comp]) {
      byComponent[comp] = {
        component: comp,
        total: 0,
        by_type: {},
        first_event: event.timestamp,
        last_event: event.timestamp
      };
    }

    byComponent[comp].total++;
    byComponent[comp].last_event = event.timestamp;

    const type = event.event_type;
    byComponent[comp].by_type[type] = (byComponent[comp].by_type[type] || 0) + 1;
  }

  return Object.values(byComponent).sort((a, b) => b.total - a.total);
}

/**
 * Get component health summary
 */
function getComponentHealth(component, days = 7) {
  const endDate = new Date().toISOString().split('T')[0];
  const startDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

  const events = queryEvents({ component, startDate, endDate, limit: 10000 });

  const starts = events.filter(e => e.event_type === 'component_start').length;
  const ends = events.filter(e => e.event_type === 'component_end').length;
  const errors = events.filter(e => e.event_type === 'component_error').length;

  const successRate = starts > 0 ? ((ends / starts) * 100).toFixed(1) : 'N/A';
  const errorRate = starts > 0 ? ((errors / starts) * 100).toFixed(1) : 'N/A';

  return {
    component,
    period: { startDate, endDate, days },
    executions: starts,
    completions: ends,
    errors,
    success_rate: successRate + '%',
    error_rate: errorRate + '%',
    total_events: events.length
  };
}

/**
 * Get trend data for a metric
 */
function getTrend(component, eventType, days = 30) {
  const endDate = new Date().toISOString().split('T')[0];
  const startDate = new Date(Date.now() - days * 24 * 60 * 60 * 1000).toISOString().split('T')[0];

  const events = queryEvents({
    component,
    type: eventType,
    startDate,
    endDate,
    limit: 100000
  });

  const byDay = {};
  for (const event of events) {
    const day = event.timestamp.split('T')[0];
    byDay[day] = (byDay[day] || 0) + 1;
  }

  // Fill in missing days with zeros
  const trend = [];
  let current = new Date(startDate);
  const end = new Date(endDate);

  while (current <= end) {
    const day = current.toISOString().split('T')[0];
    trend.push({
      date: day,
      count: byDay[day] || 0
    });
    current.setDate(current.getDate() + 1);
  }

  return {
    component,
    event_type: eventType,
    period: { startDate, endDate, days },
    data: trend,
    total: events.length,
    average: (events.length / days).toFixed(2)
  };
}

/**
 * Print help
 */
function printHelp() {
  console.log(`
Telemetry Query Interface

Usage:
  node telemetry-query.js [options]

Options:
  -c, --component <id>    Filter by component (AC-01, AC-02, etc.)
  -t, --type <type>       Filter by event type
  -d, --days <n>          Query last N days (default: 7)
  --start <date>          Start date (YYYY-MM-DD)
  --end <date>            End date (YYYY-MM-DD)
  -l, --limit <n>         Max events to return (default: 1000)
  -j, --json              Output as JSON
  -a, --aggregate <type>  Aggregate by: daily, component, health, trend
  -h, --help              Show this help

Examples:
  node telemetry-query.js --component AC-01 --days 7
  node telemetry-query.js --type component_error --json
  node telemetry-query.js --aggregate daily
  node telemetry-query.js --aggregate health --component AC-02
`);
}

/**
 * Main function
 */
function main() {
  const args = parseArgs();

  if (args.help) {
    printHelp();
    process.exit(0);
  }

  // Calculate date range
  if (!args.startDate) {
    args.startDate = new Date(Date.now() - args.days * 24 * 60 * 60 * 1000)
      .toISOString().split('T')[0];
  }
  if (!args.endDate) {
    args.endDate = new Date().toISOString().split('T')[0];
  }

  let result;

  switch (args.aggregate) {
    case 'daily':
      const events = queryEvents(args);
      result = aggregateDaily(events);
      break;

    case 'component':
      result = aggregateByComponent(queryEvents(args));
      break;

    case 'health':
      result = getComponentHealth(args.component, args.days);
      break;

    case 'trend':
      result = getTrend(args.component, args.type, args.days);
      break;

    default:
      result = queryEvents(args);
  }

  if (args.json) {
    console.log(JSON.stringify(result, null, 2));
  } else {
    // Pretty print
    if (Array.isArray(result)) {
      console.log(`Found ${result.length} items:\n`);
      for (const item of result.slice(-20)) {
        console.log(JSON.stringify(item));
      }
      if (result.length > 20) {
        console.log(`\n... and ${result.length - 20} more`);
      }
    } else {
      console.log(JSON.stringify(result, null, 2));
    }
  }
}

// Export for module use
module.exports = {
  queryEvents,
  aggregateDaily,
  aggregateByComponent,
  getComponentHealth,
  getTrend,
  getLogFiles
};

// Run if called directly
if (require.main === module) {
  main();
}
