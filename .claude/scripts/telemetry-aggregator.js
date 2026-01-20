#!/usr/bin/env node
/**
 * Telemetry Aggregator - PR-13.1
 *
 * Aggregates telemetry events into daily/weekly/monthly summaries.
 * Runs during AC-08 Maintenance or on-demand.
 *
 * Usage:
 *   node telemetry-aggregator.js --daily          # Aggregate yesterday
 *   node telemetry-aggregator.js --daily --date 2026-01-15
 *   node telemetry-aggregator.js --weekly         # Aggregate last week
 *   node telemetry-aggregator.js --cleanup        # Archive old logs
 */

const fs = require('fs');
const path = require('path');
const { queryEvents, getLogFiles } = require('./telemetry-query');

const CONFIG = {
  logDir: path.join(__dirname, '..', 'logs', 'telemetry'),
  aggregatesDir: path.join(__dirname, '..', 'metrics', 'aggregates'),
  archiveDir: path.join(__dirname, '..', 'logs', 'telemetry', 'archive'),
  compressAfterDays: 7,
  deleteAfterDays: 30
};

/**
 * Ensure directories exist
 */
function ensureDirs() {
  const dirs = [
    CONFIG.aggregatesDir,
    path.join(CONFIG.aggregatesDir, 'daily'),
    path.join(CONFIG.aggregatesDir, 'weekly'),
    path.join(CONFIG.aggregatesDir, 'monthly'),
    CONFIG.archiveDir
  ];

  for (const dir of dirs) {
    if (!fs.existsSync(dir)) {
      fs.mkdirSync(dir, { recursive: true });
    }
  }
}

/**
 * Get ISO week number
 */
function getWeekNumber(date) {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  d.setDate(d.getDate() + 4 - (d.getDay() || 7));
  const yearStart = new Date(d.getFullYear(), 0, 1);
  const weekNo = Math.ceil((((d - yearStart) / 86400000) + 1) / 7);
  return `${d.getFullYear()}-W${weekNo.toString().padStart(2, '0')}`;
}

/**
 * Aggregate events for a specific day
 */
function aggregateDay(date) {
  const events = queryEvents({
    startDate: date,
    endDate: date,
    limit: 100000
  });

  if (events.length === 0) {
    return null;
  }

  const aggregate = {
    date,
    generated: new Date().toISOString(),
    sessions: new Set(),
    components: {},
    event_types: {},
    totals: {
      events: events.length,
      errors: 0,
      metrics: 0
    }
  };

  for (const event of events) {
    // Track sessions
    aggregate.sessions.add(event.session_id);

    // Component stats
    const comp = event.component;
    if (!aggregate.components[comp]) {
      aggregate.components[comp] = {
        total: 0,
        starts: 0,
        ends: 0,
        errors: 0,
        by_type: {}
      };
    }
    aggregate.components[comp].total++;
    aggregate.components[comp].by_type[event.event_type] =
      (aggregate.components[comp].by_type[event.event_type] || 0) + 1;

    // Count lifecycle events
    if (event.event_type === 'component_start') {
      aggregate.components[comp].starts++;
    } else if (event.event_type === 'component_end') {
      aggregate.components[comp].ends++;
    } else if (event.event_type === 'component_error') {
      aggregate.components[comp].errors++;
      aggregate.totals.errors++;
    } else if (event.event_type === 'metric') {
      aggregate.totals.metrics++;
    }

    // Event type distribution
    aggregate.event_types[event.event_type] =
      (aggregate.event_types[event.event_type] || 0) + 1;
  }

  // Convert Set to count
  aggregate.sessions = aggregate.sessions.size;

  // Calculate success rates
  for (const comp in aggregate.components) {
    const c = aggregate.components[comp];
    c.success_rate = c.starts > 0
      ? parseFloat(((c.ends / c.starts) * 100).toFixed(1))
      : null;
  }

  return aggregate;
}

/**
 * Aggregate events for a week
 */
