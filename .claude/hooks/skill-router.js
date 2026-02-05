#!/usr/bin/env node
/**
 * Skill Router Hook
 *
 * Detects slash command invocations and provides parent skill context.
 * This helps Claude understand the broader workflow when running individual commands.
 *
 * Features:
 * - Parses command frontmatter for `skill:` field
 * - Reads parent skill's SKILL.md for context
 * - Suggests related commands within the skill
 * - Detects standalone commands (no skill parent)
 *
 * Created: 2026-01-22
 * Synced from AIProjects: 2026-02-05 (v2.1)
 */

const fs = require('fs').promises;
const path = require('path');

// Configuration - uses __dirname for portability
const COMMANDS_DIR = path.join(__dirname, '..', 'commands');
const SKILLS_DIR = path.join(__dirname, '..', 'skills');
const LOG_DIR = path.join(__dirname, '..', 'logs');

// Patterns to detect slash commands
const SLASH_COMMAND_PATTERN = /^\/([a-zA-Z][a-zA-Z0-9_-]*(?::[a-zA-Z0-9_-]+)?)\s*/;

/**
 * Parse YAML-like frontmatter from markdown content
 */
function parseFrontmatter(content) {
  const match = content.match(/^---\n([\s\S]*?)\n---/);
  if (!match) return {};

  const frontmatter = {};
  const lines = match[1].split('\n');

  for (const line of lines) {
    const colonIndex = line.indexOf(':');
    if (colonIndex > 0) {
      const key = line.substring(0, colonIndex).trim();
      let value = line.substring(colonIndex + 1).trim();

      // Remove quotes
      if ((value.startsWith('"') && value.endsWith('"')) ||
          (value.startsWith("'") && value.endsWith("'"))) {
        value = value.slice(1, -1);
      }

      frontmatter[key] = value;
    }
  }

  return frontmatter;
}

/**
 * Find command file and extract frontmatter
 */
async function getCommandInfo(commandName) {
  // Handle namespaced commands (e.g., "commits:status" -> "commits/status.md")
  const parts = commandName.split(':');

  let possiblePaths = [];
  if (parts.length === 2) {
    possiblePaths = [
      path.join(COMMANDS_DIR, parts[0], `${parts[1]}.md`),
      path.join(COMMANDS_DIR, `${parts[0]}-${parts[1]}.md`)
    ];
  } else {
    possiblePaths = [
      path.join(COMMANDS_DIR, `${commandName}.md`)
    ];
  }

  for (const cmdPath of possiblePaths) {
    try {
      const content = await fs.readFile(cmdPath, 'utf8');
      const frontmatter = parseFrontmatter(content);
      return {
        path: cmdPath,
        frontmatter,
        found: true
      };
    } catch {
      // File not found, try next path
    }
  }

  return { found: false };
}

/**
 * Get skill summary from SKILL.md
 */
