# SOTA Scheduled Research Integration Specification

**ID**: PR-14.5
**Version**: 1.0.0
**Status**: implementing
**Created**: 2026-01-16
**Last Modified**: 2026-01-16

---

## Purpose

Define the scheduling, automation, and maintenance systems for ongoing SOTA catalog research. This ensures the catalog remains fresh, discoveries are made proactively, and stale entries are identified and addressed.

---

## Architecture

```
+---------------------------------------------------------------------+
|                    RESEARCH SCHEDULER ARCHITECTURE                    |
+---------------------------------------------------------------------+
|                                                                       |
|  TRIGGER SOURCES                                                      |
|  +---------------+  +---------------+  +---------------+              |
|  | Scheduled     |  | Event-Based   |  | Manual        |              |
|  | Triggers      |  | Triggers      |  | Triggers      |              |
|  +-------+-------+  +-------+-------+  +-------+-------+              |
|          |                  |                  |                       |
|          +------------------+------------------+                       |
|                             |                                          |
|                             v                                          |
|                   +-------------------+                                |
|                   | RESEARCH SCHEDULER|                                |
|                   |                   |                                |
|                   | - Task queue      |                                |
|                   | - Priority mgmt   |                                |
|                   | - Resource alloc  |                                |
|                   +--------+----------+                                |
|                            |                                           |
|         +------------------+------------------+                        |
|         |                  |                  |                        |
|         v                  v                  v                        |
|  +-------------+   +-------------+   +-------------+                  |
|  | Discovery   |   | Freshness   |   | Evaluation  |                  |
|  | Tasks       |   | Tasks       |   | Tasks       |                  |
|  +------+------+   +------+------+   +------+------+                  |
|         |                 |                 |                          |
|         +-----------------+-----------------+                          |
|                           |                                            |
|                           v                                            |
|                  +-----------------+                                   |
|                  | Catalog Updates |                                   |
|                  +-----------------+                                   |
|                                                                       |
+---------------------------------------------------------------------+
```

---

## Schedule Definitions

### Scheduled Research Tasks

| Task | Frequency | Scope | Trigger |
|------|-----------|-------|---------|
| MCP Discovery | Weekly | awesome-mcp-servers | Sunday 00:00 |
| Plugin Discovery | Monthly | claude-code-plugins | 1st of month |
| Framework Scan | Monthly | Agent frameworks | 15th of month |
| Freshness Audit | Weekly | All entries | Saturday 00:00 |
| Stale Detection | Daily | High-priority entries | Daily 06:00 |
| Full Catalog Scan | Quarterly | Entire catalog | Q start |

### Schedule Configuration

```yaml
# .claude/config/research-schedule.yaml
version: "1.0.0"
enabled: true

schedules:
  - id: "mcp-discovery"
    name: "MCP Server Discovery"
    task_type: "discovery"
    category: "mcp-servers"
    frequency: "weekly"
    day: "sunday"
    time: "00:00"
    sources:
      - "awesome-mcp-servers"
      - "modelcontextprotocol-servers"
    enabled: true

  - id: "plugin-discovery"
    name: "Plugin Discovery"
    task_type: "discovery"
    category: "plugins"
    frequency: "monthly"
    day: 1
    time: "00:00"
    sources:
      - "claude-code-plugins"
      - "anthropic-tools"
    enabled: true

  - id: "framework-scan"
    name: "Agent Framework Scan"
    task_type: "discovery"
    category: "agent-frameworks"
    frequency: "monthly"
    day: 15
    time: "00:00"
    sources:
      - "anthropic-agent-skills"
      - "langchain-agents"
    enabled: true

  - id: "freshness-audit"
    name: "Catalog Freshness Audit"
    task_type: "freshness"
    frequency: "weekly"
    day: "saturday"
    time: "00:00"
    threshold_days: 90
    enabled: true

  - id: "stale-detection"
    name: "Stale Entry Detection"
    task_type: "stale"
    frequency: "daily"
    time: "06:00"
    scope: "high_priority"
    enabled: true

  - id: "quarterly-scan"
    name: "Full Catalog Scan"
    task_type: "full_scan"
    frequency: "quarterly"
    month_offset: 0
    day: 1
    time: "00:00"
    enabled: true
```

---

## Task Types

### 1. Discovery Tasks

Scan external sources for new entries.

