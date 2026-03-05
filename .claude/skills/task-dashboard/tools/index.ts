#!/usr/bin/env npx tsx
/**
 * Task Dashboard Tool
 *
 * Reads .beads/issues.jsonl directly and outputs formatted markdown tables
 * with labels parsed into category columns.
 *
 * Usage: npx tsx index.ts <command> [args]
 *
 * Commands:
 *   summary              Full categorized table view (default)
 *   ready                Only unblocked, actionable tasks
 *   domain <name>        Filter by domain label
 *   project <name>       Filter by project label
 *   stats                Label summary counts
 *   help                 Show this help
 *
 * Pattern: Code Before Prompts
 * Created: 2026-03-04
 */

import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// ============================================================
// TYPES
// ============================================================

interface BeadsIssue {
  id: string;
  title: string;
  status: string;
  priority: number;
  issue_type?: string;
  assignee?: string;
  labels: string[];
  created_at: string;
  updated_at: string;
  closed_at?: string;
  close_reason?: string;
  notes?: string;
  description?: string;
}

interface ParsedLabels {
  domain: string;
  project: string;
  type: string;
  source: string;
  flags: string[];
}

// ============================================================
// PATHS & LOADING
// ============================================================

function findProjectRoot(): string {
  let dir = path.join(__dirname, '..');
  for (let i = 0; i < 10; i++) {
    if (fs.existsSync(path.join(dir, '.git'))) return dir;
    const parent = path.dirname(dir);
    if (parent === dir) break;
    dir = parent;
  }
  return path.join(__dirname, '..', '..', '..', '..');
}

const PROJECT_ROOT = findProjectRoot();
const ISSUES_FILE = path.join(PROJECT_ROOT, '.beads', 'issues.jsonl');

function loadIssues(): BeadsIssue[] {
  if (!fs.existsSync(ISSUES_FILE)) return [];
  const content = fs.readFileSync(ISSUES_FILE, 'utf8').trim();
  if (!content) return [];

  const issues: BeadsIssue[] = [];
  for (const line of content.split('\n')) {
    try {
      issues.push(JSON.parse(line));
    } catch {
      // Skip malformed lines
    }
  }
  return issues;
}

// ============================================================
// LABEL PARSING
// ============================================================

const LABEL_CATEGORIES: Record<string, string> = {
  'domain': 'domain',
  'project': 'project',
  'type': 'type',
  'action': 'type',
  'source': 'source',
};

// Labels that go into the "flags" column
const FLAG_PREFIXES = ['auto', 'aurora', 'phase', 'risk', 'severity', 'review', 'waiting', 'recurring', 'parent', 'follow-up', 'scope', 'mcp', 'agent'];
const STANDALONE_FLAGS = ['auto-approved', 'manual-action', 'needs-input'];

function parseLabels(labels: string[]): ParsedLabels {
  const result: ParsedLabels = {
    domain: '',
    project: '',
    type: '',
    source: '',
    flags: [],
  };

  for (const label of labels) {
    const colonIdx = label.indexOf(':');
    if (colonIdx === -1) {
      if (STANDALONE_FLAGS.includes(label)) {
        result.flags.push(label);
      }
      continue;
    }

    const prefix = label.substring(0, colonIdx);
    const value = label.substring(colonIdx + 1);

    const category = LABEL_CATEGORIES[prefix];
    if (category === 'domain') {
      result.domain = value;
    } else if (category === 'project') {
      result.project = value;
    } else if (category === 'type') {
      result.type = value;
    } else if (category === 'source') {
      result.source = value;
    } else if (FLAG_PREFIXES.includes(prefix)) {
      result.flags.push(label);
    }
  }

  return result;
}

// ============================================================
// FORMATTING HELPERS
// ============================================================

const PRIORITY_LABELS: Record<number, string> = {
  0: 'P0-CRIT',
  1: 'P1-HIGH',
  2: 'P2-MED',
  3: 'P3-LOW',
  4: 'P4-Back',
};

