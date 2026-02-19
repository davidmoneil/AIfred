#!/usr/bin/env node
/**
 * Fabric Suggester Hook
 *
 * Suggests using Fabric patterns when the user asks about log analysis,
 * code review, or commit messages.
 *
 * Hook Type: UserPromptSubmit
 *
 * Suggestions:
 *   - Log analysis → /fabric:analyze-logs
 *   - Code review → /fabric:review-code
 *   - Commit message → /fabric:commit-msg
 *
 * Created: 2026-01-22
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration
const LOG_DIR = path.join(__dirname, '..', 'logs');
const SUGGESTION_LOG = path.join(LOG_DIR, 'fabric-suggestions.jsonl');

// ============================================================
// PATTERN DETECTION
// ============================================================

// Log analysis triggers
const LOG_ANALYSIS_PATTERNS = [
  /\b(analyze|check|look\s+at|review|examine|inspect)\s+(the\s+)?(logs?|output|errors?)\b/i,
  /\b(what('s|'re|\s+is|\s+are)\s+)?(in\s+the\s+)?(the\s+)?logs?\b/i,
  /\b(docker\s+logs?|container\s+logs?)\b/i,
  /\bwhy\s+is\s+\w+\s+(failing|crashing|erroring|down)\b/i,
  /\b(troubleshoot|debug|diagnose)\s+\w+\s*(container|service|logs?)?\b/i,
  /\b(errors?|exceptions?|warnings?)\s+in\s+\w+/i,
  /\b(what('s|\s+is)\s+wrong\s+with|problems?\s+with)\s+\w+/i,
  /\bcheck\s+(on\s+)?(\w+\s+)?(health|status)\s*(logs?)?/i
];

// Code review triggers
const CODE_REVIEW_PATTERNS = [
  /\b(review|check)\s+(this|my|the)\s+(code|changes?|file|pr|pull\s+request)\b/i,
  /\b(is\s+this|does\s+this)\s+(code\s+)?(look\s+)?(ok|good|right|correct)\b/i,
  /\b(any\s+)?(issues?|problems?|bugs?)\s+(with|in)\s+(this|my)\s+(code|file)\b/i,
  /\bcode\s+review\b/i,
  /\bcan\s+you\s+(review|check|look\s+at)\s+(this|my)\b/i
];

// Commit message triggers
const COMMIT_MSG_PATTERNS = [
  /\b(write|create|generate|make)\s+(a\s+)?(commit\s+)?message\b/i,
  /\b(what\s+should\s+I|help\s+me)\s+(commit|write)\b/i,
  /\bcommit\s+message\s+(for|about)\b/i,
  /\b(staged|changes?)\s+(ready\s+to\s+)?commit\b/i
];

// Skip patterns (don't suggest when already using fabric)
const SKIP_PATTERNS = [
  /^\/fabric/i,
  /\bfabric[:-]/i,
  /\bfabric-\w+-logs\.sh/i
];

// Container name detection for log suggestions
const CONTAINER_PATTERN = /\b(logs?\s+(for|from|of)\s+)(\w+[-_]?\w*)|(\w+[-_]?\w*)\s+(logs?|container|service)\b/i;

/**
 * Detect what kind of fabric suggestion to make
 */
