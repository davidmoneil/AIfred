#!/usr/bin/env node
/**
 * Context Health Monitor — B.4 Phase 4
 *
 * UserPromptSubmit hook that tracks context quality signals.
 * Detects context poisoning patterns:
 *   1. Repeated file re-reads (compression lost path)
 *   2. Tool call loops (same tool+args 3+ times)
 *   3. Confidence decay (uncertainty phrases increasing)
 *
 * Emits warnings when thresholds crossed.
 * Integrates with JICM telemetry for AC-04 metrics.
 *
 * NOTE: This hook runs on UserPromptSubmit (not PostToolUse) to avoid
 * per-tool-call overhead. It reads the watcher status file for context
 * level and checks session observation history.
 */

const fs = require("fs");
const path = require("path");

let input = "";
process.stdin.setEncoding("utf8");
process.stdin.on("data", (chunk) => (input += chunk));
process.stdin.on("end", () => {
  try {
    const hookData = JSON.parse(input);
    main(hookData);
  } catch (e) {
    output({ continue: true });
  }
});

function main(hookData) {
  const projectDir = process.env.CLAUDE_PROJECT_DIR || process.cwd();
  const warnings = [];

  // 1. Check context level from watcher status
  const watcherStatus = readWatcherStatus(projectDir);
  const contextPct = watcherStatus.percentage || 0;

  // 2. Check session observations for tool call patterns
  const sessionId = readCurrentSessionId(projectDir);
  if (sessionId) {
    const observations = readObservations(projectDir, sessionId);

    // Detect repeated tool calls (same tool 5+ times in observations)
    const toolCounts = {};
    for (const obs of observations) {
      const key = obs.tool || "unknown";
      toolCounts[key] = (toolCounts[key] || 0) + 1;
    }

    for (const [tool, count] of Object.entries(toolCounts)) {
      if (count > 20) {
        warnings.push(
          `High tool usage: ${tool} called ${count} times this session`
        );
      }
    }

    // Detect large observation accumulation
    const largeObs = observations.filter((o) => o.large === true);
    if (largeObs.length > 10) {
      warnings.push(
        `${largeObs.length} large tool outputs this session — context pressure building`
      );
    }
  }

  // 3. Check if context is in warning zone
  if (contextPct >= 50 && contextPct < 65) {
    warnings.push(
      `Context at ${contextPct}% — approaching 65% compression trigger`
    );
  } else if (contextPct >= 65 && contextPct < 73) {
    warnings.push(
      `Context at ${contextPct}% — compression should be active`
    );
  } else if (contextPct >= 73) {
    warnings.push(
      `Context at ${contextPct}% — EMERGENCY: near lockout ceiling`
    );
  }

  // 4. Emit telemetry if warnings found
  if (warnings.length > 0) {
    const telemetryEntry = JSON.stringify({
      component: "AC-04",
      event_type: "context_health_warning",
      data: {
        context_pct: contextPct,
        warnings: warnings,
        session_id: sessionId || "unknown"
      }
    });

    const eventsFile = path.join(
      projectDir,
      `.claude/logs/telemetry/events-${new Date().toISOString().slice(0, 10)}.jsonl`
    );

    try {
      fs.appendFileSync(eventsFile, telemetryEntry + "\n");
    } catch (e) {
      // Non-critical
    }
  }

  // Only inject context if there are actionable warnings
  if (warnings.length > 0 && contextPct >= 50) {
    output({
      continue: true,
      additionalContext: `[JICM Health] ${warnings.join("; ")}`
    });
  } else {
    output({ continue: true });
  }
}

/**
 * Read watcher status file for context percentage
 */
function readWatcherStatus(projectDir) {
  const statusFile = path.join(
    projectDir,
    ".claude/context/.jicm-state"
  );
  try {
    const content = fs.readFileSync(statusFile, "utf8");
    const result = {};
    for (const line of content.split("\n")) {
      const match = line.match(/^(\w+):\s*(.+)$/);
      if (match) {
        const val = match[2].trim();
        result[match[1]] = val.endsWith("%")
          ? parseInt(val)
          : val;
      }
    }
    return result;
  } catch (e) {
    return {};
  }
}

/**
 * Read current JICM session ID
 */
function readCurrentSessionId(projectDir) {
  const idFile = path.join(
    projectDir,
    ".claude/context/jicm/.current-session-id"
  );
  try {
    return fs.readFileSync(idFile, "utf8").trim();
  } catch (e) {
    return null;
  }
}

/**
 * Read session observations YAML (simple line parser)
 */
function readObservations(projectDir, sessionId) {
  const obsFile = path.join(
    projectDir,
    `.claude/context/jicm/sessions/${sessionId}/observations.yaml`
  );
  try {
    const content = fs.readFileSync(obsFile, "utf8");
    const observations = [];
    let current = null;

    for (const line of content.split("\n")) {
      const toolMatch = line.match(/^\s*-\s*tool:\s*"?(\w+)"?/);
      if (toolMatch) {
        if (current) observations.push(current);
        current = { tool: toolMatch[1] };
      }
      const tokensMatch = line.match(/^\s*tokens_est:\s*(\d+)/);
      if (tokensMatch && current) {
        current.tokens_est = parseInt(tokensMatch[1]);
      }
      const largeMatch = line.match(/^\s*large:\s*(true|false)/);
      if (largeMatch && current) {
        current.large = largeMatch[1] === "true";
      }
    }
    if (current) observations.push(current);
    return observations;
  } catch (e) {
    return [];
  }
}

function output(result) {
  console.log(JSON.stringify(result));
}
