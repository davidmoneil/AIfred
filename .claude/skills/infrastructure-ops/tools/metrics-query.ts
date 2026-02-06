#!/usr/bin/env npx tsx
/**
 * Task Metrics Query Tool
 *
 * Usage: npx tsx metrics-query.ts <command> [args]
 *
 * Commands:
 *   summary                    - Total executions, tokens, tools, success rate
 *   by-agent [name]            - Stats grouped by agent, or detail for one
 *   by-session [name]          - Stats for current or named session
 *   recent [count]             - Last N executions (default 10)
 *   top-tokens [limit]         - Agents ranked by total token usage
 *   cost [rate]                - Estimate API cost (default $3/$15 per MTok)
 *   help                       - Show this help
 *
 * Pattern: Code Before Prompts
 * Created: 2026-02-05
 */

import * as fs from 'fs';
import * as path from 'path';
import { fileURLToPath } from 'url';

// ESM compatibility
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Types
interface MetricsEntry {
  timestamp: string;
  session: string;
  agentId: string | null;
  agentName: string;
  agentType: string;
  success: boolean;
  durationMs: number | null;
  totalTokens: number | null;
  toolUses: number | null;
  resultLength: number;
}

interface AgentStats {
  name: string;
  type: string;
  count: number;
  successes: number;
  totalTokens: number;
  totalToolUses: number;
  totalDurationMs: number;
  avgTokens: number;
  avgToolUses: number;
  avgDurationMs: number;
}

// Paths
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
const METRICS_FILE = path.join(PROJECT_ROOT, '.claude', 'logs', 'task-metrics.jsonl');
const SESSION_FILE = path.join(PROJECT_ROOT, '.claude', 'logs', '.current-session');

// ============================================================
// DATA LOADING
// ============================================================

function loadEntries(): MetricsEntry[] {
  if (!fs.existsSync(METRICS_FILE)) return [];

  const content = fs.readFileSync(METRICS_FILE, 'utf8').trim();
  if (!content) return [];

  const entries: MetricsEntry[] = [];
  for (const line of content.split('\n')) {
    try {
      entries.push(JSON.parse(line));
    } catch {
      // Skip malformed lines
    }
  }
  return entries;
}

function getCurrentSession(): string {
  try {
    const content = fs.readFileSync(SESSION_FILE, 'utf8');
    try {
      const parsed = JSON.parse(content);
      return parsed.name || parsed.slug || 'default-session';
    } catch {
      return content.trim();
    }
  } catch {
    return 'default-session';
  }
}

// ============================================================
// AGGREGATION HELPERS
// ============================================================

function computeAgentStats(entries: MetricsEntry[]): Map<string, AgentStats> {
  const stats = new Map<string, AgentStats>();

  for (const e of entries) {
    let s = stats.get(e.agentName);
    if (!s) {
      s = {
        name: e.agentName,
        type: e.agentType,
        count: 0,
        successes: 0,
        totalTokens: 0,
        totalToolUses: 0,
        totalDurationMs: 0,
        avgTokens: 0,
        avgToolUses: 0,
        avgDurationMs: 0
      };
      stats.set(e.agentName, s);
    }

    s.count++;
    if (e.success) s.successes++;
    if (e.totalTokens != null) s.totalTokens += e.totalTokens;
    if (e.toolUses != null) s.totalToolUses += e.toolUses;
    if (e.durationMs != null) s.totalDurationMs += e.durationMs;
  }

  // Compute averages
  for (const s of stats.values()) {
    const tokenEntries = entries.filter(e => e.agentName === s.name && e.totalTokens != null).length;
    const toolEntries = entries.filter(e => e.agentName === s.name && e.toolUses != null).length;
    const durationEntries = entries.filter(e => e.agentName === s.name && e.durationMs != null).length;

    s.avgTokens = tokenEntries > 0 ? Math.round(s.totalTokens / tokenEntries) : 0;
    s.avgToolUses = toolEntries > 0 ? Math.round(s.totalToolUses / toolEntries) : 0;
    s.avgDurationMs = durationEntries > 0 ? Math.round(s.totalDurationMs / durationEntries) : 0;
  }

  return stats;
}

function formatDuration(ms: number | null): string {
  if (ms == null || ms === 0) return '-';
  if (ms < 1000) return `${ms}ms`;
  const seconds = Math.round(ms / 1000);
  if (seconds < 60) return `${seconds}s`;
  const minutes = Math.floor(seconds / 60);
  const remainSeconds = seconds % 60;
  return `${minutes}m ${remainSeconds}s`;
}

function formatTokens(tokens: number | null): string {
  if (tokens == null || tokens === 0) return '-';
  if (tokens < 1000) return `${tokens}`;
  return `${(tokens / 1000).toFixed(1)}k`;
}