```yaml
discovery_task:
  id: "disc-2026-01-16-mcp"
  task_type: "discovery"
  category: "mcp-servers"
  sources:
    - name: "awesome-mcp-servers"
      url: "https://github.com/punkpeye/awesome-mcp-servers"
      last_scan: "2026-01-09"

  process:
    - step: "fetch_source"
      action: "Download README/listing"

    - step: "parse_entries"
      action: "Extract project entries"

    - step: "filter_known"
      action: "Remove already cataloged"

    - step: "preliminary_assess"
      action: "Quick relevance check"

    - step: "add_to_queue"
      action: "Add relevant to research queue"

  output:
    new_entries: []
    updated_entries: []
    queue_additions: []
```

### 2. Freshness Tasks

Check catalog entries for staleness.

```yaml
freshness_task:
  id: "fresh-2026-01-16"
  task_type: "freshness"

  criteria:
    last_updated_threshold: 90  # days
    last_evaluated_threshold: 180  # days
    source_check: true

  process:
    - step: "scan_entries"
      action: "Check all entry timestamps"

    - step: "check_sources"
      action: "Verify source URLs accessible"

    - step: "compare_versions"
      action: "Check for upstream updates"

    - step: "flag_stale"
      action: "Mark stale entries"

    - step: "generate_report"
      action: "Create freshness report"

  output:
    stale_entries:
      - entry_id: "example-mcp"
        reason: "Not updated in 120 days"
        last_updated: "2025-09-16"
    source_issues:
      - entry_id: "deprecated-tool"
        reason: "Repository archived"
    version_updates:
      - entry_id: "memory-server"
        current: "0.6.2"
        latest: "0.7.0"
```

### 3. Evaluation Tasks

Re-evaluate existing entries or evaluate new discoveries.

```yaml
evaluation_task:
  id: "eval-2026-01-16-queue"
  task_type: "evaluation"

  scope: "research_queue"
  max_evaluations: 5  # Per run

  process:
    - step: "load_queue"
      action: "Get pending research items"

    - step: "prioritize"
      action: "Sort by priority and age"

    - step: "evaluate"
      action: "Run full evaluation per item"

    - step: "update_catalog"
      action: "Create/update catalog entries"

    - step: "update_queue"
      action: "Remove completed from queue"

  output:
    evaluated:
      - queue_id: "research-001"
        entry_id: "new-mcp-server"
        result: "added"
        score: 75
    pending: 3
```

### 4. Full Scan Tasks

Comprehensive catalog review.

```yaml
full_scan_task:
  id: "scan-2026-Q1"
  task_type: "full_scan"

  scope: "all_entries"
  depth: "comprehensive"

  subtasks:
    - discovery: "all_categories"
    - freshness: "all_entries"
    - evaluation: "stale_entries"
    - comparison: "high_priority"
    - cleanup: "rejected_entries"

  output:
    summary:
      entries_scanned: 75
      new_discoveries: 12
      stale_flagged: 8
      re_evaluated: 8
      removed: 2
      total_after: 85
```

---

## Research Queue Management

### Queue Structure

```yaml
# research-queue/pending.yaml
version: "1.0.0"
last_updated: "2026-01-16"

queue:
  - id: "research-001"
    item: "sqlite-mcp"
    category: "mcp-servers"
    source: "awesome-mcp-servers"
    source_url: "https://github.com/example/sqlite-mcp"
    added_date: "2026-01-16"
    priority: "high"
    reason: "Requested by user for local database"
    status: "pending"
    assigned_task: null

  - id: "research-002"
    item: "crewai-patterns"
    category: "agent-frameworks"
    source: "scheduled_discovery"
    source_url: "https://github.com/joaomdmoura/crewai"
    added_date: "2026-01-15"
    priority: "medium"
    reason: "Multi-agent orchestration patterns"
    status: "pending"
    assigned_task: null

# Completed items move here
completed:
  - id: "research-000"
    item: "chroma-server"
    completion_date: "2026-01-14"
    outcome: "adopted"
    entry_id: "chroma-server"
    notes: "Evaluated and adopted as Tier 2 MCP"
```

### Queue Operations