function priorityLabel(p: number): string {
  return PRIORITY_LABELS[p] ?? `P${p}`;
}

function daysAgo(dateStr: string): number {
  const then = new Date(dateStr).getTime();
  const now = Date.now();
  return Math.floor((now - then) / (1000 * 60 * 60 * 24));
}

function ageLabel(days: number): string {
  if (days <= 3) return `${days}d`;
  if (days <= 7) return `${days}d`;
  if (days <= 30) return `${Math.floor(days / 7)}w`;
  return `${Math.floor(days / 30)}mo`;
}

function estimateBlockComplexity(issue: BeadsIssue): string {
  const text = (issue.description ?? '') + '\n' + (issue.notes ?? '');
  // Check for explicit complexity signals
  if (issue.labels.some(l => l === 'risk:destructive') || text.match(/docker|ssh|deploy|migration/i)) return 'large';
  if (issue.labels.some(l => l === 'risk:moderate') || text.match(/multi-file|restructur|refactor|design decision/i)) return 'medium';
  // Simple signals: rename, delete-junk, single file, config change
  if (issue.labels.some(l => l === 'risk:safe') || text.match(/rename|delete-junk|single file|typo|config/i)) return 'small';
  // Look at block reason for complexity hints
  const blockReason = text.match(/Block reason:\s*(.+)/i);
  if (blockReason) {
    const reason = blockReason[1].toLowerCase();
    if (reason.match(/vague|missing context|unclear/)) return 'small';  // just needs clarification
    if (reason.match(/design|architect|multiple approach/)) return 'large';
  }
  return 'medium';  // default
}