function padRight(str: string, len: number): string {
  return str.length >= len ? str.substring(0, len) : str + ' '.repeat(len - str.length);
}

function padLeft(str: string, len: number): string {
  return str.length >= len ? str.substring(0, len) : ' '.repeat(len - str.length) + str;
}

// ============================================================
// COMMANDS
// ============================================================

function cmdSummary(entries: MetricsEntry[]): void {
  if (entries.length === 0) {
    console.log('\nNo task metrics recorded yet.');
    console.log('Run a Task agent to start collecting data.\n');
    return;
  }

  const total = entries.length;
  const successes = entries.filter(e => e.success).length;
  const successRate = ((successes / total) * 100).toFixed(1);

  const withTokens = entries.filter(e => e.totalTokens != null);
  const totalTokens = withTokens.reduce((sum, e) => sum + (e.totalTokens || 0), 0);

  const withTools = entries.filter(e => e.toolUses != null);
  const totalToolUses = withTools.reduce((sum, e) => sum + (e.toolUses || 0), 0);

  const withDuration = entries.filter(e => e.durationMs != null);
  const totalDuration = withDuration.reduce((sum, e) => sum + (e.durationMs || 0), 0);

  const uniqueAgents = new Set(entries.map(e => e.agentName)).size;
  const uniqueSessions = new Set(entries.map(e => e.session)).size;

  const first = entries[0].timestamp;
  const last = entries[entries.length - 1].timestamp;

  console.log('\n=== Task Metrics Summary ===\n');
  console.log(`Total executions:  ${total}`);
  console.log(`Success rate:      ${successRate}% (${successes}/${total})`);
  console.log(`Unique agents:     ${uniqueAgents}`);
  console.log(`Sessions:          ${uniqueSessions}`);
  console.log(`Time range:        ${first.substring(0, 10)} to ${last.substring(0, 10)}`);
  console.log('');
  console.log(`Total tokens:      ${formatTokens(totalTokens)}${withTokens.length < total ? ` (from ${withTokens.length}/${total} entries)` : ''}`);
  console.log(`Total tool uses:   ${totalToolUses}${withTools.length < total ? ` (from ${withTools.length}/${total} entries)` : ''}`);
  console.log(`Total duration:    ${formatDuration(totalDuration)}`);
  console.log(`Avg tokens/run:    ${formatTokens(withTokens.length > 0 ? Math.round(totalTokens / withTokens.length) : 0)}`);
  console.log(`Avg tools/run:     ${withTools.length > 0 ? Math.round(totalToolUses / withTools.length) : '-'}`);
  console.log(`Avg duration/run:  ${formatDuration(withDuration.length > 0 ? Math.round(totalDuration / withDuration.length) : null)}`);
  console.log('');
}

function cmdByAgent(entries: MetricsEntry[], agentFilter?: string): void {
  if (entries.length === 0) {
    console.log('\nNo task metrics recorded yet.\n');
    return;
  }

  const filtered = agentFilter
    ? entries.filter(e => e.agentName.toLowerCase().includes(agentFilter.toLowerCase()))
    : entries;

  if (filtered.length === 0) {
    console.log(`\nNo entries found for agent "${agentFilter}".\n`);
    return;
  }

  const stats = computeAgentStats(filtered);

  // Single agent detail view
  if (agentFilter && stats.size === 1) {
    const s = [...stats.values()][0];
    console.log(`\n=== Agent Detail: ${s.name} ===\n`);
    console.log(`Type:           ${s.type}`);
    console.log(`Executions:     ${s.count}`);
    console.log(`Success rate:   ${((s.successes / s.count) * 100).toFixed(1)}%`);
    console.log(`Total tokens:   ${formatTokens(s.totalTokens)}`);
    console.log(`Avg tokens:     ${formatTokens(s.avgTokens)}`);
    console.log(`Total tools:    ${s.totalToolUses}`);
    console.log(`Avg tools:      ${s.avgToolUses}`);
    console.log(`Total duration: ${formatDuration(s.totalDurationMs)}`);
    console.log(`Avg duration:   ${formatDuration(s.avgDurationMs)}`);

    // Show recent runs
    const recent = filtered.slice(-5).reverse();
    console.log(`\nRecent runs:`);
    for (const e of recent) {
      const ts = e.timestamp.substring(0, 19).replace('T', ' ');
      console.log(`  ${ts}  tokens=${formatTokens(e.totalTokens)}  tools=${e.toolUses ?? '-'}  ${formatDuration(e.durationMs)}  ${e.success ? 'OK' : 'FAIL'}`);
    }
    console.log('');
    return;
  }

  // Table view
  const sorted = [...stats.values()].sort((a, b) => b.count - a.count);

  console.log(`\n=== Agent Statistics${agentFilter ? ` (filter: ${agentFilter})` : ''} ===\n`);
  console.log(`${padRight('Agent', 25)} ${padLeft('Runs', 5)} ${padLeft('Rate', 6)} ${padLeft('Tokens', 8)} ${padLeft('Tools', 6)} ${padLeft('Avg Dur', 8)} ${padRight('Type', 18)}`);
  console.log(`${'-'.repeat(25)} ${'-'.repeat(5)} ${'-'.repeat(6)} ${'-'.repeat(8)} ${'-'.repeat(6)} ${'-'.repeat(8)} ${'-'.repeat(18)}`);

  for (const s of sorted) {
    const rate = `${((s.successes / s.count) * 100).toFixed(0)}%`;
    console.log(
      `${padRight(s.name, 25)} ${padLeft(String(s.count), 5)} ${padLeft(rate, 6)} ${padLeft(formatTokens(s.avgTokens), 8)} ${padLeft(String(s.avgToolUses), 6)} ${padLeft(formatDuration(s.avgDurationMs), 8)} ${padRight(s.type, 18)}`
    );
  }
  console.log('');
}

