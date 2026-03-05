#!/usr/bin/env node
/**
 * Prompt Dispatcher Hook
 *
 * Event: UserPromptSubmit
 * Purpose: Single entry point for all prompt-level detection and guidance.
 *
 * Consolidates:
 * - prompt-enhancer.js (tool guidance: LSP, Docker MCP, Git MCP)
 * - project-detector.js (GitHub URLs, new project phrases, evaluation context)
 *
 * Created: 2026-03-03 (consolidation of prompt-enhancer + project-detector)
 */

const { readStdin, runHook } = require('./lib/shared');

// ============================================================================
// Section 1: Tool Guidance Rules (from prompt-enhancer)
// ============================================================================

const TOOL_GUIDANCE_RULES = [
  {
    id: 'lsp-navigation',
    patterns: [
      /\b(go\s*to|find|show|get|where('?s|\s+is)?)\s+(the\s+)?(definition|impl(ementation)?)\s+(of|for)\b/i,
      /\bdefinition\s+of\b/i,
      /\bwhere\s+.{1,50}\s+(is\s+)?defined\b/i,
      /\bnavigate\s+to\b/i,
      /\b(find|show|list|get)\s+(me\s+)?(all\s+)?(the\s+)?(references?|usages?|callers?|uses)\s+(of|to|for)\b/i,
      /\bwho\s+(calls?|uses?|references?)\b/i,
      /\bwhere\s+.{1,50}\s+(is\s+)?(used|called|referenced|invoked)\b/i,
      /\b(find|locate|show)\s+(the\s+)?(function|class|method|variable|const|interface|type)\s+\w+/i,
      /\blist\s+(all\s+)?(symbols?|functions?|classes?|methods?)\s+(in|from)\b/i,
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
    patterns: [
      /\bgit\s+(status|log|diff|show|branch)\b/i,
      /\b(show|check)\s+(the\s+)?(git\s+)?(commit|branch|diff|status)\b/i
    ],
    context: `**Git Guidance**: Use MCP git tools for structured output:
- \`mcp__git__git_status\`, \`mcp__git__git_log\`, \`mcp__git__git_diff\`
These provide better structured data than raw bash commands.`
  }
];

// ============================================================================
// Section 2: Project Detection Rules (from project-detector)
// ============================================================================

const GITHUB_URL_PATTERN = /github\.com\/[\w-]+\/[\w-]+/gi;

const NEW_PROJECT_PHRASES = [
  'new project', 'create a project', 'start a project',
  'start a new', 'build a new', "let's create", "let's build", "let's start a new"
];

const EVALUATION_PHRASES = [
  'check out this', 'check out this tool', 'check out this project',
  'what do you think of', 'have you seen', 'is it worth',
  'should we use', 'evaluate this', 'review this tool',
  'look at this project', 'thoughts on', 'opinion on',
  'worth adopting', 'worth integrating', 'compare to what we have'
];

const TOOL_INDICATORS = [
  'tool', 'library', 'framework', 'package', 'mcp', 'server',
  'claude code', 'claude-code', 'cli', 'workflow', 'automation'
];

function detectProject(prompt) {
  const lower = prompt.toLowerCase();
  const githubMatches = prompt.match(GITHUB_URL_PATTERN) || [];
  const hasNewProject = NEW_PROJECT_PHRASES.some(p => lower.includes(p));
  const hasEval = EVALUATION_PHRASES.some(p => lower.includes(p));
  const hasTool = TOOL_INDICATORS.some(w => lower.includes(w));

  // Priority 1: Evaluation context
  if (hasEval && (githubMatches.length > 0 || hasTool)) {
    const urls = githubMatches.map(u => u.startsWith('http') ? u : `https://${u}`);
    return `<project-detector>
EXTERNAL TOOL EVALUATION DETECTED
${urls.length > 0 ? `URL: ${urls.join(', ')}` : ''}

Apply the External Tool Evaluation Pattern:
1. Quick Assessment: What does it do? Do we have that problem?
2. Pattern Extraction: What techniques/patterns does it use?
3. Value Assessment: Is any pattern worth adopting?
4. Decision: YES (adopt pattern) / MAYBE (track) / NO (skip)

Pattern: @.claude/context/patterns/external-tool-evaluation-pattern.md
</project-detector>`;
  }

  // Priority 2: GitHub URL = adoption/registration
  if (githubMatches.length > 0 && !hasEval) {
    const urls = githubMatches.map(u => u.startsWith('http') ? u : `https://${u}`);
    return `<project-detector>
GITHUB URL DETECTED: ${urls.join(', ')}

Before proceeding:
1. Check if this project exists in paths-registry.yaml (coding.projects section)
2. If NOT registered: clone to ~/Code/<repo-name>, add to paths-registry.yaml, create context file
3. Then continue with the original request

Pattern: .claude/commands/register-project.md
</project-detector>`;
  }

  // Priority 3: New project creation
  if (hasNewProject) {
    return `<project-detector>
NEW CODE PROJECT REQUEST DETECTED

Create in ~/Code/<name> (NOT in the project root), initialize, register in paths-registry.yaml.
Pattern: .claude/commands/new-code-project.md
For internal projects (writing, research), use /create-project instead.
</project-detector>`;
  }

  return null;
}

// ============================================================================
// Section 3: Task Query Detection — route to /tasks skill
// ============================================================================

const TASK_QUERY_PATTERNS = [
  /\b(what|show|list|display|get)\b.{0,30}\b(open|active|pending|ready|current|my)\s+(tasks?|issues?|tickets?)\b/i,
  /\b(open|active|pending|ready|current|my)\s+(tasks?|issues?|tickets?)\b/i,
  /\btask\s+(list|status|summary|overview|dashboard|report)\b/i,
  /\btasks?\s+(by|for|in)\s+(domain|project|priority)\b/i,
  /\bhow\s+many\s+tasks?\b/i,
  /\btask\s+stats?\b/i,
  /\bwhat('?s| is| are)\s+(left|remaining|todo|to do|next)\b.*\btasks?\b/i,
  /\btasks?\b.*\b(left|remaining|todo|to do|next)\b/i,
  /\b(what|show).{0,20}\b(blocke[dr]|blocking|stalled)\b.*\btasks?\b/i,
  /\btasks?\b.*\b(blocke[dr]|blocking|stalled)\b/i,
  /\btasks?\s+.{0,30}\b(pending|awaiting|waiting)\b/i,
  /\b(pending|awaiting|waiting)\b.{0,30}\btasks?\b/i
];

function detectTaskQuery(prompt) {
  if (TASK_QUERY_PATTERNS.some(p => p.test(prompt))) {
    return `**Task Dashboard**: Use the \`/tasks\` skill for standardized task output instead of raw MCP task_list calls.
Available sub-commands: \`/tasks\` (summary), \`/tasks ready\`, \`/tasks domain <name>\`, \`/tasks project <name>\`, \`/tasks stats\`.
Invoke via the Skill tool with skill: "tasks" and appropriate args.`;
  }
  return null;
}

// ============================================================================
// Main
// ============================================================================

async function main() {
  const data = await readStdin();
  const prompt = data.prompt || '';

  if (!prompt) {
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  const contextParts = [];

  // Check tool guidance rules
  const matchedRules = TOOL_GUIDANCE_RULES.filter(rule =>
    rule.patterns.some(p => p.test(prompt))
  );
  if (matchedRules.length > 0) {
    contextParts.push(...matchedRules.map(r => r.context));
    console.error(`[prompt-dispatcher] Tool guidance: ${matchedRules.map(r => r.id).join(', ')}`);
  }

  // Check task query detection
  const taskContext = detectTaskQuery(prompt);
  if (taskContext) {
    contextParts.push(taskContext);
    console.error('[prompt-dispatcher] Task query detected — routing to /tasks skill');
  }

  // Check project detection
  const projectContext = detectProject(prompt);
  if (projectContext) {
    contextParts.push(projectContext);
    console.error('[prompt-dispatcher] Project detection triggered');
  }

  const result = { proceed: true };
  if (contextParts.length > 0) {
    result.additionalContext = contextParts.join('\n\n---\n\n');
  }

  console.log(JSON.stringify(result));
}

runHook('prompt-dispatcher', main);
