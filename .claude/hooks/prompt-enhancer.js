#!/usr/bin/env node
/**
 * Prompt Enhancer Hook
 *
 * Event: UserPromptSubmit
 * Purpose: Detect common prompt patterns and inject contextual guidance
 *          to ensure Claude uses optimal tools (e.g., LSP for navigation)
 *
 * This is Phase 1 of the Prompt Enhancement Pattern - soft guidance at
 * the prompt level before Claude chooses a tool.
 *
 * Created: 2026-01-21
 */

// Enhancement rules - patterns that trigger guidance injection
const ENHANCEMENT_RULES = [
  {
    id: 'lsp-navigation',
    description: 'Code navigation queries should use LSP',
    patterns: [
      // Definition lookups
      /\b(go\s*to|find|show|get|where('?s|\s+is)?)\s+(the\s+)?(definition|impl(ementation)?)\s+(of|for)\b/i,
      /\bdefinition\s+of\b/i,
      /\bwhere\s+.{1,50}\s+(is\s+)?defined\b/i,
      /\bnavigate\s+to\b/i,

      // Reference/usage lookups
      /\b(find|show|list|get)\s+(me\s+)?(all\s+)?(the\s+)?(references?|usages?|callers?|uses)\s+(of|to|for)\b/i,
      /\bwho\s+(calls?|uses?|references?)\b/i,
      /\bwhere\s+.{1,50}\s+(is\s+)?(used|called|referenced|invoked)\b/i,

      // Symbol lookups
      /\b(find|locate|show)\s+(the\s+)?(function|class|method|variable|const|interface|type)\s+\w+/i,
      /\blist\s+(all\s+)?(symbols?|functions?|classes?|methods?)\s+(in|from)\b/i,

      // Hover/documentation
      /\bwhat\s+(is|does|are)\s+(the\s+)?(type|signature|parameters?)\s+(of|for)\b/i,
      /\bshow\s+(me\s+)?(the\s+)?(type|signature|docs?|documentation)\s+(of|for)\b/i
    ],
    context: `**LSP Guidance**: For code navigation, use the LSP tool instead of Search/Grep.

LSP is ~50x faster and provides semantic understanding:
- \`LSP(operation: "goToDefinition", filePath: "...", line: N, character: N)\`
- \`LSP(operation: "findReferences", filePath: "...", line: N, character: N)\`
- \`LSP(operation: "documentSymbol", filePath: "...")\` - list all symbols in file
- \`LSP(operation: "workspaceSymbol", filePath: "...")\` - search symbols across project

First find a file containing the symbol, then use LSP with a position in that file.`
  },
  {
    id: 'docker-mcp',
    description: 'Docker operations should use MCP',
    patterns: [
      /\bdocker\s+(ps|logs|inspect|start|stop|restart|status)\b/i,
      /\b(list|show|check)\s+(the\s+)?(containers?|docker)\b/i,
      /\bcontainer\s+(status|health|logs?)\b/i
    ],
    context: `**Docker Guidance**: Use MCP docker tools for structured output:
- \`mcp__mcp-gateway__docker\` for container operations
Prefer MCP over raw bash commands for better parsing and safety.`
  },
  {
    id: 'git-mcp',
    description: 'Git operations should use MCP',
    patterns: [
      /\bgit\s+(status|log|diff|show|branch)\b/i,
      /\b(show|check)\s+(the\s+)?(git\s+)?(commit|branch|diff|status)\b/i
    ],
    context: `**Git Guidance**: Use MCP git tools for structured output:
- \`mcp__git__git_status\`, \`mcp__git__git_log\`, \`mcp__git__git_diff\`
These provide better structured data than raw bash commands.`
  }
];

/**
 * Check if prompt matches any enhancement rules
 */
function findMatchingRules(prompt) {
  const matches = [];

  for (const rule of ENHANCEMENT_RULES) {
    const isMatch = rule.patterns.some(pattern => pattern.test(prompt));
    if (isMatch) {
      matches.push(rule);
    }
  }

  return matches;
}

/**
 * Main hook handler
 */
async function main() {
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const input = Buffer.concat(chunks).toString('utf8');

  let data;
  try {
    data = JSON.parse(input);
  } catch (err) {
    // Can't parse input, just allow
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  const prompt = data.prompt || '';

  // Find matching rules
  const matchedRules = findMatchingRules(prompt);

  // Build response
  const result = { proceed: true };

  if (matchedRules.length > 0) {
    // Inject guidance as additional context
    const contexts = matchedRules.map(r => r.context);
    result.additionalContext = contexts.join('\n\n---\n\n');

    // Log which rules matched (for debugging)
    const ruleIds = matchedRules.map(r => r.id).join(', ');
    console.error(`[prompt-enhancer] Matched rules: ${ruleIds}`);
  }

  console.log(JSON.stringify(result));
}

main().catch(err => {
  console.error(`[prompt-enhancer] Error: ${err.message}`);
  console.log(JSON.stringify({ proceed: true }));
});
