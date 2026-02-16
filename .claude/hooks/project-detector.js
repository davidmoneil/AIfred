#!/usr/bin/env node
/**
 * Project Detector Hook
 *
 * Detects when user mentions:
 * - GitHub URLs (to clone/register existing repos)
 * - "New project" phrases (to create new projects)
 * - External tool evaluation context (to apply evaluation pattern)
 *
 * Adds a system reminder for Claude to handle appropriately.
 */

const fs = require('fs');
const path = require('path');

// Read hook input from stdin
let input = '';
process.stdin.setEncoding('utf8');
process.stdin.on('data', chunk => input += chunk);
process.stdin.on('end', () => {
  try {
    const data = JSON.parse(input);
    const result = processPrompt(data);
    console.log(JSON.stringify(result));
  } catch (e) {
    // On error, allow the prompt through without modification
    console.log(JSON.stringify({ continue: true }));
  }
});

function processPrompt(data) {
  const message = data.prompt || '';
  const messageLower = message.toLowerCase();

  // Patterns to detect
  const githubUrlPattern = /github\.com\/[\w-]+\/[\w-]+/gi;

  const newProjectPhrases = [
    'new project',
    'create a project',
    'start a project',
    'start a new',
    'build a new',
    'let\'s create',
    'let\'s build',
    'let\'s start a new'
  ];

  // Evaluation context phrases - indicates user wants to EVALUATE, not adopt
  const evaluationPhrases = [
    'check out this',
    'check out this tool',
    'check out this project',
    'what do you think of',
    'have you seen',
    'is it worth',
    'should we use',
    'evaluate this',
    'review this tool',
    'look at this project',
    'thoughts on',
    'opinion on',
    'worth adopting',
    'worth integrating',
    'compare to what we have'
  ];

  // Tool/project indicator words (used with GitHub URLs to detect evaluation vs adoption)
  const toolIndicators = [
    'tool', 'library', 'framework', 'package', 'mcp', 'server',
    'claude code', 'claude-code', 'cli', 'workflow', 'automation'
  ];

  const githubMatches = message.match(githubUrlPattern) || [];
  const hasNewProjectPhrase = newProjectPhrases.some(phrase =>
    messageLower.includes(phrase)
  );
  const hasEvaluationPhrase = evaluationPhrases.some(phrase =>
    messageLower.includes(phrase)
  );
  const hasToolIndicator = toolIndicators.some(word =>
    messageLower.includes(word)
  );

  // Priority 1: Evaluation context (GitHub URL + evaluation phrase OR tool indicator + evaluation phrase)
  if (hasEvaluationPhrase && (githubMatches.length > 0 || hasToolIndicator)) {
    const urls = githubMatches.map(url =>
      url.startsWith('http') ? url : `https://${url}`
    );

    return {
      continue: true,
      hookSpecificOutput: {
        additionalContext: `<project-detector>
EXTERNAL TOOL EVALUATION DETECTED
${urls.length > 0 ? `URL: ${urls.join(', ')}` : ''}

This appears to be a request to EVALUATE an external tool/project, not adopt it.

Apply the External Tool Evaluation Pattern:
1. Quick Assessment (5 min): What does it do? Do we have that problem?
2. Pattern Extraction: What techniques/patterns does it use?
3. Value Assessment: Is any pattern worth adopting?
4. Decision: YES (adopt pattern) / MAYBE (track) / NO (skip)

Pattern: @.claude/context/patterns/external-tool-evaluation-pattern.md

Key principle: Extract valuable PATTERNS, don't adopt entire systems.
</project-detector>`
      }
    };
  }

  // Priority 2: GitHub URL without evaluation context = adoption/registration
  if (githubMatches.length > 0 && !hasEvaluationPhrase) {
    const urls = githubMatches.map(url =>
      url.startsWith('http') ? url : `https://${url}`
    );

    return {
      continue: true,
      hookSpecificOutput: {
        additionalContext: `<project-detector>
GITHUB URL DETECTED: ${urls.join(', ')}

Before proceeding with the user's request:
1. Check if this project exists in paths-registry.yaml (coding.projects section)
2. If NOT registered, automatically:
   a. Clone to ~/Code/<repo-name>
   b. Auto-detect language/type from files
   c. Add entry to paths-registry.yaml under coding.projects
   d. Create context file at .claude/context/projects/<repo-name>.md
3. Then continue with their original request

Pattern: .claude/commands/register-project.md
</project-detector>`
      }
    };
  }

  // Priority 3: New project creation
  if (hasNewProjectPhrase) {
    return {
      continue: true,
      hookSpecificOutput: {
        additionalContext: `<project-detector>
NEW CODE PROJECT REQUEST DETECTED

Clarify with user, then automatically:
1. Create in ~/Code/<name> (NOT in AIfred - AIfred is a hub)
2. Initialize: git init, README.md, .claude/CLAUDE.md, .gitignore
3. Add to paths-registry.yaml under coding.projects
4. Create context file at .claude/context/projects/<name>.md
5. Optionally create GitHub repo if requested

Pattern: .claude/commands/new-code-project.md

Note: For internal projects (writing, research), use /create-project instead.
</project-detector>`
      }
    };
  }

  // No project-related patterns detected
  return { continue: true };
}