function cmdBySession(entries: MetricsEntry[], sessionFilter?: string): void {
  if (entries.length === 0) {
    console.log('\nNo task metrics recorded yet.\n');
    return;
  }

  const targetSession = sessionFilter || getCurrentSession();
  const filtered = entries.filter(e => e.session === targetSession);

  if (filtered.length === 0) {
    console.log(`\nNo entries found for session "${targetSession}".`);
    const sessions = [...new Set(entries.map(e => e.session))];
    console.log(`Available sessions: ${sessions.join(', ')}\n`);
    return;
  }

  const totalTokens = filtered.reduce((sum, e) => sum + (e.totalTokens || 0), 0);
  const totalTools = filtered.reduce((sum, e) => sum + (e.toolUses || 0), 0);
  const totalDuration = filtered.reduce((sum, e) => sum + (e.durationMs || 0), 0);
  const successes = filtered.filter(e => e.success).length;

  console.log(`\n=== Session: ${targetSession} ===\n`);
  console.log(`Executions:     ${filtered.length}`);
  console.log(`Success rate:   ${((successes / filtered.length) * 100).toFixed(1)}%`);
  console.log(`Total tokens:   ${formatTokens(totalTokens)}`);
  console.log(`Total tools:    ${totalTools}`);
  console.log(`Total duration: ${formatDuration(totalDuration)}`);

  // Agent breakdown
  const stats = computeAgentStats(filtered);
  const sorted = [...stats.values()].sort((a, b) => b.totalTokens - a.totalTokens);

  console.log('\nAgent breakdown:');
  for (const s of sorted) {
    console.log(`  ${padRight(s.name, 20)} ${padLeft(String(s.count), 3)}x  tokens=${padLeft(formatTokens(s.totalTokens), 7)}  tools=${padLeft(String(s.totalToolUses), 4)}  ${formatDuration(s.totalDurationMs)}`);
  }
  console.log('');
}

function cmdRecent(entries: MetricsEntry[], count: number): void {
  if (entries.length === 0) {
    console.log('\nNo task metrics recorded yet.\n');
    return;
  }

  const recent = entries.slice(-count).reverse();

  console.log(`\n=== Recent Executions (last ${recent.length}) ===\n`);
  console.log(`${padRight('Timestamp', 20)} ${padRight('Agent', 22)} ${padLeft('Tokens', 8)} ${padLeft('Tools', 6)} ${padLeft('Duration', 9)} ${padLeft('Status', 6)}`);
  console.log(`${'-'.repeat(20)} ${'-'.repeat(22)} ${'-'.repeat(8)} ${'-'.repeat(6)} ${'-'.repeat(9)} ${'-'.repeat(6)}`);

  for (const e of recent) {
    const ts = e.timestamp.substring(0, 19).replace('T', ' ');
    const status = e.success ? 'OK' : 'FAIL';
    console.log(
      `${padRight(ts, 20)} ${padRight(e.agentName, 22)} ${padLeft(formatTokens(e.totalTokens), 8)} ${padLeft(String(e.toolUses ?? '-'), 6)} ${padLeft(formatDuration(e.durationMs), 9)} ${padLeft(status, 6)}`
    );
  }
  console.log('');
}

