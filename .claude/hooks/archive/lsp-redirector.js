#!/usr/bin/env node
/**
 * LSP Redirector Hook
 *
 * Event: PreToolUse
 * Purpose: Intercept Grep/Search calls that look like navigation queries
 *          and redirect Claude to use LSP instead
 *
 * Patterns detected:
 * - "definition of X" / "where X defined"
 * - "references to X" / "usages of X"
 * - "find function X" / "find class X"
 * - Symbol lookups that would be better served by LSP
 *
 * When triggered: Blocks the tool with a message to use LSP instead
 */

const fs = require('fs');
const path = require('path');

// Navigation patterns that should use LSP instead of Search/Grep
const NAVIGATION_PATTERNS = [
  // Definition lookups
  /\bdefinition\s+of\b/i,
  /\bwhere\s+.*\s+defined\b/i,
  /\bgo\s*to\s*(definition|implementation)/i,
  /\bfind\s+(the\s+)?definition\b/i,

  // Reference/usage lookups
  /\breferences?\s+(to|of)\b/i,
  /\busages?\s+(of|for)\b/i,
  /\bwho\s+(calls?|uses?)\b/i,
  /\bwhere\s+.*\s+(used|called|referenced)\b/i,
  /\bfind\s+(all\s+)?(references?|usages?)\b/i,

  // Symbol lookups
  /\bfind\s+(function|class|method|variable|const|interface)\s+\w+/i,
  /\bwhere\s+is\s+(function|class|method)\b/i,
  /\blocate\s+(the\s+)?(function|class|definition)/i,

  // Implementation lookups
  /\bimplementation\s+of\b/i,
  /\bwhere\s+.*\s+implemented\b/i
];

// File extensions that support LSP (TypeScript/JavaScript)
const LSP_SUPPORTED_EXTENSIONS = ['.ts', '.tsx', '.js', '.jsx', '.mjs'];

// Read input from stdin
let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const toolName = data.tool_name;
    const toolInput = data.tool_input || {};

    // Only process Search and Grep tools
    if (!['Search', 'Grep'].includes(toolName)) {
      // Allow other tools to proceed
      console.log(JSON.stringify({ proceed: true }));
      process.exit(0);
      return;
    }

    // Get the search pattern
    const pattern = toolInput.pattern || toolInput.query || '';
    const filePath = toolInput.path || toolInput.file || '';

    // Check if this looks like a navigation query
    const isNavigationQuery = NAVIGATION_PATTERNS.some(regex => regex.test(pattern));

    // Check if targeting LSP-supported files
    const isLspSupportedPath = !filePath || // No path specified = could be JS/TS
      LSP_SUPPORTED_EXTENSIONS.some(ext => filePath.endsWith(ext)) ||
      filePath.includes('.claude/hooks') || // Our hooks are JS
      filePath.includes('.claude/skills'); // Skills may have JS

    if (isNavigationQuery && isLspSupportedPath) {
      // Block and redirect to LSP
      console.log(JSON.stringify({
        proceed: false,
        message: `🔄 **Use LSP instead** - This looks like a code navigation query.

LSP is **50x faster** (~50ms vs seconds) and provides semantic understanding.

**Instead of Search/Grep, use:**
\`\`\`
LSP(operation: "goToDefinition", file: "path/to/file.js", position: line:column)
LSP(operation: "findReferences", file: "path/to/file.js", position: line:column)
LSP(operation: "documentSymbol", file: "path/to/file.js")
\`\`\`

**Available LSP operations:**
- \`goToDefinition\` - Jump to where a symbol is defined
- \`findReferences\` - Find all usages of a symbol
- \`documentSymbol\` - List all symbols in a file
- \`hover\` - Get type/documentation for a symbol
- \`workspaceSymbol\` - Search symbols across the project`
      }));
      process.exit(0);
      return;
    }

    // Not a navigation query, allow it
    console.log(JSON.stringify({ proceed: true }));
    process.exit(0);

  } catch (e) {
    // On error, allow the tool to proceed (fail-open)
    console.error(`LSP Redirector error: ${e.message}`);
    process.exit(1);
  }
});

// Handle stdin close without data (shouldn't happen)
process.stdin.on('close', () => {
  if (!input) {
    console.log(JSON.stringify({ proceed: true }));
    process.exit(0);
  }
});
