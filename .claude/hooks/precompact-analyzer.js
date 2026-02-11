#!/usr/bin/env node
/**
 * PreCompact Analyzer Hook
 *
 * JICM v6.1 Backup Defense: AI-Driven Context Prioritization
 *
 * This hook fires before native auto-compact triggers. It:
 * 1. Reads current context status from statusline JSON
 * 2. Reads current-priorities.md and session-state.md
 * 3. Generates a preservation manifest for the compression agent
 * 4. The manifest tells the compressor what to preserve vs compress
 *
 * Note: This is a BACKUP defense. JICM v6 watcher handles proactive
 * context management. This hook only fires if the watcher misses.
 */

const fs = require("fs");
const path = require("path");

// Parse hook input from stdin
let input = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  try {
    const hookData = JSON.parse(input);
    main(hookData);
  } catch (e) {
    // No input or invalid JSON - still run analysis
    main({});
  }
});

function main(hookData) {
  const projectDir =
    process.env.CLAUDE_PROJECT_DIR || process.cwd();

  // Only run for auto-compact, not manual /compact
  // Hook event provides matcher info
  if (hookData.matcher === "manual") {
    output({ continue: true });
    return;
  }

  // Read current context status
  const statuslineFile = path.join(
    process.env.HOME,
    ".claude/logs/statusline-input.json"
  );
  const prioritiesFile = path.join(
    projectDir,
    ".claude/context/current-priorities.md"
  );
  const stateFile = path.join(
    projectDir,
    ".claude/context/session-state.md"
  );

  let contextData = {};
  let priorities = "";
  let sessionState = "";

  // Read context status
  try {
    const statusContent = fs.readFileSync(statuslineFile, "utf8");
    contextData = JSON.parse(statusContent);
  } catch (e) {
    console.error("PreCompact: Could not read statusline data:", e.message);
  }

  // Read priorities
  try {
    priorities = fs.readFileSync(prioritiesFile, "utf8");
  } catch (e) {
    // File may not exist
  }

  // Read session state
  try {
    sessionState = fs.readFileSync(stateFile, "utf8");
  } catch (e) {
    // File may not exist
  }

  // Generate preservation manifest
  const manifest = generateManifest(contextData, priorities, sessionState);

  // Write manifest for context-compressor agent
  const manifestPath = path.join(
    projectDir,
    ".claude/context/.preservation-manifest.json"
  );

  try {
    fs.mkdirSync(path.dirname(manifestPath), { recursive: true });
    fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
  } catch (e) {
    console.error("PreCompact: Could not write manifest:", e.message);
  }

  // Log action
  const logPath = path.join(projectDir, ".claude/logs/precompact-analyzer.log");
  const logEntry = `${new Date().toISOString()} | PreCompact analysis complete | ${manifest.preserve.length} items to preserve | ${manifest.compress.length} items to compress\n`;

  try {
    fs.appendFileSync(logPath, logEntry);
  } catch (e) {
    // Log failure is not critical
  }

  // Return success with context for Claude
  output({
    continue: true,
    additionalContext: `JICM PreCompact Analysis Complete.
Preservation manifest written to ${manifestPath}
Context usage: ${contextData.context_window?.used_percentage || "unknown"}%
Items to preserve: ${manifest.preserve.length}
Items to compress: ${manifest.compress.length}

When compressing context, prioritize items marked as "critical" in the manifest.`
  });
}

/**
 * Generate preservation manifest based on current state
 */
function generateManifest(contextData, priorities, sessionState) {
  const manifest = {
    version: "1.0.0",
    timestamp: new Date().toISOString(),
    context_status: {
      used_percentage: contextData.context_window?.used_percentage || 0,
      remaining_percentage: contextData.context_window?.remaining_percentage || 100,
      total_tokens:
        (contextData.context_window?.total_input_tokens || 0) +
        (contextData.context_window?.total_output_tokens || 0)
    },
    preserve: [],
    compress: [],
    discard: []
  };

  // Extract active tasks from priorities
  const activeTasks = extractActiveTasks(priorities);
  activeTasks.forEach((task) => {
    manifest.preserve.push({
      type: "task",
      content: task,
      priority: "critical",
      reason: "Active task from current-priorities.md"
    });
  });

  // Extract key decisions from session state
  const decisions = extractDecisions(sessionState);
  decisions.forEach((decision) => {
    manifest.preserve.push({
      type: "decision",
      content: decision,
      priority: "high",
      reason: "Decision from session-state.md"
    });
  });

  // Extract work status from session state
  const workStatus = extractWorkStatus(sessionState);
  if (workStatus) {
    manifest.preserve.push({
      type: "work_status",
      content: workStatus,
      priority: "critical",
      reason: "Current work status for liftover"
    });
  }

  // Generic compression rules
  manifest.compress.push({
    type: "tool_output",
    age_minutes: 30,
    priority: "low",
    reason: "Old tool outputs can be summarized"
  });

  manifest.compress.push({
    type: "exploration",
    relevance: "low",
    priority: "low",
    reason: "Exploration outputs not directly related to current tasks"
  });

  manifest.discard.push({
    type: "error_trace",
    resolved: true,
    reason: "Resolved errors no longer needed"
  });

  manifest.discard.push({
    type: "verbose_output",
    size_tokens: 5000,
    reason: "Very large outputs should be summarized to reference only"
  });

  return manifest;
}

/**
 * Extract active tasks from priorities markdown
 */
function extractActiveTasks(priorities) {
  const tasks = [];
  if (!priorities) return tasks;

  const lines = priorities.split("\n");
  let inActiveSection = false;

  for (const line of lines) {
    // Look for active/current section headers
    if (
      line.match(/^##\s*(Active|Current|In Progress|Priority)/i)
    ) {
      inActiveSection = true;
    } else if (line.match(/^##\s/)) {
      inActiveSection = false;
    } else if (inActiveSection) {
      // Match checkbox items (incomplete)
      const checkboxMatch = line.match(/^[-*]\s+\[\s\]\s+(.+)/);
      if (checkboxMatch) {
        tasks.push(checkboxMatch[1].trim());
      }
      // Match plain list items in active section
      const listMatch = line.match(/^[-*]\s+(?!\[)(.+)/);
      if (listMatch && !line.includes("[x]")) {
        tasks.push(listMatch[1].trim());
      }
    }
  }

  return tasks;
}

/**
 * Extract decisions from session state markdown
 */
function extractDecisions(sessionState) {
  const decisions = [];
  if (!sessionState) return decisions;

  const lines = sessionState.split("\n");

  for (const line of lines) {
    // Look for decision patterns
    if (
      line.match(/Decision:|Decided:|chose:|selected:|approach:/i)
    ) {
      decisions.push(line.trim());
    }
  }

  return decisions;
}

/**
 * Extract current work status block
 */
function extractWorkStatus(sessionState) {
  if (!sessionState) return null;

  // Look for the work status section
  const statusMatch = sessionState.match(
    /## Current Work Status[\s\S]*?(?=\n---|\n## |$)/
  );

  if (statusMatch) {
    return statusMatch[0].trim();
  }

  return null;
}

/**
 * Output hook result
 */
function output(result) {
  console.log(JSON.stringify(result));
}
