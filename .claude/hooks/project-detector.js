#!/usr/bin/env node
/**
 * Project Detector Hook
 *
 * Detects when user mentions:
 * - GitHub URLs (to clone/register existing repos)
 * - "New project" phrases (to create new projects)
 *
 * Adds a system reminder for Claude to handle project setup automatically.
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

  const githubMatches = message.match(githubUrlPattern) || [];
  const hasNewProjectPhrase = newProjectPhrases.some(phrase =>
    messageLower.includes(phrase)
  );

  // Check if this looks like a project-related request
  if (githubMatches.length > 0) {
    // Found GitHub URL(s)
    const urls = githubMatches.map(url =>
      url.startsWith('http') ? url : `https://${url}`
    );

    return {
      continue: true,
      messages: [{
        role: 'system',
        content: `<project-detector>
GITHUB URL DETECTED: ${urls.join(', ')}

Before proceeding with the user's request:
1. Check if this project exists in paths-registry.yaml (development.projects section)
2. If NOT registered, automatically:
   a. Clone to the projects_root directory (from paths-registry.yaml)
   b. Auto-detect language/type from files
   c. Add entry to paths-registry.yaml under development.projects
   d. Create context file at .claude/context/projects/<repo-name>.md
3. Then continue with their original request

Pattern: .claude/commands/register-project.md
</project-detector>`
      }]
    };
  }

  if (hasNewProjectPhrase) {
    // Detected "new project" language
    return {
      continue: true,
      messages: [{
        role: 'system',
        content: `<project-detector>
NEW CODE PROJECT REQUEST DETECTED

Clarify with user, then automatically:
1. Create in projects_root (NOT in AIfred - AIfred is a hub)
2. Initialize: git init, README.md, .claude/CLAUDE.md, .gitignore
3. Add to paths-registry.yaml under development.projects
4. Create context file at .claude/context/projects/<name>.md
5. Optionally create GitHub repo if requested

Pattern: .claude/commands/create-project.md
</project-detector>`
      }]
    };
  }

  // No project-related patterns detected
  return { continue: true };
}