function aggregateWeek(weekId) {
  // Parse week ID (YYYY-Wnn)
  const match = weekId.match(/(\d{4})-W(\d{2})/);
  if (!match) throw new Error(`Invalid week ID: ${weekId}`);

  const year = parseInt(match[1]);
  const week = parseInt(match[2]);

  // Calculate start date (Monday) of the week
  const jan1 = new Date(year, 0, 1);
  const daysOffset = (week - 1) * 7;
  const startDate = new Date(jan1);
  startDate.setDate(jan1.getDate() + daysOffset - jan1.getDay() + 1);

  const endDate = new Date(startDate);
  endDate.setDate(startDate.getDate() + 6);

  const startStr = startDate.toISOString().split('T')[0];
  const endStr = endDate.toISOString().split('T')[0];

  // Load daily aggregates if they exist
  const dailyDir = path.join(CONFIG.aggregatesDir, 'daily');
  const dailyAggregates = [];

  let current = new Date(startDate);
  while (current <= endDate) {
    const dayStr = current.toISOString().split('T')[0];
    const dailyPath = path.join(dailyDir, `${dayStr}.json`);

    if (fs.existsSync(dailyPath)) {
      try {
        dailyAggregates.push(JSON.parse(fs.readFileSync(dailyPath, 'utf8')));
      } catch (e) {
        console.error(`Error reading ${dailyPath}: ${e.message}`);
      }
    }

    current.setDate(current.getDate() + 1);
  }

  if (dailyAggregates.length === 0) {
    return null;
  }

  // Combine daily aggregates
  const aggregate = {
    week: weekId,
    start_date: startStr,
    end_date: endStr,
    generated: new Date().toISOString(),
    days_with_data: dailyAggregates.length,
    sessions: 0,
    components: {},
    event_types: {},
    totals: {
      events: 0,
      errors: 0,
      metrics: 0
    }
  };

  for (const daily of dailyAggregates) {
    aggregate.sessions += daily.sessions;
    aggregate.totals.events += daily.totals.events;
    aggregate.totals.errors += daily.totals.errors;
    aggregate.totals.metrics += daily.totals.metrics;

    // Merge components
    for (const comp in daily.components) {
      if (!aggregate.components[comp]) {
        aggregate.components[comp] = {
          total: 0,
          starts: 0,
          ends: 0,
          errors: 0
        };
      }
      const c = aggregate.components[comp];
      const d = daily.components[comp];
      c.total += d.total;
      c.starts += d.starts;
      c.ends += d.ends;
      c.errors += d.errors;
    }

    // Merge event types
    for (const type in daily.event_types) {
      aggregate.event_types[type] =
        (aggregate.event_types[type] || 0) + daily.event_types[type];
    }
  }

  // Calculate success rates
  for (const comp in aggregate.components) {
    const c = aggregate.components[comp];
    c.success_rate = c.starts > 0
      ? parseFloat(((c.ends / c.starts) * 100).toFixed(1))
      : null;
  }

  return aggregate;
}

/**
 * Save aggregate to file
 */
function saveAggregate(aggregate, type, id) {
  ensureDirs();
  const dir = path.join(CONFIG.aggregatesDir, type);
  const filePath = path.join(dir, `${id}.json`);

  fs.writeFileSync(filePath, JSON.stringify(aggregate, null, 2));
  console.log(`Saved ${type} aggregate: ${filePath}`);
  return filePath;
}

/**
 * Archive old log files
 */
function archiveOldLogs() {
  ensureDirs();

  const cutoffDate = new Date(Date.now() - CONFIG.compressAfterDays * 24 * 60 * 60 * 1000)
    .toISOString().split('T')[0];

  const logFiles = getLogFiles(null, cutoffDate);

  for (const file of logFiles) {
    const basename = path.basename(file);
    const archivePath = path.join(CONFIG.archiveDir, basename);

    try {
      // Move to archive (in a real system, we'd compress here)
      fs.renameSync(file, archivePath);
      console.log(`Archived: ${basename}`);
    } catch (e) {
      console.error(`Failed to archive ${basename}: ${e.message}`);
    }
  }

  return logFiles.length;
}

