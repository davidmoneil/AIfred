/**
 * Pre-Compact Hook (Enhanced)
 *
 * Preserves critical context before conversation compaction:
 * - Key sections from session-state.md
 * - Recent blockers
 * - Active orchestration info
 * - Compaction timestamp
 * - Soft restart recommendation (PR-8.4)
 *
 * This ensures important context survives the compaction process.
 * Suggests /soft-restart as alternative to autocompaction (two paths:
 * Path A for conversation-only clear, Path B for MCP reduction).
 *
 * Priority: HIGH (Context Preservation)
 * Created: 2026-01-06
 * Updated: 2026-01-07 (PR-8.4 - Soft Restart integration)
 * Source: AIfred baseline af66364 (implemented for Jarvis)
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const WORKSPACE_ROOT = '/Users/aircannon/Claude/Jarvis';
const SESSION_STATE_PATH = path.join(WORKSPACE_ROOT, '.claude/context/session-state.md');
const COMPACTION_LOG = path.join(WORKSPACE_ROOT, '.claude/logs/compaction-history.jsonl');

/**
 * Extract key sections from session state
 */
function extractKeySections(content) {
  const sections = {
    status: null,
    currentTask: null,
    nextStep: null,
    blockers: [],
    mcpsEnabled: []
  };

  // Extract status
  const statusMatch = content.match(/\*\*Status\*\*:\s*(.+)/);
  if (statusMatch) sections.status = statusMatch[1].trim();

  // Extract current task
  const taskMatch = content.match(/\*\*Current Task\*\*:\s*(.+)/);
  if (taskMatch) sections.currentTask = taskMatch[1].trim();

  // Extract next step
  const nextMatch = content.match(/\*\*Next Step\*\*:\s*(.+)/);
  if (nextMatch) sections.nextStep = nextMatch[1].trim();

  // Extract blockers (lines starting with - in blockers section)
  const blockersMatch = content.match(/### Blockers\s*\n([\s\S]*?)(?=\n###|\n---|\n$)/);
  if (blockersMatch) {
    const blockerLines = blockersMatch[1].match(/^-\s+.+$/gm);
    if (blockerLines) sections.blockers = blockerLines.map(b => b.replace(/^-\s+/, ''));
  }

  // Extract enabled MCPs
  const mcpMatch = content.match(/### On-Demand MCPs Enabled\s*\n([\s\S]*?)(?=\n###|\n---|\n$)/);
  if (mcpMatch) {
    const mcpLines = mcpMatch[1].match(/^-\s+.+$/gm);
    if (mcpLines) sections.mcpsEnabled = mcpLines.map(m => m.replace(/^-\s+/, ''));
  }

  return sections;
}

/**
 * Format preserved context message with smart checkpoint suggestion
 */
function formatPreservedContext(sections) {
  const lines = [
    '',
    '╔══════════════════════════════════════════════════════════════╗',
    '║         ⚠️  CONTEXT THRESHOLD - COMPACTION IMMINENT          ║',
    '╚══════════════════════════════════════════════════════════════╝',
    '',
    '┌─────────────────────────────────────────────────────────────┐',
    '│  💡 RECOMMENDATION: Run /soft-restart instead              │',
    '│                                                             │',
    '│  Two options:                                               │',
    '│  Path A (Soft): /clear only → ~16K tokens freed            │',
    '│  Path B (Hard): exit + claude → ~47K tokens freed          │',
    '│                                                             │',
    '│  Both paths preserve your work state via checkpoint!       │',
    '│  This is better than autocompaction which loses context!   │',
    '└─────────────────────────────────────────────────────────────┘',
    ''
  ];

  lines.push('─────────────────── Context Being Preserved ───────────────────');
  lines.push('');

  if (sections.status) {
    lines.push(`📊 Status: ${sections.status}`);
  }
  if (sections.currentTask) {
    lines.push(`📌 Current Task: ${sections.currentTask}`);
  }
  if (sections.nextStep) {
    lines.push(`➡️ Next Step: ${sections.nextStep}`);
  }

  if (sections.blockers.length > 0) {
    lines.push('');
    lines.push('🚧 Blockers:');
    sections.blockers.forEach(b => lines.push(`   • ${b}`));
  }

  if (sections.mcpsEnabled.length > 0 && sections.mcpsEnabled[0] !== 'None') {
    lines.push('');
    lines.push('🔌 MCPs Enabled This Session:');
    sections.mcpsEnabled.forEach(m => lines.push(`   • ${m}`));
  }

  lines.push('');
  lines.push(`⏰ Compaction at: ${new Date().toISOString()}`);
  lines.push('');
  lines.push('══════════════════════════════════════════════════════════════');
  lines.push('');

  return lines.join('\n');
}

/**
 * Log compaction event
 */
async function logCompaction(sections) {
  try {
    const dir = path.dirname(COMPACTION_LOG);
    await fs.mkdir(dir, { recursive: true });

    const entry = {
      timestamp: new Date().toISOString(),
      preserved: sections
    };

    await fs.appendFile(COMPACTION_LOG, JSON.stringify(entry) + '\n');
  } catch (err) {
    // Silent failure
  }
}

module.exports = {
  name: 'pre-compact',
  description: 'Preserve critical context before conversation compaction',
  event: 'PreCompact',

  async handler(context) {
    try {
      // Read session state
      const content = await fs.readFile(SESSION_STATE_PATH, 'utf8');

      // Extract key sections
      const sections = extractKeySections(content);

      // Log compaction event
      await logCompaction(sections);

      // Output preserved context
      const message = formatPreservedContext(sections);
      console.log(message);

    } catch (err) {
      console.log(`[pre-compact] Unable to preserve context: ${err.message}`);
    }

    return { proceed: true };
  }
};