function detectSuggestion(prompt) {
  const trimmedPrompt = prompt.trim();

  // Check skip patterns
  for (const pattern of SKIP_PATTERNS) {
    if (pattern.test(trimmedPrompt)) {
      return null;
    }
  }

  // Check log analysis
  for (const pattern of LOG_ANALYSIS_PATTERNS) {
    if (pattern.test(trimmedPrompt)) {
      // Try to extract container name
      const containerMatch = trimmedPrompt.match(CONTAINER_PATTERN);
      const container = containerMatch ? (containerMatch[3] || containerMatch[4]) : null;

      return {
        type: 'analyze-logs',
        pattern: pattern.toString(),
        container,
        command: container
          ? `/fabric:analyze-logs ${container}`
          : '/fabric:analyze-logs <container>'
      };
    }
  }

  // Check code review
  for (const pattern of CODE_REVIEW_PATTERNS) {
    if (pattern.test(trimmedPrompt)) {
      return {
        type: 'review-code',
        pattern: pattern.toString(),
        command: '/fabric:review-code <file> or /fabric:review-code --staged'
      };
    }
  }

  // Check commit message
  for (const pattern of COMMIT_MSG_PATTERNS) {
    if (pattern.test(trimmedPrompt)) {
      return {
        type: 'commit-msg',
        pattern: pattern.toString(),
        command: '/fabric:commit-msg'
      };
    }
  }

  return null;
}

/**
 * Log suggestion for analytics
 */
async function logSuggestion(prompt, suggestion) {
  try {
    await fs.mkdir(LOG_DIR, { recursive: true });

    const entry = {
      timestamp: new Date().toISOString(),
      prompt: prompt.substring(0, 100),
      suggestion: suggestion.type,
      container: suggestion.container || null
    };

    await fs.appendFile(SUGGESTION_LOG, JSON.stringify(entry) + '\n');
  } catch (err) {
    // Silently ignore log errors
  }
}

/**
 * Generate suggestion message
 */
function generateSuggestionMessage(suggestion) {
  const messages = {
    'analyze-logs': suggestion.container
      ? `**Fabric Suggestion**: Use \`${suggestion.command}\` for AI-powered log analysis.\n` +
        'This will identify patterns, anomalies, and provide recommendations.\n' +
        'Uses local Ollama (free, no API cost).'
      : '**Fabric Suggestion**: Use `/fabric:analyze-logs <container>` for AI-powered log analysis.\n' +
        'Example: `/fabric:analyze-logs prometheus`\n' +
        'Uses local Ollama (free, no API cost).',

    'review-code': '**Fabric Suggestion**: Use `/fabric:review-code` for AI-powered code review.\n' +
      'Example: `/fabric:review-code src/main.ts` or `/fabric:review-code --staged`\n' +
      'Provides prioritized recommendations using local Ollama.',

    'commit-msg': '**Fabric Suggestion**: Use `/fabric:commit-msg` to generate a commit message.\n' +
      'Analyzes your staged changes and creates a conventional commit message.\n' +
      'Uses local Ollama (free, no API cost).'
  };

  return messages[suggestion.type] || '';
}

/**
 * Main handler
 */
async function handleHook(context) {
  const { prompt } = context;

  if (!prompt || prompt.length < 5) {
    return { proceed: true };
  }

  try {
    const suggestion = detectSuggestion(prompt);

    if (suggestion) {
      await logSuggestion(prompt, suggestion);

      const message = generateSuggestionMessage(suggestion);

      console.error(`[fabric-suggester] Suggested: ${suggestion.type}`);

      return {
        proceed: true,
        hookSpecificOutput: {
          hookEventName: 'UserPromptSubmit',
          fabricSuggestion: true,
          suggestionType: suggestion.type,
          additionalContext: '\n--- ' + message + ' ---\n'
        }
      };
    }
  } catch (err) {
    console.error(`[fabric-suggester] Error: ${err.message}`);
  }

  return { proceed: true };
}

/**
 * Main function - reads from stdin, processes, outputs to stdout
 */
async function main() {
  const chunks = [];
  for await (const chunk of process.stdin) {
    chunks.push(chunk);
  }
  const input = Buffer.concat(chunks).toString('utf8');

  let context;
  try {
    context = JSON.parse(input);
  } catch (err) {
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  const result = await handleHook(context);
  console.log(JSON.stringify(result));
}

main().catch(err => {
  console.error(`[fabric-suggester] Fatal error: ${err.message}`);
  console.log(JSON.stringify({ proceed: true }));
});