/**
 * Delete very old logs
 */
function deleteOldLogs() {
  if (!fs.existsSync(CONFIG.archiveDir)) return 0;

  const cutoffDate = new Date(Date.now() - CONFIG.deleteAfterDays * 24 * 60 * 60 * 1000)
    .toISOString().split('T')[0];

  const files = fs.readdirSync(CONFIG.archiveDir)
    .filter(f => f.endsWith('.jsonl'))
    .map(f => {
      const match = f.match(/events-(\d{4}-\d{2}-\d{2})\.jsonl/);
      return match ? { file: f, date: match[1] } : null;
    })
    .filter(f => f && f.date < cutoffDate);

  for (const { file } of files) {
    try {
      fs.unlinkSync(path.join(CONFIG.archiveDir, file));
      console.log(`Deleted: ${file}`);
    } catch (e) {
      console.error(`Failed to delete ${file}: ${e.message}`);
    }
  }

  return files.length;
}

/**
 * Run aggregation for yesterday
 */
function runDailyAggregation(date) {
  const targetDate = date || new Date(Date.now() - 24 * 60 * 60 * 1000)
    .toISOString().split('T')[0];

  console.log(`Aggregating day: ${targetDate}`);

  const aggregate = aggregateDay(targetDate);

  if (aggregate) {
    saveAggregate(aggregate, 'daily', targetDate);
    return aggregate;
  } else {
    console.log(`No events found for ${targetDate}`);
    return null;
  }
}

/**
 * Run aggregation for last complete week
 */
function runWeeklyAggregation(weekId) {
  const targetWeek = weekId || getWeekNumber(
    new Date(Date.now() - 7 * 24 * 60 * 60 * 1000)
  );

  console.log(`Aggregating week: ${targetWeek}`);

  const aggregate = aggregateWeek(targetWeek);

  if (aggregate) {
    saveAggregate(aggregate, 'weekly', targetWeek);
    return aggregate;
  } else {
    console.log(`No data found for ${targetWeek}`);
    return null;
  }
}

/**
 * Main function
 */
function main() {
  const args = process.argv.slice(2);

  if (args.includes('--help') || args.includes('-h')) {
    console.log(`
Telemetry Aggregator

Usage:
  node telemetry-aggregator.js [options]

Options:
  --daily [--date YYYY-MM-DD]   Aggregate a specific day (default: yesterday)
  --weekly [--week YYYY-Wnn]    Aggregate a specific week (default: last week)
  --cleanup                     Archive and delete old logs
  --help                        Show this help

Examples:
  node telemetry-aggregator.js --daily
  node telemetry-aggregator.js --daily --date 2026-01-15
  node telemetry-aggregator.js --weekly
  node telemetry-aggregator.js --cleanup
`);
    process.exit(0);
  }

  if (args.includes('--cleanup')) {
    console.log('Running cleanup...');
    const archived = archiveOldLogs();
    const deleted = deleteOldLogs();
    console.log(`Archived: ${archived} files, Deleted: ${deleted} files`);
    return;
  }

  if (args.includes('--daily')) {
    const dateIdx = args.indexOf('--date');
    const date = dateIdx !== -1 ? args[dateIdx + 1] : null;
    runDailyAggregation(date);
    return;
  }

  if (args.includes('--weekly')) {
    const weekIdx = args.indexOf('--week');
    const week = weekIdx !== -1 ? args[weekIdx + 1] : null;
    runWeeklyAggregation(week);
    return;
  }

  // Default: run daily aggregation for yesterday
  runDailyAggregation();
}

// Export for module use
module.exports = {
  aggregateDay,
  aggregateWeek,
  saveAggregate,
  archiveOldLogs,
  deleteOldLogs,
  runDailyAggregation,
  runWeeklyAggregation
};

// Run if called directly
if (require.main === module) {
  main();
}