```javascript
// Add to research queue
function addToResearchQueue(item) {
  const queue = loadResearchQueue();

  const entry = {
    id: generateQueueId(),
    item: item.name,
    category: item.category,
    source: item.source,
    source_url: item.url,
    added_date: new Date().toISOString().split('T')[0],
    priority: assessPriority(item),
    reason: item.reason || 'Scheduled discovery',
    status: 'pending',
    assigned_task: null
  };

  queue.queue.push(entry);
  saveResearchQueue(queue);

  return entry.id;
}

// Process queue item
async function processQueueItem(queueId) {
  const queue = loadResearchQueue();
  const item = queue.queue.find(q => q.id === queueId);

  if (!item) throw new Error('Queue item not found');

  item.status = 'processing';
  item.assigned_task = getCurrentTaskId();
  saveResearchQueue(queue);

  try {
    const result = await evaluateItem(item);
    completeQueueItem(queueId, result);
    return result;
  } catch (error) {
    item.status = 'failed';
    item.error = error.message;
    saveResearchQueue(queue);
    throw error;
  }
}

// Complete queue item
function completeQueueItem(queueId, result) {
  const queue = loadResearchQueue();
  const item = queue.queue.find(q => q.id === queueId);

  const completed = {
    id: item.id,
    item: item.item,
    completion_date: new Date().toISOString().split('T')[0],
    outcome: result.status,
    entry_id: result.entry_id,
    notes: result.notes
  };

  queue.completed.push(completed);
  queue.queue = queue.queue.filter(q => q.id !== queueId);
  saveResearchQueue(queue);
}
```

---

## Automatic Catalog Updates

### Update Types

| Update Type | Trigger | Action |
|-------------|---------|--------|
| New entry | Discovery finds new item | Create entry, status=evaluating |
| Version update | Freshness detects new version | Update version info |
| Status change | Evaluation completes | Update status field |
| Stale flag | Freshness threshold exceeded | Add stale warning |
| Source change | URL/repo changes | Update source info |
| Removal | Source unavailable | Archive entry |

### Update Process

```javascript
// Automatic catalog update
async function updateCatalogEntry(entryId, updates) {
  const entry = loadCatalogEntry(entryId);

  // Apply updates
  for (const [field, value] of Object.entries(updates)) {
    setNestedField(entry, field, value);
  }

  // Update metadata
  entry.last_updated = new Date().toISOString().split('T')[0];

  // Add to history
  entry.research_history.push({
    date: entry.last_updated,
    action: 'auto_update',
    notes: `Updated fields: ${Object.keys(updates).join(', ')}`
  });

  saveCatalogEntry(entry);
  updateCategoryIndex(entry.category);
  updateMasterIndex();

  return entry;
}
```

### Stale Entry Handling

```yaml
stale_handling:
  detection:
    threshold_days: 90
    check_fields:
      - last_updated
      - last_evaluated
      - source.last_commit

  actions:
    warning:
      condition: "days_stale >= 90"
      action: "Add stale warning to entry"

    re_evaluate:
      condition: "days_stale >= 180"
      action: "Add to evaluation queue"

    archive:
      condition: "source_unavailable AND days_stale >= 365"
      action: "Move to archived status"

  notification:
    - type: "log"
      message: "Entry {id} flagged as stale"
    - type: "report"
      include_in: "freshness_report"
```

---

## Integration with AC-07 R&D Cycles

### Scheduler to R&D Integration

```javascript
// R&D cycle can trigger scheduled research
async function onRDCycleStart() {
  // Check for pending scheduled tasks
  const pendingTasks = getOverdueScheduledTasks();

  for (const task of pendingTasks) {
    await executeScheduledTask(task);
  }

  // Process research queue
  const queueItems = getHighPriorityQueueItems(5);
  for (const item of queueItems) {
    await processQueueItem(item.id);
  }
}

// Scheduled task triggers R&D research
async function executeScheduledTask(task) {
  switch (task.task_type) {
    case 'discovery':
      return await runDiscoveryTask(task);
    case 'freshness':
      return await runFreshnessTask(task);
    case 'evaluation':
      return await runEvaluationTask(task);
    case 'full_scan':
      return await runFullScanTask(task);
  }
}
```

### R&D Report Integration

```yaml
rd_report_section:
  scheduled_research:
    tasks_executed:
      - task_id: "disc-2026-01-16-mcp"
        type: "discovery"
        result: "3 new items added to queue"
      - task_id: "fresh-2026-01-16"
        type: "freshness"
        result: "2 entries flagged as stale"

    queue_status:
      pending: 5
      processed_this_cycle: 3
      high_priority: 2

    catalog_updates:
      new_entries: 2
      updated_entries: 4
      archived: 0

    recommendations:
      - "Evaluate sqlite-mcp (high priority)"
      - "Update memory-server (new version available)"
```