function cmdTopTokens(entries: MetricsEntry[], limit: number): void {
  if (entries.length === 0) {
    console.log('\nNo task metrics recorded yet.\n');
    return;
  }

  const stats = computeAgentStats(entries);
  const sorted = [...stats.values()]
    .filter(s => s.totalTokens > 0)
    .sort((a, b) => b.totalTokens - a.totalTokens)
    .slice(0, limit);

  if (sorted.length === 0) {
    console.log('\nNo token data available yet.\n');
    return;
  }

  const maxTokens = sorted[0].totalTokens;

  console.log(`\n=== Top Token Consumers ===\n`);

  for (const s of sorted) {
    const barLen = Math.max(1, Math.round((s.totalTokens / maxTokens) * 30));
    const bar = '#'.repeat(barLen);
    console.log(`${padRight(s.name, 25)} ${padLeft(formatTokens(s.totalTokens), 8)}  ${bar}  (${s.count} runs, avg ${formatTokens(s.avgTokens)}/run)`);
  }
  console.log('');
}

function cmdCost(entries: MetricsEntry[], inputRate: number, outputRate: number): void {
  if (entries.length === 0) {
    console.log('\nNo task metrics recorded yet.\n');
    return;
  }

  const withTokens = entries.filter(e => e.totalTokens != null);
  if (withTokens.length === 0) {
    console.log('\nNo token data available for cost estimation.\n');
    return;
  }

  // total_tokens is combined; estimate 30% input, 70% output as rough split
  // (subagents mostly generate output)
  const totalTokens = withTokens.reduce((sum, e) => sum + (e.totalTokens || 0), 0);
  const estInput = totalTokens * 0.3;
  const estOutput = totalTokens * 0.7;
  const inputCost = (estInput / 1_000_000) * inputRate;
  const outputCost = (estOutput / 1_000_000) * outputRate;
  const totalCost = inputCost + outputCost;

  console.log(`\n=== Cost Estimate ===\n`);
  console.log(`Rates: $${inputRate}/MTok input, $${outputRate}/MTok output`);
  console.log(`Note: Uses 30/70 input/output split estimate\n`);
  console.log(`Total tokens:     ${formatTokens(totalTokens)} (from ${withTokens.length} entries)`);
  console.log(`Est. input:       ${formatTokens(estInput)} -> $${inputCost.toFixed(4)}`);
  console.log(`Est. output:      ${formatTokens(estOutput)} -> $${outputCost.toFixed(4)}`);
  console.log(`Est. total cost:  $${totalCost.toFixed(4)}`);

  // Per-agent cost breakdown
  const stats = computeAgentStats(withTokens);
  const sorted = [...stats.values()]
    .filter(s => s.totalTokens > 0)
    .sort((a, b) => b.totalTokens - a.totalTokens);

  if (sorted.length > 0) {
    console.log('\nPer-agent breakdown:');
    for (const s of sorted) {
      const agentInput = s.totalTokens * 0.3;
      const agentOutput = s.totalTokens * 0.7;
      const agentCost = (agentInput / 1_000_000) * inputRate + (agentOutput / 1_000_000) * outputRate;
      console.log(`  ${padRight(s.name, 25)} ${padLeft(formatTokens(s.totalTokens), 8)} tokens  ~$${agentCost.toFixed(4)}`);
    }
  }
  console.log('');
}

function showHelp(): void {
  console.log(`
Task Metrics Query Tool
========================

Usage: npx tsx metrics-query.ts <command> [args]

Commands:
  summary                    Total executions, tokens, tools, success rate
  by-agent [name]            Stats grouped by agent, or detail for one
  by-session [name]          Stats for current or named session
  recent [count]             Last N executions (default 10)
  top-tokens [limit]         Agents ranked by total token usage (default 10)
  cost [input] [output]      Estimate API cost (default $3/$15 per MTok)
  help                       Show this help

Examples:
  npx tsx metrics-query.ts summary
  npx tsx metrics-query.ts by-agent Plan
  npx tsx metrics-query.ts by-session "Feature Planning"
  npx tsx metrics-query.ts recent 20
  npx tsx metrics-query.ts top-tokens 5
  npx tsx metrics-query.ts cost 3 15

Data source: .claude/logs/task-metrics.jsonl
`);
}

// ============================================================
// CLI ENTRY POINT
// ============================================================

const args = process.argv.slice(2);
const command = args[0];
const cmdArgs = args.slice(1);

try {
  const entries = loadEntries();

  switch (command) {
    case 'summary':
      cmdSummary(entries);
      break;

    case 'by-agent':
      cmdByAgent(entries, cmdArgs[0]);
      break;

    case 'by-session':
      cmdBySession(entries, cmdArgs[0]);
      break;

    case 'recent':
      cmdRecent(entries, parseInt(cmdArgs[0]) || 10);
      break;

    case 'top-tokens':
      cmdTopTokens(entries, parseInt(cmdArgs[0]) || 10);
      break;

    case 'cost': {
      const inputRate = parseFloat(cmdArgs[0]) || 3;
      const outputRate = parseFloat(cmdArgs[1]) || 15;
      cmdCost(entries, inputRate, outputRate);
      break;
    }

    case 'help':
    case '--help':
    case '-h':
    case undefined:
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
