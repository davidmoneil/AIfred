#!/usr/bin/env node
// memory-mirror.js — PostToolUse hook (Write)
// Mirrors MEMORY.md from ~/.claude/projects/ auto-memory location into Jarvis context space.
// This ensures Jarvis's project-local context always has the latest memory snapshot.
//
// Also mirrors key external ~/.claude/ files that Jarvis created but Claude Code
// placed outside the project directory.
//
// Created: 2026-02-10 (B.4 enhancement)

const fs = require('fs');
const path = require('path');

const PROJECT_DIR = process.env.CLAUDE_PROJECT_DIR || path.join(process.env.HOME, 'Claude', 'Jarvis');
const MEMORY_SOURCE = path.join(process.env.HOME, '.claude', 'projects', '-Users-aircannon-Claude-Jarvis', 'memory', 'MEMORY.md');
const MEMORY_DEST = path.join(PROJECT_DIR, '.claude', 'context', 'memory', 'MEMORY.md');

function main() {
  try {
    const input = JSON.parse(fs.readFileSync('/dev/stdin', 'utf8'));
    const toolName = input.tool_name || '';
    const filePath = (input.tool_input && input.tool_input.file_path) || '';

    // Only act on Write to MEMORY.md (auto-memory or manual updates)
    if (toolName !== 'Write') {
      console.log(JSON.stringify({ proceed: true }));
      return;
    }

    // Check if the written file is the auto-memory MEMORY.md
    if (filePath.includes('memory/MEMORY.md') || filePath.endsWith('/MEMORY.md')) {
      // Ensure destination directory exists
      const destDir = path.dirname(MEMORY_DEST);
      if (!fs.existsSync(destDir)) {
        fs.mkdirSync(destDir, { recursive: true });
      }

      // Copy the source file to the project context
      if (fs.existsSync(filePath)) {
        fs.copyFileSync(filePath, MEMORY_DEST);
        console.log(JSON.stringify({
          proceed: true,
          hookSpecificOutput: {
            hookEventName: 'PostToolUse',
            action: 'memory-mirrored',
            source: filePath,
            destination: MEMORY_DEST
          }
        }));
        return;
      }
    }

    console.log(JSON.stringify({ proceed: true }));
  } catch (err) {
    // Never block tool execution
    console.log(JSON.stringify({ proceed: true }));
  }
}

main();