---

## Command Interface

### `/research-schedule` Command

```
Usage: /research-schedule [subcommand] [options]

Subcommands:
  list          List scheduled tasks
  run <task-id> Manually trigger a task
  enable <id>   Enable a scheduled task
  disable <id>  Disable a scheduled task
  status        Show scheduler status
  queue         Show research queue

Options:
  --pending     Show only pending items
  --overdue     Show only overdue tasks
  --category=<> Filter by category

Examples:
  /research-schedule list
  /research-schedule run mcp-discovery
  /research-schedule queue --pending
  /research-schedule status
```

### Scheduler Status Display

```
+---------------------------------------------------------------------+
|                    RESEARCH SCHEDULER STATUS                          |
+---------------------------------------------------------------------+
|                                                                       |
|  Scheduled Tasks                                                      |
|  +---------------------+------------+---------------+---------------+ |
|  | Task                | Frequency  | Last Run      | Next Run      | |
|  +---------------------+------------+---------------+---------------+ |
|  | mcp-discovery       | Weekly     | 2026-01-12    | 2026-01-19    | |
|  | plugin-discovery    | Monthly    | 2026-01-01    | 2026-02-01    | |
|  | freshness-audit     | Weekly     | 2026-01-13    | 2026-01-20    | |
|  | stale-detection     | Daily      | 2026-01-16    | 2026-01-17    | |
|  +---------------------+------------+---------------+---------------+ |
|                                                                       |
|  Research Queue                                                       |
|  +---------------------+----------+----------+-----------------------+|
|  | Item                | Category | Priority | Added                 ||
|  +---------------------+----------+----------+-----------------------+|
|  | sqlite-mcp          | mcp      | high     | 2026-01-16            ||
|  | crewai-patterns     | framework| medium   | 2026-01-15            ||
|  | notion-mcp          | mcp      | low      | 2026-01-14            ||
|  +---------------------+----------+----------+-----------------------+|
|                                                                       |
|  Statistics                                                           |
|  +-------------------+-------------------+-------------------+        |
|  | Tasks This Week: 4 | Queue Pending: 5  | Entries Updated: 8 |       |
|  +-------------------+-------------------+-------------------+        |
|                                                                       |
+---------------------------------------------------------------------+
```

---

## Monitoring and Alerts

### Scheduler Metrics

| Metric | Description | Target |
|--------|-------------|--------|
| Task completion rate | % of scheduled tasks completed | > 95% |
| Discovery rate | New items found per scan | > 0 |
| Queue processing rate | Items processed per week | > 5 |
| Stale entry rate | % of catalog flagged stale | < 10% |
| Source availability | % of sources accessible | > 98% |

### Alert Conditions

```yaml
alerts:
  - id: "scheduler_failure"
    condition: "scheduled_task_failed"
    severity: "warning"
    notification: "Scheduled task {task_id} failed: {error}"

  - id: "high_stale_rate"
    condition: "stale_entry_rate > 20%"
    severity: "warning"
    notification: "Catalog staleness exceeds threshold"

  - id: "queue_backlog"
    condition: "queue_pending > 20"
    severity: "info"
    notification: "Research queue backlog growing"

  - id: "source_unavailable"
    condition: "discovery_source_failed"
    severity: "alert"
    notification: "Discovery source {source} unavailable"
```

---

## Implementation Files

| File | Purpose | Status |
|------|---------|--------|
| `.claude/config/research-schedule.yaml` | Schedule config | planned |
| `.claude/hooks/research-scheduler.js` | Scheduler logic | planned |
| `.claude/commands/research-schedule.md` | Schedule command | planned |
| `projects/project-aion/sota-catalog/research-queue/` | Queue storage | planned |

---

## Validation Checklist

- [ ] Schedule configuration defined
- [ ] All task types implemented
- [ ] Research queue management working
- [ ] Automatic updates functional
- [ ] Stale detection operational
- [ ] AC-07 integration complete
- [ ] Commands operational
- [ ] Alerts configured

---

*SOTA Scheduled Research Integration -- PR-14.5 Specification*