async function getSkillSummary(skillName) {
  const skillPath = path.join(SKILLS_DIR, skillName, 'SKILL.md');

  try {
    const content = await fs.readFile(skillPath, 'utf8');

    // Extract first paragraph after title (overview)
    const lines = content.split('\n');
    let inOverview = false;
    let overview = [];

    for (const line of lines) {
      if (line.startsWith('## ')) {
        if (overview.length > 0) break;
        inOverview = line.includes('Overview') || line.includes('Purpose');
        continue;
      }
      if (inOverview && line.trim()) {
        overview.push(line.trim());
        if (overview.length >= 3) break; // Max 3 lines
      }
    }

    // Get list of related commands
    const commandsMatch = content.match(/## (?:Commands|Key Commands|Available Commands)[\s\S]*?(?=##|$)/);
    let commands = [];
    if (commandsMatch) {
      const cmdMatches = commandsMatch[0].matchAll(/`\/([^`]+)`/g);
      for (const m of cmdMatches) {
        commands.push(m[1]);
      }
    }

    return {
      found: true,
      overview: overview.join(' '),
      commands: commands.slice(0, 5) // Max 5 related commands
    };
  } catch {
    return { found: false };
  }
}

/**
 * Log skill routing for analytics
 */
async function logRouting(commandName, skillName, standalone) {
  try {
    await fs.mkdir(LOG_DIR, { recursive: true });
    const logPath = path.join(LOG_DIR, 'skill-routing.jsonl');

    const entry = {
      timestamp: new Date().toISOString(),
      command: commandName,
      skill: skillName || null,
      standalone: standalone || false
    };

    await fs.appendFile(logPath, JSON.stringify(entry) + '\n');
  } catch {
    // Logging is best-effort
  }
}

/**
 * Main handler logic
 */
async function handleHook(context) {
  const { prompt } = context;

  if (!prompt || prompt.length < 2) {
    return { proceed: true };
  }

  // Check if this looks like a slash command
  const match = prompt.match(SLASH_COMMAND_PATTERN);
  if (!match) {
    return { proceed: true };
  }

  const commandName = match[1];

  try {
    // Get command info
    const cmdInfo = await getCommandInfo(commandName);

    if (!cmdInfo.found) {
      // Command file not found, proceed without context
      return { proceed: true };
    }

    const { frontmatter } = cmdInfo;

    // Check for standalone flag
    if (frontmatter.standalone === 'true' || frontmatter.standalone === true) {
      await logRouting(commandName, null, true);

      return {
        proceed: true,
        hookSpecificOutput: {
          hookEventName: 'UserPromptSubmit',
          skillRouter: true,
          additionalContext: `\n--- Standalone Command ---\n` +
            `/${commandName} is a specialized command that runs independently.\n` +
            (frontmatter.note ? `Note: ${frontmatter.note}\n` : '') +
            `---`
        }
      };
    }

    // Check for skill mapping
    const skillName = frontmatter.skill;

    if (!skillName) {
      // No skill mapping, proceed without context
      return { proceed: true };
    }

    // Get skill context
    const skillSummary = await getSkillSummary(skillName);

    await logRouting(commandName, skillName, false);

    if (!skillSummary.found) {
      // Skill reference exists but SKILL.md not found
      return {
        proceed: true,
        hookSpecificOutput: {
          hookEventName: 'UserPromptSubmit',
          skillRouter: true,
          additionalContext: `\n--- Skill Context ---\n` +
            `/${commandName} is part of the **${skillName}** skill.\n` +
            `See: .claude/skills/${skillName}/SKILL.md\n---`
        }
      };
    }

    // Build context message
    let contextMessage = `\n--- Skill Context: ${skillName} ---\n`;

    if (skillSummary.overview) {
      contextMessage += `${skillSummary.overview}\n\n`;
    }

    if (skillSummary.commands.length > 0) {
      const otherCommands = skillSummary.commands
        .filter(c => c !== commandName)
        .slice(0, 3);

      if (otherCommands.length > 0) {
        contextMessage += `Related commands: ${otherCommands.map(c => '/' + c).join(', ')}\n`;
      }
    }

    contextMessage += `Full workflow: .claude/skills/${skillName}/SKILL.md\n---`;

    console.error(`[skill-router] Routed /${commandName} → ${skillName}`);

    return {
      proceed: true,
      hookSpecificOutput: {
        hookEventName: 'UserPromptSubmit',
        skillRouter: true,
        skill: skillName,
        command: commandName,
        additionalContext: contextMessage
      }
    };

  } catch (err) {
    console.error(`[skill-router] Error: ${err.message}`);
    return { proceed: true };
  }
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
  } catch {
    console.log(JSON.stringify({ proceed: true }));
    return;
  }

  const result = await handleHook(context);
  console.log(JSON.stringify(result));
}

main().catch(err => {
  console.error(`[skill-router] Fatal error: ${err.message}`);
  console.log(JSON.stringify({ proceed: true }));
});