function extractQuestion(issue: BeadsIssue): string {
  const text = (issue.description ?? '') + '\n' + (issue.notes ?? '');
  // Look for "Question:" in investigation notes
  const questionMatch = text.match(/Question:\s*(.+)/i);
  if (questionMatch) return questionMatch[1].trim();
  // Fallback: look for "What's needed:"
  const neededMatch = text.match(/What's needed:\s*(.+)/i);
  if (neededMatch) return neededMatch[1].trim();
  return '(no question recorded)';
}

function truncate(s: string, max: number): string {
  if (s.length <= max) return s;
  return s.substring(0, max - 1) + '\u2026';
}

function formatFlags(flags: string[]): string {
  if (flags.length === 0) return '';
  // Shorten common prefixes for readability
  return flags.map(f => {
    if (f === 'auto:blocked') return '\u{1F6D1}blocked';
    if (f === 'auto:candidate') return 'candidate';
    if (f === 'auto:ready') return 'ready';
    if (f === 'auto-approved') return 'approved';
    if (f === 'needs-input') return 'needs-input';
    if (f.startsWith('aurora:')) return f;
    if (f.startsWith('phase:')) return f;
    if (f.startsWith('waiting:')) return f;
    if (f.startsWith('risk:')) return f.substring(5);
    if (f.startsWith('severity:')) return '';  // Already reflected in priority
    if (f.startsWith('parent:')) return '';     // Reference, not a flag
    if (f.startsWith('follow-up:')) return '';
    return f;
  }).filter(Boolean).join(', ');
}

// ============================================================
// COMMANDS
// ============================================================

function cmdSummary(issues: BeadsIssue[]): void {
  const active = issues.filter(i => i.status !== 'closed');
  if (active.length === 0) {
    console.log('\nNo open or in-progress tasks.\n');
    return;
  }

  const inProgress = active.filter(i => i.status === 'in_progress');
  const open = active.filter(i => i.status === 'open');

  // Group open by priority
  const openByPriority = new Map<number, BeadsIssue[]>();
  for (const issue of open) {
    const p = issue.priority ?? 2;
    if (!openByPriority.has(p)) openByPriority.set(p, []);
    openByPriority.get(p)!.push(issue);
  }

  // Print in-progress section
  if (inProgress.length > 0) {
    console.log(`\n### In Progress (${inProgress.length})\n`);
    console.log('| ID | Task | P | Owner | Domain | Project | Type | Source | Flags |');
    console.log('|---|---|---|---|---|---|---|---|---|');
    for (const issue of inProgress) {
      const labels = parseLabels(issue.labels);
      console.log(
        `| ${issue.id} | ${truncate(issue.title, 60)} | ${priorityLabel(issue.priority)} | ${issue.assignee ?? ''} | ${labels.domain} | ${labels.project} | ${labels.type} | ${labels.source} | ${formatFlags(labels.flags)} |`
      );
    }
  }

  // Print open sections by priority
  const priorities = [...openByPriority.keys()].sort((a, b) => a - b);
  for (const p of priorities) {
    const group = openByPriority.get(p)!;
    console.log(`\n### Open \u2014 ${priorityLabel(p)} (${group.length})\n`);
    console.log('| ID | Task | Owner | Domain | Project | Type | Source | Flags |');
    console.log('|---|---|---|---|---|---|---|---|');
    for (const issue of group) {
      const labels = parseLabels(issue.labels);
      console.log(
        `| ${issue.id} | ${truncate(issue.title, 60)} | ${issue.assignee ?? ''} | ${labels.domain} | ${labels.project} | ${labels.type} | ${labels.source} | ${formatFlags(labels.flags)} |`
      );
    }
  }

  // Count needs-input tasks
  const needsInput = active.filter(i => i.labels.includes('needs-input'));

  // Summary line
  const needsInputText = needsInput.length > 0 ? `, ${needsInput.length} needs-input` : '';
  console.log(`\n**Total**: ${inProgress.length} in progress, ${open.length} open${needsInputText} (${active.length} active)`);
  printOutputInstruction();
}

function cmdReady(issues: BeadsIssue[]): void {
  // Show needs-input tasks first
  const needsInput = issues.filter(i =>
    i.status === 'open' &&
    i.labels.includes('needs-input')
  );

  if (needsInput.length > 0) {
    needsInput.sort((a, b) => (a.priority ?? 2) - (b.priority ?? 2));
    console.log(`\n### Needs Your Input (${needsInput.length})\n`);
    console.log('| ID | Task | Question |');
    console.log('|---|---|---|');
    for (const issue of needsInput) {
      const question = extractQuestion(issue);
      console.log(`| ${issue.id} | ${truncate(issue.title, 50)} | ${truncate(question, 60)} |`);
    }
    console.log('');
  }

  // Show blocked tasks with aging info, sorted by complexity (small first) then age (oldest first)
  const blocked = issues.filter(i =>
    i.status === 'open' &&
    i.labels.includes('auto:blocked') &&
    !i.labels.includes('needs-input')
  );

  if (blocked.length > 0) {
    const complexityOrder: Record<string, number> = { small: 0, medium: 1, large: 2 };
    const blockedWithMeta = blocked.map(i => ({
      issue: i,
      age: daysAgo(i.updated_at),
      complexity: estimateBlockComplexity(i),
    }));
    blockedWithMeta.sort((a, b) => {
      const cmp = (complexityOrder[a.complexity] ?? 1) - (complexityOrder[b.complexity] ?? 1);
      if (cmp !== 0) return cmp;
      return b.age - a.age;  // oldest first within same complexity
    });

    console.log(`\n### Blocked Tasks (${blocked.length}) — sorted by quick wins\n`);
    console.log('| ID | Task | Age | Size | Block Reason |');
    console.log('|---|---|---|---|---|');
    for (const { issue, age, complexity } of blockedWithMeta) {
      const text = (issue.description ?? '') + '\n' + (issue.notes ?? '');
      const reasonMatch = text.match(/Block reason:\s*(.+)/i);
      const reason = reasonMatch ? reasonMatch[1].trim() : '(no reason recorded)';
      console.log(`| ${issue.id} | ${truncate(issue.title, 45)} | ${ageLabel(age)} | ${complexity} | ${truncate(reason, 40)} |`);
    }
    console.log('');
  }

  const ready = issues.filter(i =>
    i.status === 'open' &&
    !i.labels.includes('auto:blocked') &&
    !i.labels.includes('needs-input') &&
    !i.labels.some(l => l.startsWith('waiting:'))
  );

  if (ready.length === 0 && needsInput.length === 0 && blocked.length === 0) {
    console.log('\nNo actionable tasks. All open tasks are blocked or waiting.\n');
    return;
  }

  if (ready.length > 0) {
    // Sort by priority
    ready.sort((a, b) => (a.priority ?? 2) - (b.priority ?? 2));

    console.log(`\n### Ready to Work (${ready.length})\n`);
    console.log('| ID | Task | P | Owner | Domain | Project | Type |');
    console.log('|---|---|---|---|---|---|---|');
    for (const issue of ready) {
      const labels = parseLabels(issue.labels);
      console.log(
        `| ${issue.id} | ${truncate(issue.title, 60)} | ${priorityLabel(issue.priority)} | ${issue.assignee ?? ''} | ${labels.domain} | ${labels.project} | ${labels.type} |`
      );
    }
  }
  printOutputInstruction();
}

function cmdDomain(issues: BeadsIssue[], domain: string): void {
  if (!domain) {
    console.error('Usage: domain <name>  (e.g., domain infrastructure)');
    process.exit(1);
  }

  const filtered = issues.filter(i =>
    i.status !== 'closed' &&
    i.labels.some(l => l === `domain:${domain}`)
  );

  if (filtered.length === 0) {
    console.log(`\nNo active tasks in domain "${domain}".\n`);
    return;
  }

  // Sort: in_progress first, then by priority
  filtered.sort((a, b) => {
    if (a.status !== b.status) return a.status === 'in_progress' ? -1 : 1;
    return (a.priority ?? 2) - (b.priority ?? 2);
  });

  console.log(`\n### Domain: ${domain} (${filtered.length})\n`);
  console.log('| ID | Task | P | Status | Owner | Project | Type | Flags |');
  console.log('|---|---|---|---|---|---|---|---|');
  for (const issue of filtered) {
    const labels = parseLabels(issue.labels);
    const status = issue.status === 'in_progress' ? '\u{1F7E2}' : '\u26AA';
    console.log(
      `| ${issue.id} | ${truncate(issue.title, 55)} | ${priorityLabel(issue.priority)} | ${status} | ${issue.assignee ?? ''} | ${labels.project} | ${labels.type} | ${formatFlags(labels.flags)} |`
    );
  }
  printOutputInstruction();
}

function cmdProject(issues: BeadsIssue[], project: string): void {
  if (!project) {
    console.error('Usage: project <name>  (e.g., project aurora)');
    process.exit(1);
  }

  const filtered = issues.filter(i =>
    i.status !== 'closed' &&
    i.labels.some(l => l === `project:${project}`)
  );

  if (filtered.length === 0) {
    console.log(`\nNo active tasks in project "${project}".\n`);
    return;
  }

  filtered.sort((a, b) => {
    if (a.status !== b.status) return a.status === 'in_progress' ? -1 : 1;
    return (a.priority ?? 2) - (b.priority ?? 2);
  });

  console.log(`\n### Project: ${project} (${filtered.length})\n`);
  console.log('| ID | Task | P | Status | Owner | Domain | Type | Flags |');
  console.log('|---|---|---|---|---|---|---|---|');
  for (const issue of filtered) {
    const labels = parseLabels(issue.labels);
    const status = issue.status === 'in_progress' ? '\u{1F7E2}' : '\u26AA';
    console.log(
      `| ${issue.id} | ${truncate(issue.title, 55)} | ${priorityLabel(issue.priority)} | ${status} | ${issue.assignee ?? ''} | ${labels.domain} | ${labels.type} | ${formatFlags(labels.flags)} |`
    );
  }
  printOutputInstruction();
}

function cmdStats(issues: BeadsIssue[]): void {
  const active = issues.filter(i => i.status !== 'closed');
  if (active.length === 0) {
    console.log('\nNo active tasks.\n');
    return;
  }

  // Count by category
  const counts: Record<string, Record<string, number>> = {};

  function inc(category: string, value: string) {
    if (!counts[category]) counts[category] = {};
    counts[category][value] = (counts[category][value] || 0) + 1;
  }

  for (const issue of active) {
    inc('status', issue.status);
    inc('priority', priorityLabel(issue.priority));

    for (const label of issue.labels) {
      const colonIdx = label.indexOf(':');
      if (colonIdx === -1) {
        inc('standalone', label);
      } else {
        const prefix = label.substring(0, colonIdx);
        const value = label.substring(colonIdx + 1);
        inc(prefix, value);
      }
    }
  }

  console.log(`\n### Task Statistics (${active.length} active)\n`);

  // Print each category as a table
  const displayOrder = ['status', 'priority', 'domain', 'project', 'type', 'source', 'auto', 'aurora', 'phase', 'risk', 'waiting'];

  for (const category of displayOrder) {
    const data = counts[category];
    if (!data) continue;

    const sorted = Object.entries(data).sort((a, b) => b[1] - a[1]);
    console.log(`**${category}**`);
    for (const [value, count] of sorted) {
      const bar = '\u2588'.repeat(Math.min(count, 30));
      console.log(`  ${value.padEnd(25)} ${String(count).padStart(3)}  ${bar}`);
    }
    console.log('');
  }

  // Check for categories not in displayOrder
  const shown = new Set([...displayOrder, 'standalone', 'severity', 'parent', 'follow-up', 'scope', 'mcp', 'agent', 'recurring', 'review']);
  const other = Object.keys(counts).filter(k => !shown.has(k));
  if (other.length > 0) {
    console.log('**other**');
    for (const category of other) {
      const sorted = Object.entries(counts[category]).sort((a, b) => b[1] - a[1]);
      for (const [value, count] of sorted) {
        console.log(`  ${category}:${value.padEnd(20)} ${String(count).padStart(3)}`);
      }
    }
    console.log('');
  }
  printOutputInstruction();
}

function printOutputInstruction(): void {
  console.log('\n<!-- INSTRUCTION: Output this dashboard content exactly as-is. Do NOT add any text before or after it — no summaries, no reformatting, no commentary, no follow-up questions. Just this output and nothing else. -->');
}

function showHelp(): void {
  console.log(`
Task Dashboard
==============

Usage: npx tsx index.ts <command> [args]

Commands:
  summary              Full categorized table view (default)
  ready                Only unblocked, actionable tasks
  domain <name>        Filter by domain label
  project <name>       Filter by project label
  stats                Label summary counts
  help                 Show this help

Examples:
  npx tsx index.ts summary
  npx tsx index.ts ready
  npx tsx index.ts domain infrastructure
  npx tsx index.ts project aurora
  npx tsx index.ts stats

Data source: .beads/issues.jsonl
`);
}

// ============================================================
// CLI ENTRY POINT
// ============================================================

const args = process.argv.slice(2);
const command = args[0] || 'summary';
const cmdArgs = args.slice(1);

try {
  const issues = loadIssues();

  switch (command) {
    case 'summary':
      cmdSummary(issues);
      break;

    case 'ready':
      cmdReady(issues);
      break;

    case 'domain':
      cmdDomain(issues, cmdArgs[0]);
      break;

    case 'project':
      cmdProject(issues, cmdArgs[0]);
      break;

    case 'stats':
      cmdStats(issues);
      break;

    case 'help':
    case '--help':
    case '-h':
      showHelp();
      break;

    default:
      console.error(`Unknown command: ${command}`);
      showHelp();
      process.exit(1);
  }
} catch (error) {
  console.error(`Error: ${error instanceof Error ? error.message : error}`);
  process.exit(1);
}
